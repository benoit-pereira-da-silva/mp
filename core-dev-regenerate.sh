#!/usr/bin/env bash
# Core devs
# Install the linked projects

cd ../CommandLine
swift package generate-xcodeproj
cd ../Globals
swift package generate-xcodeproj
cd ../Tolerance
swift package generate-xcodeproj
cd ../AsynchronousOperation
swift package generate-xcodeproj
cd ../MPLib
swift package generate-xcodeproj
cd ../HTTPClient
swift package generate-xcodeproj
cd ../NavetLib
swift package generate-xcodeproj
