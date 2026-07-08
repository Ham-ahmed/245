#!/bin/sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
PLUGIN_NAME="MBotton"
VERSION="1.00"
SCRIPT_VERSION="1.00"
INSTALL_DIR="/usr/lib/enigma2/python/Plugins/Extensions"
TEMP_DIR="/tmp"
URL="https://raw.githubusercontent.com/Ham-ahmed/245/refs/heads/main/MBotton.tar.gz"
PACKAGE_PATH="$TEMP_DIR/$PLUGIN_NAME-$VERSION.tar.gz"

# Trap interrupts
trap 'echo -e "\n${RED}❌ Installation interrupted by user${NC}"; exit 1' INT TERM

# Show header function
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║  ███╗   ███╗██████╗  ██████╗ ████████╗████████╗ ██████╗ ███╗   ██╗   ║"
    echo "║  ████╗ ████║██╔══██╗██╔═══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗████╗  ██║   ║"
    echo "║  ██╔████╔██║██████╔╝██║   ██║   ██║      ██║   ██║   ██║██╔██╗ ██║   ║"
    echo "║  ██║╚██╔╝██║██╔══██╗██║   ██║   ██║      ██║   ██║   ██║██║╚██╗██║   ║"
    echo "║  ██║ ╚═╝ ██║██████╔╝╚██████╔╝   ██║      ██║   ╚██████╔╝██║ ╚████║   ║"
    echo "║  ╚═╝     ╚═╝╚═════╝  ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ ╚═╝  ╚═══╝   ║"
    echo "║                                                                      ║"
    echo "║ ${WHITE}Professional Installation Script v${SCRIPT_VERSION}${CYAN}   ║"
    echo "║                                                                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Show header
show_header
sleep 2

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    exit 1
fi

# Check for wget using 'which' instead of 'command'
if ! which wget >/dev/null 2>&1; then
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

# Check if plugin already exists
if [ -d "$INSTALL_DIR/$PLUGIN_NAME" ]; then
    echo -e "${YELLOW}⚠️  Plugin already exists at: $INSTALL_DIR/$PLUGIN_NAME${NC}"
    echo -e "${YELLOW}   Removing old version...${NC}"
    rm -rf "$INSTALL_DIR/$PLUGIN_NAME"
fi

# Download package (Direct download without confirmation)
echo ""
echo -e "${BLUE}▶ Downloading $PLUGIN_NAME-$VERSION...${NC}"
sleep 2

# Try download with retry
RETRY_COUNT=0
MAX_RETRIES=3
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if wget --show-progress -qO "$PACKAGE_PATH" --no-check-certificate --timeout=10 "$URL"; then
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -e "${YELLOW}⚠️  Download attempt $RETRY_COUNT failed. Retrying...${NC}"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ Download failed after $MAX_RETRIES attempts!${NC}"
    echo -e "${YELLOW}   Please check your internet connection and try again.${NC}"
    exit 1
fi

if [ ! -s "$PACKAGE_PATH" ]; then
    echo -e "${RED}❌ Downloaded file is empty or corrupted${NC}"
    rm -f "$PACKAGE_PATH"
    exit 1
fi

# Verify file type using 'file' command if available
if command -v file >/dev/null 2>&1; then
    if ! file "$PACKAGE_PATH" 2>/dev/null | grep -qE "gzip compressed data|tar archive"; then
        echo -e "${RED}❌ Downloaded file is not a valid archive${NC}"
        echo -e "${YELLOW}   File type: $(file "$PACKAGE_PATH")${NC}"
        rm -f "$PACKAGE_PATH"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  'file' command not found. Skipping file verification...${NC}"
fi

echo -e "${GREEN}✓ Download completed${NC}"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Extract package with verification
echo -e "${YELLOW}▶ Extracting package...${NC}"
if ! tar -xzf "$PACKAGE_PATH" -C "$INSTALL_DIR" 2>&1; then
    echo -e "${RED}❌ Extraction failed${NC}"
    echo -e "${YELLOW}   Trying to extract with verbose output:${NC}"
    tar -xzvf "$PACKAGE_PATH" -C "$INSTALL_DIR" 2>&1 || true
    rm -f "$PACKAGE_PATH"
    exit 1
fi

# Verify extraction
if [ ! -d "$INSTALL_DIR/$PLUGIN_NAME" ]; then
    echo -e "${RED}❌ Installation failed - Plugin directory not found${NC}"
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
        echo "Stopping Enigma2 gracefully..."
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
            echo -e "${GREEN}✓ Enigma2 restarted successfully${NC}"
        elif [ -f /usr/local/bin/enigma2 ]; then
            /usr/local/bin/enigma2 &
            echo -e "${GREEN}✓ Enigma2 restarted successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Enigma2 binary not found. Please restart manually.${NC}"
            echo -e "${YELLOW}   Try: init 4 && init 3${NC}"
        fi
    else
        echo "Starting Enigma2..."
        if [ -f /usr/bin/enigma2 ]; then
            /usr/bin/enigma2 &
            echo -e "${GREEN}✓ Enigma2 started successfully${NC}"
        elif [ -f /usr/local/bin/enigma2 ]; then
            /usr/local/bin/enigma2 &
            echo -e "${GREEN}✓ Enigma2 started successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Enigma2 binary not found. Please restart manually.${NC}"
            echo -e "${YELLOW}   Try: init 4 && init 3${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ Installation complete. Restart Enigma2 manually when ready.${NC}"
    echo -e "${YELLOW}   To restart: init 4 && init 3${NC}"
fi

echo ""
echo -e "${CYAN}Script execution completed${NC}"