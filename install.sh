##########################################################################################
#
# Magisk Module Installer Script - Custom Model Override
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

BUILD_TAG="CSVDBG-$(date +%Y-%m-%d-%H%M%S)"

##########################################################################################
# Replace list
##########################################################################################

REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm $MODPATH/action.sh 0 0 0755
  set_perm $MODPATH/service.sh 0 0 0755
  set_perm $MODPATH/common_functions.sh 0 0 0755
}

##########################################################################################
# Installation
##########################################################################################

print_modname() {
  ui_print " "
}

on_install() {
  ui_print "- Build tag: $BUILD_TAG"
  ui_print "- Loading functions..."
  
  # Extract common functions to temp dir
  unzip -o "$ZIPFILE" 'common_functions.sh' -d $TMPDIR >&2
  unzip -o "$ZIPFILE" 'device_db.txt' -d $TMPDIR >&2
  chmod 0755 $TMPDIR/common_functions.sh
  
  # Load common functions
  if [ -f "$TMPDIR/common_functions.sh" ]; then
    . $TMPDIR/common_functions.sh
    ui_print "- Functions loaded successfully"
  else
    abort "Failed to load common functions"
  fi
  
  # Extract all module files
  ui_print "- Extracting module files..."
  unzip -o "$ZIPFILE" -d $MODPATH >&2
  
  # Run shared model configuration workflow
  run_model_configuration "$MODPATH"
  
  if [ $? -ne 0 ]; then
    abort "Installation cancelled - device not recognized"
  fi
}

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non-public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#    print <msg> to console
#    Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#    print error message <msg> to console and terminate installation
#    Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#    if [context] is empty, it will default to "u:object_r:system_file:s0"
#    this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#    if [context] is empty, it will default to "u:object_r:system_file:s0"
#    for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#    for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
