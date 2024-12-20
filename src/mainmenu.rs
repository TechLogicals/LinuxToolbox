use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::io::{stdout, Stdout, Read, Write};
use std::os::unix::fs::PermissionsExt;
use std::time::Duration;
use toml::Value;
use ratatui::{
    backend::{Backend, CrosstermBackend},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Clear, Wrap},
    layout::{Layout, Constraint, Direction, Alignment, Rect},
    style::{Color, Modifier, Style},
    text::{Span, Line},
    Terminal, Frame,
};
use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, MouseEvent, MouseEventKind, EnableMouseCapture, DisableMouseCapture},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    cursor::{MoveTo, Show, Hide},
};
use reqwest::blocking::Client;
use serde_json::Value as JsonValue;
use semver::Version;
use serde::{Deserialize, Serialize};
use chrono::Local;
use sysinfo::{System, SystemExt, CpuExt};
use rand::seq::SliceRandom;

const CURRENT_VERSION: &str = "0.6.7";
const GITHUB_REPO: &str = "TechLogicals/LinuxToolbox";
const COLOR_SCHEME_FILE: &str = "color_scheme.json";
const LOG_FILE: &str = "linuxtoolbox.log";
const LINUX_QUOTES: &[&str] = &[
    "Talk is cheap. Show me the code. - Linus Torvalds",
    "Given enough eyeballs, all bugs are shallow. - Eric S. Raymond",
    "Software is like sex: it's better when it's free. - Linus Torvalds",
    "The Linux philosophy is 'Laugh in the face of danger'. Oops. Wrong One. 'Do it yourself'. Yes, that's it. - Linus Torvalds",
    "Intelligence is the ability to avoid doing work, yet getting the work done. - Linus Torvalds",
    "A computer is like air conditioning – it becomes useless when you open Windows. - Linus Torvalds",
    "Microsoft isn't evil, they just make really crappy operating systems. - Linus Torvalds",
    "If you think your users are idiots, only idiots will use it. - Linus Torvalds",
    "I'm doing a (free) operating system (just a hobby, won't be big and professional like gnu) - Linus Torvalds",
    "The most important thing in Open Source is that people are having fun and feeling like they're part of a community. - Mark Shuttleworth",
];

#[derive(Clone)]
struct Category {
    name: String,
    programs: Vec<Program>,
}

#[derive(Clone)]
struct Program {
    name: String,
    script: PathBuf,
    is_favorite: bool,
}

