# mp

`mp`is a simple video frame processor command line for macOS

# Install *mp* (built via SPM)

1. Move to the `mp/` folder.
2. Build the release :  `swift build -c release -Xswiftc -static-stdlib`
3. Copy to the bin path: `cp -f .build/release/mp  /usr/local/bin/`


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
     Program ended with exit code: 64
```


