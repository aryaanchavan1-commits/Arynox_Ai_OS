# Desktop Environment Architecture

## Overview

The Arynox Desktop Environment is a Flutter-based shell that provides the complete user interface for the operating system. It communicates with the Wayland compositor via D-Bus and renders through Flutter's GPU-accelerated pipeline.

## Shell Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Workspace Manager                         │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐              │
│  │ WS 1 │ │ WS 2 │ │ WS 3 │ │ WS 4 │ │  +   │              │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│                  Desktop Widget Area                          │
│                                                              │
│  ┌──────────┐           ┌──────────┐                        │
│  │ Widget   │           │ Widget   │                        │
│  │ Clock    │           │ Weather  │                        │
│  └──────────┘           └──────────┘                        │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Dock  │ Launcher │ Active Windows │ Tray │ Clock │ AI ││
│  └─────────────────────────────────────────────────────────┘│
│                         Taskbar                               │
├─────────────────────────────────────────────────────────────┤
│                    Intention Hub (bottom)                     │
│  Notification Center   │   Control Center   │   Quick Setti. │
└─────────────────────────────────────────────────────────────┘
```

## Component Tree

```
ArynoxShell
├── WorkspaceManager
│   ├── DesktopWidgets
│   │   ├── ClockWidget
│   │   ├── WeatherWidget
│   │   ├── CalendarWidget
│   │   └── SystemMonitorWidget
│   └── WindowLayout (managed by compositor)
├── Taskbar
│   ├── ApplicationMenu (Launcher)
│   ├── RunningApps
│   ├── SystemTray
│   ├── Clock
│   ├── AIButton
│   └── QuickSettingsToggle
├── Dock
│   ├── FavoriteApps
│   └── RunningIndicators
├── NotificationCenter
│   ├── NotificationList
│   ├── ClearAllButton
│   └── DoNotDisturb
├── ControlCenter
│   ├── QuickSettings
│   │   ├── WiFi
│   │   ├── Bluetooth
│   │   ├── Brightness
│   │   ├── Volume
│   │   ├── DarkMode
│   │   └── AI Toggle
│   └── MediaPlayer
├── ApplicationLauncher
│   ├── SearchBar
│   ├── CategoryGrid
│   ├── AllAppsList
│   └── RecentApps
└── IntentionHub
    ├── AI Assistant
    ├── CopilotOverlay
    └── AgentStatus
```

## D-Bus Interface

The desktop shell communicates via session D-Bus:

- `org.arynox.Shell` — Shell lifecycle and state
- `org.arynox.Taskbar` — Taskbar item management
- `org.arynox.Notifications` — Notification display
- `org.arynox.Launcher` — App launching
- `org.arynox.Workspace` — Workspace management

## Gesture Support

| Gesture | Action |
|---------|--------|
| 3-finger swipe up | Workspace overview |
| 3-finger swipe down | Show desktop |
| 3-finger swipe left/right | Switch workspace |
| 4-finger pinch | Show launcher |
| Swipe from left edge | Notification center |
| Swipe from right edge | Control center |
| Swipe from bottom | Taskbar reveal (auto-hide) |

## Theming

- Material 3-based design language
- Dynamic color extraction from wallpaper
- Glassmorphism throughout
- Light and dark modes
- User-customizable accent color
- Theme Store support
