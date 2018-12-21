import XCTest
import class Foundation.Bundle

final class mpTests: XCTestCase {


    func test_001_greetings_on_launch() throws {

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let mpBinary = productsDirectory.appendingPathComponent("mp")

        let process = Process()
        process.executableURL = mpBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8){
            let result:Bool = output.starts(with:"Hey ...")
            XCTAssert(result)
        }else{
            XCTFail("mp should display its greetings.")
        }
    }


    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
        ("test_001_greetings_on_launch", test_001_greetings_on_launch),
    ]
}
