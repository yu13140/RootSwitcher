<div align="center"> 
  
# RootSwitcher
A module that makes it easier to convert the Root schema
 Support mutual conversion of Magisk and its branches, APatch, LKM modes of KSU and its Next.
(Experimental feature) Common kernel GKI mode for KernelSU v1.0.3
(Future goal: support GKI mode conversion of lower version KSU and its Next)

[项目模板](https://github.com/Aurora-Nasa-1/AMMF)  [原版readme](https://github.com/yu13140/RootSwitcher/Document/README.md) 
  
 <img src="https://img.shields.io/github/license/Aurora-Nasa-1/AMMF" alt="GitHub License">  
  
</div> 
  
## ✍🏼 介绍

一个更方便地转化Root方案的模块 
支持Magisk及其分支，APatch，KSU及其Next的LKM模式互相转化
(实验性功能)转换为KernelSUv1.0.3的通用内核GKI模式
(未来目标：支持低版本KSU及其Next的GKI模式转换)

## ❗ 注意

1.不支持非骁龙处理器的设备
   - 高通处理器实现Root更繁琐，我们建议您从线刷或卡刷开始Root实现

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
   - 如果当前设备支持A/B分区，在开始转换Root方案之前，请选择修补的boot.img应该刷入A分区还是B分区 (音量键上：A分区；音量键下：B分区)
   - 模块运行过程中，您需要选择转换成哪个Root方案，或是升级当前设备上的Root管理器
   - 对于想要转换为APatch的用户，我们把超级密钥设置成了a1234567，刷入后可以在APatch管理器中更改超级密钥

3.enjoy ^_^♪

## 🙏 感谢

项目原模板 @Aurora-Nasa-1 [AMMF](https://github.com/Aurora-Nasa-1/AMMF)
内测人员 酷安@阿凯乀 @龙在天Zz

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