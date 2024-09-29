use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::io::stdout;
use std::os::unix::fs::PermissionsExt;
use toml::Value;
use ratatui::{
    backend::CrosstermBackend,
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
    layout::{Layout, Constraint, Direction, Alignment},
    style::{Color, Modifier, Style},
    text::{Span, Spans},
    Terminal,
};
use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    cursor::{MoveTo, Show, Hide},
    terminal::Clear,
    terminal::ClearType,
};
use reqwest::blocking::Client;
use serde_json::Value as JsonValue;

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

enum MenuState {
    Categories,
    Programs,
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
    execute!(stdout(), Clear(ClearType::All), MoveTo(0, 0))?;

    let status = Command::new("bash")
        .arg("-c")
        .arg(script.to_str().unwrap())
        .status()?;

    if !status.success() {
        eprintln!("Script exited with non-zero status");
    }

    println!("\nPress Enter to return to the menu...");
    let mut input = String::new();
    std::io::stdin().read_line(&mut input)?;

    Ok(())
}

fn check_for_updates() -> Result<Option<String>, Box<dyn std::error::Error>> {
    let client = Client::new();
    let url = format!("https://api.github.com/repos/{}/releases/latest", GITHUB_REPO);
    
    println!("Checking for updates at: {}", url);
    
    let response = client.get(&url).send()?;
    
    if !response.status().is_success() {
        println!("Failed to check for updates. Status: {}", response.status());
        return Ok(None);
    }
    
    let body = response.text()?;
    
    match serde_json::from_str::<JsonValue>(&body) {
        Ok(json) => {
            if let Some(tag_name) = json["tag_name"].as_str() {
                if tag_name != CURRENT_VERSION {
                    Ok(Some(tag_name.to_string()))
                } else {
                    Ok(None)
                }
            } else {
                println!("No tag_name found in the response");
                Ok(None)
            }
        },
        Err(e) => {
            println!("Failed to parse JSON: {}", e);
            println!("Response body: {}", body);
            Ok(None)
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    enable_raw_mode()?;
    let mut stdout = stdout();
    execute!(stdout, EnterAlternateScreen, Hide)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let config_path = PathBuf::from("config.toml");
    let config = fs::read_to_string(&config_path)?;
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

    let mut selected_category = 0;
    let mut selected_program = 0;
    let mut category_state = ListState::default();
    let mut program_state = ListState::default();
    let mut menu_state = MenuState::Categories;

    let update_available = check_for_updates()?;

    loop {
        category_state.select(Some(selected_category));
        program_state.select(Some(selected_program));

        terminal.draw(|f| {
            let size = f.size();
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Length(3),
                    Constraint::Min(5),
                    Constraint::Length(3)
                ].as_ref())
                .split(size);

            // Title bar
            let mut title_text = vec![
                Span::styled("Linux Toolbox ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
                Span::styled(format!("v{}", CURRENT_VERSION), Style::default().fg(Color::Yellow)),
                Span::raw(" by "),
                Span::styled("Tech Logicals", Style::default().fg(Color::Green).add_modifier(Modifier::ITALIC)),
            ];
            if let Some(new_version) = &update_available {
                title_text.push(Span::raw(" ("));
                title_text.push(Span::styled(format!("Update v{} available", new_version), Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)));
                title_text.push(Span::raw(")"));
            }
            let title = Paragraph::new(Spans::from(title_text))
                .alignment(Alignment::Center)
                .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(Color::DarkGray)));
            f.render_widget(title, chunks[0]);

            let main_chunks = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([
                    Constraint::Percentage(30),
                    Constraint::Percentage(70)
                ].as_ref())
                .split(chunks[1]);

            // Categories
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
            f.render_stateful_widget(categories_list, main_chunks[0], &mut category_state);

            // Programs
            let program_items: Vec<ListItem> = categories[selected_category]
                .programs
                .iter()
                .map(|p| {
                    ListItem::new(Spans::from(vec![
                        Span::styled("▶ ", Style::default().fg(Color::Green)),
                        Span::raw(p.name.clone()),
                    ]))
                })
                .collect();
            let programs_list = List::new(program_items)
                .block(Block::default().title("Programs").borders(Borders::ALL).border_style(Style::default().fg(Color::Magenta)))
                .highlight_style(Style::default().bg(Color::DarkGray).add_modifier(Modifier::BOLD))
                .highlight_symbol(">> ");
            f.render_stateful_widget(programs_list, main_chunks[1], &mut program_state);

            // Help text
            let help_text = match menu_state {
                MenuState::Categories => "↑↓: Navigate | Enter: Select | q: Quit",
                MenuState::Programs => "↑↓: Navigate | Enter: Run | Esc/Backspace: Back | q: Quit",
            };
            let help_paragraph = Paragraph::new(help_text)
                .style(Style::default().fg(Color::Gray))
                .alignment(Alignment::Center)
                .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(Color::DarkGray)));
            f.render_widget(help_paragraph, chunks[2]);
        })?;

        if let Event::Key(key) = event::read()? {
            match menu_state {
                MenuState::Categories => match key.code {
                    KeyCode::Char('q') => break,
                    KeyCode::Up => {
                        if selected_category > 0 {
                            selected_category -= 1;
                        }
                    }
                    KeyCode::Down => {
                        if selected_category < categories.len() - 1 {
                            selected_category += 1;
                        }
                    }
                    KeyCode::Enter => {
                        menu_state = MenuState::Programs;
                        selected_program = 0;
                    }
                    _ => {}
                },
                MenuState::Programs => match key.code {
                    KeyCode::Char('q') => break,
                    KeyCode::Up => {
                        if selected_program > 0 {
                            selected_program -= 1;
                        }
                    }
                    KeyCode::Down => {
                        if selected_program < categories[selected_category].programs.len() - 1 {
                            selected_program += 1;
                        }
                    }
                    KeyCode::Enter => {
                        let script = &categories[selected_category].programs[selected_program].script;
                        ensure_executable(script)?;
                        run_script(script)?;
                        enable_raw_mode()?;
                        execute!(terminal.backend_mut(), EnterAlternateScreen, Hide)?;
                        terminal.clear()?;
                    }
                    KeyCode::Esc | KeyCode::Backspace => {
                        menu_state = MenuState::Categories;
                    }
                    _ => {}
                },
            }
        }
    }

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, Show)?;

    Ok(())
}