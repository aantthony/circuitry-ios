import CoreGraphics
import Foundation
import ImageIO

struct Sprite {
    let url: URL
    let name: String
    let image: CGImage
    let width: Int
    let height: Int
}

struct Placement {
    let sprite: Sprite
    let x: Int
    let y: Int
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func nextPowerOfTwo(_ value: Int) -> Int {
    var result = 1
    while result < value {
        result <<= 1
    }
    return result
}

func pack(_ sprites: [Sprite], side: Int, padding: Int) -> [Placement]? {
    var placements: [Placement] = []
    var cursorX = 0
    var cursorY = 0
    var shelfHeight = 0

    for sprite in sprites {
        guard sprite.width <= side, sprite.height <= side else {
            return nil
        }

        var x = cursorX == 0 ? 0 : cursorX + padding
        if x + sprite.width > side {
            cursorY += shelfHeight + padding
            cursorX = 0
            shelfHeight = 0
            x = 0
        }

        guard cursorY + sprite.height <= side else {
            return nil
        }

        placements.append(Placement(sprite: sprite, x: x, y: cursorY))
        cursorX = x + sprite.width
        shelfHeight = max(shelfHeight, sprite.height)
    }

    return placements
}

func loadSprites(from directory: URL) throws -> [Sprite] {
    let fileManager = FileManager.default
    let urls = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    )
    .filter { $0.pathExtension.lowercased() == "png" }
    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

    return try urls.map { url in
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw NSError(
                domain: "GenerateAtlas",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not read image at \(url.path)"]
            )
        }

        return Sprite(
            url: url,
            name: url.deletingPathExtension().lastPathComponent,
            image: image,
            width: image.width,
            height: image.height
        )
    }
}

func renderAtlas(side: Int, placements: [Placement], outputURL: URL) throws {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        fail("error: Could not create sRGB color space")
    }

    guard let context = CGContext(
        data: nil,
        width: side,
        height: side,
        bitsPerComponent: 8,
        bytesPerRow: side * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fail("error: Could not create atlas bitmap context")
    }

    context.clear(CGRect(x: 0, y: 0, width: side, height: side))
    context.interpolationQuality = .none
    context.translateBy(x: 0, y: CGFloat(side))
    context.scaleBy(x: 1, y: -1)

    for placement in placements {
        context.draw(
            placement.sprite.image,
            in: CGRect(
                x: placement.x,
                y: placement.y,
                width: placement.sprite.width,
                height: placement.sprite.height
            )
        )
    }

    guard let atlasImage = context.makeImage() else {
        fail("error: Could not create atlas image")
    }

    let pngData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(pngData, "public.png" as CFString, 1, nil) else {
        fail("error: Could not create PNG destination")
    }

    CGImageDestinationAddImage(destination, atlasImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        fail("error: Could not encode PNG")
    }

    try pngData.write(to: outputURL)
}

func writeAtlasJSON(placements: [Placement], outputURL: URL) throws {
    var atlas: [String: [String: Int]] = [:]
    for placement in placements {
        atlas[placement.sprite.name] = [
            "x": placement.x,
            "y": placement.y,
            "width": placement.sprite.width,
            "height": placement.sprite.height
        ]
    }

    let data = try JSONSerialization.data(withJSONObject: atlas, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: outputURL)
}

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    fail("usage: GenerateAtlas.swift <input .image-atlas directory> <output png> <output json>")
}

let inputDirectory = URL(fileURLWithPath: arguments[1])
let outputImage = URL(fileURLWithPath: arguments[2])
let outputJSON = URL(fileURLWithPath: arguments[3])
let padding = 1

do {
    try FileManager.default.createDirectory(
        at: outputImage.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: outputJSON.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    let sprites = try loadSprites(from: inputDirectory)
    guard !sprites.isEmpty else {
        fail("error: No PNG files found in \(inputDirectory.path)")
    }

    let sortedSprites = sprites.sorted {
        if $0.height != $1.height { return $0.height > $1.height }
        if $0.width != $1.width { return $0.width > $1.width }
        return $0.name < $1.name
    }

    let maxDimension = sortedSprites.reduce(0) { max($0, max($1.width, $1.height)) }
    let approximateArea = sortedSprites.reduce(0) { total, sprite in
        total + (sprite.width + padding) * (sprite.height + padding)
    }
    var side = nextPowerOfTwo(max(maxDimension, Int(ceil(sqrt(Double(approximateArea))))))
    var placements: [Placement]?

    while side <= 8192 {
        placements = pack(sortedSprites, side: side, padding: padding)
        if placements != nil {
            break
        }
        side <<= 1
    }

    guard let placements else {
        fail("error: Could not pack \(sprites.count) sprites into an atlas")
    }

    try renderAtlas(side: side, placements: placements, outputURL: outputImage)
    try writeAtlasJSON(placements: placements, outputURL: outputJSON)
} catch {
    fail("error: \(error.localizedDescription)")
}
