import Foundation

class PricesService {
    static func get(for area: Area, date: Date, completion: @escaping (Result<[HourAndPrice], Error>) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "\(dateFormatter.string(from: date))-\(area.rawValue)"
        let saved: Result<APIPrices, Error> = Files
            .read(filename: filename)
            .flatMap { decode(data: $0) }
        
        if case let .success(json) = saved {
            completion(.success(apiPricesToHourAndPrice(json)))
        } else {
            getPrices(area: area, date: date, completion: { res in
                let prices = res
                    .flatMap {
                        let _ = Files.store(filename: filename, contents: $0)
                        return decode(data: $0)
                    }
                    .map { apiPricesToHourAndPrice($0) }
                completion(prices)
            })
            
        }
    }
}

private func apiPricesToHourAndPrice(_ prices: APIPrices) -> [HourAndPrice] {
    var mappedPrices = prices.pricesWithoutMva.enumerated().map { price in
        let hour = prices.date.addingTimeInterval(60 * 60 * Double(price.offset))
        return HourAndPrice(hour: hour, price: price.element)
    }
    if let lastHour = mappedPrices.last {
        // Create a "fake" extra hour to display last hour correctly in graph
        mappedPrices.append(HourAndPrice(hour: lastHour.hour.addingTimeInterval(60 * 60), price: lastHour.price))
    }
    return mappedPrices
}
