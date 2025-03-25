<div align="center"> 
  
# RootSwitcher
* A module that makes it easier to convert the Root schema
* Support mutual conversion of Magisk and its branches, APatch, LKM modes of KSU and its Next.
* (Experimental feature) GKI mode for KernelSU v1.0.3
* (Experimental feature) GKI mode for KernelSU Next v1.0.5

[项目模板](https://github.com/Aurora-Nasa-1/AMMF)  [原版readme](https://github.com/yu13140/RootSwitcher/Document/README.md) 
  
 <img src="https://img.shields.io/github/license/Aurora-Nasa-1/AMMF" alt="GitHub License">  
  
</div> 

## ⭐ 如果你喜欢他，不妨给它一个Star
  
## ✍🏼 介绍

* 一个更方便地转化Root方案的模块 
* 支持Magisk及其分支，APatch，KSU及其Next的LKM模式互相转化
* (实验性功能)转换为KernelSU v1.0.3的GKI模式
* (实验性功能)转化为KernelSU Next v1.0.5的GKI模式

## ❗ 注意

1.不支持非高通处理器的设备
   - 高通处理器实现Root更繁琐，我们建议您从线刷或卡刷开始Root实现
   - 如果您是非高通处理器，但是想试试此模块，请注释/settings/custom_script.sh里的ddQualcomm函数(我们将不为刷入此模块的后果负任何责任)

2.KernelSU用户(与其Next)请谨慎使用此模块
   - 当前，我们对KernelSU仍有很多疑惑
   - 如果你正在使用KernelSU，我们或许需要你的帮助
   
3.最好具备一定的救砖能力
   - 在转换Root方案过程中，或许会出现一些奇奇怪怪的问题
   - 如果您能在此项目的issue反馈，我们会很感谢您
   
4.我们只支持拥有分区路径的设备
   - 查看/dev/block/bootdevice/by-name以确认设备是否达到要求
   - 或查看/dev/block/by-name以确认设备是否达到要求
   
## ✨ 开始

1.从本项目的Release里下载RootSwitcher.zip

2.在当前的Root管理器中刷入此模块
   - 在多数情况下，模块不需要用户提供原boot或init_boot镜像
   - 模块运行过程中，您需要选择转换成哪个Root方案，或是升级当前设备上的Root管理器
   - 对于想要转换为APatch的用户，我们把超级密钥设置成了a1234567，刷入后可以在APatch管理器中更改超级密钥
   - 模块支持自定义需要修补的boot或init_boot(把img镜像放入/data/RootSwitcher/文件夹📁)
   - 模块会备份原boot或init_boot到/data/RootSwitcher/文件夹📁
   
3.enjoy ^_^♪

## 🙏 感谢

项目原模板 @Aurora-Nasa-1 [AMMF](https://github.com/Aurora-Nasa-1/AMMF)
内测人员 酷安@阿凯乀 @龙在天Zz @LEARN_TO_WIN
[内测Q群](http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=jcmlm2-0dPiNCDOE2zTq1IkX8I5Adamq&authKey=eRFygh1DmVDuyx48n66Cv8kgvKL72U67ukVvTKvg05%2FYyZ91H5GyPcuuKtQs2JH8&noverify=0&group_code=492255877)：492255877

感谢以下项目
* **Magisk:** 
https://github.com/topjohnwu/Magisk
* **Magisk Alpha:** 
https://t.me/magiskalpha  
* **Kitsune Mask (Magisk Delta):**  
https://github.com/KitsuneMagisk/Magisk  
https://github.com/HuskyDG/magisk-files  
* **APatch:** 
https://github.com/bmax121/APatch  
* **APatch Next:**  
https://t.me/app_process64  
* **KernelSU:**
https://github.com/tiann/KernelSU  