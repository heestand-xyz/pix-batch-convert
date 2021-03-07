import AppKit
import RenderKit
import PixelKit
import Carpaccio

frameLoopRenderThread = .background
PixelKit.main.render.engine.renderMode = .manual

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
guard outputFolderExists && outputFolderIsDir.boolValue else {
    print("output needs to be a folder")
    print(outputFolderURL.path)
    exit(EXIT_FAILURE)
}


// MARK: - Images


for fileName in try! fm.contentsOfDirectory(atPath: inputFolderURL.path) {
    guard fileName != ".DS_Store" else { continue }
    let fileURL: URL = inputFolderURL.appendingPathComponent(fileName)
    let loader = ImageLoader(imageURL: fileURL, thumbnailScheme: .decodeEmbeddedThumbnail)
    guard let (cgImage, metadata) = try? loader.loadCGImage(colorSpace: nil, cancelled: nil) else {
        print("skipping \"\(fileName)\"")
        continue
    }
    
    print("image \"\(fileName)\" \(Int(metadata.size.width))x\(Int(metadata.size.height))")
    let image: NSImage = NSImage(cgImage: cgImage, size: metadata.size)
    
    let name: String = fileURL.deletingPathExtension().lastPathComponent
    let saveURL: URL = outputFolderURL.appendingPathComponent("\(name).jpg")
    
    let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
    let data: Data = bitmap.representation(using: .jpeg, properties: [.compressionFactor:0.8])!
    try data.write(to: saveURL)
}

print("done!")
