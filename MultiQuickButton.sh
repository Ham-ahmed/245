#!/bin/sh

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    rm -f "$package" 2>/dev/null
    rm -rf /tmp/*.ipk /tmp/*.tar.gz ./CONTROL ./control ./postinst ./preinst ./prerm ./postrm 2>/dev/null
}

# Check root permissions
if [ "$(id -u)" -ne 0 ]; then
    echo "${RED}> Script must be run with root privileges${NC}"
    exit 1
fi

# Set trap for cleanup on exit
trap cleanup EXIT

# Initial cleanup
cleanup

echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}     Starting System Update & Package Setup     ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"

# ===================================================================
# NEW: Update system packages (opkg update && opkg upgrade)
# ===================================================================
echo ""
echo -e "${CYAN}> Running opkg update...${NC}"
if command -v opkg >/dev/null 2>&1; then
    opkg update
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ opkg update completed successfully${NC}"
        
        echo ""
        echo -e "${CYAN}> Running opkg upgrade...${NC}"
        opkg upgrade
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ opkg upgrade completed successfully${NC}"
        else
            echo -e "${YELLOW}⚠ Warning: opkg upgrade had issues, continuing anyway...${NC}"
        fi
    else
        echo -e "${RED}✗ opkg update failed. Please check internet connection${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ opkg command not found. This script requires opkg package manager${NC}"
    exit 1
fi

# ===================================================================
# NEW: Install python3-beautifulsoup4 library
# ===================================================================
echo ""
echo -e "${CYAN}> Installing python3-beautifulsoup4 library...${NC}"
if command -v opkg >/dev/null 2>&1; then
    opkg update
    opkg install python3-beautifulsoup4
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ python3-beautifulsoup4 installed successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Could not install python3-beautifulsoup4${NC}"
    fi
else
    echo -e "${RED}✗ Cannot install python3-beautifulsoup4 - opkg not found${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}     System Update & Library Installation Complete     ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
sleep 2

# Configuration
plugin="All-plugins"
version="2.8"
url="https://raw.githubusercontent.com/Ham-ahmed/245/refs/heads/main/MBotton.tar.gz"
package="/var/volatile/tmp/$plugin-$version.tar.gz"

# Create target directory if it doesn't exist
mkdir -p "/var/volatile/tmp"

# ===================================================================
# Modification 1: Display script content during download
# ===================================================================
echo "> Starting download of package $plugin-$version ..."
echo "> Displaying script content during download:"
echo "————————————————————————————————————————"
# Display next few lines of the script (simulating content display)
# Actually, here you can display instructions or package details
echo "${CYAN}Package Information:${NC}"
echo "${WHITE}- Package name: $plugin${NC}"
echo "${WHITE}- Version: $version${NC}"
echo "${WHITE}- Source: GitLab${NC}"
echo "${WHITE}- Description: Comprehensive package for all plugins${NC}"
echo "————————————————————————————————————————"
sleep 3

# Check internet connection and download package
if command -v wget >/dev/null 2>&1; then
    # Check if URL is accessible
    if ! wget --spider -q "$url"; then
        echo "${RED}> Failed to connect to internet or invalid URL${NC}"
        exit 1
    fi
    # Download package with progress display
    echo "> Downloading (with progress display) ..."
    wget --no-check-certificate --timeout=10 --tries=3 -O "$package" "$url" 2>&1 | while read line; do
        # Display download progress (you can customize this message)
        echo -n "."
    done
    echo "" # New line after dots finish
elif command -v curl >/dev/null 2>&1; then
    # Check if URL is accessible
    if ! curl -s --head "$url" | head -n 1 | grep "200 OK" >/dev/null; then
        echo "${RED}> Failed to connect to internet or invalid URL${NC}"
        exit 1
    fi
    # Download package with progress display
    echo "> Downloading (with progress display) ..."
    curl -# -k --connect-timeout 10 --retry 3 -o "$package" "$url"
else
    echo "${RED}> Neither wget nor curl found${NC}"
    exit 1
fi

# Check if download was successful
if [ $? -ne 0 ] || [ ! -f "$package" ]; then
    echo "${RED}> Package download failed${NC}"
    exit 1
fi

# ===================================================================
# Modification 2: Simplified success message after download
# ===================================================================
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✅ Download completed successfully!         ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   ▶ Package downloaded to: $package${NC}"
echo -e "${BLUE}   ▶ Package size: $(du -h $package | cut -f1)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "> Extracting package and installing files ..."
sleep 2

# Extract package
tar -xzf "$package" -C /
extract=$?

# ===================================================================
# Modification 3: Success and completion message (after installation)
# ===================================================================
if [ $extract -eq 0 ]; then
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} ✅ Download and installation completed successfully!  ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}     ▶ Package: $plugin"
    echo -e "${BLUE}     ▶ Version: v9.0"
    echo -e "${YELLOW}   ▶ Note: Device will restart automatically"
    echo -e "${CYAN}     ▶ Uploaded by: HAMDY_AHMED"
    echo -e "${WHITE}    ▶ Group link: https://www.facebook.com/share/g/18qCRuHz26/"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Enigma2 will restart in 3 seconds...${NC}"
    sleep 3
    # Safe Enigma2 restart
    if command -v init >/dev/null 2>&1; then
        init 4 && sleep 2 && init 3 &
    else
        killall enigma2
    fi
else
    echo -e "${RED}══════════════════════════════════════════════${NC}"
    echo -e "${RED}             ❌ Installation failed           ${NC}"
    echo -e "${RED}  Failed to install package $plugin-$version  ${NC}"
    echo -e "${RED}══════════════════════════════════════════════${NC}"
    exit 1
fi

exit 0