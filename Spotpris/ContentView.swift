import SwiftUI
import Charts

struct ContentView: View {
    @AppStorage("area") var area: Area = .NO1
    @AppStorage("includeMva") var includeMva: Bool = false
    @State var date: Date = Date()
    @State var data: RemoteData<[HourAndPrice]> = .Initial
    @State var selectedHour: Date?
    @State var selectionPrice: Double?
    
    init(providedData: RemoteData<[HourAndPrice]> = .Initial) {
        data = providedData
    }
    
    var body: some View {
        VStack() {
            VStack() {
                Text("\(titleDateFormat.string(from: date))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.largeTitle)
                    .foregroundColor(Colors.cultured)
                if let selectedHour = selectedHour, let selectionPrice = selectionPrice {
                    Text("\(hourFormat.string(from: selectedHour)) - \(hourFormat.string(from: selectedHour.addingTimeInterval(60*60)))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 1)
                        .foregroundColor(Colors.cultured)
                    Text("\(formatPrice(selectionPrice * (includeMva ? 1.25 : 1.0)))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Colors.cultured)
                }
            }
            .padding(.leading, 16)
            PriceData()
            HStack {
                Text("Område")
                    .foregroundColor(Colors.cultured)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Menu {
                    ForEach(Area.allCases, id: \.self) { a in
                        Button {
                            area = a
                            loadPrices(a)
                        } label: {
                            Text(a.rawValue)
                        }
                    }
                } label: {
                    Text(area.rawValue)
                        .foregroundColor(.white)
                        .padding(
                            EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Colors.frenchRose)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }.padding(16)
            HStack {
                Text("Inkluder agifter")
                    .foregroundColor(Colors.cultured)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("Inkluder avgifter", isOn: $includeMva)
                    .tint(Colors.frenchRose)
                    .labelsHidden()
            }.padding(.leading, 16)
                .padding(.trailing, 16)
        }.onAppear(perform: { loadPrices(area) })
            .background(Colors.policeBlue)
    }
    
    @ViewBuilder
    func PriceData() -> some View {
        switch data {
        case .Initial:
            showProgress()
        case let .Failure(e):
            showError(e)
        case let .Success(v):
            showSuccess(v)
        }
    }
    
    func showProgress() -> some View {
        return VStack {
            ProgressView()
        }.frame(maxHeight: .infinity)
    }
    
    func showError(_ error: Error) -> some View {
        return VStack {
            VStack {
                Text("Klarte ikke å hente strømprisene")
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.020, green: 0.01, blue: 0.04))
                Text("Vi har en teknisk utfordring, og klarer ikke å hente dagens strømpriser.")
                    .padding(.top, 2)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.53))
                Text("(Trykk på meg for å forsøke igjen!)")
                    .padding(.top, 5)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.53))
            }
            .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
            .background(Capsule().fill(Color(red: 0.95, green: 0.95, blue: 0.98)))
            .onTapGesture {
                data = .Initial
                // Add a little fake timeout so the spinner shows
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    loadPrices(area)
                }
            }
        }.frame(maxHeight: .infinity)
    }
    
    func showSuccess(_ prices: [HourAndPrice]) -> some View {
        let multiplier = includeMva ? 1.25 : 1.0
        return Chart {
            if let hour = selectedHour ?? date {
                RuleMark(
                    x: .value("Valgt time", hour),
                    yStart: .value("Strømpris", 0),
                    yEnd: .value("Strømpris", (selectionPrice ?? 0) * multiplier)
                )
                    .foregroundStyle(Colors.frenchRose)
            }
            ForEach(prices) { hour in
                LineMark(
                    x: .value("Time", hour.hour),
                    y: .value("Strømpris", hour.price * multiplier)
                ).interpolationMethod(.stepEnd)
                    .foregroundStyle(Colors.seaSerpent)
                AreaMark(
                    x: .value("Time", hour.hour),
                    y: .value("Strømpris", hour.price * multiplier)
                ).opacity(0.5)
                   .interpolationMethod(.stepEnd)
                    .foregroundStyle(gradient)
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
                    .foregroundStyle(Colors.cultured)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture()
                        .onChanged { value in
                            updateSelectedHour(at: value.location, prices: prices, proxy: proxy, geometry: geometry)
                        }
                        .onEnded { _ in
                            let now = Date()
                            selectedHour = now
                            selectionPrice = prices.filter { $0.hour <= now }.last?.price
                        }
                    )
            }
        }.onAppear {
            let now = Date()
            selectedHour = now
            selectionPrice = prices.filter { $0.hour <= now }.last?.price
        }
    }
    
    func loadPrices(_ area: Area) {
        data = .Initial
        PricesService.get(for: area, date: date) { res in
            data = res.fold(
                { .Success($0) },
                { .Failure($0) }
            )
        }
    }
    
    func updateSelectedHour(at location: CGPoint, prices: [HourAndPrice], proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition: Double = location.x - geometry[proxy.plotAreaFrame].origin.x
        guard let hour: Date = proxy.value(atX: xPosition) else {
            return
        }
        let price = prices.filter { $0.hour <= hour }.last?.price
        selectedHour = hour
        selectionPrice = price
    }
}

let gradient = LinearGradient(colors: [Colors.seaSerpent, .white.opacity(0)], startPoint: .top, endPoint: .bottom)

private let titleDateFormat = DateFormatter(format: "dd. MMMM yyyy", locale: Locale(identifier: "no"))
private let hourFormat = DateFormatter(format: "HH")

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(providedData: .Failure("Error"))
    }
}

enum RemoteData<T> {
    case Initial
    case Failure(Error)
    case Success(T)
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

func formatPrice(_ price: Double) -> String {
    if price < 1 {
        return "\(String(format: "%0.0f", round(price * 100))) øre/kWh"
    } else {
        return String(format: "%0.2f", price) + " NOK/kWh"
    }
}
