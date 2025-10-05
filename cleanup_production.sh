#!/bin/bash
# ============================================================================
# Production Cleanup Script - Attendance System
# ============================================================================
# This script safely removes unused files and cleans up the codebase
# for production deployment of the attendance-only system.
#
# Usage: bash cleanup_production.sh [--dry-run]
#        --dry-run: Show what would be deleted without actually deleting
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if dry-run mode
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "${YELLOW}🔍 DRY RUN MODE - No files will be deleted${NC}"
fi

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Production Cleanup - Attendance System      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Safety Check
# ============================================================================
echo -e "${YELLOW}⚠️  WARNING: This script will delete files!${NC}"
echo -e "${YELLOW}   Make sure you have committed your changes to git.${NC}"
echo ""

if [ "$DRY_RUN" = false ]; then
    read -p "Do you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${RED}❌ Cleanup cancelled${NC}"
        exit 0
    fi
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Are you in the project root?${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Starting cleanup process...${NC}"
echo ""

# ============================================================================
# Phase 1: Delete Completely Unused Files
# ============================================================================
echo -e "${BLUE}📁 Phase 1: Removing unused files...${NC}"

FILES_TO_DELETE=(
    "lib/Views/home/screens/home.dart"
    "lib/Views/home/screens/payment_screen.dart"
    "lib/Views/home/screens/discipline_screen.dart"
    "lib/services/payment_services.dart"
    "lib/services/descipline_service.dart"
    "lib/models/payment.dart"
    "lib/models/discipline.dart"
    "lib/screens/settings_screen.dart"
)

DELETED_COUNT=0
SKIPPED_COUNT=0

for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} Would delete: $file"
        else
            rm "$file"
            echo -e "  ${GREEN}✓${NC} Deleted: $file"
        fi
        ((DELETED_COUNT++))
    else
        echo -e "  ${YELLOW}⊘${NC} Not found (already deleted?): $file"
        ((SKIPPED_COUNT++))
    fi
done

echo ""
echo -e "${GREEN}Phase 1 Complete:${NC} $DELETED_COUNT deleted, $SKIPPED_COUNT already gone"
echo ""

# ============================================================================
# Phase 2: Fix Unused Imports
# ============================================================================
echo -e "${BLUE}📦 Phase 2: Checking for unused imports...${NC}"
echo "  Running flutter analyze to detect unused imports..."
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "  ${YELLOW}[DRY-RUN]${NC} Would run: flutter analyze"
else
    flutter analyze 2>&1 | grep "unused_import" | head -20
fi

echo ""
echo -e "${YELLOW}Note: You'll need to manually remove unused imports shown above.${NC}"
echo ""

# ============================================================================
# Phase 3: Report Unused Variables and Methods
# ============================================================================
echo -e "${BLUE}🔍 Phase 3: Scanning for unused code...${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "  ${YELLOW}[DRY-RUN]${NC} Would run: flutter analyze"
else
    echo "Unused elements found:"
    flutter analyze 2>&1 | grep -E "(unused_element|unused_field|unused_local_variable)" | head -20
fi

echo ""

# ============================================================================
# Phase 4: Clean Up Database References
# ============================================================================
echo -e "${BLUE}🗄️  Phase 4: Database cleanup recommendations...${NC}"
echo ""
echo "  Please manually review and update:"
echo "  1. lib/SQLite/database_helper.dart"
echo "     - Remove payment table schema"
echo "     - Remove discipline table schema"
echo "     - Remove unused methods"
echo ""

# ============================================================================
# Phase 5: Optional Files
# ============================================================================
echo -e "${BLUE}📚 Phase 5: Optional cleanup...${NC}"
echo ""

OPTIONAL_FILES=(
    "lib/Components/QUICK_ACTIONS_USAGE_EXAMPLE.dart"
)

for file in "${OPTIONAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${YELLOW}⚠️${NC}  Optional: $file"
        echo "     (Documentation file - keep for reference or delete for production)"
    fi
done

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Cleanup Summary                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
    echo "  • Run without --dry-run to actually delete files"
else
    echo -e "${GREEN}✅ Files deleted: $DELETED_COUNT${NC}"
    echo -e "${YELLOW}⚠️  Skipped: $SKIPPED_COUNT${NC}"
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Review PRODUCTION_CLEANUP_REPORT.md for details"
echo "  2. Manually fix unused imports (see Phase 2 above)"
echo "  3. Remove unused methods (see Phase 3 above)"
echo "  4. Update database schema (see Phase 4 above)"
echo "  5. Run: flutter analyze"
echo "  6. Run: flutter test (if you have tests)"
echo "  7. Test the app thoroughly"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}✅ Cleanup complete!${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Test your app now!${NC}"
    echo "   Run: flutter run"
else
    echo -e "${YELLOW}💡 Run without --dry-run when ready to delete files${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
