[简体中文](SCRIPT.md) | [English](SCRIPT_EN.md)
# Function Descriptions for Custom Scripts and User Scripts


- **select_on_magisk [input Path]**
  - Call this function `select_on_magisk` and pass a path variable, for example `/your/path.txt`.
  - The user selects an item from the list, and the selected content is returned in the `$SELECT_OUTPUT` variable.
  - Use the volume keys to navigate and select by letter.
  - Can be invoked in Mgaisk module installation scripts or user scripts (use with caution).
  - Does not support special characters or Chinese (compatible with `/][{};:><?!()_-+=.`).


- **number_select [input Path]**
  - Call this function `number_select` and pass a path variable, for example `/your/path.txt`.
  - The user selects an option from the list, and the selected number is returned in the `$SELECT_OUTPUT` variable.
  - Only supported for use in user scripts.
  - Does not support special characters or Chinese (compatible with `/][{};:><?!()_-+=.`).


- **download_file [input URL]**
  - Call this function `download_file` and pass a URL variable.
  - Downloads the file specified by the URL to the directory set by the `$download_destination` variable in `settings.sh`.
  - Can be used in Mgaisk module installation scripts or user scripts.


- **key_select**
  - Call this function `key_select`.
  - Waits for the user to press a volume key (up/down), and the selected key is returned in the `$key_pressed` variable with a value of `KEY_VOLUMEUP` or `KEY_VOLUMEDOWN`.
  - Can be invoked in Mgaisk module installation scripts or user scripts (use with caution).