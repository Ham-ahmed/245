#!/bin/sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PLUGIN_NAME="MBotton"
VERSION="1.00"
INSTALL_DIR="/usr/lib/enigma2/python/Plugins/Extensions"
TEMP_DIR="/tmp"
URL="https://raw.githubusercontent.com/Ham-ahmed/245/refs/heads/main/MBotton.tar.gz"
PACKAGE_PATH="$TEMP_DIR/$PLUGIN_NAME-$VERSION.tar.gz"

# Trap interrupts
trap 'echo -e "\n${RED}❌ Installation interrupted by user${NC}"; exit 1' INT TERM

# Show header
clear
echo -e "${CYAN}"
echo "#########################################################"
echo "#           MBotton Installation Script                 #"
echo "#                   Version 1.00                        #"
echo "#########################################################"
echo -e "${NC}"
sleep 2

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Check for wget
if ! command -v wget >/dev/null 2>&1; then
    echo -e "${RED}❌ wget not found. Please install wget first.${NC}"
    echo -e "${YELLOW}Try: opkg install wget${NC}"
    exit 1
fi

# Check available space
AVAILABLE_SPACE=$(df -m /usr 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "$AVAILABLE_SPACE" ] && [ "$AVAILABLE_SPACE" -lt 20 ]; then
    echo -e "${RED}❌ Not enough space. Need at least 20MB free.${NC}"
    echo -e "${YELLOW}Available: ${AVAILABLE_SPACE}MB${NC}"
    exit 1
fi

# Ask for confirmation
echo -e "${YELLOW}⚠️  This script will install $PLUGIN_NAME plugin."
echo -e "   Device will need to restart after installation."
echo -e "   Continue? (y/n): ${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}❌ Installation cancelled by user${NC}"
    exit 0
fi

# Download package
echo ""
echo -e "${BLUE}▶ Downloading $PLUGIN_NAME-$VERSION...${NC}"
sleep 2

if ! wget --show-progress -qO "$PACKAGE_PATH" --no-check-certificate "$URL"; then
    echo -e "${RED}❌ Download failed! Check your internet connection.${NC}"
    exit 1
fi

if [ ! -s "$PACKAGE_PATH" ]; then
    echo -e "${RED}❌ Downloaded file is empty or corrupted${NC}"
    rm -f "$PACKAGE_PATH"
    exit 1
fi

# Verify file type
if ! file "$PACKAGE_PATH" 2>/dev/null | grep -q "gzip compressed data"; then
    echo -e "${RED}❌ Downloaded file is not a valid gzip archive${NC}"
    rm -f "$PACKAGE_PATH"
    exit 1
fi

echo -e "${GREEN}✓ Download completed${NC}"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Extract package
echo -e "${YELLOW}▶ Extracting package...${NC}"
if ! tar -xzf "$PACKAGE_PATH" -C "$INSTALL_DIR" 2>&1; then
    echo -e "${RED}❌ Extraction failed${NC}"
    rm -f "$PACKAGE_PATH"
    exit 1
fi

# Clean up
rm -f "$PACKAGE_PATH"
rm -f /tmp/*.ipk /tmp/*.tar.gz 2>/dev/null

echo -e "${GREEN}"
echo "#########################################################"
echo "#              ✓ INSTALLED SUCCESSFULLY                #"
echo "#                     $PLUGIN_NAME                     #"
echo "#           Enigma2 restart is required                 #"
echo "#########################################################"
echo -e "${NC}"

echo -e "${YELLOW}▶ Restart Enigma2 now? (y/n): ${NC}"
read -r RESTART_CONFIRM

if [ "$RESTART_CONFIRM" = "y" ] || [ "$RESTART_CONFIRM" = "Y" ]; then
    echo -e "${RED}▶ Restarting Enigma2...${NC}"
    sleep 2
    
    if pidof enigma2 >/dev/null; then
        echo "Stopping Enigma2..."
        killall -15 enigma2 2>/dev/null
        sleep 3
        
        if pidof enigma2 >/dev/null; then
            echo "Force stopping Enigma2..."
            killall -9 enigma2 2>/dev/null
            sleep 2
        fi
        
        echo "Starting Enigma2..."
        if [ -f /usr/bin/enigma2 ]; then
            /usr/bin/enigma2 &
        else
            echo -e "${YELLOW}⚠️ Enigma2 binary not found. Please restart manually.${NC}"
        fi
    else
        echo "Starting Enigma2..."
        if [ -f /usr/bin/enigma2 ]; then
            /usr/bin/enigma2 &
        else
            echo -e "${YELLOW}⚠️ Enigma2 binary not found. Please restart manually.${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ Installation complete. Restart Enigma2 manually when ready.${NC}"
fi

echo ""
echo -e "${CYAN}Script execution completed${NC}"
