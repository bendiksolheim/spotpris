import Foundation

extension Result {
    func getOrDefault(_ def: Success) -> Success {
        switch self {
        case let .success(v):
            return v
        case .failure(_):
            return def
        }
    }
    
    func fold<R>(_ success: (Success) -> R, _ failure: (Failure) -> R) -> R {
        switch self {
        case let .success(v):
            return success(v)
        case let .failure(e):
            return failure(e)
        }
    }
}
