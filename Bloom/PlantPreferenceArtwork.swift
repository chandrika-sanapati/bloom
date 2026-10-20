import SwiftUI

/// Small code-drawn illustrations remain sharp at large text sizes.
struct PlantFormArtwork: View {
    let form: PlantFormPreference
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 100, sy = size.height / 100
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
            func stem(_ coordinates: [(CGFloat, CGFloat)]) {
                var path = Path(); path.move(to: point(coordinates[0].0, coordinates[0].1))
                for value in coordinates.dropFirst() { path.addLine(to: point(value.0, value.1)) }
                context.stroke(path, with: .color(BloomTheme.teal.opacity(0.65)), style: StrokeStyle(lineWidth: 2 * sx, lineCap: .round, lineJoin: .round))
            }
            func leaf(_ x: CGFloat, _ y: CGFloat, _ angle: Double, _ tall: Bool = false) {
                var leafContext = context
                leafContext.translateBy(x: x * sx, y: y * sy); leafContext.rotate(by: .degrees(angle))
                let rect = CGRect(x: -8 * sx, y: tall ? -24 * sy : -6 * sy, width: 16 * sx, height: tall ? 48 * sy : 12 * sy)
                leafContext.fill(Path(ellipseIn: rect), with: .color(BloomTheme.teal.opacity(tall ? 0.85 : 0.75)))
                leafContext.stroke(Path { $0.move(to: CGPoint(x: 0, y: rect.minY + 4 * sy)); $0.addLine(to: CGPoint(x: 0, y: rect.maxY - 4 * sy)) }, with: .color(.white.opacity(0.3)), lineWidth: sx)
            }
            let potY: CGFloat = form == .trailing ? 23 : 76
            if form == .trailing {
                stem([(33, 22), (50, 1), (67, 22)])
                stem([(43, 35), (31, 45), (32, 64), (20, 83)])
                stem([(54, 34), (66, 49), (58, 68), (69, 88)])
                for v: (CGFloat, CGFloat, Double) in [(31,48,-30),(34,63,35),(24,77,-35),(65,48,35),(58,66,-30),(67,81,30)] { leaf(v.0, v.1, v.2) }
                leaf(42, 22, -35); leaf(55, 19, 35)
            } else if form == .upright {
                leaf(37, 48, -17, true); leaf(51, 39, 0, true); leaf(65, 50, 17, true)
            } else if form == .bushy {
                stem([(50, 79), (50, 40), (33, 26)]); stem([(50, 64), (25, 47)]); stem([(50, 57), (71, 31)]); stem([(50, 72), (76, 56)])
                for v: (CGFloat, CGFloat, Double) in [(31,25,-35),(24,45,-25),(49,32,0),(70,30,35),(76,54,30),(37,56,-30),(62,49,30)] { leaf(v.0, v.1, v.2) }
            } else {
                var support = Path(); support.move(to: point(55, 8)); support.addLine(to: point(55, 81))
                context.stroke(support, with: .color(.brown.opacity(0.45)), lineWidth: 4 * sx)
                stem([(45,80),(45,65),(59,53),(47,40),(59,23),(52,10)])
                for v: (CGFloat, CGFloat, Double) in [(35,64,-30),(67,52,30),(37,39,-30),(67,22,30),(45,13,-20)] { leaf(v.0, v.1, v.2) }
            }
            var pot = Path(); pot.move(to: point(32, potY)); pot.addLine(to: point(68, potY)); pot.addLine(to: point(62, potY + 22)); pot.addLine(to: point(38, potY + 22)); pot.closeSubpath()
            context.fill(pot, with: .color(BloomTone.yellow.accent.opacity(0.8)))
            context.fill(Path(roundedRect: CGRect(x: 29*sx, y: (potY-2)*sy, width: 42*sx, height: 6*sy), cornerRadius: 2*sx), with: .color(BloomTone.yellow.ink.opacity(0.35)))
        }.accessibilityHidden(true)
    }
}

struct IndoorLightArtwork: View {
    let light: IndoorSearchLight
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(light == .bright ? BloomTone.yellow.surface : BloomTone.blue.surface)
            RoundedRectangle(cornerRadius: 4).stroke(BloomTheme.teal.opacity(0.4), lineWidth: 2).frame(width: 39, height: 44).offset(x: -10, y: -3)
            Rectangle().fill(BloomTheme.teal.opacity(0.3)).frame(width: 2, height: 44).offset(x: -10, y: -3)
            Rectangle().fill(BloomTheme.teal.opacity(0.3)).frame(width: 39, height: 2).offset(x: -10, y: -3)
            if light == .bright {
                Image(systemName: "sun.max.fill").foregroundStyle(BloomTone.yellow.ink).font(.title3).offset(x: 17, y: -18)
            } else if light == .lower {
                RoundedRectangle(cornerRadius: 3).fill(BloomTone.blue.accent.opacity(0.35)).frame(width: 23, height: 48).offset(x: -20, y: -3)
            } else {
                Image(systemName: "questionmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(BloomTheme.teal, .white).font(.title2).offset(x: 20, y: -18)
            }
            PlantFormArtwork(form: .upright).frame(width: 40, height: 40).offset(x: 17, y: 18)
        }.frame(width: 80, height: 80).accessibilityHidden(true)
    }
}
