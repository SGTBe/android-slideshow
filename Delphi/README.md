# Android Slideshow App - Delphi Version

A cross-platform slideshow application built with Delphi RAD Studio Enterprise for both **Android** and **Windows 64-bit**.

## Features

- **Cross-Platform Support**: Runs on Android and Windows 64-bit with platform-specific folder selection
- **Image Directory Browser**: 
  - Android: Uses Storage Access Framework (SAF) for secure folder selection
  - Windows: Native Windows folder browser dialog
- **Automatic Image Loading**: Supports `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.webp`
- **Adjustable Slideshow Timing**: 1-20 seconds per image
- **Transition Effects**:
  - **Fade**: Smooth opacity transition
  - **Slide**: Images slide in from left
  - **Zoom**: Images zoom in/out
  - **None**: Instant image change
- **Playback Controls**: Play/Pause functionality
- **Real-time Information**: Current image count, folder path, and status messages

## Requirements

### Development
- **Delphi RAD Studio Enterprise 11 or later** (with FireMonkey and Android support)
- **Windows 64-bit for compilation**
- **Android SDK** (for Android builds)
- **JDK 8 or later**

### Runtime
- **Android 6.0+** (API Level 23+)
- **Windows 10/11 64-bit**

## File Structure

```
Delphi/
├── SlideshowApp.dpr          # Main project file
├── Unit1.pas                 # Main application unit (Windows & Android logic)
├── SlideshowApp.fmx          # FireMonkey form definition
└── README.md                 # This file
```

## Building and Running

### For Windows 64-bit

1. Open `SlideshowApp.dpr` in Delphi RAD Studio
2. Select **Platform: Windows 64-bit** in the Project Manager
3. Press **F9** or go to **Run → Run**
4. The application will launch
5. Click "Choose Folder" to select a folder with images
6. Click "Play" to start the slideshow

### For Android

1. Open `SlideshowApp.dpr` in Delphi RAD Studio
2. Select **Platform: Android** in the Project Manager
3. Connect an Android device or start an emulator
4. Press **F9** or go to **Run → Run**
5. The app will compile and deploy to the device
6. Launch "Slideshow Viewer" from your apps
7. Tap "Choose Folder" to select a folder with images using Android SAF
8. Tap "Play" to start the slideshow

## Platform-Specific Implementation

### Windows 64-bit

- Uses **SHBrowseForFolder** Windows API for folder selection
- Uses standard `TDirectory` and file I/O from `System.IOUtils`
- Full file path access without restrictions
- Compiled with Windows 64-bit platform in Delphi

### Android

- Uses **Storage Access Framework (SAF)** via Android intents for secure folder access
- Respects Android scoped storage (API 30+)
- Handles runtime permissions properly
- Uses Androidapi.JNI units for native Android integration
- Works with both internal and external storage

## Code Architecture

### Main Components

- **TForm1**: Main application form with all controls
  - Image display (TImage)
  - Folder selection button
  - Play/Pause controls
  - Timing slider (1-20 seconds)
  - Transition effect selector
  - Status labels

### Key Methods

- `FormCreate()`: Initializes the application
- `OpenFolderViaWin64Dialog()`: Windows folder selection (Windows only)
- `OpenFolderViaAndroidSAF()`: Android folder selection via SAF (Android only)
- `LoadImageFiles()`: Recursively scans folder for supported image files
- `ShowImage()`: Displays current image with selected transition
- `ApplyTransition()`: Applies fade, slide, or zoom animation
- `AnimateFade()`: Implements fade transition using TFloatAnimation
- `AnimateSlide()`: Implements slide transition
- `AnimateZoom()`: Implements zoom transition

### Conditional Compilation

```pascal
{$IFDEF MSWINDOWS}
  // Windows-specific code (SHBrowseForFolder, file dialogs)
{$ENDIF}

{$IFDEF ANDROID}
  // Android-specific code (SAF, JNI calls)
{$ENDIF}
```

## Permissions

### Android

Required permissions in `AndroidManifest.template.xml`:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

### Windows

No special permissions required; runs with standard user privileges.

## Supported Image Formats

- JPEG / JPG
- PNG
- BMP
- GIF
- WEBP

## Controls

| Control | Function |
|---------|----------|
| **Choose Folder** | Opens folder selection dialog (platform-specific) |
| **Play/Pause** | Starts or stops the slideshow |
| **Display Time Slider** | Sets time each image is shown (1-20 seconds) |
| **Transition Effect** | Selects transition animation (None, Fade, Slide, Zoom) |
| **Status Labels** | Shows current image count, folder path, and messages |

## Error Handling

- Graceful handling of missing or inaccessible folders
- Error messages displayed in the status label
- Safe image loading with exception handling
- Automatic cleanup of resources on app exit

## Performance Optimization

- Images are loaded on-demand during slideshow playback
- Bitmap animations use native FireMonkey animation framework
- Efficient file enumeration with proper filtering
- Timer-based slideshow prevents UI blocking
- Proper resource cleanup in FormDestroy

## Testing

### Windows
1. Create a test folder with sample images
2. Run the app and select the folder
3. Test each transition effect (None, Fade, Slide, Zoom)
4. Verify timing adjustment (1-20 seconds)
5. Test pause/resume functionality

### Android
1. Ensure device has a folder with images
2. Tap "Choose Folder" and use SAF to navigate
3. Verify images load correctly
4. Test transitions with different devices/screen sizes
5. Verify app doesn't crash when folder is unmounted

## Known Limitations

- Android SAF folder selection requires Android 5.0+
- Very large images may cause memory issues on low-end devices
- Recursive folder scanning may be slow on network drives (Windows)
- Android scoped storage restricts access to certain system directories

## License

MIT License - See LICENSE file in repository root

## Author

Developed for cross-platform image slideshow viewing

## Support

For issues or questions, please refer to:
- Delphi Documentation: https://docwiki.embarcadero.com/
- FireMonkey: https://docwiki.embarcadero.com/RADStudio/en/FireMonkey
- Android SAF: https://developer.android.com/guide/topics/providers/document-provider
