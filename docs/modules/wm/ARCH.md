# Window Manager Architecture

## Overview

The Arynox Window Manager provides window management capabilities via a D-Bus IPC daemon. It manages windows, workspaces, and focus state for the Flutter desktop shell.

## Architecture

```
┌─────────────────────────────────────────────────┐
│               Flutter Desktop Shell               │
│                   (D-BUS IPC)                     │
├─────────────────────────────────────────────────┤
│               Compositor Daemon                    │
│  ┌─────────────────────────────────────────────┐│
│  │              State Manager                  ││
│  │  Windows │ Workspaces │ Focus              ││
│  └─────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────┐│
│  │           D-Bus Interface                    ││
│  │  org.arynox.Compositor                       ││
│  │  - create_window / close_window              ││
│  │  - list_windows / focus_window               ││
│  │  - set_active_workspace / move_window        ││
│  │  - list_workspaces                           ││
│  └─────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

## Window Management

### State Tracking

- Windows are tracked by unique ID with position, size, workspace
- Workspaces maintain lists of windows
- Focus state tracked per-workspace

### Workspaces

- Up to 9 workspaces
- Each workspace maintains its own window list
- Windows can be moved between workspaces

## D-Bus Interface

- `org.arynox.Compositor` — Main compositor control at `/org/arynox/Compositor`
- All methods return JSON strings

## IPC Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| create_window | title, app_id | Register a new window |
| close_window | window_id | Remove a window |
| list_windows | — | List all windows |
| set_active_workspace | workspace_id | Switch workspace |
| move_window | window_id, workspace_id | Move window to workspace |
| focus_window | window_id | Set window focus |
