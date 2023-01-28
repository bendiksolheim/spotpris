import WidgetKit
import SwiftUI
import Intents
import Charts

struct PricesProvider: IntentTimelineProvider {
    
    func placeholder(in context: Context) -> PricesEntry {
        return PricesEntry(date: Date(), prices: example, configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (PricesEntry) -> Void) {
        let entry = PricesEntry(date: Date(), prices: example, configuration: ConfigurationIntent())
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<PricesEntry>) -> Void) {
        let area = getArea(from: configuration)
        let now = Date()
        getPricesJson(area: area, date: now) { (result: Result<APIPrices, Error>) in
            let prices = result.getOrDefault(APIPrices(date: Date(), pricesWithoutMva: []))
            let calendar = Calendar.current
            let startHour = now.startOfHour()
            let hour = calendar.component(.hour, from: startHour)
            let entries = (hour..<24).map { hour in
                return PricesEntry(date: calendar.date(bySetting: .hour, value: hour, of: startHour)!, prices: prices.pricesWithoutMva, configuration: configuration)
            }
            
            let refetchPolicy: Date = result.fold(
                { _ in
                    var tomorrow = DateComponents()
                    tomorrow.day = 1
                    return calendar.date(byAdding: tomorrow, to: calendar.startOfDay(for: now))!
                },
                { _ in Date().addingTimeInterval(15 * 60) }
            )
            let timeline = Timeline(entries: entries, policy: .after(refetchPolicy))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct PricesEntry: TimelineEntry {
    var date: Date
    let prices: [Double]
    let configuration: ConfigurationIntent
}

let widgetBackground = Colors.policeBlue
let graphForeground = Colors.seaSerpent

let gradient = LinearGradient(colors: [Colors.seaSerpent.opacity(0.5), .white.opacity(0)], startPoint: .top, endPoint: .bottom)

struct StroemWidgetView: View {
    var entry: PricesProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            lockscreenView()
        default:
            homescreenView()
        }
    }
    
    func homescreenView() -> some View {
        VStack {
            if let hour = Calendar.current.component(.hour, from: entry.date) {
                Text(formatHomescreenPrice(entry.prices[hour] * getMvaMultiplier(from: entry.configuration)))
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.top)
            }
            Chart {
                ForEach(Array(entry.prices.enumerated()), id: \.offset) { index, price in
                    LineMark(x: .value("Hour", index), y: .value("Price", price))
                        .foregroundStyle(graphForeground)
                    AreaMark(x: .value("Hour", index), y: .value("Price", price))
                        .foregroundStyle(gradient)
                }
                
                if let hour = Calendar.current.component(.hour, from: entry.date) {
                    PointMark(x: .value("Hour", hour), y: .value("Price", entry.prices[hour]))
                        .symbolSize(CGSize(width: 10, height: 10))
                        .foregroundStyle(widgetBackground)
                        .accessibilityLabel("Now")
                    
                    PointMark(x: .value("Hour", hour), y: .value("Price", entry.prices[hour]))
                        .symbolSize(CGSize(width: 4, height: 4))
                        .foregroundStyle(Colors.frenchRose)
                        .accessibilityLabel("Now")
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
        }
        .overlay(alignment: .bottom, content: {
            Text(getArea(from: entry.configuration).rawValue)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        })
        .background(widgetBackground)
    }
    
    func lockscreenView() -> some View {
        HStack {
            Chart {
                ForEach(Array(entry.prices.enumerated()), id: \.offset) { index, price in
                    LineMark(x: .value("Hour", index), y: .value("Price", price))
                        .foregroundStyle(graphForeground)
                    AreaMark(x: .value("Hour", index), y: .value("Price", price))
                        .foregroundStyle(gradient)
                }
                
                if let hour = Calendar.current.component(.hour, from: entry.date) {
                    PointMark(x: .value("Hour", hour), y: .value("Price", entry.prices[hour]))
                        .symbolSize(CGSize(width: 8, height: 8))
                        .foregroundStyle(graphForeground)
                        .accessibilityLabel("Now")
                    
                    PointMark(x: .value("Hour", hour), y: .value("Price", entry.prices[hour]))
                        .symbolSize(CGSize(width: 4, height: 4))
                        .foregroundStyle(.black)
                        .accessibilityLabel("Now")
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            .overlay(alignment: .bottom, content: {
                if let hour = Calendar.current.component(.hour, from: entry.date) {
                    Text(formatHomescreenPrice(entry.prices[hour] * getMvaMultiplier(from: entry.configuration)))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                }
            })
        }
    }
}

func formatHomescreenPrice(_ price: Double) -> String {
    if price < 1 {
        return "\(String(format: "%0.0f", round(price * 100))) øre/kWh"
    } else {
        return String(format: "%0.2f", price) + " NOK/kWh"
    }
}

struct SpotprisWidget: Widget {
    let kind: String = "SpotprisWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: PricesProvider()) { entry in
            StroemWidgetView(entry: entry)
        }
        .configurationDisplayName("Spotpris")
        .description("Viser strømprisen i ditt område")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct SpotprisWidget_Previews: PreviewProvider {
    static var previews: some View {
        StroemWidgetView(entry: PricesEntry(date: Date(), prices: example, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

func getArea(from configuration: ConfigurationIntent) -> Area {
    switch configuration.Area {
    case .unknown:
        return .NO1
    case .nO1:
        return .NO1
    case .nO2:
        return .NO2
    case .nO3:
        return .NO3
    case .nO4:
        return .NO4
    case .nO5:
        return .NO5
    }
}

func getMvaMultiplier(from configuration: ConfigurationIntent) -> Double {
    if let mva = configuration.WithMVA {
        if mva == 0 {
            return 1.0
        } else {
            return 1.25
        }
    } else {
        return 1.0
    }
}

let example = [0.77077,0.75037,0.75187,0.75628,0.76433,0.78355,0.81738,0.9748,1.06317,1.07767,1.0534,1.0113,0.99047,0.97748,0.87171,0.89286,0.91606,1.04051,1.033,0.97791,0.91209,0.84862,0.84916,0.83026]
