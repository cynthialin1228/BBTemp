import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct HistoryView: View {
    @ObservedObject var viewModel: TemperatureViewModel
    @State private var selectedMonth: Date = Date()
    @State private var showingExportSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                            .font(.footnote)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
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
        }
        .navigationTitle("History")
        .background(Color(.systemGroupedBackground))
        .fileExporter(
            isPresented: $showingExportSheet,
            document: TemperaturePDFDocument(entries: viewModel.entries, months: getPastMonths()),
            contentType: .pdf,
            defaultFilename: "temperature_report.pdf"
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
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

struct TemperaturePDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    let entries: [TemperatureEntry]
    let months: [Date]
    
    init(entries: [TemperatureEntry], months: [Date]) {
        self.entries = entries
        self.months = months
    }
    
    init(configuration: ReadConfiguration) throws {
        entries = []
        months = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let pdfData = generatePDF()
        return FileWrapper(regularFileWithContents: pdfData)
    }
    
    private func generatePDF() -> Data {
        let pageWidth: CGFloat = 612  // US Letter width in points
        let pageHeight: CGFloat = 792 // US Letter height in points
        let margin: CGFloat = 50
        
        let pdfMetaData = [
            kCGPDFContextCreator: "BBTemp",
            kCGPDFContextAuthor: "BBTemp App",
            kCGPDFContextTitle: "Temperature Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Title
            let title = "Temperature Report"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(
                at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: margin),
                withAttributes: titleAttributes
            )
            
            // Date range
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateRange = "From \(dateFormatter.string(from: entries.last?.date ?? Date())) to \(dateFormatter.string(from: entries.first?.date ?? Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            let dateSize = dateRange.size(withAttributes: dateAttributes)
            dateRange.draw(
                at: CGPoint(x: (pageWidth - dateSize.width) / 2, y: margin + titleSize.height + 10),
                withAttributes: dateAttributes
            )
            
            // Data table
            var yPosition = margin + titleSize.height + 50
            let tableAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            
            // Table headers
            let headers = ["Date", "Temperature", "Period Day"]
            let columnWidths: [CGFloat] = [200, 150, 100]
            var xPosition = margin
            
            for (index, header) in headers.enumerated() {
                header.draw(
                    at: CGPoint(x: xPosition, y: yPosition),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)]
                )
                xPosition += columnWidths[index]
            }
            
            yPosition += 20
            
            // Table data
            let sortedEntries = entries.sorted { $0.date > $1.date }
            for entry in sortedEntries {
                if yPosition > pageHeight - margin {
                    context.beginPage()
                    yPosition = margin
                }
                
                xPosition = margin
                
                // Date
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                let dateString = dateFormatter.string(from: entry.date)
                dateString.draw(
                    at: CGPoint(x: xPosition, y: yPosition),
                    withAttributes: tableAttributes
                )
                xPosition += columnWidths[0]
                
                // Temperature
                let tempString = String(format: "%.2f°C", entry.temperature)
                tempString.draw(
                    at: CGPoint(x: xPosition, y: yPosition),
                    withAttributes: tableAttributes
                )
                xPosition += columnWidths[1]
                
                // Period Day
                let periodString = entry.isPeriodDay ? "Yes" : "No"
                periodString.draw(
                    at: CGPoint(x: xPosition, y: yPosition),
                    withAttributes: tableAttributes
                )
                
                yPosition += 20
            }
            
            // Add monthly charts
            for month in months {
                if yPosition > pageHeight - 300 {
                    context.beginPage()
                    yPosition = margin
                }
                
                // Month title
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMMM yyyy"
                let monthTitle = monthFormatter.string(from: month)
                monthTitle.draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)]
                )
                
                yPosition += 30
                
                // Create chart image on main thread
                let chartImage = DispatchQueue.main.sync {
                    let chartView = TemperatureChartView(
                        entries: entries.filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) },
                        startDate: startOfMonth(month),
                        endDate: endOfMonth(month),
                        isHistoryView: true,
                        showDates: true
                    )
                    .frame(width: pageWidth - 2 * margin, height: 200)
                    
                    let renderer = ImageRenderer(content: chartView)
                    return renderer.uiImage
                }
                
                if let image = chartImage {
                    let imageRect = CGRect(x: margin, y: yPosition, width: pageWidth - 2 * margin, height: 200)
                    image.draw(in: imageRect)
                }
                
                yPosition += 220
            }
        }
        
        return data
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
}

#Preview {
    NavigationView {
        HistoryView(viewModel: TemperatureViewModel())
    }
} 