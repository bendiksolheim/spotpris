import Foundation

private let apiDateFormat = DateFormatter(format: "yyyy-MM-dd")

func getPrices(area: Area, date: Date, completion: @escaping (Result<Data, Error>) -> Void) {
    let url = "https://stroempris-apii.fly.dev/price/\(area)/\(apiDateFormat.string(from: date))"
    let headers = [
        "api-release-version": Bundle.main.releaseVersionNumber ?? "unknown",
        "api-build-version": Bundle.main.buildVersionNumber ?? "unknown",
        "api-key": apiKey
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

let apiKey = "b1e5014f-277c-4d93-b9f3-e45b32579d99"

extension DateFormatter {
    convenience init(format: String, locale: Locale = Locale.current) {
        self.init()
        self.dateFormat = format
        self.locale = locale
    }
}
