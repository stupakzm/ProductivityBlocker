# ProductivityBlocker Auto-Start Removal Script
# This script removes the ProductivityBlocker task from Windows Task Scheduler

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    pause
    exit 1
}

$taskName = "ProductivityBlocker"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ProductivityBlocker Auto-Start Removal" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check if task exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if (-not $existingTask) {
    Write-Host "No auto-start task found for ProductivityBlocker." -ForegroundColor Yellow
    Write-Host "Nothing to remove." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 0
}

Write-Host "Found ProductivityBlocker auto-start task." -ForegroundColor Green
$response = Read-Host "Do you want to remove it? (Y/N)"

if ($response -ne 'Y' -and $response -ne 'y') {
    Write-Host "Removal cancelled." -ForegroundColor Yellow
    pause
    exit 0
}

try {
    # Stop the task if it's running
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    # Remove the task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    
    Write-Host ""
    Write-Host "SUCCESS! ProductivityBlocker auto-start has been removed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: This only removes auto-start. If ProductivityBlocker is currently running," -ForegroundColor Yellow
    Write-Host "you need to stop it manually from Task Manager." -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: Failed to remove scheduled task." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
pause
