using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management;
using System.Threading;
using System.Windows.Forms;

namespace ProductivityBlocker
{
    class Program
    {
        // ====================================
        // CONFIGURATION - EDIT THESE VALUES
        // ====================================
        
        // List of blocked executables (case-insensitive)
        private static readonly string[] BlockedApps = new[]
        {
            "EpicGamesLauncher.exe",
            "steam.exe",
            // Add more apps here as needed
        };

        // Blocked time ranges (24-hour format)
        // Example: Block from 9 AM to 5 PM on weekdays
        private static readonly BlockSchedule[] BlockSchedules = new[]
        {
            new BlockSchedule
            {
                DaysOfWeek = new[] { DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday },
                StartHour = 8,
                StartMinute = 0,
                EndHour = 20,
                EndMinute = 0
            },
            // Add more schedules as needed
            // Example for weekends:
            // new BlockSchedule
            // {
            //     DaysOfWeek = new[] { DayOfWeek.Saturday, DayOfWeek.Sunday },
            //     StartHour = 10,
            //     StartMinute = 0,
            //     EndHour = 12,
            //     EndMinute = 0
            // }
        };

        // ====================================
        // END CONFIGURATION
        // ====================================

        private static string logFilePath;
        private static ManagementEventWatcher watcher;

        static void Main(string[] args)
        {
            // Set up log file in /log/ subdirectory with date-based filename
            string exePath = AppDomain.CurrentDomain.BaseDirectory;
            string logDirectory = Path.Combine(exePath, "log");
            
            // Create log directory if it doesn't exist
            if (!Directory.Exists(logDirectory))
            {
                Directory.CreateDirectory(logDirectory);
            }
            
            // Create filename with current date: blocked_apps_log_12-02-2025.txt
            string dateString = DateTime.Now.ToString("dd-MM-yyyy");
            string logFileName = $"blocked_apps_log_{dateString}.txt";
            logFilePath = Path.Combine(logDirectory, logFileName);

            LogEvent("ProductivityBlocker started");

            // Set up WMI event watcher for process creation
            StartProcessMonitoring();

            // Keep the application running
            Application.Run();
        }

        private static void StartProcessMonitoring()
        {
            try
            {
                // WMI query to watch for new process creation events
                string query = "SELECT * FROM Win32_ProcessStartTrace";
                
                watcher = new ManagementEventWatcher(query);
                watcher.EventArrived += OnProcessStarted;
                watcher.Start();

                LogEvent("WMI Process monitoring active");
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: Failed to start WMI watcher - {ex.Message}");
            }
        }

        private static void OnProcessStarted(object sender, EventArrivedEventArgs e)
        {
            try
            {
                string processName = e.NewEvent.Properties["ProcessName"].Value.ToString();
                uint processId = (uint)e.NewEvent.Properties["ProcessID"].Value;

                // Check if this process is in our blocked list
                if (IsBlockedApp(processName))
                {
                    // Check if we're in a blocked time period
                    if (IsInBlockedPeriod())
                    {
                        // Kill the process immediately
                        KillProcess((int)processId, processName);
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: Exception in process monitor - {ex.Message}");
            }
        }

        private static bool IsBlockedApp(string processName)
        {
            return BlockedApps.Any(app => 
                string.Equals(app, processName, StringComparison.OrdinalIgnoreCase));
        }

        private static bool IsInBlockedPeriod()
        {
            DateTime now = DateTime.Now;
            
            foreach (var schedule in BlockSchedules)
            {
                // Check if today is in the blocked days
                if (schedule.DaysOfWeek.Contains(now.DayOfWeek))
                {
                    // Check if current time is within the blocked hours
                    TimeSpan currentTime = now.TimeOfDay;
                    TimeSpan startTime = new TimeSpan(schedule.StartHour, schedule.StartMinute, 0);
                    TimeSpan endTime = new TimeSpan(schedule.EndHour, schedule.EndMinute, 0);

                    if (currentTime >= startTime && currentTime < endTime)
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        private static void KillProcess(int processId, string processName)
        {
            try
            {
                Process process = Process.GetProcessById(processId);
                process.Kill();
                process.WaitForExit(2000); // Wait up to 2 seconds

                string message = $"BLOCKED: {processName} (PID: {processId}) at {DateTime.Now:yyyy-MM-dd HH:mm:ss}";
                LogEvent(message);
            }
            catch (ArgumentException)
            {
                // Process already exited, that's fine
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: Failed to kill {processName} (PID: {processId}) - {ex.Message}");
            }
        }

        private static void LogEvent(string message)
        {
            try
            {
                string logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
                File.AppendAllText(logFilePath, logEntry + Environment.NewLine);
            }
            catch
            {
                // Silent fail - we're running in background
            }
        }
    }

    public class BlockSchedule
    {
        public DayOfWeek[] DaysOfWeek { get; set; }
        public int StartHour { get; set; }
        public int StartMinute { get; set; }
        public int EndHour { get; set; }
        public int EndMinute { get; set; }
    }
}
