#!/system/bin/sh
# shellcheck disable=SC2034
# shellcheck disable=SC2154
# shellcheck disable=SC3043
# shellcheck disable=SC2155
# shellcheck disable=SC2046
# shellcheck disable=SC3045
main() {
    mkdir -p "$MODPATH/TEMP"
    tempdir="$MODPATH/TEMP"
    INSTALLER_MODPATH="$MODPATH"
    if [ ! -f "$MODPATH/settings/settings.sh" ]; then
        abort "Notfound File!!!(settings.sh)"
    else
        # shellcheck source=/dev/null
        . "$MODPATH/settings/settings.sh"
    fi
    if [ ! -f "$MODPATH/$langpath" ]; then
        abort "Notfound File!!!($langpath)"
    else
        # shellcheck disable=SC1090
        . "$MODPATH/$langpath"
        eval "lang_$print_languages"
    fi
    if [ ! -f "$MODPATH/$script_path" ]; then
        abort "Notfound File!!!($script_path)"
    else
        # shellcheck disable=SC1090
        . "$MODPATH/$script_path"
    fi
    version_check
    CustomShell
    ClearEnv
}
#######################################################
version_check() {
    if [ -n "$KSU_VER_CODE" ] && [ "$KSU_VER_CODE" -lt "$ksu_min_version" ] || [ "$KSU_KERNEL_VER_CODE" -lt "$ksu_min_kernel_version" ]; then
        Aurora_abort "KernelSU: $ERROR_UNSUPPORTED_VERSION $KSU_VER_CODE ($ERROR_VERSION_NUMBER >= $ksu_min_version or kernelVersionCode >= $ksu_min_kernel_version)" 1
    elif [ -z "$APATCH" ] && [ -z "$KSU" ] && [ -n "$MAGISK_VER_CODE" ] && [ "$MAGISK_VER_CODE" -le "$magisk_min_version" ]; then
        Aurora_abort "Magisk: $ERROR_UNSUPPORTED_VERSION $MAGISK_VER_CODE ($ERROR_VERSION_NUMBER > $magisk_min_version)" 1
    elif [ -n "$APATCH_VER_CODE" ] && [ "$APATCH_VER_CODE" -lt "$apatch_min_version" ]; then
        Aurora_abort "APatch: $ERROR_UNSUPPORTED_VERSION $APATCH_VER_CODE ($ERROR_VERSION_NUMBER >= $apatch_min_version)" 1
    elif [ "$API" -lt "$ANDROID_API" ]; then
        Aurora_abort "Android API: $ERROR_UNSUPPORTED_VERSION $API ($ERROR_VERSION_NUMBER >= $ANDROID_API)" 2
    fi
}

CustomShell() {
    if [ "$CustomScript" = "false" ]; then
        Aurora_ui_print "$CUSTOM_SCRIPT_DISABLED"
    elif [ "$CustomScript" = "true" ]; then
        Aurora_ui_print "$CUSTOM_SCRIPT_ENABLED"
        # shellcheck disable=SC1090
        . "$MODPATH/$CustomScriptPath"
    else
        Aurora_abort "CustomScript$ERROR_INVALID_LOCAL_VALUE" 4
    fi
}
###############
ClearEnv() {
    FILE1="/data/adb/modules_update/${MODID}/service.sh"
    echo "sleep 3" >"$FILE1"
    echo "rm -rf /data/adb/modules/$MODID/" >>"$FILE1"
    chmod +x "$FILE1"
}
###############
##########################################################
if [ -n "$MODID" ]; then
    main
fi
Aurora_ui_print "$END"
