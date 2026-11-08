import AppKit
import CoreGraphics
import CoreText
import Foundation

// Base directory is the parent of `scripts/` (i.e. /Users/tiger4th/git/lp/giin/img/screenshot)
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let baseDir = scriptURL.deletingLastPathComponent().deletingLastPathComponent().path

// Register LINE Seed JP fonts
let fontDir = "/Users/tiger4th/git/giin/assets/fonts/LINESeedJP"
for file in ["LINESeedJP_A_TTF_Rg.ttf", "LINESeedJP_A_TTF_Bd.ttf", "LINESeedJP_A_TTF_Eb.ttf"] {
    let url = URL(fileURLWithPath: "\(fontDir)/\(file)")
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
}

let rawPhoneDir = "\(baseDir)/raw/phone"
let outDir = "\(baseDir)/creative_assets"
let iconPath = "/Users/tiger4th/git/giin/assets/icon/icon.png"

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func loadCGImage(_ path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func cropPhoneAppArea(_ cgImg: CGImage) -> CGImage? {
    let rect = CGRect(x: 0, y: 46, width: cgImg.width, height: 960 - 46)
    return cgImg.cropping(to: rect)
}

func drawText(
    _ text: String,
    fontName: String,
    fontSize: CGFloat,
    maxWidth: CGFloat? = nil,
    color: NSColor,
    point: CGPoint,
    align: NSTextAlignment = .left,
    in ctx: CGContext
) -> CGSize {
    var actualSize = fontSize
    var font = NSFont(name: fontName, size: actualSize) ?? NSFont.boldSystemFont(ofSize: actualSize)
    if let limit = maxWidth {
        while actualSize > 24.0 {
            let testSize = NSAttributedString(string: text, attributes: [.font: font]).size()
            if testSize.width <= limit { break }
            actualSize -= 2.0
            font = NSFont(name: fontName, size: actualSize) ?? NSFont.boldSystemFont(ofSize: actualSize)
        }
    }
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let size = attrStr.size()
    let x: CGFloat
    switch align {
    case .center:
        x = point.x - size.width / 2.0
    case .right:
        x = point.x - size.width
    default:
        x = point.x
    }
    let rect = CGRect(x: x, y: point.y - size.height / 2.0, width: size.width, height: size.height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    attrStr.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    return size
}

func drawPhoneFrame(
    cgImg: CGImage,
    rect: CGRect,
    cornerRadius: CGFloat,
    bezelPad: CGFloat,
    shadowBlur: CGFloat,
    in ctx: CGContext
) {
    let bezelRect = rect.insetBy(dx: -bezelPad, dy: -bezelPad)
    let bezelCorner = cornerRadius + bezelPad

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -shadowBlur * 0.35),
        blur: shadowBlur,
        color: NSColor(calibratedRed: 0.08, green: 0.02, blue: 0.22, alpha: 0.52).cgColor
    )
    let bezelPath = CGPath(roundedRect: bezelRect, cornerWidth: bezelCorner, cornerHeight: bezelCorner, transform: nil)
    ctx.setFillColor(NSColor(calibratedWhite: 1.0, alpha: 0.98).cgColor)
    ctx.addPath(bezelPath)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    let screenPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(screenPath)
    ctx.clip()
    ctx.draw(cgImg, in: rect)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.setStrokeColor(NSColor(calibratedWhite: 0.0, alpha: 0.08).cgColor)
    ctx.setLineWidth(max(2.0, bezelPad * 0.15))
    ctx.addPath(screenPath)
    ctx.strokePath()
    ctx.restoreGState()
}

func drawPurpleBackground(width w: CGFloat, height h: CGFloat, in ctx: CGContext) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors: [CGColor] = [
        NSColor(calibratedRed: 0.32, green: 0.12, blue: 0.76, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.48, green: 0.23, blue: 0.92, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.64, green: 0.40, blue: 0.98, alpha: 1.0).cgColor
    ]
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: locations) {
        ctx.drawLinearGradient(
            grad,
            start: CGPoint(x: 0, y: h),
            end: CGPoint(x: w, y: 0),
            options: []
        )
    }

    ctx.saveGState()
    ctx.setFillColor(NSColor(calibratedWhite: 1.0, alpha: 0.08).cgColor)
    ctx.fillEllipse(in: CGRect(x: -w * 0.12, y: h * 0.35, width: w * 0.55, height: w * 0.55))
    ctx.fillEllipse(in: CGRect(x: w * 0.55, y: -w * 0.15, width: w * 0.50, height: w * 0.50))
    ctx.setFillColor(NSColor(calibratedRed: 0.90, green: 0.75, blue: 1.0, alpha: 0.10).cgColor)
    ctx.fillEllipse(in: CGRect(x: w * 0.28, y: h * 0.45, width: w * 0.42, height: w * 0.42))
    ctx.restoreGState()
}

