# Haa Backup App Setup and Run Guide

This document provides a step-by-step guide to set up and run the Haa Backup Flutter application on both Android and iOS platforms.

## 1. Project Setup

First, navigate to the project directory in your terminal:

```bash
cd haa_backup
```

Then, get the Flutter dependencies:

```bash
flutter pub get
```

## 2. Android Configuration

### Permissions

Ensure the following permissions are added to your `android/app/src/main/AndroidManifest.xml` file, inside the `<manifest>` tag and outside the `<application>` tag:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

For Android 10 (API level 29) and above, you might also need to add `android:requestLegacyExternalStorage="true"` to your `<application>` tag:

```xml
<application
    android:requestLegacyExternalStorage="true"
    ...
>
    ...
</application>
```

### Kotlin Version

Open `android/build.gradle` and ensure your Kotlin version is up-to-date (e.g., `kotlin_version = '1.8.0'` or higher):

```gradle
buildscript {
    ext.kotlin_version = '1.8.0' // Or a newer version
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2' // Or a newer version
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

## 3. iOS Configuration

### Permissions

Add the following privacy descriptions to your `ios/Runner/Info.plist` file:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to select images and videos for backup.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone to record videos.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to take photos and videos.</string>
```

### Pods Update

Navigate to the `ios` directory and update your Pods:

```bash
cd ios
pod install --repo-update
cd ..
```

## 4. Running the Application

After completing the platform-specific configurations, you can run the application on a connected device or emulator:

```bash
flutter run
```

This will build and launch the application. If it's the first run, you might be prompted to set a PIN. Enjoy using Haa Backup!
