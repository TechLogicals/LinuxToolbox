use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::io::{stdout, Stdout};
use std::os::unix::fs::PermissionsExt;
use toml::Value;
use ratatui::{
    backend::{Backend, CrosstermBackend},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Clear},
    layout::{Layout, Constraint, Direction, Alignment},
    style::{Color, Modifier, Style},
    text::{Span, Spans},
    Terminal, Frame,
};
use crossterm::{
    event::{self, Event, KeyCode, KeyEvent},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    cursor::{MoveTo, Show, Hide},
};
use reqwest::blocking::Client;
use serde_json::Value as JsonValue;
use semver::Version;

const CURRENT_VERSION: &str = "0.04";
const GITHUB_REPO: &str = "TechLogicals/LinuxToolbox";

struct Category {
    name: String,
    programs: Vec<Program>,
}

struct Program {
    name: String,
    script: PathBuf,
}

#[derive(PartialEq)]
enum MenuState {
    Categories,
    Programs,
    Search,
}

fn setup_terminal() -> Result<Terminal<CrosstermBackend<Stdout>>, Box<dyn std::error::Error>> {
    enable_raw_mode()?;
    let mut stdout = stdout();
    execute!(stdout, EnterAlternateScreen, Hide)?;
    let backend = CrosstermBackend::new(stdout);
    let terminal = Terminal::new(backend)?;
    Ok(terminal)
}

fn load_config(config_path: &PathBuf) -> Result<(Vec<Category>, PathBuf), Box<dyn std::error::Error>> {
    let config = fs::read_to_string(config_path)?;
    let config: Value = toml::from_str(&config)?;

    let default_dir = PathBuf::from(".");
    let config_dir = config_path.parent().unwrap_or(&default_dir);

    let mut categories = Vec::new();
    for (category_name, category_value) in config.as_table().unwrap() {
        let mut programs = Vec::new();
        for (program_name, program_value) in category_value.as_table().unwrap() {
            let script_path = config_dir.join(program_value.as_str().unwrap());
            programs.push(Program {
                name: program_name.to_string(),
                script: script_path,
            });
        }
        categories.push(Category {
            name: category_name.to_string(),
            programs,
        });
    }

    Ok((categories, config_dir.to_path_buf()))
}

fn check_for_updates() -> Result<Option<String>, Box<dyn std::error::Error>> {
    let client = Client::new();
    let url = format!("https://api.github.com/repos/{}/releases/latest", GITHUB_REPO);
    let response = client.get(&url).header("User-Agent", "LinuxToolbox").send()?;
    
    if response.status().is_success() {
        let json: JsonValue = response.json()?;
        if let Some(tag_name) = json["tag_name"].as_str() {
            let latest_version = Version::parse(&tag_name.trim_start_matches('v'))?;
            let current_version = Version::parse(CURRENT_VERSION)?;
            
            if latest_version > current_version {
                return Ok(Some(latest_version.to_string()));
            }
        }
    }
    
    Ok(None)
}

fn ensure_executable(path: &PathBuf) -> std::io::Result<()> {
    let metadata = fs::metadata(path)?;
    let mut permissions = metadata.permissions();
    let mode = permissions.mode();
    if mode & 0o111 == 0 {
        permissions.set_mode(mode | 0o111);
        fs::set_permissions(path, permissions)?;
    }
    Ok(())
}

fn run_script(script: &PathBuf) -> std::io::Result<()> {
    disable_raw_mode()?;
    execute!(stdout(), LeaveAlternateScreen, Show)?;
    execute!(stdout(), crossterm::terminal::Clear(crossterm::terminal::ClearType::All), MoveTo(0, 0))?;

    let status = Command::new("bash")
        .arg("-c")
        .arg(script.to_str().unwrap())
        .status()?;

    if !status.success() {
        println!("Script exited with non-zero status code");
    }

    println!("Press any key to continue...");
    let _ = event::read()?;

    Ok(())
}

