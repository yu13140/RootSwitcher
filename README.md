[简体中文](README.md) | [English](README_EN.md)

# 🚀 快速开始

欢迎使用本模块框架！以下是快速开始的步骤：

## 📥 获取框架

- **Fork** 此仓库或直接 **下载** 此仓库。

## ⚙️ 配置设置

1. 编辑 `./settings/Settings.ini` 文件：
   - 写入你的模块名称和模块介绍。
   - 指定模块要求的环境。
   - 选择是否使用自定义脚本。

2. 编辑 `./settings/languages.ini` 文件以实现多语言支持。

## 🛠️ 自定义脚本

- **请勿使用** `custmize.sh` 作为自定义安装脚本。
- 应该选择 `./settings/custom_script.sh` 作为自定义脚本。

## 🖱️ 用户脚本

- `Click.sh` 可供用户在模块外执行模块提供的适用于用户的脚本，可改为 `action.sh`（Magisk内执行有某些限制）。
- `Click.sh` 通过 `busybox` 实现使用 `./settings/script/User.sh`，在 `/data/local/tmp/` 内执行。

## 🏗️ 框架适用性

- 本框架适用于 **Github Action** 打包模块。
- 本框架默认去除 `META-INF`，如有需要请自行添加。

---

欢迎PR，如果觉得好用可以Star哦，感谢使用本框架！🚀

（闲的没事从AuroraNasa_Installer里面提取修改弄出来的玩意，不喜勿喷）