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
                show_menu "选择第 $CHAR_POS 位字母分组：" \
                    "当前候选字母: $CHARS" \
                    "> $CURRENT_GROUP" \
                    $(echo "$AVAILABLE_GROUPS" | sed "s/$CURRENT_GROUP/[ $CURRENT_GROUP ]/")

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
                show_menu "选择第 $CHAR_POS 位字符：" \
                    "分组: $CURRENT_GROUP" \
                    "> $CURRENT_CHAR" \
                    $(echo "$GROUP_CHARS" | sed "s/$CURRENT_CHAR/[ $CURRENT_CHAR ]/g")

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

    cat "$CURRENT_FILES"
    rm -f "$MODPATH"/TEMP/*.tmp 2>/dev/null
}
show_menu() {
    clear
    echo "=============================="
    echo "$1"
    echo "------------------------------"
    shift
    while [ $# -gt 0 ]; do
        echo "  $1"
        shift
    done
    echo "=============================="
    echo "VOL+ 选择 | VOL- 下一个选项"
}
# 数字选择函数
number_select() {
    mkdir -p "$NOW_PATH/TEMP"
    CURRENT_FILES="$NOW_PATH/TEMP/current_files.tmp"
    # 初始化文件列表
    cp "1" "$CURRENT_FILES"
    selected="$NOW_PATH/TEMP/selected.tmp"
    clear
    echo "可用文件列表："
    nl -w 3 -n rz -s " " "$CURRENT_FILES"

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
}
webui_select() {
    TARGET_FILE="$1"
    OUTPUT_FILE="$NOW_PATH/selected.txt"
    PORT=1547
    webui_main
}

gen_webpage() {
    cat <<EOF
HTTP/1.0 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
<head>
    <title>文件选择器</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {font-family: Arial, sans-serif; margin:0; padding:20px;}
        .item {padding:10px; border-bottom:1px solid #ddd; cursor:pointer;}
        .item:hover {background:#f8f8f8;}
    </style>
</head>
<body>
    <h2>当前路径：$NOW_PATH</h2>
    $(cd "$NOW_PATH" && awk '{print "<div class=\"item\" onclick=\"selectItem(\x27" $0 "\x27)\">" $0 "</div>"}' files.txt)
    <script>
    function selectItem(v) {
        fetch('/select?q='+encodeURIComponent(v))
        .then(() => window.close())
    }
    </script>
</body>
</html>
EOF
}

# 启动HTTP服务器
start_server() {
    (
        cd "$NOW_PATH" || exit 1
        {
            gen_webpage
            while read -r line; do
                if echo "$line" | grep -q "GET /select"; then
                    # 提取选择参数
                    echo "$line" | awk -F'[?&= ]' '{for(i=1;i<=NF;i++){if($i~/^q=/){print substr($i,3);exit}}}' |
                        sed 's/+/ /g; s/%/\\x/g' | xargs -0 printf "%b" >"$OUTPUT_FILE"
                    printf "HTTP/1.0 204 No Content\r\n\r\n"
                    exit
                fi
            done
        } | httpd -f -p "127.0.0.1:$PORT" -h "$NOW_PATH"
    )
}

# 主流程
webui_main() {
    # 创建锁文件
    [ -f "$LOCK_FILE" ] && {
        echo "已有进程在运行"
        exit 1
    }
    touch "$LOCK_FILE"

    # 初始化文件
    cp -f "$TARGET_FILE" "$CURRENT_FILES"

    # 启动Web界面
    echo "访问地址：http://127.0.0.1:$PORT"
    start_server &
    if ! netstat -an | grep "$PORT" | grep LISTEN >/dev/null 2>&1; then
        Aurora_abort "HTTP 服务未能成功启动，请检查配置或端口是否被占用。" "12"
    fi
    # 等待选择结果
    while :; do
        [ -s "$OUTPUT_FILE" ] && break
        sleep 1
    done

    # 清理
    pkill -f "busybox httpd.*$NOW_PATH"
    rm -f "$LOCK_FILE" "$CURRENT_FILES"

    # 输出结果
    echo "用户选择：$(cat "$OUTPUT_FILE")"
}
