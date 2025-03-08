#!/system/bin/sh

# Custom Script
# -----------------
# This script extends the functionality of the default and setup scripts, allowing direct use of their variables and functions.
ASH_STANDALONE=1
MODDIR=${0%/*}

. "$MODPATH/settings/settings.sh"
. "$MODPATH/$script_path"

KERNEL_VER="$(uname -r | cut -d "." -f1,2)"

ddQualcomm() {
platform=$(getprop ro.board.platform 2>/dev/null)
if echo "$platform" | grep -qiE '^(msm|apq|qsd)'; then
    Aurora_ui_print "检测到高通处理器（平台：$platform）"
    return
fi
hardware=$(getprop ro.hardware 2>/dev/null)
[ -z "$hardware" ] && hardware=$(getprop ro.boot.hardware 2>/dev/null)
if echo "$hardware" | grep -qi 'qcom'; then
    Aurora_ui_print "检测到高通处理器（硬件：$hardware）" 
    return   
fi
if grep -qiE 'qualcomm|qcom' /proc/cpuinfo 2>/dev/null; then
    Aurora_ui_print "检测到高通处理器（来自/proc/cpuinfo）"  
    return  
fi
if [ -f /system/build.prop ]; then
    if grep -qiE 'qualcomm|qcom' /system/build.prop 2>/dev/null; then
        Aurora_ui_print "检测到高通处理器（来自/system/build.prop）"  
        return      
    fi
fi

Aurora_abort "未检测到高通处理器"
}

ddQualcomm

if [[ ! -d "/dev/block/by-name" ]]; then   
    SITE="/dev/block/bootdevice/by-name"
    if [[ ! -d "/dev/block/bootdevice/by-name" ]]; then
        Aurora_abort "未检测到分区路径，取消安装操作"
    fi 
else
    SITE="/dev/block/by-name" 
fi

foundboot() {
FBOOT="$MODPATH/boot.img"
cd $MODPATH
if [[ $not_magisk = "false" ]]; then
    backup_boot="$(ls -lt /data | grep magisk_backup | head -n 1 | awk '{print $8}')"
    if [[ $backup_boot = "" ]]; then
        Aurora_abort "未找到Magisk备份的原Boot.img，取消安装操作"
    else        
        gzip -dk /data/$backup_boot/boot.img.gz
        cp /data/$backup_boot/boot.img $MODPATH/             
        ./bin/magiskboot unpack boot.img
        mv kernel kernel-b
    fi
else
    if [[ $not_magisk = "apatch" ]]; then
        APatchboot
    elif [[ $not_magisk = "ksu" ]]; then
        backup_boot="$(ls -lt /data/adb/ksu/ | grep ksu_backup | head -n 1 | awk '{print $8}')"        
        if [[ $backup_boot = "" ]]; then
            Aurora_abort "未找到KSU备份的原Boot.img，取消安装操作"
        else
            cp /data/adb/ksu/$backup_boot $MODPATH/            
            mv $MODPATH/$backup_boot boot.img
        fi                                 
    fi    
fi
}

CheckPartition() {
BOOTAB="$(getprop ro.build.ab_update)"
Partition_location="$(getprop ro.boot.slot_suffix)"
if [[ $BOOTAB = "true" ]]; then
    Aurora_ui_print "检测到设备支持A/B分区"    
        if [[ "$Partition_location" == "_a" ]]; then
            Aurora_ui_print "你目前处于 A 分区"
            position=$(ls -l $SITE/boot_a | awk '{print $NF}')
        elif [[ "$Partition_location" == "_b" ]]; then
            Aurora_ui_print "你目前处于 B 分区"
            position=$(ls -l $SITE/boot_b | awk '{print $NF}')
        elif [[ "$Partition_location" == "" ]]; then 
            Aurora_ui_print "未检测到设备目前处于哪个槽位，请选择你需要刷入的槽位"
            Aurora_ui_print "音量上：刷入a槽                       音量下：刷入b槽$RE"
            echo "a" > $MODPATH/ab.txt ; echo "b" >> $MODPATH/ab.txt
            select_magisk "$MODPATH/ab.txt"
            case $SELECT_OUTPUT in 
            a) 
            position=$(ls -l $SITE/boot_a | awk '{print $NF}') ;;
            b) 
            position=$(ls -l $SITE/boot_b | awk '{print $NF}') ;;
            *)
            Aurora_ui_print "$YE输入错误，默认安装到a槽"; position=$(ls -l $SITE/boot_a | awk '{print $NF}') ;;
            esac
        fi
else
    position=$(ls -l $SITE/boot | awk '{print $NF}')
fi    
}

ddbootpatch() {
    if [[ $SELECT_OUTPUT = "APatch" ]]; then
        if [[ `echo "6.1 > $KERNEL_VER" | bc` -eq 1 ]] && [[ `echo "$KERNEL_VER > 3.1" | bc` -eq 1 ]] ; then
            Aurora_abort "你的内核版本不适合APatch，刷入可能会卡一屏"
        fi
        PATCH_PATH="$MODPATH/bin/APatch/"
        foundboot
        chmod -R 755 $PATCH_PATH
        Aurora_ui_print "默认您的超级密钥为a1234567，请记住了"
        $PATCH_PATH/kptools -p --image kernel-b --skey "a1234567" --kpimg $PATCH_PATH/kpimg --out kernel      
        ./bin/magiskboot repack boot.img        
        mv -f new-boot.img boot.img
        dd if=boot.img of="$position" bs=4M
        ./$MODPATH/bin/magiskboot cleanup
    elif [[ $SELECT_OUTPUT = "APatch Next" ]]; then
        if [[ `echo "6.1 > $KERNEL_VER" | bc` -eq 1 ]] && [[ `echo "$KERNEL_VER > 3.1" | bc` -eq 1 ]] ; then
            Aurora_abort "你的内核版本不适合APatch Next，刷入可能会卡一屏"
        fi
        PATCH_PATH="$MODPATH/bin/APatchNext/"
        foundboot
        chmod -R 755 $PATCH_PATH
        Aurora_ui_print "默认您的超级密钥为a1234567，请记住了"
        $PATCH_PATH/kptools -p --image kernel-b --skey "a1234567" --kpimg $PATCH_PATH/kpimg --out kernel        
        ./bin/magiskboot repack boot.img        
        mv -f new-boot.img boot.img
        dd if=boot.img of="$position" bs=4M
        ./$MODPATH/bin/magiskboot cleanup        
    elif [[ $SELECT_OUTPUT = "KernelSU" ]]; then
        if [[ `echo "5.1 > $KERNEL_VER" | bc` -eq 1 ]]; then
            Aurora_abort "你的内核版本不太适合KSU呢，或许你需要自己编译"
        fi
        PATCH_PATH="$MODPATH/bin/KSU/"
        foundboot
        
        android_version=$(getprop ro.build.version.release | cut -d. -f1)
        mm_kernel_version=$(uname -r | cut -d- -f1)
        match_string="android${android_version}-${mm_kernel_version}"
        line_number=$(grep -nx "$match_string" kernel.conf | cut -d: -f1)
        if [ -n "$line_number" ]; then
            giturl=$(sed -n "${line_number}p" $MODPATH/bin/kernelurl.conf)
            download_file "https://github.proxy.class3.fun/$giturl"
            cd $MODPATH
            unzip -o "./AnyKernel3.zip"
            ./bin/magiskboot unpack boot.img
            mv -f Image kernel
            ./bin/magiskboot repack boot.img    
        else
            chmod -R 755 $PATCH_PATH
            $PATCH_PATH/ksud boot-patch -b boot.img --magiskboot $MODPATH/bin/magiskboot
        fi            
            mv -f new-boot.img boot.img        
            sleep 2
            dd if=boot.img of="$position" bs=4M
            ./$MODPATH/bin/magiskboot cleanup        
    elif [[ $SELECT_OUTPUT = "KernelSU" ]]; then
        if [[ `echo "5.1 > $KERNEL_VER" | bc` -eq 1 ]]; then
            Aurora_abort "你的内核版本不太适合KSU NEXT呢，或许你需要自己编译"
        fi
        PATCH_PATH="$MODPATH/bin/KSUNEXT/"
        foundboot
        chmod -R 755 $PATCH_PATH
        $PATCH_PATH/ksud boot-patch -b boot.img --magiskboot $MODPATH/bin/magiskboot       
        mv -f new-boot.img boot.img
        sleep 2
        dd if=boot.img of="$position" bs=4M
        ./$MODPATH/bin/magiskboot cleanup    
    elif [[ $SELECT_OUTPUT = "Magisk Alpha" ]]; then
        PATCH_PATH="$MODPATH/bin/Magisk/Alpha/boot_patch.sh"
        foundboot
        chmod -R 755 $PATCH_PATH
        $PATCH_PATH "$FBOOT"
        sleep 2      
        mv -f new-boot.img boot.img
        dd if=boot.img of="$position" bs=4M
        ./$MODPATH/bin/magiskboot cleanup
    elif [[ $SELECT_OUTPUT = "Magisk Alpha" ]]; then
        PATCH_PATH="$MODPATH/bin/Magisk/Delta/boot_patch.sh"
        foundboot
        chmod -R 755 $PATCH_PATH
        $PATCH_PATH "$FBOOT"
        sleep 2      
        mv -f new-boot.img boot.img
        dd if=boot.img of="$position" bs=4M
        ./$MODPATH/bin/magiskboot cleanup    
    fi
}

APatchboot() {
cd $MODPATH
command -v ./bin/magiskboot >/dev/null 2>&1 || { >&2 echo "- Command magiskboot not found!"; exit 1; }
command -v $APP_PATH/kptools >/dev/null 2>&1 || { >&2 echo "- Command kptools not found!"; exit 1; }
if [ ! -f $APP_PATH/new-boot.img ]; then
    Aurora_ui_print "未找到APatch修补后的boot.img，启用方案二"
    dd if="$position" of="$MODPATH/new-boot.img" bs=4M      
else
    cp $APP_PATH/new-boot.img ./
fi 
./bin/magiskboot unpack new-boot.img
if [ ! $($APP_PATH/kptools -i kernel -l | grep patched=false) ]; then
    $APP_PATH/kptools -u --image kernel --out rekernel
    mv -f rekernel kernel
    ./bin/magiskboot repack new-boot.img boot.img
else
    mv new-boot.img boot.img
fi
}

if [[ -z "$APATCH" ]] && [[ -z "$KSU" ]] && [[ -n "$MAGISK_VER_CODE" ]]; then    
    VERSION="$MAGISK_VER_CODE"
    not_magisk="false"
    if echos "$MAGISK_VER" | grep -qi "kitsune"; then
        Aurora_ui_print "您正在使用Kitsune Mask($VERSION)"
        whichroot="Kitsune Mask"
        newest_version="$(sed -n '1p' $MODPATH/bin/newest_version.conf)"
    elif echos "$MAGISK_VER" | grep -qi "alpha"; then
        Aurora_ui_print "您正在使用Magisk Alpha($VERSION)"
        whichroot="Magisk Alpha"
        newest_version="$(sed -n '2p' $MODPATH/bin/newest_version.conf)"
    else
        Aurora_ui_print "您正在使用Magisk($VERSION)"
        whichroot="Magisk"
        newest_version="$(sed -n '3p' $MODPATH/bin/newest_version.conf)"
    fi
elif [[ -n "$APATCH" ]] && [[ -n "$BOOTMODE" ]]; then    
    APATCH_NEXT_VERSIONS="11008 11010 11021"
    VERSION="$APATCH_VER_CODE"
    not_magisk="apatch"
    if echos " $APATCH_NEXT_VERSIONS " | grep -q " $VERSION "; then
        Aurora_ui_print "您正在使用APatch Next($VERSION)"        
        whichroot="APatch Next"
        newest_version="$(sed -n '4p' $MODPATH/bin/newest_version.conf)"    
    else
        Aurora_ui_print "您正在使用APatch($VERSION)"
        newest_version="$(sed -n '5p' $MODPATH/bin/newest_version.conf)"
        NEXT_AP=0
    fi    
    if [[ -d /data/data/me.garfieldhan.apatch.next ]] && [[ $whichroot = "APatch Next" ]]; then
        APP_PATH="/data/data/me.garfieldhan.apatch.next/patch"
    elif [[ -d /data/data/me.bmax.apatch ]] && [[ $whichroot = "APatch" ]]; then
        APP_PATH="/data/data/me.bmax.apatch/patch"
    else
        Aurora_abort "未找到你的APatch，请确认是否安装了APatch管理器"
    fi
elif [[ -n $KSU ]] && [[ -n $BOOTMODE ]]; then
    VERSION="$KSU_VER_CODE"
    not_magisk="ksu"
    if [[ -d /data/data/com.rifsxd.ksunext ]]; then
        Aurora_ui_print "您正在使用KernelSU Next($VERSION)"
        whichroot="KernelSU Next"
        newest_version="$(sed -n '6p' $MODPATH/bin/newest_version.conf)"
    else
        Aurora_ui_print "您正在使用KernelSU($VERSION)"
        whichroot="KernelSU"
        newest_version="$(sed -n '7p' $MODPATH/bin/newest_version.conf)"
    fi
else
    Aurora_abort "此模块不支持你的Root方案！"
fi    

Aurora_ui_print "选择你需要切换的Root方案"
Aurora_ui_print "目前不支持MKSU与Magisk v28.1的转换"
select_magisk "$MODPATH/bin/rootlist.conf"
CheckPartition
if [[ $SELECT_OUTPUT = "$whichroot" ]]; then
    if [[ ! $VERSION = $newest_version ]]; then
        Aurora_abort "你搁这复制自己呢，瞎换"
    else  
        Aurora_ui_print "您正在为您的$whichroot更新"
        Aurora_ui_print "即将更新$whichroot($newest_version)"
        sleep 1
        ddbootpatch
    fi
else
    Aurora_ui_print "您正在把当前的$whichroot换成$SELECT_OUTPUT"
    Aurora_ui_print "此模块即将开始工作……"
    sleep 1
    ddbootpatch         
fi       