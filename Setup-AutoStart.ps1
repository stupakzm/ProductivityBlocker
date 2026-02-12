# ProductivityBlocker Auto-Start Setup Script
# This script creates a Windows Task Scheduler task to run ProductivityBlocker at startup with admin privileges

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    pause
    exit 1
}

# Get the current directory (where the script is located)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptPath "ProductivityBlocker.exe"

# Verify the executable exists
if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: ProductivityBlocker.exe not found at: $exePath" -ForegroundColor Red
    Write-Host "Make sure this script is in the same folder as ProductivityBlocker.exe" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ProductivityBlocker Auto-Start Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Executable path: $exePath" -ForegroundColor Green
Write-Host ""

# Task name
$taskName = "ProductivityBlocker"

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "WARNING: A task named '$taskName' already exists." -ForegroundColor Yellow
    $response = Read-Host "Do you want to replace it? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Setup cancelled." -ForegroundColor Yellow
        pause
        exit 0
    }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Existing task removed." -ForegroundColor Green
}

# Create the scheduled task action
$action = New-ScheduledTaskAction -Execute $exePath

# Create trigger to run at logon
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Create principal to run with highest privileges (admin)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Days 0)

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Productivity Blocker - Prevents specified apps from running during configured hours" | Out-Null
    
    Write-Host ""
    Write-Host "SUCCESS! ProductivityBlocker will now start automatically when you log in." -ForegroundColor Green
    Write-Host ""
    Write-Host "The app will run with administrator privileges in the background (no window)." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To verify: Open Task Scheduler and look for 'ProductivityBlocker' task." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To remove auto-start later, run: Remove-AutoStart.ps1" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: Failed to create scheduled task." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Press any key to start ProductivityBlocker now..." -ForegroundColor Yellow
pause

# Start the task immediately
Start-ScheduledTask -TaskName $taskName
Write-Host ""
Write-Host "ProductivityBlocker is now running!" -ForegroundColor Green
Write-Host "Check the log file at: $scriptPath\log\blocked_apps_log_$(Get-Date -Format 'dd-MM-yyyy').txt" -ForegroundColor Cyan
Write-Host ""
pause
