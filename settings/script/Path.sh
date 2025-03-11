#!/system/bin/sh
# shellcheck disable=SC2034
# shellcheck disable=SC2154
# shellcheck disable=SC3043
# shellcheck disable=SC2155
# shellcheck disable=SC2046
# shellcheck disable=SC3045
if [ -z "$NOW_PATH" ]; then
    NOW_PATH="$MODPATH"
    SH_NOTMAGISK=true
fi
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
    local filename="AnyKernel3.zip"
    local local_path="$download_destination/$filename"
    local retry_count=0
    local wget_file="$tempdir/wget_file"    

    wget -S --spider "$link" 2>&1 | grep 'Content-Length:' | awk '{print $2}' >"$wget_file"
    file_size_bytes=$(cat "$wget_file")
    if [ -z "$file_size_bytes" ]; then
        Aurora_ui_print "$FAILED_TO_GET_FILE_SIZE $link"
    fi
    local file_size_mb=$(echo "scale=2; $file_size_bytes / 1048576" | bc)
    Aurora_ui_print "$DOWNLOADING $filename $file_size_mb MB"
    while [ $retry_count -lt "$max_retries" ]; do
        wget --output-document="$local_path" "$link"
        if [ -s "$local_path" ]; then
            mv "$local_path" "$local_path"
            Aurora_ui_print "$DOWNLOAD_SUCCEEDED $local_path"
            return 0
        else
            retry_count=$((retry_count + 1))
            rm -f "$local_path"
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

# 文件列表
select_magisk() {
    mkdir -p "$NOW_PATH/TEMP"
    local file="$1"
    local total_lines=$(wc -l <"$file")
    local current_selection=1
    local pressed_key=""
    local SELECT_OUTPUT=""
    local temp_index="$NOW_PATH/TEMP/line_index.tmp"

    # 生成带行号的临时文件
    awk '{print NR "|" $0}' "$file" > "$temp_index"

    # 显示菜单函数
    show_list_menu() {
        echo "================================"
        echo "  如果短按选择不行，请长按3-4s后松开来选择"
        echo "  请用音量键选择模块 (当前选择：$current_selection)"
        echo "================================"
        # 打印前5行（含滚动逻辑）
        local start=$((current_selection - 2))
        [ $start -lt 1 ] && start=1
        local end=$((start + 4))
        [ $end -gt $total_lines ] && end=$total_lines
        
        awk -v start="$start" -v end="$end" -v curr="$current_selection" '
            NR >= start && NR <= end {
                prefix = (NR == curr) ? " > " : "   "
                split($0, arr, "|")
                print prefix arr[2]
            }
        ' "$temp_index"
        echo "================================"
        echo "[音量+] 上移 | [音量-] 下移 | [电源键] 确认"
    }

    # 主选择循环
    while true; do
        show_list_menu
        key_select
        case "$key_pressed" in
            KEY_VOLUMEUP)
                current_selection=$((current_selection > 1 ? current_selection - 1 : 1))
                ;;
            KEY_VOLUMEDOWN)
                current_selection=$((current_selection < total_lines ? current_selection + 1 : total_lines))
                ;;
            KEY_POWER)  # 添加电源键确认支持
                SELECT_OUTPUT=$(awk -F "|" -v line="$current_selection" 'NR == line {print $2}' "$temp_index")
                Aurora_ui_print "已选择：$SELECT_OUTPUT"
                break
                ;;
        esac
        # 简易清屏：打印50个空行
        for i in $(seq 1 50); do echo; done
    done
      
    echo "$SELECT_OUTPUT" > "$MODPATH/select.txt"
}

# 数字选择函数
number_select() {
    mkdir -p "$NOW_PATH/TEMP"
    CURRENT_FILES="$NOW_PATH/TEMP/current_files.tmp"
    # 初始化文件列表
    cp "$1" "$CURRENT_FILES"
    selected="$NOW_PATH/TEMP/selected.tmp"
    clear
    cat -n "$CURRENT_FILES"
    sed -i -e '$a\' "$CURRENT_FILES"

    # 获取有效数字范围
    total=$(wc -l <"$CURRENT_FILES")
    max_digits=${#total}

    # 数字输入处理
    while true; do
        printf "%s" "$PROMPT_ENTER_NUMBER"
        printf "(1-%d): " "$total"
        read num

        # 去除前导零
        num=$(echo "$num" | sed 's/^0*//')

        # 验证输入有效性
        if [ -z "$num" ] || ! [ "$num" -eq "$num" ] 2>/dev/null; then
            echo "$ERROR_OUT_OF_RANGE"
            continue
        fi

        if [ "$num" -ge 1 ] && [ "$num" -le "$total" ]; then
            # 提取选择结果
            awk -v line="$num" 'NR == line' "$CURRENT_FILES" >"$selected"
            mv "$selected" "$CURRENT_FILES"
            SELECT_OUTPUT=$(cat "$CURRENT_FILES")
            Aurora_ui_print "$RESULT_TITLE $SELECT_OUTPUT"
            return 0
        else
            echo "$ERROR_OUT_OF_RANGE"
        fi
    done
}
