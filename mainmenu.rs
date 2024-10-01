use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::io::{stdout, Stdout, Read, Write};
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
use serde::{Deserialize, Serialize};

const CURRENT_VERSION: &str = "0.05";
const GITHUB_REPO: &str = "TechLogicals/LinuxToolbox";
const COLOR_SCHEME_FILE: &str = "color_scheme.json";

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

#[derive(Clone, Copy, PartialEq, Serialize, Deserialize)]
enum ColorScheme {
    Default,
    Dark,
    Light,
    Ocean,
    Forest,
    Sunset,
    Neon,
    Pastel,
    Monochrome,
    Autumn,
    Winter,
    Spring,
    Summer,
    Cyberpunk,
    Retro,
    Desert,
    Space,
    Candy,
    Earth,
    Midnight,
}

impl ColorScheme {
    fn next(&self) -> Self {
        match self {
            ColorScheme::Default => ColorScheme::Dark,
            ColorScheme::Dark => ColorScheme::Light,
            ColorScheme::Light => ColorScheme::Ocean,
            ColorScheme::Ocean => ColorScheme::Forest,
            ColorScheme::Forest => ColorScheme::Sunset,
            ColorScheme::Sunset => ColorScheme::Neon,
            ColorScheme::Neon => ColorScheme::Pastel,
            ColorScheme::Pastel => ColorScheme::Monochrome,
            ColorScheme::Monochrome => ColorScheme::Autumn,
            ColorScheme::Autumn => ColorScheme::Winter,
            ColorScheme::Winter => ColorScheme::Spring,
            ColorScheme::Spring => ColorScheme::Summer,
            ColorScheme::Summer => ColorScheme::Cyberpunk,
            ColorScheme::Cyberpunk => ColorScheme::Retro,
            ColorScheme::Retro => ColorScheme::Desert,
            ColorScheme::Desert => ColorScheme::Space,
            ColorScheme::Space => ColorScheme::Candy,
            ColorScheme::Candy => ColorScheme::Earth,
            ColorScheme::Earth => ColorScheme::Midnight,
            ColorScheme::Midnight => ColorScheme::Default,
        }
    }

    fn get_colors(&self) -> (Color, Color, Color) {
        match self {
            ColorScheme::Default => (Color::Reset, Color::White, Color::Cyan),
            ColorScheme::Dark => (Color::Black, Color::White, Color::Yellow),
            ColorScheme::Light => (Color::White, Color::Black, Color::Blue),
            ColorScheme::Ocean => (Color::Rgb(0, 105, 148), Color::White, Color::Rgb(0, 255, 255)),
            ColorScheme::Forest => (Color::Rgb(34, 139, 34), Color::White, Color::Rgb(255, 215, 0)),
            ColorScheme::Sunset => (Color::Rgb(255, 99, 71), Color::White, Color::Rgb(255, 215, 0)),
            ColorScheme::Neon => (Color::Black, Color::Rgb(255, 0, 255), Color::Rgb(0, 255, 0)),
            ColorScheme::Pastel => (Color::Rgb(255, 240, 245), Color::Rgb(70, 130, 180), Color::Rgb(255, 182, 193)),
            ColorScheme::Monochrome => (Color::Black, Color::White, Color::Gray),
            ColorScheme::Autumn => (Color::Rgb(139, 69, 19), Color::White, Color::Rgb(255, 140, 0)),
            ColorScheme::Winter => (Color::Rgb(65, 105, 225), Color::White, Color::Rgb(176, 224, 230)),
            ColorScheme::Spring => (Color::Rgb(144, 238, 144), Color::Black, Color::Rgb(255, 105, 180)),
            ColorScheme::Summer => (Color::Rgb(255, 215, 0), Color::Black, Color::Rgb(0, 191, 255)),
            ColorScheme::Cyberpunk => (Color::Black, Color::Rgb(0, 255, 255), Color::Rgb(255, 0, 255)),
            ColorScheme::Retro => (Color::Rgb(64, 64, 64), Color::Rgb(0, 255, 0), Color::Rgb(255, 165, 0)),
            ColorScheme::Desert => (Color::Rgb(210, 180, 140), Color::Black, Color::Rgb(255, 69, 0)),
            ColorScheme::Space => (Color::Rgb(25, 25, 112), Color::White, Color::Rgb(255, 215, 0)),
            ColorScheme::Candy => (Color::Rgb(255, 192, 203), Color::Black, Color::Rgb(127, 255, 212)),
            ColorScheme::Earth => (Color::Rgb(139, 69, 19), Color::White, Color::Rgb(34, 139, 34)),
            ColorScheme::Midnight => (Color::Rgb(25, 25, 112), Color::White, Color::Rgb(138, 43, 226)),
        }
    }
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
    color_scheme: &mut ColorScheme,
) -> bool {
    match key.code {
        KeyCode::Tab => {
            *color_scheme = color_scheme.next();
            if let Err(e) = save_color_scheme(color_scheme) {
                eprintln!("Failed to save color scheme: {}", e);
            }
            false
        },
        _ => match menu_state {
            MenuState::Categories => match key.code {
                KeyCode::Char('q') => true,
                KeyCode::Char('/') => {
                    *menu_state = MenuState::Search;
                    search_query.clear();
                    false
                }
                KeyCode::Up => {
                    if *selected_category > 0 {
                        *selected_category -= 1;
                        category_state.select(Some(*selected_category));
                    }
                    false
                }
                KeyCode::Down => {
                    if *selected_category < categories.len() - 1 {
                        *selected_category += 1;
                        category_state.select(Some(*selected_category));
                    }
                    false
                }
                KeyCode::Enter => {
                    *menu_state = MenuState::Programs;
                    *selected_program = 0;
                    program_state.select(Some(0));
                    false
                }
                _ => false,
            },
            MenuState::Programs => match key.code {
                KeyCode::Char('q') => true,
                KeyCode::Char('/') => {
                    *menu_state = MenuState::Search;
                    search_query.clear();
                    false
                }
                KeyCode::Up => {
                    if *selected_program > 0 {
                        *selected_program -= 1;
                        program_state.select(Some(*selected_program));
                    }
                    false
                }
                KeyCode::Down => {
                    if *selected_program < categories[*selected_category].programs.len() - 1 {
                        *selected_program += 1;
                        program_state.select(Some(*selected_program));
                    }
                    false
                }
                KeyCode::Enter => true,
                KeyCode::Esc | KeyCode::Backspace => {
                    *menu_state = MenuState::Categories;
                    *selected_program = 0;
                    program_state.select(Some(0));
                    false
                }
                _ => false,
            },
            MenuState::Search => match key.code {
                KeyCode::Enter => !filtered_programs.is_empty(),
                KeyCode::Esc => {
                    *menu_state = MenuState::Categories;
                    search_query.clear();
                    false
                }
                KeyCode::Char(c) => {
                    search_query.push(c);
                    update_filtered_programs(categories, search_query, filtered_programs);
                    false
                }
                KeyCode::Backspace => {
                    search_query.pop();
                    update_filtered_programs(categories, search_query, filtered_programs);
                    false
                }
                _ => false,
            },
        },
    }
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
    color_scheme: &ColorScheme,
) {
    let (bg_color, fg_color, highlight_color) = color_scheme.get_colors();

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
        Span::styled("Linux Toolbox ", Style::default().fg(highlight_color).add_modifier(Modifier::BOLD)),
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
    .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)));
