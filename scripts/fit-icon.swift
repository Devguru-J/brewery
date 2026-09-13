// 사용법: swift scripts/fit-icon.swift <입력 png> <출력 1024 png>
// 검정 배경 위의 둥근 사각형 아이콘을 찾아 바깥을 투명하게 자르고 macOS 표준 여백(1024 중 824)에 맞춰 놓는다.
import AppKit

let input = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
let src = NSImage(contentsOfFile: input)!
let cg = src.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let w = cg.width, h = cg.height

// 픽셀 읽기
let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
let px = ctx.data!.bindMemory(to: UInt8.self, capacity: w * h * 4)

// 밝은 픽셀(배경 아닌 것)의 경계 상자. 글로우를 제외하도록 문턱값을 넉넉히 둔다.
func bright(_ x: Int, _ y: Int) -> Bool {
    let i = (y * w + x) * 4
    let l = Int(px[i]) + Int(px[i + 1]) + Int(px[i + 2])
    return l > 110
}
// 도형은 정사각형이므로 가운데 행에서 좌우 경계, 가운데 열에서 상하 경계를 잰다(직선 변이라 정확).
// 배경(검정)과 도형 경계는 밝기 차가 크다. 문턱값을 넘는 첫/마지막 픽셀을 찾는다.
func lum(_ x: Int, _ y: Int) -> Int { let i = (y * w + x) * 4; return Int(px[i]) + Int(px[i + 1]) + Int(px[i + 2]) }
let th = 90
let my = h / 2, mx = w / 2
var minX = 0, maxX = w - 1, minY = 0, maxY = h - 1
while minX < w && lum(minX, my) < th { minX += 1 }
while maxX > 0 && lum(maxX, my) < th { maxX -= 1 }
while minY < h && lum(mx, minY) < th { minY += 1 }
while maxY > 0 && lum(mx, maxY) < th { maxY -= 1 }
let side = max(maxX - minX, maxY - minY) + 1
let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
let crop = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
print("bounds:", crop)

// CGContext는 원점이 아래. crop은 위쪽 기준 좌표계로 계산됐으므로 뒤집는다.
let cropCG = CGRect(x: crop.minX, y: CGFloat(h) - crop.maxY, width: crop.width, height: crop.height)
let cropped = cg.cropping(to: cropCG)!

let canvas: CGFloat = 1024
let shape: CGFloat = 824          // Apple 템플릿 기준 아이콘 도형 크기
let inset = (canvas - shape) / 2
let out = NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { _ in
    let rect = CGRect(x: inset, y: inset, width: shape, height: shape)
    let path = NSBezierPath(roundedRect: rect, xRadius: shape * 0.2237, yRadius: shape * 0.2237)
    path.addClip()
    NSGraphicsContext.current!.cgContext.draw(cropped, in: rect)
    return true
}
let rep = NSBitmapImageRep(data: out.tiffRepresentation!)!
rep.size = NSSize(width: canvas, height: canvas)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
