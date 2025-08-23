escape_special_characters() {
    local input="$1"
    echo "$input" | xmlstarlet unescape | sed -e 's/\\/\\\\/g' \
                        -e 's/"/\\"/g' \
                        -e "s/'/\\'/g" \
                        -e 's/(/\\(/g' \
                        -e 's/)/\\)/g' \
                        -e 's/\[/\\[/g' \
                        -e 's/\]/\\]/g' \
                        -e 's/{/\\{/g' \
                        -e 's/}/\\}/g' \
                        -e 's/\$/\\$/g' \
                        -e 's/</\\</g' \
                        -e 's/>/\\>/g' \
                        -e 's/~//g' \
                        -e 's/&/\\&/g' \
                        -e 's/\*/\\*/g' \
                        -e 's/|/\\|/g' \
                        -e 's/`/\\`/g' \
                        -e 's/;/\\;/g' \
                        -e 's/ /\\ /g'
}
check_title_loaded=true