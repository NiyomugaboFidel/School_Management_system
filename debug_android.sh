#!/bin/bash

echo "🔧 Android Debug Script for XTAP App"
echo "====================================="

# Clean the project
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Clean Android build
echo "🧹 Cleaning Android build..."
cd android
./gradlew clean
cd ..

# Build debug APK with verbose logging
echo "🔨 Building debug APK..."
flutter build apk --debug --verbose

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-debug.apk"
    
    # Install on connected device
    echo "📲 Installing on device..."
    flutter install --debug
    
    # Run with verbose logging
    echo "🚀 Running app with verbose logging..."
    flutter run --debug --verbose
else
    echo "❌ Build failed!"
    echo "Check the error messages above."
fi 