#[derive(PartialEq)]
enum MenuState {
    Categories,
    Programs,
    Search,
    Help,
    SystemInfo,
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
    Matrix,
    Nordic,
    Dracula,
    Solarized,
    Monokai,
    Gruvbox,
    Tokyo,
    Synthwave,
    Coffee,
    Nature,
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
            ColorScheme::Midnight => ColorScheme::Matrix,
            ColorScheme::Matrix => ColorScheme::Nordic,
            ColorScheme::Nordic => ColorScheme::Dracula,
            ColorScheme::Dracula => ColorScheme::Solarized,
            ColorScheme::Solarized => ColorScheme::Monokai,
            ColorScheme::Monokai => ColorScheme::Gruvbox,
            ColorScheme::Gruvbox => ColorScheme::Tokyo,
            ColorScheme::Tokyo => ColorScheme::Synthwave,
            ColorScheme::Synthwave => ColorScheme::Coffee,
            ColorScheme::Coffee => ColorScheme::Nature,
            ColorScheme::Nature => ColorScheme::Default,
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
            ColorScheme::Matrix => (Color::Black, Color::Rgb(0, 255, 0), Color::Rgb(0, 200, 0)),
            ColorScheme::Nordic => (Color::Rgb(46, 52, 64), Color::Rgb(216, 222, 233), Color::Rgb(94, 129, 172)),
            ColorScheme::Dracula => (Color::Rgb(40, 42, 54), Color::Rgb(248, 248, 242), Color::Rgb(255, 121, 198)),
            ColorScheme::Solarized => (Color::Rgb(0, 43, 54), Color::Rgb(131, 148, 150), Color::Rgb(181, 137, 0)),
            ColorScheme::Monokai => (Color::Rgb(39, 40, 34), Color::Rgb(248, 248, 242), Color::Rgb(249, 38, 114)),
            ColorScheme::Gruvbox => (Color::Rgb(40, 40, 40), Color::Rgb(235, 219, 178), Color::Rgb(251, 73, 52)),
            ColorScheme::Tokyo => (Color::Rgb(26, 27, 38), Color::Rgb(169, 177, 214), Color::Rgb(187, 154, 247)),
            ColorScheme::Synthwave => (Color::Rgb(39, 23, 64), Color::Rgb(255, 236, 255), Color::Rgb(255, 82, 197)),
            ColorScheme::Coffee => (Color::Rgb(59, 35, 20), Color::Rgb(237, 221, 185), Color::Rgb(191, 128, 64)),
            ColorScheme::Nature => (Color::Rgb(42, 61, 44), Color::Rgb(233, 237, 201), Color::Rgb(139, 189, 139)),
        }
    }

    fn display_name(&self) -> &str {
        match self {
            ColorScheme::Default => "Default",
            ColorScheme::Dark => "Dark",
            ColorScheme::Light => "Light",
            ColorScheme::Ocean => "Ocean",
            ColorScheme::Forest => "Forest",
            ColorScheme::Sunset => "Sunset",
            ColorScheme::Neon => "Neon",
            ColorScheme::Pastel => "Pastel",
            ColorScheme::Monochrome => "Monochrome",
            ColorScheme::Autumn => "Autumn",
            ColorScheme::Winter => "Winter",
            ColorScheme::Spring => "Spring",
            ColorScheme::Summer => "Summer",
            ColorScheme::Cyberpunk => "Cyberpunk",
            ColorScheme::Retro => "Retro",
            ColorScheme::Desert => "Desert",
            ColorScheme::Space => "Space",
            ColorScheme::Candy => "Candy",
            ColorScheme::Earth => "Earth",
            ColorScheme::Midnight => "Midnight",
            ColorScheme::Matrix => "Matrix",
            ColorScheme::Nordic => "Nordic",
            ColorScheme::Dracula => "Dracula",
            ColorScheme::Solarized => "Solarized",
            ColorScheme::Monokai => "Monokai",
            ColorScheme::Gruvbox => "Gruvbox",
            ColorScheme::Tokyo => "Tokyo Night",
            ColorScheme::Synthwave => "Synthwave",
            ColorScheme::Coffee => "Coffee",
            ColorScheme::Nature => "Nature",
        }
    }
}

struct AppState {
    status_message: Option<String>,
    loading: bool,
    loading_progress: u8,
    system_info: String,
    current_quote: String,
}

enum InputAction {
    Quit,
    RunScript,
    Continue,
    ConfirmQuit,
}

fn setup_terminal() -> Result<Terminal<CrosstermBackend<Stdout>>, Box<dyn std::error::Error>> {
    enable_raw_mode()?;
    let mut stdout = stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture, Hide)?;
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
                is_favorite: false,
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
    println!("Checking for updates...");
    println!("Current version: {}", CURRENT_VERSION);
    
    let current_version = Version::parse(CURRENT_VERSION)
        .map_err(|e| format!("Failed to parse current version '{}': {}", CURRENT_VERSION, e))?;
    
    println!("Parsed current version: {}", current_version);
    
    let client = Client::new();
    let url = format!("https://api.github.com/repos/{}/releases/latest", GITHUB_REPO);
    let response = client.get(&url).header("User-Agent", "LinuxToolbox").send()?;
    
    if response.status().is_success() {
        let json: JsonValue = response.json()?;
        if let Some(tag_name) = json["tag_name"].as_str() {
            println!("Latest version from GitHub: {}", tag_name);
            
            let latest_version = Version::parse(&tag_name.trim_start_matches('v'))
                .map_err(|e| format!("Failed to parse latest version '{}': {}", tag_name, e))?;
            
            println!("Parsed latest version: {}", latest_version);
            
            if latest_version > current_version {
                return Ok(Some(latest_version.to_string()));
            }
        }
    }
    
    Ok(None)
}

