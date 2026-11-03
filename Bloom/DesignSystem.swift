import SwiftUI
#if os(iOS)
import UIKit
#endif

private struct ReturnToPlantsKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct PresentPlantAddKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var presentPlantAdd: () -> Void {
        get { self[PresentPlantAddKey.self] }
        set { self[PresentPlantAddKey.self] = newValue }
    }
    var returnToPlants: () -> Void {
        get { self[ReturnToPlantsKey.self] }
        set { self[ReturnToPlantsKey.self] = newValue }
    }
}

enum BloomTone: Equatable {
    case teal, blue, yellow, neutral
    var surface: Color { switch self { case .teal: BloomTheme.selected; case .blue: Color("BlueSurface"); case .yellow: Color("YellowSurface"); case .neutral: Color(uiColor: .secondarySystemFill) } }
    var ink: Color { switch self { case .teal: BloomTheme.teal; case .blue: Color("BlueInk"); case .yellow: Color("YellowInk"); case .neutral: BloomTheme.secondary } }
    var accent: Color { switch self { case .teal: BloomTheme.teal; case .blue: Color("BlueAccent"); case .yellow: Color("YellowAccent"); case .neutral: BloomTheme.secondary } }
}

enum BloomTheme {
    static let teal = Color("ActionPrimary")
    static let pressed = Color("ActionPressed")
    static let ink = Color("TextPrimary")
    static let secondary = Color("TextSecondary")
    static let card = Color("SurfaceCard")
    static let selected = Color("SurfaceSelected")
    static let border = Color("BorderSeparator")
    static let canvas = card
    static let surface = Color.white
    static let cardRadius: CGFloat = 16
    static let tagRadius: CGFloat = 8
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.86)
    static let heading = Font.system(.title2).weight(.bold)
    static let section = Font.system(.body).weight(.semibold)
}

/// Home and shared card layouts use an 8-point spacing rhythm.
enum BloomSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

/// Four semantic roles, all scaled by the user's Dynamic Type setting.
enum BloomType {
    static let title = BloomTheme.heading
    static let section = BloomTheme.section
    static let body = Font.body
    static let supporting = Font.footnote
}

@MainActor enum BloomFeedback {
    static func selection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

struct BloomPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : BloomTheme.spring, value: configuration.isPressed)
    }
}

/// Interface symbols share a scaled square and weight; compact is for inline indicators.
struct BloomSymbol: View {
    let name: String
    var compact = false
    @ScaledMetric(relativeTo: .body) private var edge = 24
    var body: some View {
        Image(systemName: name)
            .font(.system(size: edge * (compact ? 0.55 : 0.75), weight: .semibold))
            .frame(width: edge * (compact ? 2.0 / 3.0 : 1), height: edge * (compact ? 2.0 / 3.0 : 1))
            .accessibilityHidden(true)
    }
}

struct BloomLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .body) private var edge = 24
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: edge * 0.75, weight: .semibold))
                .frame(width: edge, height: edge).accessibilityHidden(true)
            configuration.title
        }
    }
}

struct BloomActionLabel: View {
    let title: String
    var body: some View {
        Text(title).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
    }
}

