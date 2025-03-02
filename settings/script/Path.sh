#!/system/bin/sh
# shellcheck disable=SC2034
# shellcheck disable=SC2154
# shellcheck disable=SC3043
# shellcheck disable=SC2155
# shellcheck disable=SC2046
# shellcheck disable=SC3045

key_select() {
    key_pressed=""
    while true; do
        local output=$(/system/bin/getevent -qlc 1)
        local key_event=$(echo "$output" | awk '{ print $3 }' | grep 'KEY_')
        local key_status=$(echo "$output" | awk '{ print $4 }')
        if echo "$key_event" | grep -q 'KEY_' && [ "$key_status" = "DOWN" ]; then
            key_pressed="$key_event"
            break
        fi
    done
    while true; do
        local output=$(/system/bin/getevent -qlc 1)
        local key_event=$(echo "$output" | awk '{ print $3 }' | grep 'KEY_')
        local key_status=$(echo "$output" | awk '{ print $4 }')
        if [ "$key_event" = "$key_pressed" ] && [ "$key_status" = "UP" ]; then
            break
        fi
    done
}
Aurora_ui_print() {
    sleep 0.02
    echo "[${OUTPUT}] $1"
}

Aurora_abort() {
    echo "[${ERROR_TEXT}] $1"
    abort "$ERROR_CODE_TEXT: $2"
}
Aurora_test_input() {
    if [ -z "$3" ]; then
        Aurora_ui_print "$1 ( $2 ) $WARN_MISSING_PARAMETERS"
    fi
}
print_title() {
    if [ -n "$2" ]; then
        Aurora_ui_print "$1 $2"
    fi
}
ui_print() {
    if [ "$1" = "- Setting permissions" ]; then
        return
    fi
    if [ "$1" = "- Extracting module files" ]; then
        return
    fi
    if [ "$1" = "- Current boot slot: $SLOT" ]; then
        return
    fi
    if [ "$1" = "- Device is system-as-root" ]; then
        return
    fi
    if [ "$(echo "$1" | grep -c '^ - Mounting ')" -gt 0 ]; then
        return
    fi
    if [ "$1" = "- Done" ]; then
        return
    fi
    echo "$1"
}
#About_the_custom_script
###############
un_zstd_tar() {
    Aurora_test_input "un_zstd_tar" "1" "$1"
    Aurora_test_input "un_zstd_tar" "2" "$2"
    $zstd -d "$1" -o "$2/temp.tar"
    tar -xf "$2/temp.tar" -C "$2"
    rm "$2/temp.tar"
    if [ $? -eq 0 ]; then
        Aurora_ui_print "$UNZIP_FINNSH"
    else
        Aurora_ui_print "$UNZIP_ERROR"
    fi
}
check_network() {
    ping -c 1 www.baidu.com >/dev/null 2>&1
    local baidu_status=$?
    ping -c 1 github.com >/dev/null 2>&1
    local github_status=$?
    ping -c 1 google.com >/dev/null 2>&1
    local google_status=$?
    if [ $google_status -eq 0 ]; then
        Aurora_ui_print "$INTERNET_CONNET (Google)"
        Internet_CONN=3
    elif [ $github_status -eq 0 ]; then
        Aurora_ui_print "$INTERNET_CONNET (GitHub)"
        Internet_CONN=2
    elif [ $baidu_status -eq 0 ]; then
        Aurora_ui_print "$INTERNET_CONNET (Baidu.com)"
        Internet_CONN=1
    else
        Internet_CONN=
    fi
}
download_file() {
    Aurora_test_input "download_file" "1" "$1"
    local link="$1"
    local filename=$(wget --spider -S "$link" 2>&1 | grep -o -E 'filename="[^"]*"' | sed -e 's/^filename="//' -e 's/"$//')
    local local_path="$download_destination/$filename"
    local retry_count=0
    local wget_file="$tempdir/wget_file"
    mkdir -p "$download_destination"

    wget -S --spider "$link" 2>&1 | grep 'Content-Length:' | awk '{print $2}' >"$wget_file"
    file_size_bytes=$(cat "$wget_file")
    if [ -z "$file_size_bytes" ]; then
        Aurora_ui_print "$FAILED_TO_GET_FILE_SIZE $link"
    fi
    local file_size_mb=$(echo "scale=2; $file_size_bytes / 1048576" | bc)
    Aurora_ui_print "$DOWNLOADING $filename $file_size_mb MB"
    while [ $retry_count -lt "$max_retries" ]; do
        wget --output-document="$local_path.tmp" "$link"
        if [ -s "$local_path.tmp" ]; then
            mv "$local_path.tmp" "$local_path"
            Aurora_ui_print "$DOWNLOAD_SUCCEEDED $local_path"
            return 0
        else
            retry_count=$((retry_count + 1))
            rm -f "$local_path.tmp"
            Aurora_ui_print "$RETRY_DOWNLOAD $retry_count/$max_retries... $DOWNLOAD_FAILED $filename"
        fi
    done

    Aurora_ui_print "$DOWNLOAD_FAILED $link"
    Aurora_ui_print "${KEY_VOLUME}+${PRESS_VOLUME_RETRY}"
    Aurora_ui_print "${KEY_VOLUME}-${PRESS_VOLUME_SKIP}"
    key_select
    if [ "$key_pressed" = "KEY_VOLUMEUP" ]; then
        download_file "$link"
    fi
    return 1
}
#!/bin/sh

