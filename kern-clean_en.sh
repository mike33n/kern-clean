#!/bin/bash

# Check if bc is installed
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' is not installed. Please install it: sudo apt install bc"
    exit 1
fi

# Color definitions using tput (uses your terminal's color palette)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BRIGHT_GREEN=$(tput setaf 2; tput bold)
NC=$(tput sgr0) # Reset to default terminal colors

# Virtualization detection
VIRT_STATUS=$(systemd-detect-virt)
VIRT_MSG=$([ "$VIRT_STATUS" = "none" ] && echo "${GREEN}PHYSICAL${NC}" || echo "${RED}VIRTUAL ($VIRT_STATUS)${NC}")

get_size() {
    local pkg_name="$1"
    local size_kb=$(dpkg-query -W -f='${Installed-Size}' "$pkg_name" 2>/dev/null)
    if [[ -z "$size_kb" ]]; then echo "0.00"; else echo "scale=2; $size_kb / 1024" | bc; fi
}

refresh_lists() {
    CURRENT_KERNEL=$(uname -r)
    # Filtering only installed packages (status ii)
    KERNELS_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-image-[0-9]*' | grep '^ii' | awk '{print $2}' | sort -V))
    HEADERS_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-headers-[0-9]*' | grep '^ii' | grep -v 'common' | awk '{print $2}' | sort -V))
    MODULES_EXTRA_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-modules-extra-[0-9]*' | grep '^ii' | awk '{print $2}' | sort -V))
    MODULES_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-modules-[0-9]*' | grep '^ii' | grep -v 'extra' | awk '{print $2}' | sort -V))
}

display_indexed_list() {
    local -n current_list=$1
    if [ ${#current_list[@]} -eq 0 ]; then 
        echo "${RED}   No installed packages found.${NC}"
        return 1
    fi
    local i=0
    for item in "${current_list[@]}"; do
        char=$(printf "\\$(printf '%03o' $((i + 97)))")
        size=$(get_size "$item")
        if [[ "$item" == *"$CURRENT_KERNEL"* ]]; then
            echo "  ${BRIGHT_GREEN}$char) $item  [$size MB]  [ACTIVE]${NC}"
        else
            echo "  ${RED}$char)${NC} $item  [${BLUE}$size MB${NC}]"
        fi
        ((i++))
    done
}

process_removal() {
    local -n current_list=$1
    local input=$2
    input=$(echo "$input" | sed 's/[ ,]//g')
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        idx=$(($(printf '%d' "'$char") - 97))
        if [[ "$idx" -ge 0 && "$idx" -lt "${#current_list[@]}" ]]; then
            package="${current_list[$idx]}"
            if [[ "$package" == *"$CURRENT_KERNEL"* ]]; then
                echo "${RED}BLOCK: $package is currently in use!${NC}"
            else
                echo "${RED}Removing: $package...${NC}"
                sudo apt-get purge "$package" -y
                [[ "$package" == *"linux-image-"* || "$package" == *"linux-modules-"* ]] && sudo update-grub
            fi
        fi
    done
    read -p "Done. Press Enter..."
}

while true; do
    refresh_lists
    clear
    echo "${BLUE}======================================================${NC}"
    echo " ACTIVE KERNEL: ${BRIGHT_GREEN}$CURRENT_KERNEL${NC}"
    echo " SYSTEM TYPE:   $VIRT_MSG"
    echo "${BLUE}======================================================${NC}"
    echo " 1) Kernels (images)    2) Headers"
    echo " 3) Extra Modules       4) Base Modules"
    echo "------------------------------------------------------"
    echo " a) Autoremove          c) Clean 'ghost' pkgs (status rc)"
    echo " f) Remove dead /lib/modules (Free up space)"
    echo " q) Exit"
    echo "------------------------------------------------------"
    read -p "Choose option: " MAIN_CHOICE

    case $MAIN_CHOICE in
        [1-4]) 
            case $MAIN_CHOICE in
                1) list=KERNELS_LIST ;; 2) list=HEADERS_LIST ;; 3) list=MODULES_EXTRA_LIST ;; 4) list=MODULES_LIST ;;
            esac
            
            echo ""
            echo "${BLUE}--- Select letters to remove ---${NC}"
            echo "${RED}(Or press ENTER to go back)${NC}"
            echo ""
            
            if display_indexed_list $list; then
                read -p "Selection: " L
                if [[ -z "$L" ]]; then
                    continue
                elif [[ "$L" != "q" ]]; then
                    process_removal $list "$L"
                fi
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        a) sudo apt autoremove --purge -y && read -p "Finished. Press Enter..." ;;
        c) echo "${RED}Removing residual configuration (rc)...${NC}"
           dpkg -l | grep '^rc' | awk '{print $2}' | xargs -r sudo dpkg --purge
           read -p "Finished. Press Enter..." ;;
        f) echo "${RED}Searching for orphaned folders in /lib/modules...${NC}"
           for dir in /lib/modules/*; do
               version=$(basename "$dir")
               if ! dpkg -l | grep -q "linux-modules-$version"; then
                   if [[ "$version" != "$CURRENT_KERNEL" ]]; then
                       echo "${RED}Deleting orphaned directory: $dir${NC}"
                       sudo rm -rf "$dir"
                   fi
               fi
           done
           read -p "Cleanup complete. Press Enter..." ;;
        q) exit 0 ;;
    esac
done