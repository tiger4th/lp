import AppKit
import CoreGraphics
import CoreText
import Foundation

// Base directory is the parent of `scripts/` (i.e. /Users/tiger4th/git/lp/giin/img/screenshot)
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let baseDir = scriptURL.deletingLastPathComponent().deletingLastPathComponent().path

// Register LINE Seed JP fonts from /Users/tiger4th/git/giin/assets/fonts/LINESeedJP
let fontDir = "/Users/tiger4th/git/giin/assets/fonts/LINESeedJP"
for file in ["LINESeedJP_A_TTF_Rg.ttf", "LINESeedJP_A_TTF_Bd.ttf", "LINESeedJP_A_TTF_Eb.ttf"] {
    let url = URL(fileURLWithPath: "\(fontDir)/\(file)")
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
}

struct SlideSpec {
    let id: String
    let mainImage: String
    let overlayImage: String?
    let badge: String
    let titleLine1: String
    let titleLine2: String
    let subtitle: String
    let isDarkTheme: Bool
}

let slides: [SlideSpec] = [
    SlideSpec(
        id: "01_chat",
        mainImage: "01_chat.jpg",
        overlayImage: nil,
        badge: "国会議事録アプリ GIIN",
        titleLine1: "国会議事録を",
        titleLine2: "チャット感覚でサクサク",
        subtitle: "むずかしい国会審議も、吹き出し表示で読みやすく",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "02_ai_summary",
        mainImage: "02_ai_summary.jpg",
        overlayImage: nil,
        badge: "AI要約で時短チェック",
        titleLine1: "長時間の国会審議も",
        titleLine2: "AIがわかりやすく要約",
        subtitle: "会議の概要・主な論点・答弁の要旨を瞬時に整理",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "03_follow_speaker",
        mainImage: "03_follow_speaker.jpg",
        overlayImage: nil,
        badge: "議員フォロー＆ランダム発見",
        titleLine1: "気になる議員をフォロー",
        titleLine2: "最新の発言をチェック",
        subtitle: "右下のランダム表示で新しい議員との出会いも",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "04_follow_word",
        mainImage: "04_follow_word.jpg",
        overlayImage: nil,
        badge: "キーワード追跡＆新着通知",
        titleLine1: "注目キーワードを登録",
        titleLine2: "新着発言を通知でお知らせ",
        subtitle: "子育て・物価・NISA・AIなど関心のあるテーマを追跡",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "05_search_highlight",
        mainImage: "05_search_highlight.jpg",
        overlayImage: nil,
        badge: "ページ内検索＆ハイライト",
        titleLine1: "キーワード検索で",
        titleLine2: "知りたい発言にすぐ飛べる",
        subtitle: "該当箇所がハイライトされて議論の流れがわかる",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "06_bookmark_share",
        mainImage: "06_bookmark.jpg",
        overlayImage: "share_card_speech.png",
        badge: "ブックマーク＆画像シェア",
        titleLine1: "心に残る発言を保存＆",
        titleLine2: "画像カードでSNSシェア",
        subtitle: "発言・会議・AI要約を保存していつでも振り返り",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "07_meeting_history",
        mainImage: "07_meeting_history.jpg",
        overlayImage: nil,
        badge: "過去〜最新の会議を網羅",
        titleLine1: "1947年の第1回国会から",
        titleLine2: "最新の本会議・委員会まで",
        subtitle: "日付やキーワードから見たい会議をすぐに検索",
        isDarkTheme: false
    ),
    SlideSpec(
        id: "08_dark_mode",
        mainImage: "08_dark_mode.jpg",
        overlayImage: nil,
        badge: "ダークモード対応",
        titleLine1: "目に優しいダークモードで",
        titleLine2: "夜でも快適にじっくり読める",
        subtitle: "テーマ設定からいつでも切り替え可能",
        isDarkTheme: true
    )
]

let rawPhoneDir = "\(baseDir)/raw/phone"