f.render_widget(title, chunks[0]);

// Search bar
let search_bar = Paragraph::new(search_query)
    .style(Style::default().fg(highlight_color))
    .block(Block::default().borders(Borders::ALL).title("Search").border_style(Style::default().fg(fg_color).bg(bg_color)));
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
            Span::styled("• ", Style::default().fg(highlight_color)),
            Span::raw(c.name.clone()),
        ]))
    })
    .collect();

let categories_list = List::new(category_items)
    .block(Block::default().title("Categories").borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)))
    .highlight_style(Style::default().bg(highlight_color).fg(bg_color).add_modifier(Modifier::BOLD))
    .highlight_symbol(">> ");

f.render_stateful_widget(categories_list, main_chunks[0], category_state);

// Programs list
let program_items: Vec<ListItem> = if *menu_state == MenuState::Search {
    filtered_programs.iter().map(|(_, p)| {
        ListItem::new(Spans::from(vec![
            Span::styled("▶ ", Style::default().fg(highlight_color)),
            Span::raw(p.name.clone()),
        ]))
    }).collect()
} else {
    categories[selected_category].programs.iter().map(|p| {
        ListItem::new(Spans::from(vec![
            Span::styled("▶ ", Style::default().fg(highlight_color)),
            Span::raw(p.name.clone()),
        ]))
    }).collect()
};

let programs_list = List::new(program_items)
    .block(Block::default().title("Programs").borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)))
    .highlight_style(Style::default().bg(highlight_color).fg(bg_color).add_modifier(Modifier::BOLD))
    .highlight_symbol(">> ");

f.render_stateful_widget(programs_list, main_chunks[1], program_state);

// Help text
let help_text = match menu_state {
    MenuState::Categories => "↑↓: Navigate | Enter: Select | /: Search | Tab: Change Color | q: Quit",
    MenuState::Programs => "↑↓: Navigate | Enter: Run | Esc/Backspace: Back | /: Search | Tab: Change Color | q: Quit",
    MenuState::Search => "Type to search | Enter: Select | Esc: Cancel | Tab: Change Color",
};

let help_paragraph = Paragraph::new(help_text)
    .style(Style::default().fg(fg_color))
    .alignment(Alignment::Center)
    .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)));
f.render_widget(help_paragraph, chunks[3]);
}

fn load_color_scheme() -> ColorScheme {
match std::fs::File::open(COLOR_SCHEME_FILE) {
    Ok(mut file) => {
        let mut contents = String::new();
        if file.read_to_string(&mut contents).is_ok() {
            serde_json::from_str(&contents).unwrap_or(ColorScheme::Default)
        } else {
            ColorScheme::Default
        }
    }
    Err(_) => ColorScheme::Default,
}
}

fn save_color_scheme(scheme: &ColorScheme) -> std::io::Result<()> {
let json = serde_json::to_string(scheme)?;
let mut file = std::fs::File::create(COLOR_SCHEME_FILE)?;
file.write_all(json.as_bytes())?;
Ok(())
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
let mut color_scheme = load_color_scheme();

terminal.clear()?;

loop {
    terminal.draw(|f| {
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
            &color_scheme,
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
            &mut color_scheme,
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