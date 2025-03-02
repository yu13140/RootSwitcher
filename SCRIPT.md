[简体中文](SCRIPT.md) | [English](SCRIPT_EN.md)
# 关于自定义脚本以及用户脚本提供的函数说明


- **select_on_magisk [input Path]**
  - 调用此函数`select_on_magisk`，传递路径变量，例如`/your/path.txt`。
  - 用户在列表中选择一项，所选内容将返回在`$SELECT_OUTPUT`变量中。
  - 使用音量键进行字母选择。
  - 可在Mgaisk模块安装脚本或用户脚本（谨慎使用）中调用。
  - 不支持特殊字符及中文（兼容支持`/][{};:><?!()_-+=.`）。


- **number_select [input Path]**
  - 调用此函数`number_select`，传递路径变量，例如`/your/path.txt`。
  - 用户在列表中选择一个选项，所选数字将返回在`$SELECT_OUTPUT`变量中。
  - 只支持在用户脚本中使用。


- **download_file [input URL]**
  - 调用此函数`download_file`，传递一个URL变量。
  - 下载URL指定的文件至`settings.sh`中设置的`$download_destination`目录。
  - 可在Mgaisk模块安装脚本或用户脚本中使用。


- **key_select**
  - 调用此函数`key_select`。
  - 等待用户按下音量键（上/下），所选按键将返回在`$key_pressed`变量中，值为`KEY_VOLUMEUP`或`KEY_VOLUMEDOWN`。
  - 可在Mgaisk模块安装脚本或用户脚本（谨慎使用）中调用。