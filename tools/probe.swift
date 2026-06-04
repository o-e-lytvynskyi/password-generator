import AppKit

let nsImg = NSImage(contentsOfFile: "Assets/AppIcon-raw.png")!
let cg = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let rep = NSBitmapImageRep(cgImage: cg)
let w = rep.pixelsWide, h = rep.pixelsHigh
let data = rep.bitmapData!
let bpr = rep.bytesPerRow, spp = rep.samplesPerPixel

func lum(_ x: Int, _ y: Int) -> Int {
    let p = data + y * bpr + x * spp
    return (Int(p[0]) + Int(p[1]) + Int(p[2])) / 3
}
print("size \(w)x\(h)")
let pts = [(5,5),(50,512),(150,512),(300,512),(400,512),(768,512),(5,512),(1530,512),(768,5),(768,1018)]
for (x,y) in pts { print("(\(x),\(y)) lum=\(lum(x,y))") }
// scan middle row luminance transitions
var prev = -1
for x in stride(from: 0, to: w, by: 1) {
    let l = lum(x, 512)
    let bucket = l > 26 ? 1 : 0
    if bucket != prev { print("x=\(x) lum=\(l) -> \(bucket == 1 ? "ON" : "off")"); prev = bucket }
}
