[简体中文](README.md) | [English](README_EN.md)

<div style="display: flex; justify-content: space-between;">
    <img src="https://img.shields.io/github/commit-activity/w/Aurora-Nasa-1/AMMF" alt="GitHub Commit" style="margin-right: 10px;">
    <img src="https://img.shields.io/github/license/Aurora-Nasa-1/AMMF" alt="GitHub License">
</div>

# 🚀 Quick Start

Welcome to use this module framework! Here are the steps to get started:

## 📥 Get the Framework

- **Fork** this repository or **download** this repository directly.

## ⚙️ Configuration Settings

1. Edit the `./settings/Settings.sh` file:
   - Write your module name and module description.
   - Specify the environment required by the module.

2. Edit the `./settings/languages.ini` file to enable multi-language support.

## 🛠️ Custom Scripts

- **Do not use** `custmize.sh` as the custom installation script.
- You should choose `./settings/custom_script.sh` as the custom script.
- This framework provides some functions, please read the [instructions](SCRIPT_EN.md).

## 🖱️ User Scripts

- `Click.sh` can be used by users to execute scripts provided by the module outside the module, and can be renamed to `action.sh` (with some limitations when executed within Magisk).
- `Click.sh` uses `busybox` to execute `./settings/script/User.sh` in `/data/local/tmp/`.
- This framework provides some functions, please read the [instructions](SCRIPT_EN.md).

## 🏗️ Framework Applicability

- This framework is suitable for **GitHub Action** to package modules.
- This framework removes `META-INF` by default, please add it yourself if needed.

---

PRs are welcome. If you find it useful, please give it a star. Thank you for using this framework! 🚀

(Extracted and modified from AuroraNasa_Installer, please don't criticize if you don't like it)