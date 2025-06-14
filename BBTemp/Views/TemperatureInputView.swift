import SwiftUI

struct TemperatureInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TemperatureViewModel
    @State private var temperature: Double = 36.5
    @State private var isPeriodDay: Bool = false
    @State private var selectedDate = Date()
    
    private let temperatureRange = stride(from: 35.0, through: 38.0, by: 0.05)
    
    var isEditing: Bool {
        viewModel.getEntryForDate(selectedDate) != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        // Title
                        Text(isEditing ? "Edit Temperature" : "Add Temperature")
                            .font(.title2).fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        
                        // Date Picker
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            DatePicker(
                                "Date",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .labelsHidden()
                            .onChange(of: selectedDate) { newDate in
                                if let existingEntry = viewModel.getEntryForDate(newDate) {
                                    temperature = existingEntry.temperature
                                    isPeriodDay = existingEntry.isPeriodDay
                                } else {
                                    temperature = 36.5
                                    isPeriodDay = false
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        
                        // Temperature Input
                        HStack(spacing: 12) {
                            Image(systemName: "thermometer")
                                .foregroundColor(.orange)
                            Picker("Temperature", selection: $temperature) {
                                ForEach(Array(temperatureRange), id: \.self) { temp in
                                    Text(String(format: "%.2f°C", temp))
                                        .tag(temp)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        
                        // Period Day Toggle
                        HStack(spacing: 12) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.red)
                            Toggle("Period Day", isOn: $isPeriodDay)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            viewModel.addEntry(
                                date: selectedDate,
                                temperature: temperature,
                                isPeriodDay: isPeriodDay
                            )
                            dismiss()
                        }) {
                            Text(isEditing ? "Update" : "Save")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        if isEditing {
                            Divider().padding(.horizontal, 8)
                            Button(role: .destructive) {
                                viewModel.deleteEntry(for: selectedDate)
                                dismiss()
                            } label: {
                                Label("Delete Entry", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let existingEntry = viewModel.getEntryForDate(selectedDate) {
                    temperature = existingEntry.temperature
                    isPeriodDay = existingEntry.isPeriodDay
                } else {
                    temperature = 36.5
                    isPeriodDay = false
                }
            }
        }
    }
} 