import AppKit
import Carpaccio

let args = CommandLine.arguments
let fm = FileManager.default

let callURL: URL = URL(fileURLWithPath: args[0])

func getURL(_ path: String) -> URL {
    if path.starts(with: "/") {
        return URL(fileURLWithPath: path)
    }
    if path.starts(with: "~/") {
        let docsURL: URL = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docsURL.deletingLastPathComponent().appendingPathComponent(path.replacingOccurrences(of: "~/", with: ""))
    }
    return callURL.appendingPathComponent(path)
}

let argCount: Int = 2
guard args.count == argCount + 1 else {
    print("pix-batch-convert <input-folder> <output-folder>")
    exit(EXIT_FAILURE)
}

let inputFolderURL: URL = getURL(args[1])
var inputFolderIsDir: ObjCBool = false
let inputFolderExists: Bool = fm.fileExists(atPath: inputFolderURL.path, isDirectory: &inputFolderIsDir)
guard inputFolderExists && inputFolderIsDir.boolValue else {
    print("input needs to be a folder")
    print(inputFolderURL.path)
    exit(EXIT_FAILURE)
}

let outputFolderURL: URL = getURL(args[2])
var outputFolderIsDir: ObjCBool = false
let outputFolderExists: Bool = fm.fileExists(atPath: outputFolderURL.path, isDirectory: &outputFolderIsDir)
if outputFolderExists {
    guard outputFolderIsDir.boolValue else {
        print("output needs to be a folder")
        print(outputFolderURL.path)
        exit(EXIT_FAILURE)
    }
} else {
    try! fm.createDirectory(at: outputFolderURL, withIntermediateDirectories: true, attributes: nil)
}


// MARK: - Images


for fileName in try! fm.contentsOfDirectory(atPath: inputFolderURL.path).sorted() {

    guard fileName != ".DS_Store" else { continue }
    let fileURL: URL = inputFolderURL.appendingPathComponent(fileName)
    let name: String = fileURL.deletingPathExtension().lastPathComponent
    let saveURL: URL = outputFolderURL.appendingPathComponent("\(name).jpg")

    let saveFileExists: Bool = fm.fileExists(atPath: saveURL.path)
    if saveFileExists {
        print("skip \"\(fileName)\"")
        continue
    }
    
    let loader = ImageLoader(imageURL: fileURL, thumbnailScheme: .decodeEmbeddedThumbnail)
    guard let (cgImage, metadata) = try? loader.loadCGImage(colorSpace: nil, cancelled: nil) else {
        print("error \"\(fileName)\"")
        continue
    }
    
    print("image \"\(fileName)\" \(Int(metadata.size.width))x\(Int(metadata.size.height))")
    let image: NSImage = NSImage(cgImage: cgImage, size: metadata.size)
    
    let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
    let data: Data = bitmap.representation(using: .jpeg, properties: [.compressionFactor:0.8])!
    try data.write(to: saveURL)
}

print("done!")
