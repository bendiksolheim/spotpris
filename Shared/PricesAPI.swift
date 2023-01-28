import Foundation

private let apiDateFormat = DateFormatter(format: "yyyy-MM-dd")

func getPrices(area: Area, date: Date, completion: @escaping (Result<Data, Error>) -> Void) {
    let url = "https://stroempris-api.fly.dev/price/\(area)/\(apiDateFormat.string(from: date))"
    let headers = [
        "api-release-version": Bundle.main.releaseVersionNumber ?? "unknown",
        "api-build-version": Bundle.main.buildVersionNumber ?? "unknown",
    ]
    
    getData(url: url, headers: headers, completion: completion)
}

func getPricesJson(area: Area, date: Date, completion: @escaping (Result<APIPrices, Error>) -> Void) {
    getPrices(area: area, date: date) { res in
        let prices = res
            .flatMap { (r) -> Result<APIPrices, Error> in decode(data: r) }
        completion(prices)
    }
}

struct APIPrices: Decodable {
    let date: Date
    let pricesWithoutMva: [Double]
}

struct HourAndPrice: Identifiable {
    let hour: Date
    let price: Double
    
    var id: Date { hour }
}

extension DateFormatter {
    convenience init(format: String, locale: Locale = Locale.current) {
        self.init()
        self.dateFormat = format
        self.locale = locale
    }
}
