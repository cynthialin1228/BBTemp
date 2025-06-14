import SwiftUI

struct PeriodView: View {
    @ObservedObject var viewModel: TemperatureViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(getPeriodRanges(), id: \.start) { period in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(formatFullDate(period.start))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        TemperatureChartView(
                            entries: getEntriesForPeriod(period),
                            startDate: period.start,
                            endDate: period.end,
                            isHistoryView: true
                        )
                        .frame(height: 320)
                        .padding(.horizontal, 12)
                        
                        // Period information with icons
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Period Duration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(period.periodDays) days")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text("Cycle Length")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(period.totalDays) days")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Periods")
        .background(Color(.systemGroupedBackground))
    }
    
    private struct PeriodRange {
        let start: Date
        let end: Date
        let periodDays: Int
        let totalDays: Int
    }
    
    private func getPeriodRanges() -> [PeriodRange] {
        let calendar = Calendar.current
        let sortedEntries = viewModel.entries.sorted { $0.date < $1.date }
        var periods: [PeriodRange] = []
        var currentPeriodStart: Date?
        var currentPeriodDays: [Date] = []
        var lastDate: Date?
        var isInPeriod = false
        
        // Find all period ranges
        for entry in sortedEntries {
            if entry.isPeriodDay {
                if !isInPeriod {
                    // Start of a new period
                    currentPeriodStart = entry.date
                    currentPeriodDays = [entry.date]
                    isInPeriod = true
                } else {
                    // Continue current period
                    currentPeriodDays.append(entry.date)
                }
                lastDate = entry.date
            } else if isInPeriod {
                // Non-period day after a period
                if let start = currentPeriodStart {
                    // Add 5 days after the period end
                    let periodEnd = calendar.date(byAdding: .day, value: 5, to: entry.date) ?? entry.date
                    let totalDays = calendar.dateComponents([.day], from: start, to: periodEnd).day ?? 0
                    periods.append(PeriodRange(
                        start: start,
                        end: periodEnd,
                        periodDays: currentPeriodDays.count,
                        totalDays: totalDays + 1
                    ))
                }
                isInPeriod = false
                currentPeriodStart = nil
                currentPeriodDays = []
            }
        }
        
        // Add the last period if exists
        if isInPeriod, let start = currentPeriodStart, let end = lastDate {
            let periodEnd = calendar.date(byAdding: .day, value: 5, to: end) ?? end
            let totalDays = calendar.dateComponents([.day], from: start, to: periodEnd).day ?? 0
            periods.append(PeriodRange(
                start: start,
                end: periodEnd,
                periodDays: currentPeriodDays.count,
                totalDays: totalDays + 1
            ))
        }
        
        return periods.reversed() // Most recent periods first
    }
    
    private func getEntriesForPeriod(_ period: PeriodRange) -> [TemperatureEntry] {
        return viewModel.entries.filter { entry in
            entry.date >= period.start && entry.date <= period.end
        }
    }
    
    private func calculateAverageTemperature(for period: PeriodRange) -> Double? {
        let entries = getEntriesForPeriod(period)
        guard !entries.isEmpty else { return nil }
        let sum = entries.reduce(0.0) { $0 + $1.temperature }
        return sum / Double(entries.count)
    }
    
    private func formatDateRange(_ period: PeriodRange) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startDate = formatter.string(from: period.start)
        let endDate = formatter.string(from: period.end)
        return "\(startDate) - \(endDate)"
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        PeriodView(viewModel: TemperatureViewModel())
    }
} 