func saveContext(_ ctx: CGContext, to path: String) {
    guard let outCG = ctx.makeImage() else { return }
    let bmpRep = NSBitmapImageRep(cgImage: outCG)
    if let pngData = bmpRep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: path))
    }
}

func renderSearchResultsAsset(width canvasW: Int, height canvasH: Int, outPath: String) {
    let w = CGFloat(canvasW)
    let h = CGFloat(canvasH)
    let scale = w / 3840.0

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: canvasW,
        height: canvasH,
        bitsPerComponent: 8,
        bytesPerRow: canvasW * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return }
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    drawPurpleBackground(width: w, height: h, in: ctx)

    guard let rawChat = loadCGImage("\(rawPhoneDir)/01_chat.jpg"),
          let imgChat = cropPhoneAppArea(rawChat),
          let rawSummary = loadCGImage("\(rawPhoneDir)/02_ai_summary.jpg"),
          let imgSummary = cropPhoneAppArea(rawSummary),
          let rawSpeaker = loadCGImage("\(rawPhoneDir)/03_follow_speaker.jpg"),
          let imgSpeaker = cropPhoneAppArea(rawSpeaker) else { return }

    let pillText = "国会議事録・AI要約・政治学習"
    let pillFontSize = 92.0 * scale
    let pillFont = NSFont(name: "LINESeedJPApp_TTF-ExtraBold", size: pillFontSize) ?? NSFont.boldSystemFont(ofSize: pillFontSize)
    let pillTextSize = NSAttributedString(string: pillText, attributes: [.font: pillFont]).size()
    let pillW = pillTextSize.width + 160.0 * scale
    let pillH = pillTextSize.height + 52.0 * scale
    let pillRect = CGRect(x: (w - pillW) / 2.0, y: h - 220.0 * scale, width: pillW, height: pillH)

    ctx.saveGState()
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillH / 2.0, cornerHeight: pillH / 2.0, transform: nil)
    ctx.setFillColor(NSColor(calibratedWhite: 1.0, alpha: 0.96).cgColor)
    ctx.addPath(pillPath)
    ctx.fillPath()
    ctx.restoreGState()

    _ = drawText(
        pillText,
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: pillFontSize,
        color: NSColor(calibratedRed: 0.38, green: 0.14, blue: 0.82, alpha: 1.0),
        point: CGPoint(x: w / 2.0, y: pillRect.midY - 4.0 * scale),
        align: .center,
        in: ctx
    )

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -10.0 * scale),
        blur: 28.0 * scale,
        color: NSColor(calibratedWhite: 0.0, alpha: 0.30).cgColor
    )
    _ = drawText(
        "国会議事録をチャット感覚で！",
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: 228.0 * scale,
        maxWidth: w * 0.94,
        color: .white,
        point: CGPoint(x: w / 2.0, y: h - 435.0 * scale),
        align: .center,
        in: ctx
    )
    _ = drawText(
        "長時間の審議もAIがわかりやすく要約",
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: 216.0 * scale,
        maxWidth: w * 0.94,
        color: NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.62, alpha: 1.0),
        point: CGPoint(x: w / 2.0, y: h - 695.0 * scale),
        align: .center,
        in: ctx
    )
    ctx.restoreGState()

    let imgAspect = CGFloat(imgChat.width) / CGFloat(imgChat.height)
    let sideW = 1140.0 * scale
    let sideH = sideW / imgAspect
    let centerW = 1280.0 * scale
    let centerH = centerW / imgAspect

    let sideTopY = h - 920.0 * scale
    let centerTopY = h - 850.0 * scale

    let leftRect = CGRect(x: 110.0 * scale, y: sideTopY - sideH, width: sideW, height: sideH)
    drawPhoneFrame(cgImg: imgSpeaker, rect: leftRect, cornerRadius: 64.0 * scale, bezelPad: 22.0 * scale, shadowBlur: 60.0 * scale, in: ctx)

    let rightRect = CGRect(x: w - 110.0 * scale - sideW, y: sideTopY - sideH, width: sideW, height: sideH)
    drawPhoneFrame(cgImg: imgSummary, rect: rightRect, cornerRadius: 64.0 * scale, bezelPad: 22.0 * scale, shadowBlur: 60.0 * scale, in: ctx)

    let centerRect = CGRect(x: (w - centerW) / 2.0, y: centerTopY - centerH, width: centerW, height: centerH)
    drawPhoneFrame(cgImg: imgChat, rect: centerRect, cornerRadius: 72.0 * scale, bezelPad: 26.0 * scale, shadowBlur: 80.0 * scale, in: ctx)

    saveContext(ctx, to: outPath)
}

