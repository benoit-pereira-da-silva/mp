#!/usr/bin/env bash
# Core devs
# Install the linked projects

INITIAL_DIR=$(pwd)

# Generate the xcode project
swift package generate-xcodeproj

cd ../CommandLine
git clone https://github.com/benoit-pereira-da-silva/CommandLine
cd ../Globals
git clone https://github.com/benoit-pereira-da-silva/Globals
cd ../Tolerance
git clone https://github.com/benoit-pereira-da-silva/Tolerance
cd ../MPLib
git clone https://github.com/benoit-pereira-da-silva/MPLib
cd ../HTTPClient
git clone https://github.com/benoit-pereira-da-silva/HTTPClient
cd ../NavetLib
git clone https://github.com/benoit-pereira-da-silva/NavetLib

cd "$INITIAL_DIR"
sh ./core-dev-regenerate.sh


swift build -c release -Xswiftc -static-stdlib
cp ./.build/x86_64-apple-macosx10.10/release/mp  /usr/local/bin/
