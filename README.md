# Android Slideshow App

A simple Android app that lets you select a folder of images and play them as a slideshow.

## Features
- Select any image directory using Android's system folder picker
- Automatically loads supported images (`.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.webp`)
- Adjustable slideshow timing from 1 to 15 seconds
- Transition effects: Fade, Slide, Zoom, and None
- Play and pause controls

## Requirements
- Android Studio Hedgehog or newer
- JDK 17
- Android SDK 34

## How to run
1. Open the project in Android Studio.
2. Let Gradle sync.
3. Connect a device or start an emulator.
4. Press Run.
5. Tap "Choose Folder" and select a directory containing images.
6. Use the controls to play or pause the slideshow and adjust settings.

## Notes
This app uses the Storage Access Framework so you can choose a folder without needing to request broad storage permissions on modern Android versions.
