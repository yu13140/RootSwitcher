#!/system/bin/sh

# Custom Script
# -----------------
# This script extends the functionality of the default and setup scripts, allowing direct use of their variables and functions.

# When calling functions without specifying $MODPATH, it will be automatically prefixed. Thus, there is no need to manually add it.
# $MODPATH can be replaced with any path, but please ensure the correctness of the path.

# Example: Volume Key Selection for Module Installation
# ---------------------
# Use key_installer "$MODPATH/upper_key_module_path.zip" "$MODPATH/lower_key_module_path.zip" "Upper key module name to be printed" "Lower key module name to be printed" # to select the module to install via volume keys.
# If the module name is not provided, relevant prompts will not be displayed during installation.

# Example: Use volume keys to select whether to install a module
# -----------------
# key_installer_once "$MODPATH/module_path.zip" "Module name to be printed" # Use volume keys to select whether to install the module.
# Example: Getting the Latest Release File Link from a Github Repository
# github_get_url "repository_owner/repository_name" "filename_to_be_included_in_release"
# The output link address is stored in the $DESIRED_DOWNLOAD_URL variable.

# Example: Downloading a Single File
# download_file "file_link"

# Example: Detecting Volume Key Selection
# ------------------
# After calling key_select, you can get the user's selection result through volume keys via the $key_pressed variable.

# Notes
# ------
# Please avoid using the exit functions in this script to prevent unexpected interruption of script execution.