import Foundation

extension Date {
    func startOfHour() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components)!
    }
}
