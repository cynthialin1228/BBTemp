import Foundation
import SwiftUI

@MainActor
class TemperatureViewModel: ObservableObject {
    @Published var entries: [TemperatureEntry] = []
    @Published var visibleDateRange: (start: Date, end: Date)
    private let saveKey = "temperatureEntries"
    private let calendar = Calendar.current
    private let defaultDaysToShow = 8
    
    init() {
        // Initialize with the last 10 days
        let today = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let startDate = calendar.date(byAdding: .day, value: -(defaultDaysToShow - 1), to: tomorrow) ?? tomorrow
        visibleDateRange = (startDate, tomorrow)
        loadData()
    }
    
    func addEntry(date: Date, temperature: Double, isPeriodDay: Bool) {
        // Remove any existing entry for this date
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        
        // Add the new entry
        let entry = TemperatureEntry(date: date, temperature: temperature, isPeriodDay: isPeriodDay)
        entries.append(entry)
        // Sort entries by date
        entries.sort { $0.date > $1.date }
        saveData()
        
        // Force UI update
        objectWillChange.send()
    }
    
    func getEntryForDate(_ date: Date) -> TemperatureEntry? {
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getEntriesForCurrentRange() -> [TemperatureEntry] {
        return entries.filter { entry in
            entry.date >= visibleDateRange.start && entry.date <= visibleDateRange.end
        }
    }
    
    func updateVisibleRange(by days: Int) {
        let newStart = calendar.date(byAdding: .day, value: days, to: visibleDateRange.start) ?? visibleDateRange.start
        let newEnd = calendar.date(byAdding: .day, value: days, to: visibleDateRange.end) ?? visibleDateRange.end
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? calendar.startOfDay(for: Date())
        // If newEnd is after tomorrow, clamp to tomorrow and adjust start
        if newEnd > tomorrow {
            let adjustedStart = calendar.date(byAdding: .day, value: -(defaultDaysToShow - 1), to: tomorrow) ?? tomorrow
            visibleDateRange = (adjustedStart, tomorrow)
            return
        }
        visibleDateRange = (newStart, newEnd)
    }
    
    func getLastPeriodInfo() -> (startDate: Date?, duration: Int, daysSinceStart: Int) {
        let sortedEntries = entries.sorted { $0.date < $1.date } // Sort by date ascending
        var periodDays: [Date] = []
        var currentPeriodStart: Date?
        var lastDate: Date?
        
        // Find the most recent consecutive period days
        for entry in sortedEntries.reversed() {
            if entry.isPeriodDay {
                if lastDate == nil {
                    // First period day found
                    currentPeriodStart = entry.date
                    periodDays.append(entry.date)
                } else if calendar.isDate(entry.date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: lastDate!)!) {
                    // Consecutive day
                    currentPeriodStart = entry.date
                    periodDays.append(entry.date)
                } else {
                    // Non-consecutive day, start new period
                    periodDays = [entry.date]
                    currentPeriodStart = entry.date
                }
                lastDate = entry.date
            } else {
                if lastDate != nil {
                    // Found a non-period day after period days
                    break
                }
            }
        }
        
        guard let startDate = currentPeriodStart else {
            return (nil, 0, 0)
        }
        
        let today = Date()
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        
        return (startDate, periodDays.count, daysSinceStart)
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TemperatureEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    
    func getEntriesForLastMonth() -> [TemperatureEntry] {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.date >= oneMonthAgo }
    }
    
    func deleteEntry(for date: Date) {
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        saveData()
        objectWillChange.send()
    }
} 