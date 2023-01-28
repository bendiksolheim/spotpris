import Foundation

func getData(url: String, headers: [String: String] = [:], completion: @escaping (Result<Data, Error>) -> Void) {
    print("URL: \(url)")
    if let url = URL(string: url) {
        var request = URLRequest(url: url)
        headers.forEach { (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let urlSession = URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            
            if let data = data {
                completion(.success(data))
            }
        }
        
        urlSession.resume()
    }
}

func getJson<T: Decodable>(url: String, headers: [String: String] = [:], completion: @escaping (Result<T, Error>) -> Void) {
    getData(url: url) { (res: Result<Data, Error>) in
        completion(res.flatMap { data in decode(data: data) })
    }
}

func decode<T: Decodable>(data: Data) -> Result<T, Error> {
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = apiDateFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "")
        }
        let json = try decoder.decode(T.self, from: data)
        return .success(json)
    } catch {
        return .failure(error)
    }
}

private let apiDateFormatter = DateFormatter(format: "yyyy-MM-dd")
