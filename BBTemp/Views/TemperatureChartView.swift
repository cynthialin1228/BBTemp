import SwiftUI
import Charts

struct TemperatureChartView: View {
    let entries: [TemperatureEntry]
    let startDate: Date
    let endDate: Date
    var isHistoryView: Bool = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        Chart {
            // Add background highlight for the target temperature range
            RectangleMark(
                xStart: .value("Start", startDate),
                xEnd: .value("End", endDate),
                yStart: .value("Min", 36.65),
                yEnd: .value("Max", 36.75)
            )
            .foregroundStyle(Color.yellow.opacity(0.2))
            
            // Add today's vertical line
            if isTodayInRange() {
                RuleMark(
                    x: .value("Today", Date())
                )
                .foregroundStyle(Color.blue.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Temperature", entry.temperature)
                )
                .foregroundStyle(isHistoryView && entry.isPeriodDay ? Color.pink : Color.blue)
                
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Temperature", entry.temperature)
                )
                .foregroundStyle(isHistoryView && entry.isPeriodDay ? Color.pink : Color.blue)
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
            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 28, height: 20)
                            Text(dayOfMonth(date))
                                .font(.footnote)
                                .foregroundColor(isToday(date) ? .blue : .primary)
                                .fontWeight(isToday(date) ? .bold : .regular)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .frame(height: 300)
        .padding()
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
} 