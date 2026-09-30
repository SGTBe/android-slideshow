# Android Slideshow App - Delphi FireMonkey

A professional-grade, cross-platform slideshow application built with **Delphi RAD Studio Enterprise** for **Android** and **Windows 64-bit**.

## 🎬 Features

### Core Functionality
- **Dual-Platform Support**: Seamless experience on Android and Windows 64-bit
- **Smart Image Loading**: Asynchronous background thread prevents UI freeze
- **Supported Formats**: `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.webp`

### Folder Selection
- **Android**: Integrated Storage Access Framework (SAF) for secure, modern folder browsing
- **Windows**: Native Windows folder dialog with full path access

### Slideshow Controls
- **Adjustable Timing**: 1-20 seconds per image with real-time display
- **Play/Pause**: Control slideshow with emoji-enhanced buttons
- **Progress Indicator**: Visual progress bar showing current image position

### Transition Effects (Smooth & Polished)
- **Fade**: Smooth opacity transitions (250ms)
- **Slide**: Image slides from left with repositioning (350ms)
- **Zoom**: Elegant zoom in/out effect (300ms)
- **Scale**: Subtle grow/shrink animation (400ms)
- **None**: Instant image swap for fast viewing

### UI/UX Enhancements
- **Real-time Status**: Shows loading progress, image count, folder name
- **Gesture Support**: Long-press on image to pause (Android)
- **Shadow Effects**: Professional drop shadow on images
- **Color-Coded Labels**: Yellow for image info, Silver for metadata
- **Responsive Design**: Adapts to portrait/landscape orientation

## 🛠️ Requirements