struct BloomMark: View {
    var body: some View {
        Image(systemName: "leaf.fill").font(.title3.weight(.medium))
            .foregroundStyle(.white).frame(width: 40, height: 40)
            .background(BloomTheme.teal, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct BloomIconTile: View {
    let symbol: String
    var emphasized = false
    var tone: BloomTone = .teal
    @ScaledMetric(relativeTo: .body) private var size = 40
    var body: some View {
        BloomSymbol(name: symbol)
            .foregroundStyle(emphasized && tone != .yellow ? .white : tone.ink)
            .frame(width: size, height: size)
            .background(emphasized ? tone.accent : tone.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct BloomPanel: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
    }
}

extension View {
    func bloomHeading(_ font: Font = BloomTheme.section) -> some View {
        self.font(font).foregroundStyle(BloomTheme.ink).accessibilityAddTraits(.isHeader)
    }
    func bloomCard(padding: CGFloat = 18) -> some View { modifier(BloomPanel(padding: padding)) }
    func bloomFooter<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom) {
            content().padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 10).background(BloomTheme.canvas)
        }
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text).font(BloomType.body).foregroundStyle(BloomTheme.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct InfoCard: View {
    let title: String
    var message: String? = nil
    var icon = "leaf"
    var tone: BloomTone = .teal
    var body: some View {
        HStack(alignment: .top, spacing: BloomSpacing.medium) {
            BloomIconTile(symbol: icon, tone: tone)
            VStack(alignment: .leading, spacing: BloomSpacing.small) {
                Text(title).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                if let message, !message.isEmpty {
                    Text(message).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }.bloomCard(padding: 16)
    }
}

struct PlantPortrait: View {
    var plant: Plant
    var contentMode: ContentMode = .fill
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let data = plant.photo, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
                } else if !plant.asset.isEmpty {
                    Image(plant.asset).resizable().aspectRatio(contentMode: contentMode)
                } else if plant.species == "Epipremnum aureum" {
                    Image("pothos").resizable().aspectRatio(contentMode: contentMode)
                } else {
                    ZStack {
                        BloomTheme.selected
                        VStack(spacing: 8) {
                            BloomSymbol(name: "camera").foregroundStyle(BloomTheme.secondary)
                            if geometry.size.width >= 120 && geometry.size.height >= 100 {
                                Text("Add a plant photo").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                            }
                        }.padding(12)
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height).clipped()
        }.contentShape(Rectangle()).accessibilityHidden(true)
    }
}

struct StatusTag: View {
    let text: String
    var symbol: String? = nil
    var tone: BloomTone = .teal
    var body: some View {
        HStack(spacing: 4) {
            if let symbol { BloomSymbol(name: symbol, compact: true) }
            Text(text)
        }.font(BloomType.supporting.weight(.semibold)).foregroundStyle(tone.ink)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(tone.surface, in: RoundedRectangle(cornerRadius: BloomTheme.tagRadius, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct BloomSectionHeader: View {
    let title: String
    var detail: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title).bloomHeading()
            if let detail { Text(detail).font(BloomType.body).foregroundStyle(BloomTheme.secondary) }
            Spacer(minLength: 0)
        }
    }
}

struct BloomPlantCard: View {
    let plant: Plant
    let status: String
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlantPortrait(plant: plant, contentMode: typeSize.isAccessibilitySize ? .fit : .fill)
                .frame(height: typeSize.isAccessibilitySize ? 224 : 128)
            VStack(alignment: .leading, spacing: BloomSpacing.small) {
                Text(plant.displayName).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(plant.location.isEmpty ? "Location not set" : plant.location).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(BloomSpacing.medium)
        }.background(BloomTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityValue(status == "Not checked yet" ? "No soil check recorded" : "Last soil check: \(status)")
    }
}

struct RecordRow: View {
    let record: CareRecord
    let plantName: String
    @Environment(\.dynamicTypeSize) private var typeSize
    private var tone: BloomTone { record.kind == .check ? .blue : record.kind == .change ? .yellow : .teal }
    private var tag: String {
        switch record.kind { case .check: "Soil check"; case .change: "Observation"; case .followUp: "Check-in"; case .careAction: "Care action" }
    }
    private var showsTypeTag: Bool { record.kind == .change || record.kind == .careAction }
    var body: some View {
        VStack(alignment: .leading, spacing: BloomSpacing.small) {
            HStack(alignment: .center, spacing: BloomSpacing.small) {
                VStack(alignment: .leading, spacing: BloomSpacing.small) {
                    Text(record.title).font(BloomType.section).foregroundStyle(BloomTheme.ink).fixedSize(horizontal: false, vertical: true)
                    Text("\(plantName) · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !typeSize.isAccessibilitySize && showsTypeTag { StatusTag(text: tag, tone: tone) }
            }
            if typeSize.isAccessibilitySize && showsTypeTag { StatusTag(text: tag, tone: tone) }
        }.accessibilityElement(children: .combine)
    }
}

struct BloomReminderRow: View {
    let plant: Plant
    @Environment(\.dynamicTypeSize) private var typeSize
    private var kind: PlantReminderKind { plant.reminderKind ?? .soilCheck }
    private var tone: BloomTone { kind == .soilCheck ? .blue : .yellow }
    var body: some View {
        VStack(alignment: .leading, spacing: BloomSpacing.small) {
            HStack(alignment: .center, spacing: BloomSpacing.small) {
                VStack(alignment: .leading, spacing: BloomSpacing.small) {
                    Text(kind == .soilCheck ? "Check soil" : "Compare observation").font(BloomType.section)
                    Text(plant.displayName + (plant.reminder.map { " · " + $0.formatted(date: .abbreviated, time: .omitted) } ?? ""))
                        .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !typeSize.isAccessibilitySize {
                    StatusTag(text: kind == .soilCheck ? "Soil check" : "Observation", tone: tone)
                    BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                }
            }
            if typeSize.isAccessibilitySize {
                HStack(alignment: .center, spacing: BloomSpacing.small) {
                    StatusTag(text: kind == .soilCheck ? "Soil check" : "Observation", tone: tone)
                    Spacer(minLength: BloomSpacing.small)
                    BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                }
            }
        }.padding(BloomSpacing.medium).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))

    }
}
