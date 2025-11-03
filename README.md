# Custom Model Override - Magisk Module

A Magisk module that allows you to override your Android device's model name with intelligent auto-detection and interactive installation.

## Features

- 🎯 Override device model name (`ro.product.model` and `ro.product.product.model`)
- 🤖 **Auto-detection** - Detects device codename (e.g., 'taro')
- 📚 **Local database** - Built-in database with popular devices
- 🌐 **Online lookup** - Fetches model name from online sources
- 🎮 **Volume button prompts** - Interactive installation with Vol Up/Down
- � **File fallback** - Use custom name via `model.txt` file
- 🔄 **Easy updates** - Change model anytime via action button
- 🚀 **One reboot only** - Configured during installation

## Installation

1. Download `custom-model.zip`
2. Open Magisk Manager
3. Tap on "Modules" tab
4. Tap "Install from storage"
5. Select the `custom-model.zip` file
6. **Follow the interactive prompts:**
   - Module will detect your device (e.g., 'taro')
   - If found in database, you'll see the name from the local offline db
   - **Vol Up = Yes**, **Vol Down = No**
   - If you decline all options, you can use a custom name
7. Reboot your device - Done!

## Interactive Installation Flow

The installer follows this logic:

1. **Detect device codename** (e.g., 'taro' for Xiaomi 12 Pro)
2. **Check local database** → If found, prompt: "Use this name?"
3. **Try online lookup** → If found, prompt: "Use online name?"
4. **Offer device codename** → Prompt: "Use codename directly?"
5. **Check for model.txt** → If exists, prompt: "Use file content?"
6. **If all declined or no file** → Abort with instructions

### Volume Button Controls

During installation:
- **Vol Up** = Yes / Accept
- **Vol Down** = No / Decline

## Usage

### Changing Model After Installation

**Option 1: Using Action Button**
1. Create/edit `model.txt` in root of main storage
2. Write your desired model name
3. Open Magisk Manager → Modules
4. Tap the action button (⚡) next to Custom Model Override
5. Device will reboot automatically

**Option 2: Reinstall Module**
- Reinstall the ZIP and follow the interactive prompts again

### Custom Model via File

If you want to use a specific model name:

1. Create file `model.txt` in root of main storage
2. Write your desired model name (e.g., `Samsung Galaxy S23 Ultra`)
3. Save the file
4. Install module or tap action button

**Manual Edit (Advanced)**
```bash
su
nano /data/adb/modules/custom-model/system.prop
# Edit the values, then reboot
reboot
```

## Examples of Model Names

Supported in database:
- `taro` → Xiaomi 12 Pro
- `zeus` → Xiaomi 12
- `dm3q` → Samsung Galaxy S22 Ultra
- `cheetah` → Google Pixel 7 Pro
- `alioth` → POCO F3
- `yt9213fj` → Lenovo Legion Y70

Or use any custom name in `model.txt`:
- Samsung Galaxy S23 Ultra
- OnePlus 11 Pro
- iPhone 15 Pro Max (for fun 😄)

## File Structure

```
custom-model/
├── module.prop            # Module metadata
├── system.prop            # System properties override
├── customize.sh           # Installation script
├── action.sh             # Action button script
├── service.sh            # Boot service script
├── common_functions.sh   # Shared functions
├── device_db.txt         # Device database
└── README.md             # This file
```

## Troubleshooting

### Installation Aborts
- If you decline all options, create `model.txt` in root of main storage
- Write your desired model name
- Reinstall the module

### Model Not Changing
- Make sure you rebooted after installation
- Check `/data/adb/modules/custom-model/system.prop` contains your model
- Check logs: `/data/adb/modules/custom-model/service.log`

### Action Button Not Working
- Create/update `model.txt` in root of main storage
- Make sure file contains only the model name (no extra lines)
- Check logs: `/data/adb/modules/custom-model/action.log`

-### Adding Your Device to Database
- Edit `device_db.txt` in module folder
- Add line: `your_codename=Your Local Offline DB Name`
- Reinstall module

## Version History

### v2.0 (Current)
- 🎮 Interactive installation with volume button prompts
- 🤖 Auto-detection of device codename
- 📚 Built-in device database
- 🌐 Online name lookup
- 📝 Smart fallback to file input
- ⚡ One reboot installation

### v1.0
- Basic model override with file input

## Credits

- **Author**: xbzk
- **License**: MIT
- **Repository**: [Your repo URL here]

## Disclaimer

This module modifies system properties. While generally safe, use at your own risk. The author is not responsible for any issues that may arise from using this module.

## Support

If you encounter any issues or have suggestions, please:
- Open an issue on GitHub
- Provide relevant logs
- Describe your device and Android version

---

**Enjoy your custom device model! 🎉**