fn handle_input<'a>(
    key: KeyEvent,
    menu_state: &mut MenuState,
    selected_category: &mut usize,
    selected_program: &mut usize,
    categories: &'a [Category],
    search_query: &mut String,
    filtered_programs: &mut Vec<(&'a Category, &'a Program)>,
    category_state: &mut ListState,
    program_state: &mut ListState,
) -> bool {
    match menu_state {
        MenuState::Categories => match key.code {
            KeyCode::Char('q') => return true,
            KeyCode::Char('/') => {
                *menu_state = MenuState::Search;
                search_query.clear();
            }
            KeyCode::Up => {
                if *selected_category > 0 {
                    *selected_category -= 1;
                    category_state.select(Some(*selected_category));
                }
            }
            KeyCode::Down => {
                if *selected_category < categories.len() - 1 {
                    *selected_category += 1;
                    category_state.select(Some(*selected_category));
                }
            }
            KeyCode::Enter => {
                *menu_state = MenuState::Programs;
                *selected_program = 0;
                program_state.select(Some(0));
            }
            _ => {}
        },
        MenuState::Programs => match key.code {
            KeyCode::Char('q') => return true,
            KeyCode::Char('/') => {
                *menu_state = MenuState::Search;
                search_query.clear();
            }
            KeyCode::Up => {
                if *selected_program > 0 {
                    *selected_program -= 1;
                    program_state.select(Some(*selected_program));
                }
            }
            KeyCode::Down => {
                if *selected_program < categories[*selected_category].programs.len() - 1 {
                    *selected_program += 1;
                    program_state.select(Some(*selected_program));
                }
            }
            KeyCode::Enter => {
                return true;
            }
            KeyCode::Esc | KeyCode::Backspace => {
                *menu_state = MenuState::Categories;
                *selected_program = 0;
                program_state.select(Some(0));
            }
            _ => {}
        },
        MenuState::Search => match key.code {
            KeyCode::Enter => {
                if !filtered_programs.is_empty() {
                    return true;
                }
            }
            KeyCode::Esc => {
                *menu_state = MenuState::Categories;
                search_query.clear();
            }
            KeyCode::Char(c) => {
                search_query.push(c);
                update_filtered_programs(categories, search_query, filtered_programs);
            }
            KeyCode::Backspace => {
                search_query.pop();
                update_filtered_programs(categories, search_query, filtered_programs);
            }
            _ => {}
        },
    }
    false
}

fn update_filtered_programs<'a>(
    categories: &'a [Category],
    search_query: &str,
    filtered_programs: &mut Vec<(&'a Category, &'a Program)>,
) {
    filtered_programs.clear();
    for category in categories {
        filtered_programs.extend(
            category.programs.iter().filter_map(move |program| {
                if program.name.to_lowercase().contains(&search_query.to_lowercase()) {
                    Some((category, program))
                } else {
                    None
                }
            })
        );
    }
}

