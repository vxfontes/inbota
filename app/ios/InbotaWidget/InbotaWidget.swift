import SwiftUI
import WidgetKit

struct InbotaWidgetEntry: TimelineEntry {
    let date: Date
}

struct InbotaWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> InbotaWidgetEntry {
        InbotaWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (InbotaWidgetEntry) -> Void) {
        completion(InbotaWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InbotaWidgetEntry>) -> Void) {
        let now = Date()
        let entries = (0..<5).compactMap { hourOffset -> InbotaWidgetEntry? in
            guard let nextDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now) else {
                return nil
            }
            return InbotaWidgetEntry(date: nextDate)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct InbotaWidgetEntryView: View {
    var entry: InbotaWidgetTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inbota")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("Seu dia em ordem")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Text(entry.date, style: .time)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(14)
        .widgetContainerBackground(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.13, blue: 0.17), Color(red: 0.17, green: 0.32, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct InbotaWidget: Widget {
    let kind: String = "InbotaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InbotaWidgetTimelineProvider()) { entry in
            InbotaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Inbota")
        .description("Mostra um resumo rápido do seu dia.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground<Background: View>(_ background: Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }
}

struct InbotaWidget_Previews: PreviewProvider {
    static var previews: some View {
        InbotaWidgetEntryView(entry: InbotaWidgetEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