func loadCGImage(_ path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func cropAppArea(_ cgImg: CGImage) -> CGImage? {
    let rect = CGRect(x: 0, y: 46, width: cgImg.width, height: 960 - 46)
    return cgImg.cropping(to: rect)
}

func drawCenteredText(
    _ text: String,
    fontName: String,
    fontSize: CGFloat,
    maxWidth: CGFloat? = nil,
    color: NSColor,
    yCenter: CGFloat,
    canvasWidth: CGFloat,
    in ctx: CGContext
) {
    var actualSize = fontSize
    var font = NSFont(name: fontName, size: actualSize) ?? NSFont.boldSystemFont(ofSize: actualSize)
    if let limit = maxWidth {
        while actualSize > 20.0 {
            let testSize = NSAttributedString(string: text, attributes: [.font: font]).size()
            if testSize.width <= limit { break }
            actualSize -= 2.0
            font = NSFont(name: fontName, size: actualSize) ?? NSFont.boldSystemFont(ofSize: actualSize)
        }
    }
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let size = attrStr.size()
    let rect = CGRect(
        x: (canvasWidth - size.width) / 2.0,
        y: yCenter - size.height / 2.0,
        width: size.width,
        height: size.height
    )
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    attrStr.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
}

func renderSlide(
    spec: SlideSpec,
    canvasWidth: Int,
    canvasHeight: Int,
    outPath: String
) {
    let w = CGFloat(canvasWidth)
    let h = CGFloat(canvasHeight)
    let scale = w / 1242.0

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: canvasWidth,
        height: canvasHeight,
        bitsPerComponent: 8,
        bytesPerRow: canvasWidth * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return }

    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let bgColors: [CGColor]
    if spec.isDarkTheme {
        bgColors = [
            NSColor(calibratedRed: 0.16, green: 0.10, blue: 0.28, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.16, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.09, alpha: 1.0).cgColor
        ]
    } else {
        bgColors = [
            NSColor(calibratedRed: 0.44, green: 0.22, blue: 0.88, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.54, green: 0.31, blue: 0.96, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.99, alpha: 1.0).cgColor
        ]
    }
    let locations: [CGFloat] = [0.0, 0.45, 1.0]
    if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: locations) {
        ctx.drawLinearGradient(
            grad,
            start: CGPoint(x: w * 0.5, y: h),
            end: CGPoint(x: w * 0.5, y: 0),
            options: []
        )
    }

    ctx.saveGState()
    let circleColor = spec.isDarkTheme
        ? NSColor(calibratedRed: 0.55, green: 0.32, blue: 1.0, alpha: 0.14).cgColor
        : NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.10).cgColor
    ctx.setFillColor(circleColor)
    ctx.fillEllipse(in: CGRect(x: -w * 0.2, y: h - w * 0.65, width: w * 0.75, height: w * 0.75))
    ctx.fillEllipse(in: CGRect(x: w * 0.55, y: h - w * 0.55, width: w * 0.65, height: w * 0.65))
    ctx.restoreGState()

    let isTall = (h / w) > 2.0
    let headerRatio: CGFloat = isTall ? 0.255 : 0.275
    let headerHeight = h * headerRatio
    let topEdge = h

    let badgeFontSize = (isTall ? 44.0 : 40.0) * scale
    let badgeFont = NSFont(name: "LINESeedJPApp_TTF-ExtraBold", size: badgeFontSize) ?? NSFont.boldSystemFont(ofSize: badgeFontSize)
    let badgeAttr = NSAttributedString(string: spec.badge, attributes: [.font: badgeFont])
    let badgeTextSize = badgeAttr.size()
    let pillW = badgeTextSize.width + 80.0 * scale
    let pillH = badgeTextSize.height + 28.0 * scale
    let pillY = topEdge - headerHeight * 0.20 - pillH / 2.0
    let pillRect = CGRect(x: (w - pillW) / 2.0, y: pillY, width: pillW, height: pillH)

    ctx.saveGState()
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillH / 2.0, cornerHeight: pillH / 2.0, transform: nil)
    if spec.isDarkTheme {
        ctx.setFillColor(NSColor(calibratedRed: 0.55, green: 0.32, blue: 1.0, alpha: 0.35).cgColor)
    } else {
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.95).cgColor)
    }
    ctx.addPath(pillPath)
    ctx.fillPath()
    ctx.restoreGState()

    let badgeTextColor = spec.isDarkTheme
        ? NSColor(calibratedRed: 0.92, green: 0.85, blue: 1.0, alpha: 1.0)
        : NSColor(calibratedRed: 0.42, green: 0.18, blue: 0.85, alpha: 1.0)
    drawCenteredText(
        spec.badge,
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: badgeFontSize,
        color: badgeTextColor,
        yCenter: pillRect.midY - 2.0 * scale,
        canvasWidth: w,
        in: ctx
    )

    let titleFontSize = (isTall ? 94.0 : 84.0) * scale
    let line1Y = topEdge - headerHeight * 0.45
    let line2Y = topEdge - headerHeight * 0.68

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -5.0 * scale),
        blur: 16.0 * scale,
        color: NSColor(calibratedWhite: 0.0, alpha: 0.25).cgColor
    )
    drawCenteredText(
        spec.titleLine1,
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: titleFontSize,
        maxWidth: w * 0.92,
        color: .white,
        yCenter: line1Y,
        canvasWidth: w,
        in: ctx
    )
    let line2Color = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.65, alpha: 1.0)
    drawCenteredText(
        spec.titleLine2,
        fontName: "LINESeedJPApp_TTF-ExtraBold",
        fontSize: titleFontSize,
        maxWidth: w * 0.92,
        color: line2Color,
        yCenter: line2Y,
        canvasWidth: w,
        in: ctx
    )
    ctx.restoreGState()

    let subFontSize = (isTall ? 45.0 : 42.0) * scale
    let subY = topEdge - headerHeight * 0.88
    drawCenteredText(
        spec.subtitle,
        fontName: "LINESeedJPApp_TTF-Bold",
        fontSize: subFontSize,
        maxWidth: w * 0.92,
        color: NSColor(calibratedWhite: 1.0, alpha: 0.95),
        yCenter: subY,
        canvasWidth: w,
        in: ctx
    )

    guard let rawCG = loadCGImage("\(rawPhoneDir)/\(spec.mainImage)"),
          let croppedCG = cropAppArea(rawCG) else { return }

    let imgAspect = CGFloat(croppedCG.width) / CGFloat(croppedCG.height)
    let bottomMargin = (isTall ? 75.0 : 52.0) * scale
    let availableH = h - headerHeight - bottomMargin - 16.0 * scale
    let maxScreenW = w * 0.84

    var screenH = availableH
    var screenW = screenH * imgAspect
    if screenW > maxScreenW {
        screenW = maxScreenW
        screenH = screenW / imgAspect
    }

    let screenX = (w - screenW) / 2.0
    let screenY = bottomMargin + (availableH - screenH) / 2.0
    let screenRect = CGRect(x: screenX, y: screenY, width: screenW, height: screenH)
    let cornerRadius = 44.0 * scale
    let bezelPad = 14.0 * scale
    let bezelRect = screenRect.insetBy(dx: -bezelPad, dy: -bezelPad)
    let bezelCorner = cornerRadius + bezelPad

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -18.0 * scale),
        blur: 45.0 * scale,
        color: NSColor(calibratedRed: 0.12, green: 0.04, blue: 0.28, alpha: 0.42).cgColor
    )
    let bezelPath = CGPath(roundedRect: bezelRect, cornerWidth: bezelCorner, cornerHeight: bezelCorner, transform: nil)
    if spec.isDarkTheme {
        ctx.setFillColor(NSColor(calibratedRed: 0.22, green: 0.20, blue: 0.28, alpha: 1.0).cgColor)
    } else {
        ctx.setFillColor(NSColor(calibratedWhite: 1.0, alpha: 0.95).cgColor)
    }
    ctx.addPath(bezelPath)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    let screenPath = CGPath(roundedRect: screenRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(screenPath)
    ctx.clip()
    ctx.draw(croppedCG, in: screenRect)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.setStrokeColor(NSColor(calibratedWhite: spec.isDarkTheme ? 1.0 : 0.0, alpha: 0.08).cgColor)
    ctx.setLineWidth(2.0 * scale)
    ctx.addPath(screenPath)
    ctx.strokePath()
    ctx.restoreGState()

    if let overlayName = spec.overlayImage,
       let overCG = loadCGImage("\(rawPhoneDir)/\(overlayName)") {
        let overAspect = CGFloat(overCG.width) / CGFloat(overCG.height)
        let overW = w * 0.90
        let overH = overW / overAspect
        let overX = (w - overW) / 2.0
        let overY = screenY - 18.0 * scale
        let overRect = CGRect(x: overX, y: overY, width: overW, height: overH)
        let overCorner = 28.0 * scale

        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -14.0 * scale),
            blur: 36.0 * scale,
            color: NSColor(calibratedRed: 0.08, green: 0.02, blue: 0.20, alpha: 0.55).cgColor
        )
        let overBgPath = CGPath(roundedRect: overRect, cornerWidth: overCorner, cornerHeight: overCorner, transform: nil)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.addPath(overBgPath)
        ctx.fillPath()
        ctx.restoreGState()

        ctx.saveGState()
        let overClipPath = CGPath(roundedRect: overRect, cornerWidth: overCorner, cornerHeight: overCorner, transform: nil)
        ctx.addPath(overClipPath)
        ctx.clip()
        ctx.draw(overCG, in: overRect)
        ctx.restoreGState()

        ctx.saveGState()
        ctx.setStrokeColor(NSColor(calibratedRed: 0.55, green: 0.32, blue: 1.0, alpha: 0.45).cgColor)
        ctx.setLineWidth(4.0 * scale)
        ctx.addPath(overClipPath)
        ctx.strokePath()
        ctx.restoreGState()
    }

    guard let outCG = ctx.makeImage() else { return }
    let bmpRep = NSBitmapImageRep(cgImage: outCG)
    if let pngData = bmpRep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outPath))
    }
}

let fm = FileManager.default
let iosDir = "\(baseDir)/ios_1242x2688"
let androidDir = "\(baseDir)/android_1080x1920"
try? fm.createDirectory(atPath: iosDir, withIntermediateDirectories: true)
try? fm.createDirectory(atPath: androidDir, withIntermediateDirectories: true)

for spec in slides {
    renderSlide(spec: spec, canvasWidth: 1242, canvasHeight: 2688, outPath: "\(iosDir)/\(spec.id).png")
    renderSlide(spec: spec, canvasWidth: 1080, canvasHeight: 1920, outPath: "\(androidDir)/\(spec.id).png")
    print("Generated phone \(spec.id)")
}
