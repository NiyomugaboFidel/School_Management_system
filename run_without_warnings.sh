#!/bin/bash

# Set environment variables to suppress Java warnings
export JAVA_OPTS="-Xlint:-options -Xlint:-deprecation"
export GRADLE_OPTS="-Dorg.gradle.warning.mode=summary"
 
# Run Flutter with suppressed warnings
flutter run "$@" 2>&1 | grep -v "warning: \[options\] source value 8 is obsolete" | grep -v "warning: \[options\] target value 8 is obsolete" | grep -v "To suppress warnings about obsolete options" 