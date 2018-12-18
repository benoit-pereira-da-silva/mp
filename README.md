# mp

`mp`is a video media processor command line wrapper of `mplib` for macOS.

# How to debug and launch from xcode?

Check [Using the Package Manager on swift.org](https://swift.org/getting-started/#using-the-package-manager) if your not familiar with the Swift Package Manager (SPM).

1. You need to have the xcode tools installed (xcode 10.1 / Swift 4.2)
2. To Generate the xcode project  via SPM move to mp's folder and call: `swift package generate-xcodeproj` 
3. You can add arguments on launch in xcode by editing the scheme. For example : `detect-shots -i /Users/bpds/Desktop/1.mp4 -o /Users/bpds/Desktop/shots.json` will try to detect the file **1.mp4** automatically after compilation.  

# How to install *mp*

1. Clone `https://github.com/benoit-pereira-da-silva/mplib.git` side by side with `mp`
2. Move to the `mp/` folder.
3. Build the release :  `swift build -c release -Xswiftc -static-stdlib`
4. Copy the executable to the bin path: `cp ./.build/x86_64-apple-macosx10.10/release/mp  /usr/local/bin/`


# mp detect-shots command

In filmmaking and video production, a shot is a series of frames, that runs for an uninterrupted period of time. `mp detect-shots` detect the shots from a file or an URL and saves the result into a json file 

` mp detect-shots help`


```
Usage: mp detect-shots [options]
  -i, --input:
      The media file URL or path (supports Bearer tokens)
  -o, --output:
      The optional Output file URL or path. If not set the result will be printed to the standard output. In case of URL usage + token it POST the file with the token in an HTTP Authorization Header
  -a, --authorization-token:
      The optional Authorization bearer token (for media URLs)
  -s, --starts:
      The optional starting time stamp in seconds (double)
  -e, --ends:
      The optional ends time stamp in seconds (double)
  -t, --threshold:
      The optional detection threshold (integer from 1 to 255)
  -p, --pretty-json:
      Should the result be pretty encoded (default is false)
  -v, --verbose:
      If verbose some progress messages will be displayed in the standard output.
```


## Samples

### Distant video 

Detect the shots in the second minute of Big buck bunny :

`mp detect-shots -v -s 60 -e 120 -i https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4 -o ~/Desktop/BigBuckBunny.shot.json`


```json
{
  "shots": [{
    "detectionValue": 45,
    "time": 60.6875,
    "timeCode": "00:01:00:16"
  }, {
    "detectionValue": 71,
    "time": 63.8125,
    "timeCode": "00:01:03:19"
  }, {
    "detectionValue": 68,
    "time": 69.4375,
    "timeCode": "00:01:09:10"
  }, {
    "detectionValue": 87,
    "time": 71.3125,
    "timeCode": "00:01:11:07"
  }, {
    "detectionValue": 63,
    "time": 73.479166666666671,
    "timeCode": "00:01:13:11"
  }, {
    "detectionValue": 61,
    "time": 75.5625,
    "timeCode": "00:01:15:13"
  }, {
    "detectionValue": 69,
    "time": 79.979166666666671,
    "timeCode": "00:01:19:23"
  }, {
    "detectionValue": 69,
    "time": 89.770833333333329,
    "timeCode": "00:01:29:18"
  }, {
    "detectionValue": 69,
    "time": 91.4375,
    "timeCode": "00:01:31:10"
  }, {
    "detectionValue": 86,
    "time": 99.770833333333329,
    "timeCode": "00:01:39:18"
  }, {
    "detectionValue": 67,
    "time": 103.9375,
    "timeCode": "00:01:43:22"
  }, {
    "detectionValue": 56,
    "time": 117.97916666666667,
    "timeCode": "00:01:57:23"
  }, {
    "detectionValue": 62,
    "time": 120.89583333333333,
    "timeCode": "00:02:00:21"
  }],
  "stats": {
    "startTimeString": "00:01:00:00",
    "imgPerSecond": 34,
    "cliVersion": "1.0.5",
    "endTime": 120,
    "elapsedTime": 41.053743958473206,
    "averageImageComparisonResult": 3,
    "endTimeString": "00:02:00:00",
    "frameDuration": 0.041666666666666664,
    "startTime": 60,
    "numberOfFrames": 1440,
    "elapsedTimeString": "00:41"
  },
  "source": {
    "height": 180,
    "origin": 0,
    "originTimeCode": "00:00",
    "width": 320,
    "fps": 24,
    "duration": 596.45899999999995,
    "url": "https:\/\/download.blender.org\/peach\/bigbuckbunny_movies\/BigBuckBunny_320x180.mp4"
  }
}
```