### Development
- **Delphi RAD Studio Enterprise 11+** (Community edition won't work - requires Android support)
- **Windows 10/11 64-bit** for compilation
- **Android SDK** (API Level 23+)
- **JDK 8 or later**
- **File → New → Multi-Device Application** project template

### Runtime
- **Android 6.0+** (API Level 23+)
- **Windows 10/11 64-bit**

## 📁 Project Structure

```
Delphi/
├── SlideshowApp.dpr           # Main project file
├── Unit1.pas                  # Complete application logic
├── Unit1.fmx                  # FireMonkey form design (must match Unit1.pas)
├── SlideshowApp.cfg           # Compiler configuration
├── AndroidManifest.template.xml  # Android permissions & metadata
├── .gitignore                 # Ignore build artifacts
└── README.md                  # This file
```

## 🚀 Getting Started

### Windows 64-bit Build

1. **Open Project**
   - Launch Delphi RAD Studio Enterprise
   - Open `Delphi/SlideshowApp.dpr`

2. **Configure Project**
   - Right-click project → **Project Options**
   - Select **Platforms** → Ensure **Win64** is active
   - Verify compiler settings

3. **Build & Run**
   - Press **F9** or **Run → Run**
   - Click **📂 Open Folder** to select a folder
   - Click **▶ Play** to start slideshow
   - Adjust **Display Time** and **Transition** in real-time

### Android Build

1. **Configure SDK/NDK**
   - **Tools → Options → Deployment → SDK Manager**
   - Ensure Android SDK (API 23+) and JDK 8+ are configured

2. **Connect Device**
   - Connect Android 6.0+ device via USB with **Developer Mode** enabled
   - OR start Android emulator

3. **Build & Deploy**
   - Right-click project → **Project Manager**
   - Select **Android** platform
   - Press **F9** to compile and deploy
   - App launches automatically as **"Slideshow Viewer"**

4. **First Launch**
   - Tap **📂 Open Folder** to access Storage Access Framework
   - Navigate to folder with images
   - Tap ✓ to confirm
   - Tap **▶ Play** to begin slideshow

## 🎨 UI Controls Reference

| Control | Type | Effect |
|---------|------|--------|
| **📂 Open Folder** | Button | Opens platform-specific folder picker |
| **▶ Play / ⏸ Pause** | Button | Toggles slideshow playback |
| **Display Time Slider** | TrackBar | Sets image duration (1-20 seconds) |
| **Transition Dropdown** | ComboBox | Selects animation effect |
| **Image Area** | TImage | Displays current image with shadow |
| **Status Label** | Label | Shows real-time status messages |
| **Progress Bar** | ProgressBar | Visual indicator of slideshow position |
| **Image Info** | Label | Shows "Image X of Y" and filename |
| **Folder Path** | Label | Displays selected folder name |

## 🔄 Transition Effects Details

### Fade
- **Duration**: 250ms out + 250ms in = 500ms total
- **Effect**: Opacity smoothly transitions from 1.0 → 0.0 → 1.0
- **Best for**: Smooth, professional presentations

### Slide
- **Duration**: 350ms out + 350ms in = 700ms total
- **Effect**: Old image slides left, new image slides in from right
- **Position**: Translates X from 0 → -Width → Width → 0
- **Best for**: Dynamic, engaging transitions

### Zoom
- **Duration**: 300ms out + 300ms in = 600ms total
- **Effect**: Image scales from 1.0 → 0.7 → 1.0
- **Scale**: Reduces to 70% size then returns
- **Best for**: Attention-grabbing presentations

### Scale
- **Duration**: 400ms out + 400ms in = 800ms total
- **Effect**: Image grows from 1.0 → 1.1 → 1.0
- **Scale**: Increases to 110% size then returns
- **Best for**: Subtle, cinematic effect

### None
- **Duration**: Instant
- **Effect**: Direct image swap
- **Best for**: Fast browsing, testing

## 🔐 Platform-Specific Implementation

### Windows 64-bit
```pascal
// Uses Winapi.Windows and Winapi.ShlObj
SHBrowseForFolder()  // Native folder dialog
FindFirst()          // File system enumeration
```

### Android
```pascal
// Uses Androidapi.JNI units
Intent.ACTION_OPEN_DOCUMENT_TREE  // SAF folder picker
Flag.GRANT_PERSISTABLE_URI_PERMISSION  // Persistent access
```

## 🔌 Key Optimizations

1. **Asynchronous Image Loading**
   - `TImageLoadThread`: Background loading prevents UI freeze
   - Callback pattern ensures thread-safe UI updates

2. **Memory Efficiency**
   - Images loaded on-demand during playback
   - Old bitmaps freed before loading new ones
   - Proper thread cleanup in FormDestroy

3. **Smooth Animations**
   - `TFloatAnimation` for hardware-accelerated transitions
   - OnFinish callbacks chain animations seamlessly
   - Duration tuned for 60fps playback

4. **Responsive UI**
   - Non-blocking folder operations
   - Status updates for user feedback
   - Thread-safe synchronization

## 📝 Android Manifest Permissions

```xml
<!-- Required for Android 6+ to read images -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Required for Android 5-12 legacy storage access -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

<!-- Required for Android 4-10 if writing metadata -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />

<!-- Minimum API 21 (Android 5.0) -->
<uses-sdk android:minSdkVersion="21" android:targetSdkVersion="34" />
```

## 🧪 Testing Checklist

### Windows
- [ ] Folder selection dialog opens
- [ ] Images load from nested folders
- [ ] All transitions work smoothly
- [ ] Timing adjustment works in real-time
- [ ] Play/Pause toggles correctly
- [ ] Progress bar advances
- [ ] Status messages display correctly
- [ ] App handles missing images gracefully

### Android
- [ ] SAF folder picker opens
- [ ] Persistable URI permission granted
- [ ] Images load from selected folder
- [ ] All transitions work smoothly
- [ ] Touch controls responsive
- [ ] Long-press pauses slideshow
- [ ] Timing adjustment works
- [ ] App survives screen rotation
- [ ] No crashes on permission denied

## 🐛 Troubleshooting

### Android
**SAF not opening**: Ensure Android SDK API 21+ is installed
**Images not loading**: Check manifest permissions are set correctly
**Crashes on rotation**: Form will auto-recover via OnCreate

### Windows
**Folder dialog not appearing**: Run as administrator
**Slow image loading**: Check antivirus isn't scanning files

## 📚 Development Tips

1. **Debug Image Loading**: Check `LabelStatus` text for error messages
2. **Test Animations**: Toggle transitions quickly to verify smoothness
3. **Performance**: Monitor task manager for memory leaks
4. **Android Testing**: Use Android emulator with at least 2GB RAM

## 📄 License

MIT License - Free to use and modify

## 🙋 Support

- **Delphi Docs**: https://docwiki.embarcadero.com/RADStudio/
- **FireMonkey**: https://docwiki.embarcadero.com/RADStudio/en/FireMonkey
- **Android SAF**: https://developer.android.com/guide/topics/providers/document-provider

---

**Version**: 2.0  
**Last Updated**: 2026-09-29  
**Platform**: Windows 64-bit, Android 6.0+  
**Status**: Production Ready ✓