# 文件列表
select_on_magisk() {
    # 初始化文件列表和位置
    mkdir -p "$NOW_PATH/TEMP"
    CURRENT_FILES="$NOW_PATH/TEMP/current_files.tmp"
    CHAR_POS=1

    # 初始化当前文件列表
    cp "$1" "$CURRENT_FILES"
    filtered_files="$NOW_PATH/TEMP/filtered.tmp"
    filtered="$NOW_PATH/TEMP/filtered.tmp"
    current_chars="$NOW_PATH/TEMP/current_chars.tmp"
    group_chars="$NOW_PATH/TEMP/group_chars.tmp"
    # 主循环处理每个字符位置
    while [ "$(wc -l <"$CURRENT_FILES")" -gt 1 ]; do
        # 处理第N个字符
        cut -c "$CHAR_POS" "$CURRENT_FILES" | tr '[:lower:]' '[:upper:]' | sort -u >"$current_chars"

        CHAR_COUNT=$(wc -l <"$current_chars")
        CHARS=$(tr '\n' ' ' <"$current_chars")

        if [ "$CHAR_COUNT" -eq 1 ]; then
            # 自动选择唯一字符
            SELECTED_CHAR=$(head -1 "$current_chars")
            show_menu "自动选择第 $CHAR_POS 位字符：" "--> $SELECTED_CHAR"
            sleep 1
        else
            # 显示分组选择
            GROUP_ORDER="A-G H-M N-T U-Z Other"
            AVAILABLE_GROUPS=""

            # 生成可用分组列表
            for GROUP in $GROUP_ORDER; do
                case $GROUP in
                "A-G") PATTERN="[A-G]" ;;
                "H-M") PATTERN="[H-M]" ;;
                "N-T") PATTERN="[N-T]" ;;
                "U-Z") PATTERN="[U-Z]" ;;
                "Other") PATTERN="[^A-Z]" ;;
                esac
                grep -q -E "$PATTERN" "$current_chars" && AVAILABLE_GROUPS="$AVAILABLE_GROUPS $GROUP"
            done

            # 分组选择交互
            GROUP_INDEX=0
            AVAILABLE_GROUPS=$(echo "$AVAILABLE_GROUPS" | sed 's/^ //')
            NUM_GROUPS=$(echo "$AVAILABLE_GROUPS" | wc -w)

            while true; do
                CURRENT_GROUP=$(echo "$AVAILABLE_GROUPS" | cut -d ' ' -f $((GROUP_INDEX + 1)))

                # 显示分组菜单
                show_menu "$CHAR_POS" "group" "$AVAILABLE_GROUPS" $((GROUP_INDEX+1))

                key_select
                case "$key_pressed" in
                KEY_VOLUMEUP) break ;;
                KEY_VOLUMEDOWN)
                    GROUP_INDEX=$(((GROUP_INDEX + 1) % NUM_GROUPS))
                    ;;
                esac
            done

            # 处理分组内字符选择
            case "$CURRENT_GROUP" in
            "A-G") PATTERN="[A-G]" ;;
            "H-M") PATTERN="[H-M]" ;;
            "N-T") PATTERN="[N-T]" ;;
            "U-Z") PATTERN="[U-Z]" ;;
            "Other") PATTERN="[^A-Z]" ;;
            esac

            grep -E "$PATTERN" "$current_chars" >"$group_chars"
            GROUP_CHARS=$(tr '\n' ' ' <"$group_chars")
            NUM_CHARS=$(wc -w <"$group_chars")

            # 字符选择交互
            CHAR_INDEX=0
            while true; do
                CURRENT_CHAR=$(echo "$GROUP_CHARS" | cut -d ' ' -f $((CHAR_INDEX + 1)))

                # 显示字符菜单
                show_menu "$CHAR_POS" "char" "$GROUP_CHARS" $((CHAR_INDEX+1))

                key_select
                case "$key_pressed" in
                KEY_VOLUMEUP)
                    SELECTED_CHAR="$CURRENT_CHAR"
                    break
                    ;;
                KEY_VOLUMEDOWN)
                    CHAR_INDEX=$(((CHAR_INDEX + 1) % NUM_CHARS))
                    ;;
                esac
            done
        fi

        # 过滤文件
        awk -v pos="$CHAR_POS" -v char="$SELECTED_CHAR" '
        BEGIN { FS="" }
        {
            current = toupper(substr($0, pos, 1))
            if (current == toupper(char)) print
        }
    ' "$CURRENT_FILES" >"$filtered"

        mv "$filtered" "$CURRENT_FILES"
        CHAR_POS=$((CHAR_POS + 1))
    done

    SELECT_OUTPUT=$(cat "$CURRENT_FILES")
    Aurora_ui_print "选择结果：$SELECT_OUTPUT"
    rm -f "$MODPATH"/TEMP/*.tmp 2>/dev/null
}
show_menu() {
    local clear_command="1"
    while [ "${clear_command}" -le 5 ]; do
        printf "\n                                        \n"
        clear_command=$((clear_command + 1))
    done
    clear
    case "$2" in
    "group")
        echo "======== 分组选择 ========"
        echo "当前候选字母: $CHARS"
        echo "--------------------------"
        ;;
    "char")
        echo "======== 字符选择 ========"
        echo "当前分组: $CURRENT_GROUP"
        echo "--------------------------"
        ;;
    esac

    # 显示选项（仅修改此处循环）
    counter=0
    for item in $3; do
        counter=$((counter + 1))
        if [ $counter -eq $4 ]; then
            echo "> $item"
        else
            echo "  $item"
        fi
    done
    echo "========================"
    echo "VOL+选择 | VOL-切换"
    local clear_command="1"
    while [ "${clear_command}" -le 5 ]; do
        printf "\n                                        \n"
        clear_command=$((clear_command + 1))
    done
}

# 数字选择函数
number_select() {
    mkdir -p "$NOW_PATH/TEMP"
    CURRENT_FILES="$NOW_PATH/TEMP/current_files.tmp"
    # 初始化文件列表
    cp "$1" "$CURRENT_FILES"
    selected="$NOW_PATH/TEMP/selected.tmp"
    clear
    echo "可用列表："
    cat -n "$CURRENT_FILES"
    sed -i -e '$a\' "$CURRENT_FILES"

    # 获取有效数字范围
    total=$(wc -l <"$CURRENT_FILES")
    max_digits=${#total}

    # 数字输入处理
    while true; do
        printf "请输入数字（1-%d）: " "$total"
        read num

        # 去除前导零
        num=$(echo "$num" | sed 's/^0*//')

        # 验证输入有效性
        if [ -z "$num" ] || ! [ "$num" -eq "$num" ] 2>/dev/null; then
            echo "无效输入！"
            continue
        fi

        if [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
            # 提取选择结果
            awk -v line="$num" 'NR == line' "$CURRENT_FILES" >"$selected"
            mv "$selected" "$CURRENT_FILES"
            return 0
        else
            echo "超出范围！"
        fi
    done
    SELECT_OUTPUT=$(cat "$selected")
    Aurora_ui_print "选择结果：$SELECT_OUTPUT"
}
