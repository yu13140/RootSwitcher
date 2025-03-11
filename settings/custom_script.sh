#!/system/bin/sh

# Custom Script
# -----------------
# This script extends the functionality of the default and setup scripts, allowing direct use of their variables and functions.
ASH_STANDALONE=1
MODDIR=${0%/*}

. "$MODPATH/settings/settings.sh"
. "$MODPATH/$script_path"

KERNEL_VER="$(uname -r | cut -d "." -f1,2)"

if [[ -f $MODPATH/boot.img || -f $MODPATH/new-boot.img || -f $MODPATH/kernel ]]; then
    Aurora_abort "请清理上一次刷入此模块的残余文件，保持一个干净的模块环境"
fi

searchmy() {
if [[ -d /data/RootSwitcher ]]; then
    myboot="$(find /data/RootSwitcher/ -name ".img" | head -n 1)"
    if [ $? -ne 0 ]; then
        Aurora_ui_print "不存在RootSwitcher备份的img镜像！"
        return
    else        
        for name in boot init_boot; do
            local existboot=0
            [ -f /data/RootSwitcher/${name}.img.gz ] && existboot=1
        done
        if [[ $existboot = 0 ]]; then
            Aurora_ui_print "不存在符合要求的img镜像"
            return
        fi
    fi
    readonly bootkind="$(basename $myboot .img)"
    mv $myboot new-boot.img
fi
}

ddcleanup() {
cleanround() {
    if [[ $not_magisk = "ksu" ]]; then
        echo "rm -rf /data/adb/ksu /data/adb/ksud" > /data/adb/service.d/RootSwitcher.sh
    elif [[ $not_magisk = "apatch" ]]; then
        echo "rm -rf /data/adb/ap/ /data/adb/apd" > /data/adb/service.d/RootSwitcher.sh
    elif [[ $not_magisk = "false" ]]; then
        echo "rm -rf /data/adb/magisk/ /data/adb/magisk.db" > /data/adb/service.d/RootSwitcher.sh
    fi
}
if [[ $? -eq 0 ]]; then
    if [[ $SELECT_OUTPUT = "APatch"* ]]; then
        echo "if [ -n "$APATCH" ];then" > /data/adb/service.d/RootSwitcher.sh
        cleanround
        echo "fi" > /data/adb/service.d/RootSwitcher.sh
    elif [[ $SELECT_OUTPUT = "KernelSU"* ]]; then
        echo "if [ -n "$KSU" ];then" > /data/adb/service.d/RootSwitcher.sh
        cleanround
        echo "fi"  > /data/adb/service.d/RootSwitcher.sh
    else
        echo "if [ -z "$APATCH" ]&&[ -z "$KSU" ]&&[ -n "$MAGISK_VER_CODE" ];then" > /data/adb/service.d/RootSwitcher.sh
        cleanround
        echo "fi" > /data/adb/service.d/RootSwitcher.sh
    fi
else
    Aurora_abort "刷入失败！"   
fi
}

ddbootinit() {
./bin/magiskboot unpack $1
if [ -f kernel ]; then
    bootkind="boot"
else
    bootkind="init_boot"
fi
./bin/magiskboot cleanup
}

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
if [[ -f /system/build.prop ]]; then
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
    ls $SITE | grep init_boot >/dev/null 2>&1 
    if [[ $? -ne 0 ]]; then
        magiskneedboot="boot"
    else
        magiskneedboot="initboot"
    fi
else
    SITE="/dev/block/by-name"
    ls $SITE | grep init_boot >/dev/null 2>&1 
    if [[ $? -ne 0 ]]; then
        magiskneedboot="boot"
    else
        magiskneedboot="initboot"
    fi 
fi

foundboot() {
FBOOT="$MODPATH/boot.img"
cd $MODPATH
chmod 755 ./bin/magiskboot
chmod 755 ./bin/APatch/kptools

if [[ $not_magisk = "false" ]]; then
    backup_boot="$(ls /data | grep magisk_backup | head -n 1)"
    if [[ $backup_boot = "" ]]; then
        Aurora_ui_print "未找到Magisk备份的原Boot.img，正在使用方案二"
        if [[ $magiskneedboot = "init_boot" ]]; then
            dd if="$position" of="$MODPATH/backup_initboot.img" bs=4M         
            ./magiskboot unpack $MODPATH/backup_initboot.img
            ./magiskboot cpio ramdisk.cpio "exists /.backup/.magisk"
            case $? in
            0 )
            ./magiskboot cpio ramdisk.cpio restore ;;                           
            esac
            ./magiskboot repack backup_initboot.img boot.img # init_boot
            ./magiskboot cleanup
        else
            Aurora_abort "设备不支持方案二"
        fi               
    elif [[ -d /data/$backup_boot ]]; then               
        gzip -dk /data/$backup_boot/${magiskneedboot}.img.gz
        if [ $? -ne 0 ]; then
            Aurora_abort "未备份原${magiskneedboot}.img，取消安装操作"
        fi
        mv /data/$backup_boot/${magiskneedboot}.img $MODPATH/
        bootinit  
        mkdir -p /data/RootSwitcher/
        cp /data/$backup_boot/${bootkind}.img.gz /data/RootSwitcher/  
        Aurora_ui_print "已经把原${bootkind}备份到/data/RootSwitcher/"          
    fi
else
    if [[ $not_magisk = "apatch" ]]; then
        APatchboot
    elif [[ $not_magisk = "ksu" ]]; then
        backup_boot="$(ls -lt /data/adb/ksu/ | grep ksu_backup | head -n 1 | awk '{print $8}')"        
        if [[ $backup_boot = "" ]]; then
            Aurora_ui_print "未找到KSU备份的${magiskneedboot}.img，启用方案二"
            if [[ $magiskneedboot = "init_boot" ]]; then
                dd if="$position" of="$MODPATH/backup_initboot.img" bs=4M
                ./magiskboot unpack $MODPATH/backup_initboot.img
                ./magiskboot cpio ramdisk.cpio "exists kernelsu.ko"
                case $? in
                0 )
                ./magiskboot cpio ramdisk.cpio "extract init.real init"
                ./magiskboot cpio ramdisk.cpio "rm init"
                ./magiskboot cpio ramdisk.cpio "rm init.real"
                ./magiskboot cpio ramdisk.cpio "rm kernelsu.ko"
                ./magiskboot cpio ramdisk.cpio "add 755 init init"           
                ;;      
                esac
                ./magiskboot repack backup_initboot.img boot.img # init_boot
                ./magiskboot cleanup
            else
                Aurora_abort "设备不支持方案二"
            fi       
        else
            cp /data/adb/ksu/$backup_boot $MODPATH/            
            mv $MODPATH/$backup_boot boot.img
            ddbootinit boot.img
            zip -9k boot.img
            mkdir -p /data/RootSwitcher/
            mv boot.img.gz /data/RootSwitcher/
            if [ $? -ne 0 ]; then
                Aurora_abort "未备份原Boot.img，取消安装操作"
            fi            
            Aurora_ui_print "已经把原Boot备份到/data/RootSwitcher/"
        fi                                 
    fi    
fi
}

CheckPartition() {
BOOTAB="$(getprop ro.build.ab_update)"
Partition_location="$(getprop ro.boot.slot_suffix)"
if [[ "$BOOTAB" = "true" ]]; then
    Aurora_ui_print "检测到设备支持A/B分区"    
        if [[ "$Partition_location" == "_a" ]]; then
            Aurora_ui_print "你目前处于 A 分区"
            position=$(ls -l $SITE/${magiskneedboot}_a | awk '{print $NF}')
        elif [[ "$Partition_location" == "_b" ]]; then
            Aurora_ui_print "你目前处于 B 分区"
            position=$(ls -l $SITE/${magiskneedboot}_b | awk '{print $NF}')
        elif [[ "$Partition_location" == "" ]]; then 
            Aurora_ui_print "未检测到设备目前处于哪个槽位，请选择你需要刷入的槽位"
            Aurora_ui_print "音量上：刷入a槽                       音量下：刷入b槽$RE"
            echo "a" > $MODPATH/ab.txt ; echo "b" >> $MODPATH/ab.txt
            select_magisk "$MODPATH/ab.txt"
            case $SELECT_OUTPUT in 
            a) 
            position=$(ls -l $SITE/${magiskneedboot}_a | awk '{print $NF}') ;;
            b) 
            position=$(ls -l $SITE/${magiskneedboot}_b | awk '{print $NF}') ;;
            *)
            Aurora_ui_print "$YE输入错误，默认安装到a槽"; position=$(ls -l $SITE/${magiskneedboot}_a | awk '{print $NF}') ;;
            esac
        fi
else
    position=$(ls -l $SITE/${magiskneedboot} | awk '{print $NF}')
fi    
}

ddbootpatch() {
    if [[ $SELECT_OUTPUT = "APatch" ]]; then        
        if [[ `echo "6.1 < $KERNEL_VER" | bc` -eq 1 ]] || [[ `echo "$KERNEL_VER < 3.1" | bc` -eq 1 ]] ; then
            Aurora_abort "你的内核版本不适合APatch，刷入可能会卡一屏"
        fi
        if [[ ! -d /data/data/me.bmax.apatch ]]; then
            Aurora_abort "在转换之前，请先安装APatch管理器！"
        fi        
        PATCH_PATH="$MODPATH/bin/APatch/"
        foundboot
        if [[ "$bootkind" != "boot" ]]; then
            mv -f boot.img init_boot.img                 
            dd if=init_boot.img of="$position" bs=4M
            dd if=boot"$Partition_location" of="$MODPATH/new-boot.img" bs=4M     
        fi
        chmod -R 755 $PATCH_PATH
        Aurora_ui_print "默认您的超级密钥为a1234567，请记住了"
        $PATCH_PATH/kptools -p --image kernel-b --skey "a1234567" --kpimg $PATCH_PATH/kpimg --out kernel      
        ./bin/magiskboot repack boot.img        
        mv -f new-boot.img boot.img
        ./bin/magiskboot cleanup
        dd if=boot.img of="$position" bs=4M            
        ddcleanup       
    elif [[ $SELECT_OUTPUT = "APatchNext" ]]; then
        if [[ `echo "6.1 < $KERNEL_VER" | bc` -eq 1 ]] || [[ `echo "$KERNEL_VER < 3.1" | bc` -eq 1 ]] ; then
            Aurora_abort "你的内核版本不适合APatch Next，刷入可能会卡一屏"
        fi
        if [[ ! -d /data/data/me.garfieldhan.apatch.next ]]; then
            Aurora_abort "在转换之前，请先安装APatch Next管理器！"
        fi        
        PATCH_PATH="$MODPATH/bin/APatchNext/"
        foundboot
        if [[ "$bootkind" != "boot" ]]; then
            mv -f boot.img init_boot.img                 
            dd if=init_boot.img of="$position" bs=4M
            dd if=boot"$Partition_location" of="$MODPATH/new-boot.img" bs=4M
        fi
        chmod -R 755 $PATCH_PATH
        Aurora_ui_print "默认您的超级密钥为a1234567，请记住了"
        $PATCH_PATH/kptools -p --image kernel-b --skey "a1234567" --kpimg $PATCH_PATH/kpimg --out kernel        
        ./bin/magiskboot repack boot.img        
        mv -f new-boot.img boot.img
        ./bin/magiskboot cleanup
        dd if=boot.img of="$position" bs=4M        
        ddcleanup        
    elif [[ $SELECT_OUTPUT = "KernelSU" ]]; then
        if [[ `echo "5.1 > $KERNEL_VER" | bc` -eq 1 ]]; then
            Aurora_abort "你的内核版本不太适合KSU呢，或许你需要自己编译"
        fi
        if [[ ! -d /data/data/me.weishu.kernelsu ]]; then
            Aurora_abort "在转换之前，请先安装KSU管理器！"
        fi        
        PATCH_PATH="$MODPATH/bin/KSU/"
        foundboot
        
        android_version=$(getprop ro.build.version.release | cut -d. -f1)
        mm_kernel_version=$(uname -r | cut -d- -f1)
        match_string="android${android_version}-${mm_kernel_version}"
        line_number=$(grep -nx "$match_string" kernel.conf | cut -d: -f1)
        if [ -n "$line_number" ]; then
            if [[ "$bootkind" != "boot" ]]; then
                mv -f boot.img init_boot.img                 
                dd if=init_boot.img of="$position" bs=4M
                dd if=boot"$Partition_location" of="$MODPATH/new-boot.img" bs=4M
            fi
            giturl=$(sed -n "${line_number}p" $MODPATH/bin/kernelurl.conf)
            download_file "https://github.proxy.class3.fun/$giturl"
            cd $MODPATH
            unzip -o "./AnyKernel3.zip"
            ./bin/magiskboot unpack new-boot.img
            mv -f Image kernel
            ./bin/magiskboot repack new-boot.img    
        else
            if [[ "$bootkind" != "init_boot" ]]; then
                Aurora_abort "设备上备份的boot好像不是init_boot.img呢！"
            fi
            chmod -R 755 $PATCH_PATH
            $PATCH_PATH/ksud boot-patch -b boot.img --magiskboot $MODPATH/bin/magiskboot
        fi            
            mv -f new-boot.img boot.img        
            sleep 2
            ./bin/magiskboot cleanup
            dd if=boot.img of="$position" bs=4M
            ddcleanup     
    elif [[ $SELECT_OUTPUT = "KernelSUNext" ]]; then
        if [[ `echo "5.1 > $KERNEL_VER" | bc` -eq 1 ]]; then
            Aurora_abort "你的内核版本不太适合KSU NEXT呢，或许你需要自己编译"
        fi
        if [[ ! -d /data/data/com.rifsxd.ksunext ]]; then
            Aurora_abort "在转换之前，请先安装KSU NEXT管理器！"
        fi        
        PATCH_PATH="$MODPATH/bin/KSUNEXT/"
        foundboot
        if [[ "$bootkind" != "init_boot" ]]; then
            Aurora_abort "设备上备份的boot好像不是init_boot.img呢！"
        fi
        chmod -R 755 $PATCH_PATH
        $PATCH_PATH/ksud boot-patch -b boot.img --magiskboot $MODPATH/bin/magiskboot       
        mv -f new-boot.img boot.img
        sleep 2
        ./bin/magiskboot cleanup
        dd if=boot.img of="$position" bs=4M
        ddcleanup    
    elif [[ $SELECT_OUTPUT = "MagiskAlpha" ]]; then
        if [[ ! -d /data/data/io.github.vvb2060.magisk ]]; then
            Aurora_abort "在转换之前，请先安装Magisk Alpha管理器！"
        fi    
        PATCH_PATH="$MODPATH/bin/Magisk/Alpha/boot_patch.sh"
        foundboot
        ddbootinit boot.img                  
        if [[ "$bootkind" != "$magiskneedboot" ]]; then
            Aurora_abort "设备上备份的boot好像不是Magisk想要的呢！"
        fi
        chmod -R 755 $PATCH_PATH
        $PATCH_PATH "$FBOOT"
        sleep 2             
        mv -f "./bin/Magisk/Alpha/new-boot.img" ./boot.img
        ./bin/magiskboot cleanup
        dd if=boot.img of="$position" bs=4M
        ddcleanup
    elif [[ $SELECT_OUTPUT = "KitsuneMask" ]]; then
        if [[ ! -d /data/data/io.github.huskydg.magisk ]]; then
            Aurora_abort "在转换之前，请先安装Kitsune Mask管理器！"
        fi    
        PATCH_PATH="$MODPATH/bin/Magisk/Delta/boot_patch.sh"
        foundboot
        ddbootinit boot.img
        if [[ "$bootkind" != "$magiskneedboot" ]]; then
            Aurora_abort "设备上备份的boot好像不是Magisk想要的呢！"
        fi        
        chmod -R 755 $PATCH_PATH
        $PATCH_PATH "$FBOOT"
        sleep 2      
        mv -f ./bin/Magisk/Delta/new-boot.img boot.img
        ./bin/magiskboot cleanup
        dd if=boot.img of="$position" bs=4M
        ddcleanup
    else
        Aurora_abort "你未选择任意管理器！"  
    fi
}

APatchboot() {
if [ ! -f $APP_PATH/new-boot.img ]; then
    Aurora_ui_print "未找到APatch修补后的boot.img，启用方案二"
    dd if="boot$Partition_location" of="$MODPATH/new-boot.img" bs=4M      
else
    cp $APP_PATH/new-boot.img ./
fi 
./bin/magiskboot unpack new-boot.img
if [ ! $(./bin/APatch/kptools -i kernel -l | grep patched=false) ]; then
    ./bin/APatch/kptools -u --image kernel --out rekernel
    mv -f rekernel kernel
    ./bin/magiskboot repack new-boot.img boot.img
    bootkind="boot"    
    gzip -9k boot.img
    mkdir -p /data/RootSwitcher/
    chmod 660 boot.img.gz
    mv boot.img.gz /data/RootSwitcher/
    if [ $? -ne 0 ]; then
        Aurora_abort "未找到Magisk备份的原Boot.img，取消安装操作"
    fi    
    Aurora_ui_print "已经把原Boot备份到/data/RootSwitcher/"
else
    mv new-boot.img boot.img
    bootkind="boot"
    zip -9k boot.img
    mkdir -p /data/RootSwitcher/
    mv boot.img.gz /data/RootSwitcher/
    if [ $? -ne 0 ]; then
        Aurora_abort "未找到Magisk备份的原Boot.img，取消安装操作"
    fi    
    Aurora_ui_print "已经把原Boot备份到/data/RootSwitcher/"
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
    if echo " $APATCH_NEXT_VERSIONS " | grep -q " $VERSION "; then
        Aurora_ui_print "您正在使用APatch Next($VERSION)"        
        whichroot="APatch Next"
        newest_version="$(sed -n '4p' $MODPATH/bin/newest_version.conf)"    
    else
        whichroot="APatch"
        Aurora_ui_print "您正在使用APatch($VERSION)"
        newest_version="$(sed -n '5p' $MODPATH/bin/newest_version.conf)"        
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
SELECT_OUTPUT="$(cat $MODPATH/select.txt)"
CheckPartition
if [[ "$SELECT_OUTPUT" = "$whichroot" ]]; then
    if [[ ! $VERSION = $newest_version ]]; then
        Aurora_abort "你搁这复制自己呢，瞎换"
    else  
        Aurora_ui_print "您正在为您的$whichroot更新"
        Aurora_ui_print "即将更新$whichroot($newest_version)"
        sleep 1
        ddbootpatch
    fi
else
    Aurora_ui_print "您正在把当前的"$whichroot"换成"$SELECT_OUTPUT""
    Aurora_ui_print "此模块即将开始工作……"
    sleep 1
    ddbootpatch         
fi       