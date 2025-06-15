import SwiftUI
import Charts
import UniformTypeIdentifiers

struct TemperatureChartView: View {
    let entries: [TemperatureEntry]
    let startDate: Date
    let endDate: Date
    var isHistoryView: Bool = false
    var isPeriodPage: Bool = false
    var showDates: Bool = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            Chart {
                // Add background highlight for the target temperature range
                RectangleMark(
                    xStart: .value("Start", startDate),
                    xEnd: .value("End", endDate),
                    yStart: .value("Min", 36.65),
                    yEnd: .value("Max", 36.75)
                )
                .foregroundStyle(Color(.systemGray5).opacity(0.7))
                
                // Add today's vertical line
                if isTodayInRange() {
                    RuleMark(
                        x: .value("Today", Date())
                    )
                    .foregroundStyle(Color.black.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                
                ForEach(entries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Temperature", entry.temperature)
                    )
                    .foregroundStyle(
                        isPeriodPage ? Color.black : (isHistoryView ? (entry.isPeriodDay ? Color.red : Color.black) : Color.black)
                    )
                    
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Temperature", entry.temperature)
                    )
                    .foregroundStyle(
                        isPeriodPage ? Color.black : (isHistoryView ? (entry.isPeriodDay ? Color.red : Color.black) : Color.black)
                    )
                }
            }
            .chartYScale(domain: 35.75...37.5)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let temp = value.as(Double.self) {
                            Text(String(format: "%.2f°", temp))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                if isHistoryView || showDates {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                if showDates {
                                    VStack(spacing: 0) {
                                        Text(dayOfMonth(date))
                                            .font(.footnote)
                                            .foregroundColor(isToday(date) ? .black : .primary)
                                            .fontWeight(isToday(date) ? .bold : .regular)
                                        Text(shortMonth(date))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 40)
                                } else {
                                    Text(dayOfMonth(date))
                                        .font(.footnote)
                                        .foregroundColor(isToday(date) ? .black : .primary)
                                        .fontWeight(isToday(date) ? .bold : .regular)
                                        .frame(width: 24)
                                }
                            }
                        }
                    }
                } else {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                VStack(spacing: 2) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.systemGray6))
                                            .frame(width: 28, height: 20)
                                        Text(dayOfMonth(date))
                                            .font(.footnote)
                                            .foregroundColor(isToday(date) ? .black : .primary)
                                            .fontWeight(isToday(date) ? .bold : .regular)
                                    }
                                    if let entry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }), entry.isPeriodDay {
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.red)
                                            .padding(.top, 1)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func isTodayInRange() -> Bool {
        let today = Date()
        return today >= startDate && today <= endDate
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func monthAndYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func dayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func shortMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func customHistoryXAxisDates() -> [Date] {
        guard let first = entries.map({ $0.date }).min(), let last = entries.map({ $0.date }).max() else { return [] }
        var dates: [Date] = []
        var current = first
        while current < last {
            dates.append(current)
            if let next = calendar.date(byAdding: .day, value: 7, to: current) {
                current = next
            } else {
                break
            }
        }
        if !calendar.isDate(dates.last ?? Date.distantPast, inSameDayAs: last) {
            dates.append(last)
        }
        return dates
    }
    
    private func getLastThreeMonthsData() -> [TemperatureEntry] {
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        return entries.filter { $0.date >= threeMonthsAgo }
    }
}

struct TemperatureDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var entries: [TemperatureEntry]
    
    init(entries: [TemperatureEntry]) {
        self.entries = entries
    }
    
    init(configuration: ReadConfiguration) throws {
        entries = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let csvString = "Date,Temperature,Is Period Day\n" +
            entries.map { entry in
                "\(dateFormatter.string(from: entry.date)),\(entry.temperature),\(entry.isPeriodDay)"
            }.joined(separator: "\n")
        
        let data = Data(csvString.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
} 