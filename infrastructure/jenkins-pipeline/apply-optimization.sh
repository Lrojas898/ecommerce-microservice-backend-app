#!/bin/bash

# Script para aplicar la optimización del Jenkinsfile

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ORIGINAL="${SCRIPT_DIR}/Jenkinsfile.build"
OPTIMIZED="${SCRIPT_DIR}/Jenkinsfile.build.optimized"
BACKUP="${SCRIPT_DIR}/Jenkinsfile.build.backup"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Jenkins Pipeline Optimization${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if files exist
if [ ! -f "$ORIGINAL" ]; then
    echo -e "${RED}✗ Original Jenkinsfile not found: $ORIGINAL${NC}"
    exit 1
fi

if [ ! -f "$OPTIMIZED" ]; then
    echo -e "${RED}✗ Optimized Jenkinsfile not found: $OPTIMIZED${NC}"
    exit 1
fi

# Show comparison
echo -e "\n${YELLOW}Comparison:${NC}"
echo -e "Original:  $(wc -l < "$ORIGINAL") lines"
echo -e "Optimized: $(wc -l < "$OPTIMIZED") lines"
echo -e "Reduction: $(echo "scale=1; (1 - $(wc -l < "$OPTIMIZED") / $(wc -l < "$ORIGINAL")) * 100" | bc)%"

echo -e "\n${YELLOW}Key improvements:${NC}"
echo -e "✓ Unified Maven build (10 builds → 1 build)"
echo -e "✓ Parallel test execution"
echo -e "✓ Parallel Docker builds"
echo -e "✓ Optimized Docker images (no multi-stage)"
echo -e "✓ Better resource management"
echo -e "✓ Expected time: 45min → 12min"

echo -e "\n${BLUE}What would you like to do?${NC}"
echo "1) Apply optimization (backup original)"
echo "2) Show diff between versions"
echo "3) View comparison document"
echo "4) Rollback to backup"
echo "5) Exit"

read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        # Backup original
        if [ ! -f "$BACKUP" ]; then
            echo -e "\n${YELLOW}Creating backup...${NC}"
            cp "$ORIGINAL" "$BACKUP"
            echo -e "${GREEN}✓ Backup created: $BACKUP${NC}"
        else
            echo -e "\n${YELLOW}Backup already exists at: $BACKUP${NC}"
        fi

        # Apply optimization
        echo -e "\n${YELLOW}Applying optimization...${NC}"
        cp "$OPTIMIZED" "$ORIGINAL"
        echo -e "${GREEN}✓ Optimization applied!${NC}"
        echo -e "\n${YELLOW}Next steps:${NC}"
        echo "1. Commit the changes: git add $ORIGINAL"
        echo "2. Push to trigger Jenkins build"
        echo "3. Monitor the first build carefully"
        echo "4. Rollback if needed with: $0 (option 4)"
        ;;

    2)
        echo -e "\n${YELLOW}Showing diff...${NC}"
        diff -u "$ORIGINAL" "$OPTIMIZED" || true
        ;;

    3)
        echo -e "\n${YELLOW}Opening comparison document...${NC}"
        cat "${SCRIPT_DIR}/OPTIMIZATION_COMPARISON.md" | less
        ;;

    4)
        if [ ! -f "$BACKUP" ]; then
            echo -e "${RED}✗ No backup found${NC}"
            exit 1
        fi
        echo -e "\n${YELLOW}Rolling back to backup...${NC}"
        cp "$BACKUP" "$ORIGINAL"
        echo -e "${GREEN}✓ Rollback complete${NC}"
        ;;

    5)
        echo -e "\n${BLUE}Exiting...${NC}"
        exit 0
        ;;

    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac
