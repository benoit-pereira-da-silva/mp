# mp

`mp`is a simple video frame processor command line for macOS.

# How to debug and launch from xcode?

Check [Using the Package Manager on swift.org](https://swift.org/getting-started/#using-the-package-manager) if your not familiar with the Swift Package Manager (SPM).

1. You need to have the xcode tools installed (xcode 10.1 / Swift 4.2)
2. To Generate the xcode project  via SPM move to mp's folder and call: `swift package generate-xcodeproj` 
3. You can add arguments on launch in xcode by editing the scheme. For example : `detect-shots -i /Users/bpds/Desktop/1.mp4 -o /Users/bpds/Desktop/shots.json` will try to detect the file **1.mp4** automatically after compilation.  

# How to install *mp*

1. Move to the `mp/` folder.
2. Build the release :  `swift build -c release -Xswiftc -static-stdlib`
3. Copy the executable to the bin path: `cp -f .build/release/mp  /usr/local/bin/`


# Usage

` mp detect-shots help`


```
     Usage: mp detect-shots [options]
     -i, --input-file:
     The media file url or path
     -o, --output-file:
     The Out put file path
     -s, --starts:
     The optional starting time stamp in seconds (double)
     -e, --ends:
     The optional ends time stamp in seconds (double)
     -t, --threshold:
     The optional detection threshold (integer from 1 to 255)
```


