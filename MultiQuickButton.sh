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
EXTRACT_DIR="$TEMP_DIR/$PLUGIN_NAME-extract"

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

# Check for wget
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

# Download package
echo ""
echo -e "${BLUE}▶ Downloading $PLUGIN_NAME-$VERSION...${NC}"
sleep 2

# Clean old temp files
rm -rf "$EXTRACT_DIR" "$PACKAGE_PATH" 2>/dev/null

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

echo -e "${GREEN}✓ Download completed (Size: $(du -h "$PACKAGE_PATH" | cut -f1))${NC}"

# Create extraction directory
mkdir -p "$EXTRACT_DIR"

# Extract package and find the actual plugin directory
echo -e "${YELLOW}▶ Extracting package...${NC}"
if ! tar -xzf "$PACKAGE_PATH" -C "$EXTRACT_DIR" 2>&1; then
    echo -e "${RED}❌ Extraction failed${NC}"
    echo -e "${YELLOW}   File content preview:${NC}"
    tar -tzf "$PACKAGE_PATH" 2>&1 | head -20
    rm -rf "$PACKAGE_PATH" "$EXTRACT_DIR"
    exit 1
fi

echo -e "${GREEN}✓ Extraction completed${NC}"

# Show what was extracted
echo -e "${YELLOW}▶ Contents of extracted archive:${NC}"
ls -la "$EXTRACT_DIR" 2>/dev/null

# Find the actual plugin directory
PLUGIN_SOURCE=""
if [ -d "$EXTRACT_DIR/$PLUGIN_NAME" ]; then
    PLUGIN_SOURCE="$EXTRACT_DIR/$PLUGIN_NAME"
elif [ -d "$EXTRACT_DIR" ] && [ -f "$EXTRACT_DIR/plugin.py" ]; then
    PLUGIN_SOURCE="$EXTRACT_DIR"
else
    # Try to find any directory that might be the plugin
    PLUGIN_FOUND=$(find "$EXTRACT_DIR" -maxdepth 2 -type d -name "MBotton" -o -name "MBotton-*" 2>/dev/null | head -1)
    if [ -n "$PLUGIN_FOUND" ] && [ -d "$PLUGIN_FOUND" ]; then
        PLUGIN_SOURCE="$PLUGIN_FOUND"
    elif [ -d "$EXTRACT_DIR" ]; then
        # Check if there's a subdirectory with plugin.py
        SUBDIR=$(find "$EXTRACT_DIR" -maxdepth 2 -name "plugin.py" -exec dirname {} \; 2>/dev/null | head -1)
        if [ -n "$SUBDIR" ] && [ -d "$SUBDIR" ]; then
            PLUGIN_SOURCE="$SUBDIR"
        else
            # Use the first directory found
            FIRST_DIR=$(find "$EXTRACT_DIR" -maxdepth 1 -type d ! -path "$EXTRACT_DIR" 2>/dev/null | head -1)
            if [ -n "$FIRST_DIR" ]; then
                PLUGIN_SOURCE="$FIRST_DIR"
            fi
        fi
    fi
fi

if [ -z "$PLUGIN_SOURCE" ] || [ ! -d "$PLUGIN_SOURCE" ]; then
    echo -e "${RED}❌ Could not find plugin directory in the archive${NC}"
    echo -e "${YELLOW}   Archive contents:${NC}"
    tar -tzf "$PACKAGE_PATH" 2>&1 | head -30
    rm -rf "$PACKAGE_PATH" "$EXTRACT_DIR"
    exit 1
fi

echo -e "${GREEN}✓ Found plugin at: $PLUGIN_SOURCE${NC}"

# Copy plugin to installation directory
echo -e "${YELLOW}▶ Installing plugin to $INSTALL_DIR...${NC}"
mkdir -p "$INSTALL_DIR"

# Remove old installation
rm -rf "$INSTALL_DIR/$PLUGIN_NAME" 2>/dev/null

# Copy the plugin
if ! cp -rf "$PLUGIN_SOURCE" "$INSTALL_DIR/$PLUGIN_NAME" 2>&1; then
    echo -e "${RED}❌ Failed to copy plugin${NC}"
    rm -rf "$PACKAGE_PATH" "$EXTRACT_DIR"
    exit 1
fi

# Verify installation
if [ ! -d "$INSTALL_DIR/$PLUGIN_NAME" ]; then
    echo -e "${RED}❌ Installation failed - Plugin directory not found${NC}"
    rm -rf "$PACKAGE_PATH" "$EXTRACT_DIR"
    exit 1
fi

# Check if plugin.py exists
if [ ! -f "$INSTALL_DIR/$PLUGIN_NAME/plugin.py" ]; then
    echo -e "${YELLOW}⚠️  Warning: plugin.py not found in the installed directory${NC}"
    echo -e "${YELLOW}   Installed files:${NC}"
    ls -la "$INSTALL_DIR/$PLUGIN_NAME"
fi

# Clean up
rm -rf "$PACKAGE_PATH" "$EXTRACT_DIR"

echo -e "${GREEN}"
echo "#########################################################"
echo "#              ✓ INSTALLED SUCCESSFULLY                #"
echo "#                     $PLUGIN_NAME                     #"
echo "#           Enigma2 restart is required                 #"
echo "#########################################################"
echo -e "${NC}"

# Automatic restart after 3 seconds
echo -e "${YELLOW}▶ Restarting Enigma2 in 3 seconds...${NC}"
echo -e "${YELLOW}   Press Ctrl+C to cancel${NC}"
sleep 3

echo -e "${RED}▶ Restarting Enigma2...${NC}"

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

echo ""
echo -e "${CYAN}Script execution completed${NC}"