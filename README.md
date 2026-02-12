# Productivity Blocker

A Windows background application that prevents specified programs from running during configured time periods.

## Features

- **WMI Event Monitoring**: Intercepts process creation events system-wide
- **Scheduled Blocking**: Only blocks apps during specific hours/days
- **Silent Operation**: Blocks apps without notifications, just logs events
- **Hardcoded Configuration**: Simple editing directly in Program.cs

## How It Works

1. Monitors all process creation events using Windows Management Instrumentation (WMI)
2. When a blocked app tries to start, checks if current time is in a blocked period
3. If blocked, immediately kills the process before it can fully launch
4. Logs all blocking events to `ProductivityBlocker.log`

## Setup

### Prerequisites
- Windows 10/11
- .NET 6.0 or later
- Administrator privileges (required for WMI process monitoring)

### Build Instructions

1. Open the folder in Visual Studio or use command line:
   ```
   dotnet build -c Release
   ```

2. The executable will be in: `bin/Release/net6.0-windows/ProductivityBlocker.exe`

### Running

The app now runs as a **background process** (no window). 

**Manual start (requires admin):**
1. Right-click `ProductivityBlocker.exe` → "Run as administrator"
2. The app runs silently in the background - check Task Manager to verify it's running
3. Check the log file to confirm it's working

**To stop it manually:**
1. Open Task Manager (Ctrl+Shift+Esc)
2. Find "ProductivityBlocker.exe" in the Details tab
3. Right-click → End Task

### Auto-Start on Windows Boot

Use the provided PowerShell script for automatic setup:

**Setup auto-start:**
1. Right-click `Setup-AutoStart.ps1` → "Run with PowerShell as Administrator"
2. Follow the prompts
3. ProductivityBlocker will start automatically at login with admin privileges

**Remove auto-start:**
1. Right-click `Remove-AutoStart.ps1` → "Run with PowerShell as Administrator"
2. Confirm removal

**What the auto-start does:**
- Creates a Windows Task Scheduler task
- Runs ProductivityBlocker at login with admin privileges
- Runs in background (no window)
- Persists across reboots

**Manual Task Scheduler setup (if you prefer):**
1. Open Task Scheduler (search in Start menu)
2. Create Basic Task
3. Name: "ProductivityBlocker"
4. Trigger: "When I log on"
5. Action: "Start a program"
6. Program: Browse to `ProductivityBlocker.exe`
7. Finish and right-click the task → Properties
8. Check "Run with highest privileges"
9. OK to save

## Configuration

Edit `Program.cs` and modify these sections:

### 1. Blocked Apps

```csharp
private static readonly string[] BlockedApps = new[]
{
    "EpicGamesLauncher.exe",
    "steam.exe",
    // Add more apps here
};
```

**Finding exe names:**
- Open Task Manager (Ctrl+Shift+Esc)
- Go to Details tab
- Find your app and note the "Name" column (e.g., "chrome.exe")

### 2. Block Schedules

```csharp
private static readonly BlockSchedule[] BlockSchedules = new[]
{
    new BlockSchedule
    {
        DaysOfWeek = new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday },
        StartHour = 9,      // 9 AM
        StartMinute = 0,
        EndHour = 17,       // 5 PM
        EndMinute = 0
    }
};
```

**Available days:**
- `DayOfWeek.Monday`
- `DayOfWeek.Tuesday`
- `DayOfWeek.Wednesday`
- `DayOfWeek.Thursday`
- `DayOfWeek.Friday`
- `DayOfWeek.Saturday`
- `DayOfWeek.Sunday`

**Time format**: 24-hour (0-23 for hours)

### Example Configurations

**Block games on weekdays 9 AM - 6 PM:**
```csharp
private static readonly string[] BlockedApps = new[]
{
    "steam.exe",
    "EpicGamesLauncher.exe"
};

private static readonly BlockSchedule[] BlockSchedules = new[]
{
    new BlockSchedule
    {
        DaysOfWeek = new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday },
        StartHour = 9,
        StartMinute = 0,
        EndHour = 18,
        EndMinute = 0
    }
};
```

**Block social media only during work hours:**
```csharp
private static readonly string[] BlockedApps = new[]
{
    "Discord.exe",
    "Telegram.exe",
    "Instagram.exe"
};

private static readonly BlockSchedule[] BlockSchedules = new[]
{
    new BlockSchedule
    {
        DaysOfWeek = new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday },
        StartHour = 9,
        StartMinute = 0,
        EndHour = 17,
        EndMinute = 0
    }
};
```

**Multiple time blocks:**
```csharp
private static readonly BlockSchedule[] BlockSchedules = new[]
{
    // Weekday work hours
    new BlockSchedule
    {
        DaysOfWeek = new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday },
        StartHour = 9,
        StartMinute = 0,
        EndHour = 17,
        EndMinute = 0
    },
    // Weekend mornings
    new BlockSchedule
    {
        DaysOfWeek = new[] { DayOfWeek.Saturday, DayOfWeek.Sunday },
        StartHour = 8,
        StartMinute = 0,
        EndHour = 12,
        EndMinute = 0
    }
};
```

## Log File

All blocking events are logged to the `/log/` subdirectory with date-based filenames in the format `blocked_apps_log_DD-MM-YYYY.txt`.

**Log location:** `(executable folder)/log/blocked_apps_log_12-02-2025.txt`

A new log file is created each day automatically. Old logs are preserved.

**Log format:**
```
[2025-02-12 14:35:22] ProductivityBlocker started
[2025-02-12 14:37:45] BLOCKED: chrome.exe (PID: 12345) at 2025-02-12 14:37:45
[2025-02-12 15:22:10] BLOCKED: steam.exe (PID: 67890) at 2025-02-12 15:22:10
```

## Stopping the Blocker

Since the app runs in the background with no window:

1. Open Task Manager (Ctrl+Shift+Esc)
2. Go to "Details" tab
3. Find "ProductivityBlocker.exe"
4. Right-click → End Task

OR (if using auto-start):

Use the `Remove-AutoStart.ps1` script to disable auto-start, then reboot.

## Troubleshooting

**How do I know if it's running?**
- Check Task Manager → Details tab for "ProductivityBlocker.exe"
- Check the log file - it creates an entry when it starts

**App doesn't block anything:**
- Make sure it's running as Administrator (check Task Manager → Details → right-click → Properties → see if "Run as administrator" is enabled)
- Check the exe name is correct (case doesn't matter)
- Verify the current time is within a blocked schedule
- Check the log file for errors

**"Access Denied" errors in log:**
- Ensure the app is running with admin privileges
- Some system processes can't be killed even by admin

**Can't find ProductivityBlocker.exe in Task Manager:**
- It may not have started - try running it manually as admin first
- Check the log directory was created successfully
- Look in Task Scheduler to verify the auto-start task exists and is enabled

## Technical Details

**Why WMI over other methods?**
- Catches processes started any way (explorer, cmd, shortcuts, etc.)
- Minimal CPU overhead (~0-1% when idle)
- No kernel drivers needed
- Works in user-mode with admin rights

**Limitations:**
- Requires admin privileges
- ~50-200ms delay between process start and kill (WMI event latency)
- Can't block processes that run and exit faster than detection window
- Some protected system processes may not be killable

## Security Note

This app requires admin privileges. Review the source code before running to ensure it only does what's described.
