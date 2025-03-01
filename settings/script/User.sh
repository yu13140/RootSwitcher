#!/system/bin/sh
# shellcheck disable=SC2034
# shellcheck disable=SC2154
# shellcheck disable=SC3043
# shellcheck disable=SC2155
# shellcheck disable=SC2046
# shellcheck disable=SC3045
# shellcheck disable=SC2164
MODPATH="$1"
NOW_PATH="$2"


main() {
    echo ""
    # your code here
}


abort() {
    echo "$1"
    exit 1
}
print_KEY_title() {
    echo ""
    echo -e "\033[36m******************************************\033[0m"
    echo "         ${KEY_VOLUME}+$1"
    echo "         ${KEY_VOLUME}-$2"
    echo -e "\033[36m******************************************\033[0m"
    echo ""
    key_select
}
if [ ! -f "$NOW_PATH/settings/settings.sh" ]; then
    abort "Notfound File!!!(settings.sh)"
else
    # shellcheck source=/dev/null
    . "$NOW_PATH/settings/settings.sh"
fi
if [ ! -f "$NOW_PATH/$langpath" ]; then
    abort "Notfound File!!!($langpath)"
else
    # shellcheck disable=SC1090
    . "$NOW_PATH/$langpath"
    eval "lang_$print_languages"
fi
if [ ! -f "$NOW_PATH/$script_path" ]; then
    abort "Notfound File!!!($script_path)"
else
    # shellcheck disable=SC1090
    . "$NOW_PATH/$script_path"
fi
main
echo ""
rm -rf "$NOW_PATH"
echo -e "\033[32;49;1m [DONE] \033[39;49;0m"
exit 0