func renderProductPageHeader(width canvasW: Int, height canvasH: Int, outPath: String) {
    let w = CGFloat(canvasW)
    let h = CGFloat(canvasH)
    let scale = w / 3840.0

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: canvasW,
        height: canvasH,
        bitsPerComponent: 8,
        bytesPerRow: canvasW * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return }
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    drawPurpleBackground(width: w, height: h, in: ctx)

    guard let rawChat = loadCGImage("\(rawPhoneDir)/01_chat.jpg"),
          let imgChat = cropPhoneAppArea(rawChat),
          let rawSummary = loadCGImage("\(rawPhoneDir)/02_ai_summary.jpg"),
          let imgSummary = cropPhoneAppArea(rawSummary),
          let iconCG = loadCGImage(iconPath) else { return }

    let leftX = 160.0 * scale
    let maxLeftW = w * 0.54

    let iconSize = 210.0 * scale
    let iconRect = CGRect(x: leftX, y: h * 0.72, width: iconSize, height: iconSize)
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -10.0 * scale),
        blur: 28.0 * scale,
        color: NSColor(calibratedWhite: 0.0, alpha: 0.32).cgColor
    )
    let iconPathClip = CGPath(roundedRect: iconRect, cornerWidth: 48.0 * scale, cornerHeight: 48.0 * scale, transform: nil)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.addPath(iconPathClip)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(iconPathClip)
    ctx.clip()
    ctx.draw(iconCG, in: iconRect)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.88).cgColor)
    ctx.setLineWidth(5.0 * scale)
    ctx.addPath(iconPathClip)
    ctx.strokePath()
    ctx.restoreGState()

    let badgeX = leftX + iconSize + 44.0 * scale
    _ = drawText(
        "GIIN（ギイン）",
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: 118.0 * scale,
        color: .white,
        point: CGPoint(x: badgeX, y: iconRect.midY + 44.0 * scale),
        align: .left,
        in: ctx
    )
    _ = drawText(
        "国会議事録・AI要約・政治学習",
        fontName: "LINESeedJPApp_TTF-Bold",
        fontSize: 76.0 * scale,
        color: NSColor(calibratedWhite: 1.0, alpha: 0.94),
        point: CGPoint(x: badgeX, y: iconRect.midY - 54.0 * scale),
        align: .left,
        in: ctx
    )

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -10.0 * scale),
        blur: 28.0 * scale,
        color: NSColor(calibratedWhite: 0.0, alpha: 0.28).cgColor
    )
    _ = drawText(
        "国会議事録を",
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: 215.0 * scale,
        maxWidth: maxLeftW,
        color: .white,
        point: CGPoint(x: leftX, y: h * 0.50),
        align: .left,
        in: ctx
    )
    _ = drawText(
        "チャット感覚で！",
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: 215.0 * scale,
        maxWidth: maxLeftW,
        color: NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.62, alpha: 1.0),
        point: CGPoint(x: leftX, y: h * 0.30),
        align: .left,
        in: ctx
    )
    ctx.restoreGState()

    let subPillText = "AI要約・議員フォロー・キーワード通知"
    let subFontSize = 78.0 * scale
    let subFont = NSFont(name: "LINESeedJPApp_TTF-ExtraBold", size: subFontSize) ?? NSFont.boldSystemFont(ofSize: subFontSize)
    let subSize = NSAttributedString(string: subPillText, attributes: [.font: subFont]).size()
    let subPillW = subSize.width + 110.0 * scale
    let subPillH = subSize.height + 44.0 * scale
    let subPillRect = CGRect(x: leftX, y: h * 0.11 - subPillH / 2.0, width: subPillW, height: subPillH)

    ctx.saveGState()
    let subPillPath = CGPath(roundedRect: subPillRect, cornerWidth: subPillH / 2.0, cornerHeight: subPillH / 2.0, transform: nil)
    ctx.setFillColor(NSColor(calibratedWhite: 1.0, alpha: 0.20).cgColor)
    ctx.addPath(subPillPath)
    ctx.fillPath()
    ctx.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.55).cgColor)
    ctx.setLineWidth(4.0 * scale)
    ctx.addPath(subPillPath)
    ctx.strokePath()
    ctx.restoreGState()

    _ = drawText(
        subPillText,
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: subFontSize,
        color: .white,
        point: CGPoint(x: subPillRect.midX, y: subPillRect.midY - 3.0 * scale),
        align: .center,
        in: ctx
    )

    let imgAspect = CGFloat(imgChat.width) / CGFloat(imgChat.height)
    let backW = 1040.0 * scale
    let backH = backW / imgAspect
    let frontW = 1140.0 * scale
    let frontH = frontW / imgAspect

    let rightPhoneRect = CGRect(
        x: w - 120.0 * scale - backW,
        y: h * 0.88 - backH,
        width: backW,
        height: backH
    )
    drawPhoneFrame(cgImg: imgSummary, rect: rightPhoneRect, cornerRadius: 56.0 * scale, bezelPad: 20.0 * scale, shadowBlur: 55.0 * scale, in: ctx)

    let frontPhoneRect = CGRect(
        x: w - 120.0 * scale - backW - frontW * 0.68,
        y: h * 0.94 - frontH,
        width: frontW,
        height: frontH
    )
    drawPhoneFrame(cgImg: imgChat, rect: frontPhoneRect, cornerRadius: 62.0 * scale, bezelPad: 22.0 * scale, shadowBlur: 75.0 * scale, in: ctx)

    saveContext(ctx, to: outPath)
}