fn check_script(script: &PathBuf) -> std::io::Result<()> {
    if !script.exists() {
        return Err(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            format!("Script not found: {:?}", script)
        ));
    }

    let metadata = fs::metadata(script)?;
    if !metadata.is_file() {
        return Err(std::io::Error::new(
            std::io::ErrorKind::InvalidInput,
            format!("Not a file: {:?}", script)
        ));
    }

    let permissions = metadata.permissions();
    if permissions.mode() & 0o111 == 0 {
        return Err(std::io::Error::new(
            std::io::ErrorKind::PermissionDenied,
            format!("Script is not executable: {:?}", script)
        ));
    }

    Ok(())
}

fn run_script(script: &PathBuf) -> std::io::Result<()> {
    check_script(script)?;

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

fn draw_help_screen<B: Backend>(f: &mut Frame<B>, color_scheme: &ColorScheme) {
    let (bg_color, fg_color, _highlight_color) = color_scheme.get_colors();
    let help_text = vec![
        Line::from("Linux Toolbox Help"),
        Line::from(""),
        Line::from("Navigation:"),
        Line::from("↑↓ or Mouse Wheel: Move selection"),
        Line::from("Mouse Click or Enter: Select/Run program"),
        Line::from("Esc/Backspace: Go back"),
        Line::from(""),
        Line::from("Shortcuts:"),
        Line::from("/: Search"),
        Line::from("Tab: Change color scheme"),
        Line::from("h: Toggle help screen"),
        Line::from("q: Quit"),
        Line::from("1-9: Quick select category"),
        Line::from("Home: Back to top"),
        Line::from("f: Toggle favorite"),
        Line::from("i: View system information"),
    ];

    let help_paragraph = Paragraph::new(help_text)
        .block(Block::default().title("Help").borders(Borders::ALL))
        .style(Style::default().fg(fg_color).bg(bg_color));

    f.render_widget(help_paragraph, f.size());
}

fn handle_input<'a>(
    key: KeyEvent,
    menu_state: &mut MenuState,
    selected_category: &mut usize,
    selected_program: &mut usize,
    categories: &'a mut [Category],
    search_query: &mut String,
    filtered_programs: &mut Vec<(String, String, PathBuf)>,
    category_state: &mut ListState,
    program_state: &mut ListState,
    color_scheme: &mut ColorScheme,
    app_state: &mut AppState,
) -> (InputAction, bool) {
    let mut menu_state_changed = false;
    
    match key.code {
        KeyCode::Tab => {
            *color_scheme = color_scheme.next();
            if let Err(e) = save_color_scheme(color_scheme) {
                eprintln!("Failed to save color scheme: {}", e);
            }
            (InputAction::Continue, menu_state_changed)
        },
        KeyCode::Char('q') => {
            app_state.status_message = Some("Press 'y' to confirm quit, any other key to cancel".to_string());
            (InputAction::ConfirmQuit, menu_state_changed)
        },
        KeyCode::Char('y') if app_state.status_message == Some("Press 'y' to confirm quit, any other key to cancel".to_string()) => {
            (InputAction::Quit, menu_state_changed)
        },
        KeyCode::Char('h') => {
            let new_state = if *menu_state == MenuState::Help { MenuState::Categories } else { MenuState::Help };
            menu_state_changed = *menu_state != new_state;
            *menu_state = new_state;
            (InputAction::Continue, menu_state_changed)
        },
        KeyCode::Char('f') if *menu_state == MenuState::Programs => {
            let program = &mut categories[*selected_category].programs[*selected_program];
            program.is_favorite = !program.is_favorite;
            app_state.status_message = Some(format!("{} {} favorites", if program.is_favorite { "Added to" } else { "Removed from" }, program.name));
            (InputAction::Continue, menu_state_changed)
        },
        KeyCode::Char('i') => {
            let new_state = if *menu_state == MenuState::SystemInfo { MenuState::Categories } else { MenuState::SystemInfo };
            menu_state_changed = *menu_state != new_state;
            *menu_state = new_state;
            (InputAction::Continue, menu_state_changed)
        },
        _ => match menu_state {
            MenuState::Categories => match key.code {
                KeyCode::Char('/') => {
                    *menu_state = MenuState::Search;
                    search_query.clear();
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Up => {
                    if *selected_category > 0 {
                        *selected_category -= 1;
                        category_state.select(Some(*selected_category));
                    }
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Down => {
                    if *selected_category < categories.len() - 1 {
                        *selected_category += 1;
                        category_state.select(Some(*selected_category));
                    }
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Enter => {
                    *menu_state = MenuState::Programs;
                    *selected_program = 0;
                    program_state.select(Some(0));
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Home => {
                    *selected_category = 0;
                    category_state.select(Some(0));
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Char(c) if c.is_digit(10) => {
                    let index = c.to_digit(10).unwrap() as usize;
                    if index > 0 && index <= categories.len() {
                        *selected_category = index - 1;
                        category_state.select(Some(*selected_category));
                    }
                    (InputAction::Continue, menu_state_changed)
                }
                _ => (InputAction::Continue, menu_state_changed),
            },
            MenuState::Programs => match key.code {
                KeyCode::Char('/') => {
                    *menu_state = MenuState::Search;
                    search_query.clear();
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Up => {
                    if *selected_program > 0 {
                        *selected_program -= 1;
                        program_state.select(Some(*selected_program));
                    }
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Down => {
                    if *selected_program < categories[*selected_category].programs.len() - 1 {
                        *selected_program += 1;
                        program_state.select(Some(*selected_program));
                    }
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Enter => (InputAction::RunScript, menu_state_changed),
                KeyCode::Esc | KeyCode::Backspace => {
                    *menu_state = MenuState::Categories;
                    *selected_program = 0;
                    program_state.select(Some(0));
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Home => {
                    *selected_program = 0;
                    program_state.select(Some(0));
                    (InputAction::Continue, menu_state_changed)
                }
                _ => (InputAction::Continue, menu_state_changed),
            },
            MenuState::Search => match key.code {
                KeyCode::Enter => {
                    if !filtered_programs.is_empty() {
                        (InputAction::RunScript, menu_state_changed)
                    } else {
                        (InputAction::Continue, menu_state_changed)
                    }
                },
                KeyCode::Esc => {
                    *menu_state = MenuState::Categories;
                    search_query.clear();
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Char(c) => {
                    search_query.push(c);
                    update_filtered_programs(categories, search_query, filtered_programs);
                    (InputAction::Continue, menu_state_changed)
                }
                KeyCode::Backspace => {
                    search_query.pop();
                    update_filtered_programs(categories, search_query, filtered_programs);
                    (InputAction::Continue, menu_state_changed)
                }
                _ => (InputAction::Continue, menu_state_changed),
            },
            MenuState::Help => match key.code {
                KeyCode::Esc | KeyCode::Char('h') => {
                    *menu_state = MenuState::Categories;
                    (InputAction::Continue, menu_state_changed)
                }
                _ => (InputAction::Continue, menu_state_changed),
            },
            MenuState::SystemInfo => match key.code {
                KeyCode::Esc | KeyCode::Char('i') => {
                    *menu_state = MenuState::Categories;
                    (InputAction::Continue, menu_state_changed)
                }
                _ => (InputAction::Continue, menu_state_changed),
            },
        },
    }
}

fn update_filtered_programs(
    categories: &[Category],
    search_query: &str,
    filtered_programs: &mut Vec<(String, String, PathBuf)>,
) {
    filtered_programs.clear();
    for category in categories {
        for program in &category.programs {
            if program.name.to_lowercase().contains(&search_query.to_lowercase()) {
                filtered_programs.push((category.name.clone(), program.name.clone(), program.script.clone()));
            }
        }
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
    filtered_programs: &[(String, String, PathBuf)],
    update_available: &Option<String>,
    color_scheme: &ColorScheme,
    app_state: &AppState,
) {
    let (bg_color, fg_color, _highlight_color) = color_scheme.get_colors();

    let size = f.size();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Title
            Constraint::Length(3),  // Search bar
            Constraint::Min(10),    // Main content (categories and programs)
            Constraint::Length(3),  // OS info
            Constraint::Length(3),  // Help text
            Constraint::Length(3),  // Quote (new)
        ].as_ref())
        .split(size);

    // Modified title section
    let current_date = Local::now().format("%Y-%m-%d").to_string();
    let mut title_text = vec![
        Line::from(vec![
            Span::styled("Linux Toolbox ", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
            Span::styled(format!("v{}", CURRENT_VERSION), Style::default().fg(Color::Yellow)),
            Span::raw(" by "),
            Span::styled("Tech Logicals", Style::default().fg(Color::Green).add_modifier(Modifier::ITALIC)),
            Span::raw(" | "),
            Span::styled(current_date, Style::default().fg(Color::Magenta)),
            Span::raw(" | Theme: "),
            Span::styled(color_scheme.display_name(), Style::default().fg(Color::Cyan)),
        ]),
    ];

    if let Some(new_version) = update_available {
        title_text.push(Line::from(vec![
            Span::raw(" | "),
            Span::styled(format!("Update v{} available", new_version), Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)),
        ]));
    }

    let title = Paragraph::new(title_text)
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)));
    f.render_widget(title, chunks[0]);

    // Search bar
    let search_bar = Paragraph::new(search_query)
        .style(Style::default().fg(Color::Cyan))
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
            ListItem::new(Line::from(vec![
                Span::styled("• ", Style::default().fg(Color::Cyan)),
                Span::raw(c.name.clone()),
            ]))
        })
        .collect();

    let categories_list = List::new(category_items)
        .block(Block::default().title("Categories").borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)))
        .highlight_style(Style::default().bg(Color::Cyan).fg(bg_color).add_modifier(Modifier::BOLD))
        .highlight_symbol(">> ");

    f.render_stateful_widget(categories_list, main_chunks[0], category_state);

    // Programs list
    let program_items: Vec<ListItem> = if *menu_state == MenuState::Search {
        filtered_programs.iter().map(|(_, p, _)| {
            ListItem::new(Line::from(vec![
                Span::styled("▶ ", Style::default().fg(Color::Cyan)),
                Span::raw(p.clone()),
            ]))
        }).collect()
    } else {
        categories[selected_category].programs.iter().map(|p| {
            ListItem::new(Line::from(vec![
                Span::styled(if p.is_favorite { "★ " } else { "▶ " }, Style::default().fg(Color::Cyan)),
                Span::raw(p.name.clone()),
            ]))
        }).collect()
    };

    let programs_list = List::new(program_items)
        .block(Block::default().title("Programs").borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)))
        .highlight_style(Style::default().bg(Color::Cyan).fg(bg_color).add_modifier(Modifier::BOLD))
        .highlight_symbol(">> ");

    f.render_stateful_widget(programs_list, main_chunks[1], program_state);

    // System info (now just showing OS)
    let os_info = app_state.system_info.lines().next().unwrap_or("Unknown OS");
    let system_info = Paragraph::new(os_info)
        .style(Style::default().fg(fg_color))
        .block(Block::default().title("OS").borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)));
    f.render_widget(system_info, chunks[3]);

    // Help text
    let help_text = match menu_state {
        MenuState::Categories => "Mouse/↑↓: Move | Enter/Click: Select | /: Search | Tab: Theme | h: Help | i: Info | q: Quit | 1-9: Quick Select",
        MenuState::Programs => "Mouse/↑↓: Move | Enter/Click: Run | Esc: Back | f: Favorite | /: Search | h: Help | i: Info | q: Quit",
        MenuState::Search => "Type to search | Enter/Click: Select | Esc: Cancel | Tab: Theme | h: Help | i: Info",
        MenuState::Help => "Press 'h' or Esc to return",
        MenuState::SystemInfo => "Press 'i' or Esc to return",
    };

    let help_paragraph = Paragraph::new(help_text)
        .style(Style::default().fg(fg_color))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)));
    f.render_widget(help_paragraph, chunks[4]);

    // Quote
    let quote = Paragraph::new(app_state.current_quote.as_str())
        .style(Style::default().fg(Color::Yellow).add_modifier(Modifier::ITALIC))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::ALL).border_style(Style::default().fg(fg_color).bg(bg_color)));
    f.render_widget(quote, chunks[5]);

    // Status message
    if let Some(message) = &app_state.status_message {
        let status_bar = Paragraph::new(message.as_str())
            .style(Style::default().fg(Color::Cyan))
            .alignment(Alignment::Center);
        f.render_widget(status_bar, chunks[4]);
    }

    // Loading animation
    if app_state.loading {
        draw_loading_animation(f, color_scheme, app_state.loading_progress);
    }
}

