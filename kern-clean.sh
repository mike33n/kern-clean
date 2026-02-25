#!/bin/bash

# Sprawdzenie czy bc jest zainstalowane
if ! command -v bc &> /dev/null; then
    echo "Błąd: Program 'bc' nie jest zainstalowany. Zainstaluj go: sudo apt install bc"
    exit 1
fi

# Definicja kolorów za pomocą tput (korzysta z palety terminala)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BRIGHT_GREEN=$(tput setaf 2; tput bold)
NC=$(tput sgr0) # Reset do domyślnych kolorów terminala

# Wykrywanie wirtualizacji
VIRT_STATUS=$(systemd-detect-virt)
VIRT_MSG=$([ "$VIRT_STATUS" = "none" ] && echo -e "${GREEN}FIZYCZNY${NC}" || echo -e "${RED}WIRTUALNY ($VIRT_STATUS)${NC}")

get_size() {
    local pkg_name="$1"
    local size_kb=$(dpkg-query -W -f='${Installed-Size}' "$pkg_name" 2>/dev/null)
    if [[ -z "$size_kb" ]]; then echo "0.00"; else echo "scale=2; $size_kb / 1024" | bc; fi
}

refresh_lists() {
    CURRENT_KERNEL=$(uname -r)
    KERNELS_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-image-[0-9]*' | grep '^ii' | awk '{print $2}' | sort -V))
    HEADERS_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-headers-[0-9]*' | grep '^ii' | grep -v 'common' | awk '{print $2}' | sort -V))
    MODULES_EXTRA_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-modules-extra-[0-9]*' | grep '^ii' | awk '{print $2}' | sort -V))
    MODULES_LIST=($(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 'linux-modules-[0-9]*' | grep '^ii' | grep -v 'extra' | awk '{print $2}' | sort -V))
}

display_indexed_list() {
    local -n current_list=$1
    if [ ${#current_list[@]} -eq 0 ]; then 
        echo "${RED}   Brak zainstalowanych pakietów.${NC}"
        return 1
    fi
    local i=0
    for item in "${current_list[@]}"; do
        char=$(printf "\\$(printf '%03o' $((i + 97)))")
        size=$(get_size "$item")
        if [[ "$item" == *"$CURRENT_KERNEL"* ]]; then
            echo "  ${BRIGHT_GREEN}$char) $item  [$size MB]  [AKTYWNE]${NC}"
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
                echo "${RED}BLOKADA: $package${NC}"
            else
                echo "${RED}Usuwanie: $package...${NC}"
                sudo apt-get purge "$package" -y
                [[ "$package" == *"linux-image-"* || "$package" == *"linux-modules-"* ]] && sudo update-grub
            fi
        fi
    done
    read -p "Gotowe. Enter..."
}

while true; do
    refresh_lists
    clear
    echo "${BLUE}======================================================${NC}"
    echo " AKTYWNE JĄDRO: ${BRIGHT_GREEN}$CURRENT_KERNEL${NC}"
    echo " STATUS:        $VIRT_MSG"
    echo "${BLUE}======================================================${NC}"
    echo " 1) Jądra (image)       2) Nagłówki (headers)"
    echo " 3) Moduły Extra        4) Moduły Podstawowe"
    echo "------------------------------------------------------"
    echo " a) Autoremove          c) Czyść 'duchy' (status rc)"
    echo " f) Usuń martwe foldery /lib/modules (Zwolnij miejsce)"
    echo " q) Wyjście"
    echo "------------------------------------------------------"
    read -p "Wybierz opcję: " MAIN_CHOICE

    case $MAIN_CHOICE in
        [1-4]) 
            case $MAIN_CHOICE in
                1) list=KERNELS_LIST ;; 2) list=HEADERS_LIST ;; 3) list=MODULES_EXTRA_LIST ;; 4) list=MODULES_LIST ;;
            esac
            
            echo ""
            echo "${BLUE}--- Wybierz litery do usunięcia ---${NC}"
            echo "${RED}(Lub naciśnij ENTER, aby wrócić)${NC}"
            echo ""
            
            if display_indexed_list $list; then
                read -p "Wybór: " L
                if [[ -z "$L" ]]; then
                    continue
                elif [[ "$L" != "q" ]]; then
                    process_removal $list "$L"
                fi
            else
                read -p "Naciśnij Enter, aby kontynuować..."
            fi
            ;;
        a) sudo apt autoremove --purge -y && read -p "Zakończono. Enter..." ;;
        c) echo "${RED}Usuwanie pozostałości (rc)...${NC}"
           dpkg -l | grep '^rc' | awk '{print $2}' | xargs -r sudo dpkg --purge
           read -p "Zakończono. Enter..." ;;
        f) echo "${RED}Szukanie folderów w /lib/modules...${NC}"
           for dir in /lib/modules/*; do
               version=$(basename "$dir")
               if ! dpkg -l | grep -q "linux-modules-$version"; then
                   if [[ "$version" != "$CURRENT_KERNEL" ]]; then
                       echo "${RED}Usuwam osierocony folder: $dir${NC}"
                       sudo rm -rf "$dir"
                   fi
               fi
           done
           read -p "Zakończono czyszczenie plików. Enter..." ;;
        q) exit 0 ;;
    esac
done