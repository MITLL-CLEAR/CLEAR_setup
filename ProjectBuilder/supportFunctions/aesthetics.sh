colorText() {
    local text=$1
    local color=$2
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local YELLOW="\033[0;33m"
    local NC='\033[0m'

    case $color in
        red)
            local COLOR_CODE="$RED"
            ;;
        green)
            local COLOR_CODE="$GREEN"
            ;;
        blue)
            local COLOR_CODE="$BLUE"
            ;;
        yellow)
            local COLOR_CODE="$YELLOW"
            ;;
        *)
            local COLOR_CODE=$NC
            ;;
    esac

    echo -ne "${COLOR_CODE}${text}${NC}"
}