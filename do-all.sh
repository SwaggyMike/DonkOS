#!/bin/bash

# Default paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ISO_OUTPUT="$SCRIPT_DIR/DonkOS.iso"
LOG_FILE="$SCRIPT_DIR/COMPILE.log"

# Parse options
while getopts "D:L:" opt; do
  case ${opt} in
    D ) ISO_OUTPUT="$OPTARG/DonkOS.iso" ;;
    L ) LOG_FILE="$OPTARG/COMPILE.log" ;;
    * ) echo "Usage: $0 [-D iso_output_dir] [-L log_output_dir]"; exit 1 ;;
  esac
done

# Start logging
echo "Starting DonkOS ISO build..." | tee "$LOG_FILE"

echo "Using Kickstart directory: $SCRIPT_DIR/kickstart" | tee -a "$LOG_FILE"
echo "ISO will be saved to: $ISO_OUTPUT" | tee -a "$LOG_FILE"
echo "Log file will be saved to: $LOG_FILE" | tee -a "$LOG_FILE"

# Ensure dependencies are installed
echo "Checking dependencies..." | tee -a "$LOG_FILE"
for cmd in xorriso createrepo_c; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd not found. Install it before proceeding." | tee -a "$LOG_FILE"
        exit 1
    fi
done

# Ensure efiboot.img exists
if [ ! -f "$SCRIPT_DIR/kickstart/images/efiboot.img" ]; then
    echo "Error: Missing EFI boot image (images/efiboot.img). Ensure it exists before proceeding." | tee -a "$LOG_FILE"
    exit 1
fi

# Regenerate repository metadata
echo "Updating repository metadata..." | tee -a "$LOG_FILE"
for repo in BaseOS minimal; do
    if [ -d "$SCRIPT_DIR/kickstart/$repo" ]; then
        echo "Running createrepo_c on $repo..." | tee -a "$LOG_FILE"
        createrepo_c --update "$SCRIPT_DIR/kickstart/$repo" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "Warning: Repository directory $repo not found, skipping." | tee -a "$LOG_FILE"
    fi
done

# Build the ISO
echo "Building DonkOS UEFI-only ISO..." | tee -a "$LOG_FILE"
xorriso -as mkisofs -o "$ISO_OUTPUT" \
    -e images/efiboot.img -no-emul-boot \
    -V "DonkOS" -J -R "$SCRIPT_DIR/kickstart" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo "UEFI-only ISO successfully created: $ISO_OUTPUT" | tee -a "$LOG_FILE"
else
    echo "Error: ISO build failed." | tee -a "$LOG_FILE"
    exit 1
fi

echo "Build completed." | tee -a "$LOG_FILE"
exit 0

