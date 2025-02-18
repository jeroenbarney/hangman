#!/usr/bin/env bash
set -Eeu

# Variables
IFS='' read -r -d '' output <<'EOL' || true
    +-------+
    |       |
   %s      |
   %s      |
   %s      |
            |
            |
+-----------+

word: %s
incorrect guesses: %s
%s
EOL
lines="$(echo "${output}" | wc -l)"
start="$((($(tput lines) - ${lines}) / 2))"
warning=''
declare -a correct=()
declare -a incorrect=()
declare -a words=('algorithm')
declare -A steps=(
    #step 1
    [01]='   ' [02]='   ' [03]='   '
    #step 2
    [11]=' 0 ' [12]='   ' [13]='   '
    #step 3
    [21]='\0 ' [22]='   ' [23]='   '
    #step 4
    [31]='\0/' [32]=' | ' [33]='   '
    #step 5
    [41]='\0/' [42]=' | ' [43]='/  '
    #step 6
    [51]='\0/' [52]=' | ' [53]='/ \'
)
word="${words[$((RANDOM % ${#words[@]}))]}"

# Functions
cleanup() {
    tput cnorm
    tput rmcup
}
initialize() {
    tput smcup
    tput civis
    trap cleanup EXIT
}
get_word_output() {
    if [[ "${#correct[@]}" == 0 ]]; then
        echo "${word}" | sed -e 's/./_/g'
    else
        echo "${word}" | sed -e "s/$(printf '%s\n' "${correct[@]}" | awk '{printf "%s%s",sep,$_;sep="|"} BEGIN {printf "[^"} END {printf "]"}')/_/g"
    fi
}
get_wrong_output() {
    if [[ "${#incorrect[@]}" == 0 ]]; then
        echo "None"
    else
        printf '%s ' "${incorrect[@]}"
    fi
}
generate_output() {
    for ((i=0;i<$lines;i++)); do
        tput cup $((start + i)) 0
        tput el
    done
    tput cup ${start} 0

    printf -- "${output}" \
        "${steps["${#incorrect[@]}1"]}" \
        "${steps["${#incorrect[@]}2"]}" \
        "${steps["${#incorrect[@]}3"]}" \
        "$(get_word_output)" \
        "$(get_wrong_output)" \
        "${warning}"
}
in_array() {
    local needle="${1}" && shift
    local -a array=("${@}")
    for x in "${array[@]}"; do
        [[ "${x}" == "${needle}" ]] && return 0
    done
    return 1
}
read_next_letter() {
    while true; do
        read -s -n1 char
        [[ "${char}" != '' ]] && break
    done
    warning=''
    if in_array "${char}" "${incorrect[@]}"; then
        warning="$(tput setaf 3)'${char}' is already guessed incorrectly$(tput sgr0)"
    elif in_array "${char}" "${correct[@]}"; then
        warning="$(tput setaf 3)'${char}' is already guessed correctly$(tput sgr0)"
    elif echo "${word}" | grep -q "${char}"; then
        correct+=("${char}")
        warning="$(tput setaf 2)'${char}' was a good guess!$(tput sgr0)"
    else
        incorrect+=("${char}")
        warning="$(tput setaf 1)'${char}' was a wrong guess!$(tput sgr0)"
    fi
}
game_is_won() {
    if ! get_word_output | grep -q _; then
        return 0
    fi
    return 1
}
game_is_lost() {
    if [[ "${#incorrect[@]}" == 5 ]]; then
        return 0
    fi
    return 1
}

initialize
while true; do
    stop=false
    if game_is_won; then
        warning="$(tput setaf 2)You have won the game! :)$(tput sgr0)"
        stop=true
    elif game_is_lost; then
        warning="$(tput setaf 1)game is lost :($(tput sgr0)"
        stop=true
    fi
    generate_output
    if ${stop}; then
        read -s
        break
    fi
    read_next_letter
done