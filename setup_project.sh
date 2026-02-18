#!/bin/bash

# setup_project.sh
# Automated bootstrapping script for Student Attendance Tracker
# Handles directory creation, file generation, config updates, signal trapping, and health checks

set -euo pipefail

# Function: Cleanup on interrupt (SIGINT / Ctrl+C)
cleanup() {
    echo -e "\n\n[Interrupted] Script terminated by user."
    echo "[Cleanup] Creating archive of current state and removing incomplete directory..."
    
    cd "$PARENT_DIR"
    
    if [ -d "$PROJECT_NAME" ]; then
        tar -czf "${PROJECT_NAME}_archive.tar.gz" "$PROJECT_NAME" 2>/dev/null || echo "[Warning] Archive creation failed (possibly empty directory)"
        rm -rf "$PROJECT_NAME"
        echo "[Cleanup] Incomplete project removed. Archive saved as ${PROJECT_NAME}_archive.tar.gz"
    else
        echo "[Cleanup] No directory to clean up."
    fi
    
    exit 1
}

# Trap SIGINT early
trap cleanup SIGINT

# Get project identifier from user
read -p "Enter project identifier (will create attendance_tracker_<identifier>): " INPUT
if [ -z "$INPUT" ]; then
    echo "Error: Identifier cannot be empty."
    exit 1
fi

PROJECT_NAME="attendance_tracker_${INPUT}"
PARENT_DIR="$(pwd)"
PROJECT_DIR="${PARENT_DIR}/${PROJECT_NAME}"

# Check if directory already exists
if [ -d "$PROJECT_DIR" ]; then
    echo "Warning: Directory '$PROJECT_DIR' already exists."
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_DIR"
        echo "Existing directory removed."
    else
        echo "Aborting."
        exit 1
    fi
fi

# Create project directory
echo "Creating project directory: $PROJECT_DIR"
mkdir "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create subdirectories
mkdir Helpers reports

# Generate config.json with defaults
cat > Helpers/config.json << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

# Generate assets.csv
cat > Helpers/assets.csv << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Generate empty reports.log
> reports/reports.log

# Generate main Python script
cat > attendance_checker.py << 'EOF'
#!/usr/bin/env python
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

chmod +x attendance_checker.py

echo "Core files generated."

# Prompt user about updating thresholds
echo
read -p "Do you want to update the attendance thresholds? (y/N): " UPDATE
if [[ "$UPDATE" =~ ^[Yy]$ ]]; then
    while true; do
        read -p "Enter warning threshold in % (0-100, default 75): " NEW_WARNING
        NEW_WARNING=${NEW_WARNING:-75}
        if [[ "$NEW_WARNING" =~ ^[0-9]+$ ]] && [ "$NEW_WARNING" -ge 0 ] && [ "$NEW_WARNING" -le 100 ]; then
            break
        else
            echo "Error: Please enter a valid number between 0 and 100."
        fi
    done

    while true; do
        read -p "Enter failure threshold in % (0-100, default 50): " NEW_FAILURE
        NEW_FAILURE=${NEW_FAILURE:-50}
        if [[ "$NEW_FAILURE" =~ ^[0-9]+$ ]] && [ "$NEW_FAILURE" -ge 0 ] && [ "$NEW_FAILURE" -le 100 ]; then
            break
        else
            echo "Error: Please enter a valid number between 0 and 100."
        fi
    done

    # Update config.json using sed (in-place edit)
    sed -i "s/\"warning_threshold\": [0-9]\+/\"warning_threshold\": $NEW_WARNING/" Helpers/config.json
    sed -i "s/\"failure_threshold\": [0-9]\+/\"failure_threshold\": $NEW_FAILURE/" Helpers/config.json
    
    echo "Thresholds updated in config.json"
fi

# Environment validation / Health check
echo
echo "=== Health Check ==="

# Check Python3
if command -v python3 >/dev/null 2>&1; then
    VERSION=$(python3 --version 2>&1)
    echo "✓ Python3 is installed: $VERSION"
else
    echo "✗ Warning: python3 is not installed or not in PATH"
fi

# Verify directory structure
echo
echo "Verifying directory structure..."
missing=0

[ -f attendance_checker.py ]       && echo "✓ attendance_checker.py"      || { echo "✗ attendance_checker.py missing"; missing=1; }
[ -d Helpers ]                      && echo "✓ Helpers/ directory"        || { echo "✗ Helpers/ missing"; missing=1; }
[ -f Helpers/assets.csv ]           && echo "✓ Helpers/assets.csv"        || { echo "✗ Helpers/assets.csv missing"; missing=1; }
[ -f Helpers/config.json ]          && echo "✓ Helpers/config.json"       || { echo "✗ Helpers/config.json missing"; missing=1; }
[ -d reports ]                      && echo "✓ reports/ directory"        || { echo "✗ reports/ missing"; missing=1; }
[ -f reports/reports.log ]          && echo "✓ reports/reports.log"       || { echo "✗ reports/reports.log missing"; missing=1; }

if [ $missing -eq 0 ]; then
    echo
    echo "All checks passed! Project setup complete."
    echo "Directory: $PROJECT_DIR"
    echo "To run: cd $PROJECT_NAME && python3 attendance_checker.py"
else
    echo "Some files are missing. Setup incomplete."
fi

