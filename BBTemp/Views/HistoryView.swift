import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: TemperatureViewModel
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(getPastMonths(), id: \.self) { month in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatMonthTitle(month))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        TemperatureChartView(
                            entries: getEntriesForMonth(month),
                            startDate: startOfMonth(month),
                            endDate: endOfMonth(month),
                            isHistoryView: true
                        )
                        .frame(height: 320)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("History")
        .background(Color(.systemGroupedBackground))
    }
    
    private func getPastMonths() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var months: [Date] = []
        
        // Get the first entry date
        if let firstEntry = viewModel.entries.last {
            var currentDate = startOfMonth(firstEntry.date)
            
            // Add months until today
            while currentDate <= today {
                months.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return months.reversed()
    }
    
    private func getEntriesForMonth(_ month: Date) -> [TemperatureEntry] {
        let start = startOfMonth(month)
        let end = endOfMonth(month)
        return viewModel.entries.filter { entry in
            entry.date >= start && entry.date <= end
        }
    }
    
    private func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func endOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(month: 1, day: -1)
        return calendar.date(byAdding: components, to: startOfMonth(date)) ?? date
    }
    
    private func formatMonthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        HistoryView(viewModel: TemperatureViewModel())
    }
} 