fn draw_ui<B: Backend>(
    f: &mut Frame<B>,
    categories: &[Category],
    selected_category: usize,
    category_state: &mut ListState,
    program_state: &mut ListState,
    menu_state: &MenuState,
    search_query: &str,
    filtered_programs: &[(&Category, &Program)],
    update_available: &Option<String>,
) {
    let size = f.size();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Length(3),
            Constraint::Min(5),
            Constraint::Length(3)
        ].as_ref())
        .split(size);

    // Title
    let mut title_text = vec![
        Span::styled("Linux Toolbox ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        Span::styled(format!("v{}", CURRENT_VERSION), Style::default().fg(Color::Yellow)),
        Span::raw(" by "),
        Span::styled("Tech Logicals", Style::default().fg(Color::Green).add_modifier(Modifier::ITALIC)),
    ];

    if let Some(new_version) = update_available {
        title_text.push(Span::raw(" ("));
        title_text.push(Span::styled(format!("Update v{} available", new_version), Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)));
        title_text.push(Span::raw(")"));
    }

    let title = Paragraph::new(Spans::from(title_text))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(Color::DarkGray)));
    f.render_widget(title, chunks[0]);

    // Search bar
    let search_bar = Paragraph::new(search_query)
        .style(Style::default().fg(Color::Yellow))
        .block(Block::default().borders(Borders::ALL).title("Search").border_style(Style::default().fg(Color::Blue)));
    f.render_widget(search_bar, chunks[1]);

    // Main content
    let main_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(40),
            Constraint::Percentage(60)
        ].as_ref())
        .split(chunks[2]);

    // Categories list
    let category_items: Vec<ListItem> = categories
        .iter()
        .map(|c| {
            ListItem::new(Spans::from(vec![
                Span::styled("• ", Style::default().fg(Color::Yellow)),
                Span::raw(c.name.clone()),
            ]))
        })
        .collect();

    let categories_list = List::new(category_items)
        .block(Block::default().title("Categories").borders(Borders::ALL).border_style(Style::default().fg(Color::Cyan)))
        .highlight_style(Style::default().bg(Color::DarkGray).add_modifier(Modifier::BOLD))
        .highlight_symbol(">> ");

    f.render_stateful_widget(categories_list, main_chunks[0], category_state);

    // Programs list
    let program_items: Vec<ListItem> = if *menu_state == MenuState::Search {
        filtered_programs.iter().map(|(_, p)| {
            ListItem::new(Spans::from(vec![
                Span::styled("▶ ", Style::default().fg(Color::Green)),
                Span::raw(p.name.clone()),
            ]))
        }).collect()
    } else {
        categories[selected_category].programs.iter().map(|p| {
            ListItem::new(Spans::from(vec![
                Span::styled("▶ ", Style::default().fg(Color::Green)),
                Span::raw(p.name.clone()),
            ]))
        }).collect()
    };

    let programs_list = List::new(program_items)
        .block(Block::default().title("Programs").borders(Borders::ALL).border_style(Style::default().fg(Color::Magenta)))
        .highlight_style(Style::default().bg(Color::DarkGray).add_modifier(Modifier::BOLD))
        .highlight_symbol(">> ");

    f.render_stateful_widget(programs_list, main_chunks[1], program_state);

    // Help text
    let help_text = match menu_state {
        MenuState::Categories => "↑↓: Navigate | Enter: Select | /: Search | q: Quit",
        MenuState::Programs => "↑↓: Navigate | Enter: Run | Esc/Backspace: Back | /: Search | q: Quit",
        MenuState::Search => "Type to search | Enter: Select | Esc: Cancel",
    };

    let help_paragraph = Paragraph::new(help_text)
        .style(Style::default().fg(Color::Gray))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(Color::DarkGray)));
    f.render_widget(help_paragraph, chunks[3]);
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut terminal = setup_terminal()?;
    let config_path = PathBuf::from("config.toml");
    let (categories, _config_dir) = load_config(&config_path)?;

    let mut selected_category = 0;
    let mut selected_program = 0;
    let mut category_state = ListState::default();
    category_state.select(Some(0));
    let mut program_state = ListState::default();
    program_state.select(Some(0));
    let mut menu_state = MenuState::Categories;
    let mut search_query = String::new();
    let mut filtered_programs: Vec<(&Category, &Program)> = Vec::new();

    let update_available = check_for_updates()?;

    // Clear the screen before entering the main loop
    terminal.clear()?;

    loop {
        terminal.draw(|f| {
            // Clear the screen at the start of each draw
            f.render_widget(Clear, f.size());
            
            draw_ui(
                f,
                &categories,
                selected_category,
                &mut category_state,
                &mut program_state,
                &menu_state,
                &search_query,
                &filtered_programs,
                &update_available,
            )
        })?;

        if let Event::Key(key) = event::read()? {
            let should_run_script = handle_input(
                key,
                &mut menu_state,
                &mut selected_category,
                &mut selected_program,
                &categories,
                &mut search_query,
                &mut filtered_programs,
                &mut category_state,
                &mut program_state,
            );

            if should_run_script {
                let script = match menu_state {
                    MenuState::Programs => &categories[selected_category].programs[selected_program].script,
                    MenuState::Search => &filtered_programs[selected_program].1.script,
                    _ => continue,
                };

                ensure_executable(script)?;
                run_script(script)?;
                enable_raw_mode()?;
                execute!(terminal.backend_mut(), EnterAlternateScreen, Hide)?;
                terminal.clear()?;
            }

            if key.code == KeyCode::Char('q') && menu_state != MenuState::Search {
                break;
            }
        }
    }

    // Cleanup
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, Show)?;

    Ok(())
}