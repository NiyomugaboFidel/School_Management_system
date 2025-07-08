#!/bin/bash

echo "🧹 Clean Rebuild Script for XTAP App"
echo "====================================="

# Stop any running Flutter processes
echo "🛑 Stopping Flutter processes..."
pkill -f flutter || true

# Clean everything
echo "🧹 Cleaning project..."
flutter clean

# Clean Android build
echo "🧹 Cleaning Android build..."
cd android
./gradlew clean
cd ..

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Clean Android cache
echo "🧹 Cleaning Android cache..."
rm -rf ~/.gradle/caches/ || true
rm -rf android/.gradle/ || true

# Build debug APK
echo "🔨 Building debug APK..."
flutter build apk --debug

# Install on device
echo "📲 Installing on device..."
flutter install --debug

echo "✅ Clean rebuild completed!"
echo "🚀 Run 'flutter run' to start the app" 