# Custom Model Override - Magisk Module

A Magisk module that allows you to override your Android device's model name with intelligent auto-detection and interactive installation.

## Features

- 🎯 Override device model name (`ro.product.model` and `ro.product.product.model`)
- 🤖 Auto-detection — Detects device codename (e.g., 'halo')
- 📚 Local offline database — Built-in names for popular devices
- 🌐 Online lookup — Fetches model name from online sources
- 🎮 Volume button prompts — Interactive install with Vol Up/Down
- 🔄 Easy updates — Change model anytime via action button
- 🚀 One reboot only — Configured during installation

## Installation

1. Download `custom-model.zip`
2. Open Magisk Manager
3. Modules → Install from storage
4. Select `custom-model.zip`
5. Follow the prompts:
   - Module detects your codename (e.g., 'halo')
   - If found in the local offline db, you’ll be offered that name
   - Vol Up = Yes, Vol Down = No
6. Reboot when finished

## Interactive flow

1. Detect device codename
2. Check local offline db → ask to use
3. Try online lookup → ask to use
4. Offer codename directly → ask to use
5. If all declined → abort with instructions

### Volume buttons
- Vol Up = Yes / Accept
- Vol Down = No / Decline

## Usage

### Change model after install
Option A: Action button
1. Magisk → Modules
2. Tap the action button (⚡) next to this module
3. Pick an option; device reboots automatically

Option B: Reinstall the ZIP and follow prompts

### Custom model via local offline db
1. Note your device codename (shown during install)
2. Edit `/data/adb/modules/custom-model/device_db.txt`
3. Add or edit a line: `halo=Lenovo Legion Y70`
4. Save, then reinstall or press the action button

Advanced manual edit
```bash
su
nano /data/adb/modules/custom-model/system.prop
# Edit values, then reboot
reboot
```

## Examples

Built-in examples:
- `taro` → Xiaomi 12 Pro
- `zeus` → Xiaomi 12
- `dm3q` → Samsung Galaxy S22 Ultra
- `cheetah` → Google Pixel 7 Pro
- `alioth` → POCO F3
- `halo` → Lenovo Legion Y70

Or add your own in `device_db.txt`:
- Samsung Galaxy S23 Ultra
- OnePlus 11 Pro
- iPhone 15 Pro Max (for fun 😄)

## File structure

```
custom-model/
├── module.prop            # Module metadata
├── system.prop            # System properties override
├── install.sh             # Installation script
├── action.sh              # Action button script
├── service.sh             # Boot service script
├── common_functions.sh    # Shared functions
├── device_db.txt          # Device database
└── README.md              # This file
```

## Troubleshooting

Model not changing:
- Reboot after installation
- Check `/data/adb/modules/custom-model/system.prop` has your model
- If needed, edit `device_db.txt` and reinstall or use the action button

## Version history

v2.0 (Current)
- Interactive volume-button installer
- Auto-detection of device codename
- Local offline database
- Online lookup
- One reboot workflow

v1.0
- Basic model override with file input

## Credits

- Author: xbzk
- License: MIT
- Repository: [magisk-custom-model-module](https://github.com/allisonbzk/magisk-custom-model-module)

## Disclaimer

This module modifies system properties. Use at your own risk.

## Support

If you encounter issues or have suggestions:
- Open an issue on GitHub
- Include relevant logs/details (device, Android version)

— Enjoy your custom device model! 🎉
