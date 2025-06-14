import SwiftUI

struct PeriodInfoView: View {
    let startDate: Date?
    let duration: Int
    let daysSinceStart: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Period")
                        .font(.headline)
                    if let startDate = startDate {
                        Text(formattedDate(startDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(duration) days duration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No period recorded")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if duration > 0 {
                    VStack(alignment: .trailing) {
                        Text("\(daysSinceStart)")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("days since start")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 