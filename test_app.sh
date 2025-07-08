#!/bin/bash

echo "🧪 Testing XTAP App with Error Handling"
echo "========================================"

# Clean and build
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

# Build and run with verbose logging
echo "🚀 Building and running app..."
flutter run --debug --verbose 2>&1 | tee app_logs.txt

echo "✅ Test completed. Check app_logs.txt for detailed logs." 