func renderCleanProductPageHeader(width canvasW: Int, height canvasH: Int, outPath: String) {
    let w = CGFloat(canvasW)
    let h = CGFloat(canvasH)
    let scale = w / 3840.0

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: canvasW,
        height: canvasH,
        bitsPerComponent: 8,
        bytesPerRow: canvasW * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return }
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    drawPurpleBackground(width: w, height: h, in: ctx)

    guard let rawChat = loadCGImage("\(rawPhoneDir)/01_chat.jpg"),
          let imgChat = cropPhoneAppArea(rawChat),
          let rawSummary = loadCGImage("\(rawPhoneDir)/02_ai_summary.jpg"),
          let imgSummary = cropPhoneAppArea(rawSummary),
          let rawSpeaker = loadCGImage("\(rawPhoneDir)/03_follow_speaker.jpg"),
          let imgSpeaker = cropPhoneAppArea(rawSpeaker) else { return }

    let imgAspect = CGFloat(imgChat.width) / CGFloat(imgChat.height)
    let sideW = 1140.0 * scale
    let sideH = sideW / imgAspect
    let centerW = 1260.0 * scale
    let centerH = centerW / imgAspect

    let centerX = w * 0.5

    let p1Rect = CGRect(x: centerX - centerW * 0.5 - sideW * 0.82, y: h * 0.88 - sideH, width: sideW, height: sideH)
    drawPhoneFrame(cgImg: imgSpeaker, rect: p1Rect, cornerRadius: 60.0 * scale, bezelPad: 22.0 * scale, shadowBlur: 60.0 * scale, in: ctx)

    let p3Rect = CGRect(x: centerX + centerW * 0.5 - sideW * 0.18, y: h * 0.88 - sideH, width: sideW, height: sideH)
    drawPhoneFrame(cgImg: imgSummary, rect: p3Rect, cornerRadius: 60.0 * scale, bezelPad: 22.0 * scale, shadowBlur: 60.0 * scale, in: ctx)

    let p2Rect = CGRect(x: centerX - centerW * 0.5, y: h * 0.95 - centerH, width: centerW, height: centerH)
    drawPhoneFrame(cgImg: imgChat, rect: p2Rect, cornerRadius: 66.0 * scale, bezelPad: 24.0 * scale, shadowBlur: 80.0 * scale, in: ctx)

    saveContext(ctx, to: outPath)
}

renderProductPageHeader(width: 3840, height: 1646, outPath: "\(outDir)/header_3840x1646.png")
print("Generated header_3840x1646.png")

renderCleanProductPageHeader(width: 3840, height: 1646, outPath: "\(outDir)/header_clean_ui_3840x1646.png")
print("Generated header_clean_ui_3840x1646.png")

renderSearchResultsAsset(width: 3840, height: 2560, outPath: "\(outDir)/search_results_3840x2560.png")
print("Generated search_results_3840x2560.png")

renderSearchResultsAsset(width: 1920, height: 1280, outPath: "\(outDir)/search_results_1920x1280.png")
print("Generated search_results_1920x1280.png")

renderProductPageHeader(width: 1024, height: 500, outPath: "\(outDir)/google_play_feature_1024x500.png")
print("Generated google_play_feature_1024x500.png")
