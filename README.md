# MAU Log Reader

MAU Log Reader is a modern macOS application designed to help IT administrators and support professionals easily read, parse, and understand Microsoft AutoUpdate (MAU) logs. Built with SwiftUI, it provides a clean, intuitive, and powerful interface to diagnose update issues for Microsoft 365 applications on macOS.

## About The Project

Microsoft's unified logging system for its applications on macOS can be verbose and difficult to navigate. This tool was inspired by the need for a simple, yet powerful log viewer that could transform cryptic log messages into human-readable explanations, similar to well-known Windows log viewers. It specifically targets the MAU logs located at `/Library/Logs/Microsoft/`.

The application provides a three-panel interface that is both familiar and efficient: a sidebar for navigation and filtering, a central pane for the log list, and a detail pane for in-depth analysis of a selected log entry.

## Features

- **Real-time Log Monitoring**: Automatically monitors the MAU log file for changes and updates the view in real-time with the "Auto-refresh" feature.
- **Application-Specific Filtering**: Segregates logs by Microsoft application (e.g., Teams, Outlook, OneDrive, Word, etc.), making it easy to isolate issues.
- **Human-Readable Explanations**: Translates complex log messages into simple, easy-to-understand explanations under the "What This Means" section.
- **Detailed Log View**: Select any log entry to see a detailed breakdown, including Application Information, the simplified explanation, the original message, and the raw log data.
- **Advanced Filtering & Search**: Quickly find relevant log entries by searching across all log messages or filtering by application.
- **Log Export**: Export the currently loaded logs to CSV or JSON for further analysis or record-keeping.
- **Fixed, Clean UI**: A non-resizable three-column layout provides a stable and predictable user experience.

## How It Works

The application works by:
1.  **Accessing Logs**: The app is configured to have the necessary permissions to read log files from the `/Library/Logs/Microsoft/` directory, where MAU stores its logs. The App Sandbox is disabled to allow this access.
2.  **Parsing Logs**: It uses regular expressions (`NSRegularExpression`) to parse each line of the log file into a structured `LogEntry` object, extracting key information like timestamp, application, log level, and the message itself.
3.  **Identifying Applications**: It uses a list of official Microsoft Application Identifiers (e.g., `TEAMS21` for Teams, `OPIM2019` for Outlook) to accurately categorize each log entry.
4.  **Generating Explanations**: A custom parser analyzes the content of the log message, identifies key patterns and data points, and generates a simple, "human-readable" explanation of what the log entry means.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- macOS
- Xcode

### Installation

1.  Clone the repo:
    ```sh
    git clone https://github.com/your_username/MAU-Log-Reader.git
    ```
2.  Open the `MAU-Log-Reader.xcodeproj` file in Xcode.
3.  Build and run the project. The app should launch, and you can start analyzing logs immediately.

## Usage

- **Load Logs**: Click "Load Latest" to load the most recent MAU log file, or "Browse..." to open a specific log file.
- **Filter**: Use the sidebar to filter logs by a specific application (e.g., Teams, Outlook).
- **Search**: Use the search bar in the middle pane to find logs containing specific keywords.
- **View Details**: Click on any log entry in the list to see a detailed, human-readable breakdown in the right-hand pane.
- **Export**: Use the "Export" menu to save the current log entries as a CSV or JSON file.