fn draw_loading_animation<B: Backend>(f: &mut Frame<B>, color_scheme: &ColorScheme, progress: u8) {
    let (_, fg_color, _) = color_scheme.get_colors();
    let loading_text = format!("Loading {}", ".".repeat(progress as usize));
    let loading_widget = Paragraph::new(loading_text)
        .style(Style::default().fg(fg_color))
        .alignment(Alignment::Center);
    let area = centered_rect(30, 3, f.size());
    f.render_widget(Clear, area);
    f.render_widget(loading_widget, area);
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ].as_ref())
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ].as_ref())
        .split(popup_layout[1])[1]
}

fn log_action(action: &str) {
    use std::fs::OpenOptions;
    use std::io::prelude::*;

    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
    let log_entry = format!("[{}] {}\n", timestamp, action);

    if let Err(e) = OpenOptions::new()
        .create(true)
        .append(true)
        .open(LOG_FILE)
        .and_then(|mut file| file.write_all(log_entry.as_bytes()))
    {
        eprintln!("Failed to log action: {}", e);
    }
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

fn get_system_info() -> String {
    let mut sys = System::new_all();
    sys.refresh_all();

    let cpu_info = sys.cpus().first().map(|cpu| cpu.brand()).unwrap_or("Unknown CPU");
    let total_memory = sys.total_memory() / 1024 / 1024; // Convert to MB
    let used_memory = sys.used_memory() / 1024 / 1024; // Convert to MB
    let gpu_info = "GPU info not available"; // sysinfo doesn't provide GPU info easily

    let os_info = if let Some(os_version) = sys.long_os_version() {
        os_version
    } else {
        sys.name().unwrap_or_else(|| "Unknown OS".to_string())
    };

    format!(
        "OS: {}\nCPU: {}\nMemory: {} MB / {} MB\nGPU: {}",
        os_info, cpu_info, used_memory, total_memory, gpu_info
    )
}

fn draw_system_info_screen<B: Backend>(f: &mut Frame<B>, color_scheme: &ColorScheme, system_info: &str) {
    let (bg_color, fg_color, _highlight_color) = color_scheme.get_colors();
    
    let system_info_lines: Vec<Line> = system_info
        .lines()
        .map(|line| {
            let parts: Vec<&str> = line.splitn(2, ": ").collect();
            if parts.len() == 2 {
                Line::from(vec![
                    Span::styled(format!("{}: ", parts[0]), Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
                    Span::raw(parts[1]),
                ])
            } else {
                Line::from(line)
            }
        })
        .collect();

    let mut text = vec![
        Line::from(vec![
            Span::styled("System Information", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        ]),
        Line::from(""),
    ];
    text.extend(system_info_lines);
    text.push(Line::from(""));
    text.push(Line::from(vec![
        Span::raw("Press "),
        Span::styled("'i'", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        Span::raw(" or "),
        Span::styled("Esc", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        Span::raw(" to return to the main menu"),
    ]));

    let system_info_paragraph = Paragraph::new(text)
        .block(Block::default().title("System Info").borders(Borders::ALL))
        .style(Style::default().fg(fg_color).bg(bg_color))
        .alignment(Alignment::Left)
        .wrap(Wrap { trim: true });

    let area = centered_rect(60, 40, f.size());
    f.render_widget(Clear, area);
    f.render_widget(system_info_paragraph, area);
}

fn get_random_quote() -> &'static str {
    LINUX_QUOTES.choose(&mut rand::thread_rng()).unwrap_or(&"No quote available")
}

fn is_within_rect(x: u16, y: u16, rect: Rect) -> bool {
    x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting program. Current version: {}", CURRENT_VERSION);
    log_action("Program started");
    
    let mut terminal = setup_terminal()?;
    let config_path = PathBuf::from("config.toml");
    let (mut categories, _config_dir) = load_config(&config_path)?;

    let mut selected_category = 0;
    let mut selected_program = 0;
    let mut category_state = ListState::default();
    category_state.select(Some(0));
    let mut program_state = ListState::default();
    program_state.select(Some(0));
    let mut menu_state = MenuState::Categories;
    let mut search_query = String::new();
    let mut filtered_programs: Vec<(String, String, PathBuf)> = Vec::new();

    let mut app_state = AppState {
        status_message: None,
        loading: true,
        loading_progress: 0,
        system_info: get_system_info(),
        current_quote: get_random_quote().to_string(),
    };

    // Simulate loading
    terminal.draw(|f| {
        draw_loading_animation(f, &ColorScheme::Default, app_state.loading_progress);
    })?;

    let update_available = match check_for_updates() {
        Ok(update) => {
            app_state.loading = false;
            update
        },
        Err(e) => {
            app_state.loading = false;
            eprintln!("Error checking for updates: {}", e);
            log_action(&format!("Error checking for updates: {}", e));
            None
        }
    };

    let mut color_scheme = load_color_scheme();

    terminal.clear()?;

    loop {
        let categories_clone = categories.clone();
        terminal.draw(|f| {
            f.render_widget(Clear, f.size());
            
            match menu_state {
                MenuState::Help => draw_help_screen(f, &color_scheme),
                MenuState::SystemInfo => draw_system_info_screen(f, &color_scheme, &app_state.system_info),
                _ => draw_ui(
                    f,
                    &categories_clone,
                    selected_category,
                    &mut category_state,
                    &mut program_state,
                    &menu_state,
                    &search_query,
                    &filtered_programs,
                    &update_available,
                    &color_scheme,
                    &app_state,
                ),
            }
        })?;

        if let Event::Key(key) = event::read()? {
            let (action, menu_state_changed) = handle_input(
                key,
                &mut menu_state,
                &mut selected_category,
                &mut selected_program,
                &mut categories,
                &mut search_query,
                &mut filtered_programs,
                &mut category_state,
                &mut program_state,
                &mut color_scheme,
                &mut app_state,
            );

            match action {
                InputAction::Quit => {
                    log_action("Program exited");
                    break;
                }
                InputAction::RunScript => {
                    let script = match menu_state {
                        MenuState::Programs => &categories[selected_category].programs[selected_program].script,
                        MenuState::Search => &filtered_programs[selected_program].2,
                        _ => continue,
                    };

                    app_state.loading = true;
                    app_state.loading_progress = 0;
                    let loading_thread = std::thread::spawn(move || {
                        for i in 0..4 {
                            std::thread::sleep(Duration::from_millis(500));
                            app_state.loading_progress = i;
                        }
                    });

                    match run_script(script) {
                        Ok(_) => {
                            app_state.status_message = Some("Script executed successfully".to_string());
                            log_action(&format!("Script executed: {:?}", script));
                        },
                        Err(e) => {
                            app_state.status_message = Some(format!("Error running script: {}", e));
                            log_action(&format!("Error running script: {:?} - {}", script, e));
                            disable_raw_mode()?;
                            execute!(terminal.backend_mut(), LeaveAlternateScreen, Show)?;
                            println!("Error running script: {}", e);
                            println!("Press any key to continue...");
                            let _ = event::read()?;
                        }
                    }

                    loading_thread.join().unwrap();
                    app_state.loading = false;

                    enable_raw_mode()?;
                    execute!(terminal.backend_mut(), EnterAlternateScreen, Hide)?;
                    terminal.clear()?;
                }
                InputAction::ConfirmQuit => {
                    // Do nothing here, wait for next input
                }
                InputAction::Continue => {
                    if app_state.status_message == Some("Press 'y' to confirm quit, any other key to cancel".to_string()) {
                        app_state.status_message = Some("Quit cancelled".to_string());
                    }
                    // Refresh the quote when the menu state changes
                    if menu_state_changed {
                        app_state.current_quote = get_random_quote().to_string();
                    }
                }
            }
        } else if let Event::Mouse(mouse_event) = event::read()? {
            match mouse_event.kind {
                MouseEventKind::Down(_) => {
                    let mouse_x = mouse_event.column;
                    let mouse_y = mouse_event.row;

                    // Get the layout chunks (you'll need to make these accessible)
                    let size = terminal.size()?;
                    let chunks = Layout::default()
                        .direction(Direction::Vertical)
                        .constraints([
                            Constraint::Length(3),  // Title
                            Constraint::Length(3),  // Search bar
                            Constraint::Min(10),    // Main content
                            Constraint::Length(3),  // OS info
                            Constraint::Length(3),  // Help text
                            Constraint::Length(3),  // Quote
                        ].as_ref())
                        .split(size);

                    let main_chunks = Layout::default()
                        .direction(Direction::Horizontal)
                        .constraints([
                            Constraint::Percentage(40),
                            Constraint::Percentage(60)
                        ].as_ref())
                        .split(chunks[2]);

                    // Handle clicks in categories list
                    if is_within_rect(mouse_x, mouse_y, main_chunks[0]) {
                        let relative_y = mouse_y - main_chunks[0].y - 1; // -1 for border
                        if relative_y < categories.len() as u16 {
                            selected_category = relative_y as usize;
                            category_state.select(Some(selected_category));
                            if menu_state == MenuState::Categories {
                                menu_state = MenuState::Programs;
                                selected_program = 0;
                                program_state.select(Some(0));
                            }
                        }
                    }
                    // Handle clicks in programs list
                    else if is_within_rect(mouse_x, mouse_y, main_chunks[1]) {
                        let relative_y = mouse_y - main_chunks[1].y - 1; // -1 for border
                        let programs = if menu_state == MenuState::Search {
                            filtered_programs.len()
                        } else {
                            categories[selected_category].programs.len()
                        };
                        
                        if relative_y < programs as u16 {
                            selected_program = relative_y as usize;
                            program_state.select(Some(selected_program));
                            
                            // Double click to run program
                            if mouse_event.kind == MouseEventKind::Down(event::MouseButton::Left) {
                                let script = match menu_state {
                                    MenuState::Programs => &categories[selected_category].programs[selected_program].script,
                                    MenuState::Search => &filtered_programs[selected_program].2,
                                    _ => continue,
                                };
                                
                                // Run the script
                                match run_script(script) {
                                    Ok(_) => {
                                        app_state.status_message = Some("Script executed successfully".to_string());
                                        log_action(&format!("Script executed: {:?}", script));
                                    },
                                    Err(e) => {
                                        app_state.status_message = Some(format!("Error running script: {}", e));
                                        log_action(&format!("Error running script: {:?} - {}", script, e));
                                    }
                                }
                            }
                        }
                    }
                },
                MouseEventKind::ScrollDown => {
                    match menu_state {
                        MenuState::Categories => {
                            if selected_category < categories.len() - 1 {
                                selected_category += 1;
                                category_state.select(Some(selected_category));
                            }
                        },
                        MenuState::Programs => {
                            let max_programs = categories[selected_category].programs.len();
                            if selected_program < max_programs - 1 {
                                selected_program += 1;
                                program_state.select(Some(selected_program));
                            }
                        },
                        MenuState::Search => {
                            if selected_program < filtered_programs.len() - 1 {
                                selected_program += 1;
                                program_state.select(Some(selected_program));
                            }
                        },
                        _ => {}
                    }
                },
                MouseEventKind::ScrollUp => {
                    match menu_state {
                        MenuState::Categories => {
                            if selected_category > 0 {
                                selected_category -= 1;
                                category_state.select(Some(selected_category));
                            }
                        },
                        MenuState::Programs | MenuState::Search => {
                            if selected_program > 0 {
                                selected_program -= 1;
                                program_state.select(Some(selected_program));
                            }
                        },
                        _ => {}
                    }
                },
                _ => {}
            }
        }
    }

    // Cleanup
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture,
        Show
    )?;

    Ok(())
}
