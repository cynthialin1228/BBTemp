import Foundation

struct TemperatureEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let temperature: Double
    let isPeriodDay: Bool
    
    init(id: UUID = UUID(), date: Date = Date(), temperature: Double, isPeriodDay: Bool) {
        self.id = id
        self.date = date
        self.temperature = temperature
        self.isPeriodDay = isPeriodDay
    }
} 