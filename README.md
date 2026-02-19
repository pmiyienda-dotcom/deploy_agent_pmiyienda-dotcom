# deploy_agent_pmiyienda-dotcom

A shell script that automates the setup of a **Student Attendance Tracker** project workspace, including directory creation, dynamic configuration, environment validation, and graceful process management.

## Prerequisites
A Unix-based system (Linux or macOS)
'bash' shell
'python3' (optional — the script will warn you if it is not found)

## How to Run
1. **Clone the repository:**
   git clone https://github.com/<your-username>/deploy_agent_<your-username>.git
   cd deploy_agent_<your-username>
2. **Make the script executable:**
   chmod +x setup_project.sh
3. **Run the script:**
   ./setup_project.sh
4. **Follow the prompts:**
   - Enter a project name (e.g., v1). The script will create a directory called       attendance_tracker_v1
   - You will be asked whether you want to update the attendance thresholds.
   - If yes, enter a numeric value for the **Warning threshold** (default: '75') and the **Failure threshold** (default: '50').
     - The script validates that your inputs are numeric before applying changes. If not it will give an error.

## What the Script Does

| Step | Description |
|------|-------------|
| **Directory Setup** | Creates `attendance_tracker_{input}/` with `Helpers/` and `reports/` subdirectories |
| **File Generation** | Populates `attendance_checker.py`, `Helpers/assets.csv`, `Helpers/config.json`, and `reports/reports.log` |
| **Config Update** | Uses `sed` to update Warning and Failure threshold values in `config.json` |
| **Health Check** | Runs `python3 --version` to verify Python is installed on the system |
| **Signal Handling** | Catches `SIGINT` (Ctrl+C) and triggers the archive/cleanup routine |


## How to Trigger the Archive Feature
The archive is triggered automatically when you interrupt the script with **Ctrl+C** before it finishes.

**Steps to trigger it:**
1. Start the script: `./setup_project.sh`
2. Press **Ctrl+C** at any point during execution.
3. The script will catch the `SIGINT` signal and:
   - Bundle the current (incomplete) project directory into a compressed archive named attendance_tracker_{input}_archive.tar.gz'
   - Delete the incomplete project directory to keep the workspace clean
   - Print a message confirming the archive was created

**Example output on interrupt:**

^C
[!] Interrupt received. Cleaning up...
[✓] Archive created: attendance_tracker_v1_archive.tar.gz
[✓] Incomplete directory removed.
Exiting.




## Project Structure Created

attendance_tracker_{input}/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
    └── reports.log


## Notes

- If the target directory already exists, the script will notify you and exit safely to avoid overwriting existing work.
- All threshold inputs are validated to be numeric — entering letters or leaving the field blank will prompt you to re-enter.
