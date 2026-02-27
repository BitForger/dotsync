# DotSync

A lightweight macOS menu bar app that automatically syncs your config files between your Macs using iCloud Drive — no manual effort required.

## Overview

DotSync runs quietly in your menu bar and keeps your dotfiles and config files in sync across all your Macs. It uses iCloud Drive as the sync backend, so there's no extra account or service to set up — just iCloud, which you already have.

## Features

- **Menu bar app** — lives in your system status bar and stays out of the way
- **Automatic syncing** — syncs your files every 5 minutes in the background
- **Manual sync** — trigger a sync at any time from the menu bar
- **Smart conflict resolution** — compares file modification dates and syncs the newest version; automatically backs up the older file before overwriting
- **Safe sync** — never overwrites a non-empty file with an empty one
- **Start at login** — optional Launch Agent support to start syncing automatically when you log in
- **macOS notifications** — get notified when files are downloaded or the initial sync completes
- **Configurable file list** — add or remove any files you want to keep in sync via the Settings window

## Default Files Synced

Out of the box, DotSync will sync the following files:

| File | Description |
|------|-------------|
| `~/.zshrc` | Zsh shell configuration |
| `~/.zprofile` | Zsh login profile |
| `~/.gitconfig` | Git global configuration |
| `~/.vimrc` | Vim configuration |
| `~/.ssh/config` | SSH client configuration |

You can add or remove files in **Settings**.

## How It Works

DotSync stores your files in a dedicated folder inside iCloud Drive:

```
~/Library/Mobile Documents/com~apple~CloudDocs/DotSync/
```

When a sync runs, each configured file is compared between your local machine and iCloud:

- **Local is newer** → uploads to iCloud (backs up the cloud copy first)
- **Cloud is newer** → downloads to local (backs up the local copy first)
- **Cloud has content, local is empty/missing** → downloads from iCloud
- **Local has content, cloud is empty/missing** → uploads to iCloud
- **Same modification date** → no action taken

## Requirements

- macOS 13 (Ventura) or later
- iCloud Drive enabled

## Installation

1. Download the latest release from the [Releases](../../releases) page
2. Move `DotSync.app` to your `/Applications` folder
3. Launch the app — it will appear in your menu bar
4. *(Optional)* Open **Settings** and enable **Start at Login** to have DotSync run automatically on every login

## Usage

Click the **↺** icon in the menu bar to access the following options:

| Menu Item | Description |
|-----------|-------------|
| **Sync Now** | Immediately sync all configured files |
| **Open Settings…** | Open the Settings window to manage files and preferences |
| **Open iCloud Folder** | Open the DotSync folder in iCloud Drive in Finder |
| **Quit** | Quit the app |

### Settings Window

In the Settings window you can:

- **Add files** — type a file path (e.g. `~/.bashrc`) and click **Add**
- **Remove files** — click the trash icon next to any file to stop syncing it
- **Reset to Defaults** — restore the default list of files
- **Start at Login** — toggle the Launch Agent to start DotSync automatically on login

## Building from Source

This project is built with **Swift** and **SwiftUI** using Xcode.

1. Clone the repository:
   ```sh
   git clone https://github.com/BitForger/config-sync.git
   ```
2. Open `dotsync.xcodeproj` in Xcode
3. Select your target Mac and press **⌘R** to build and run

## License

This project is open source. See [LICENSE](LICENSE) for details.
