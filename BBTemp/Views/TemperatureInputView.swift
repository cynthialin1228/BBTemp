import SwiftUI

struct TemperatureInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TemperatureViewModel
    @State private var temperature: String = ""
    @State private var isPeriodDay: Bool = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .onChange(of: selectedDate) { newDate in
                        if let existingEntry = viewModel.getEntryForDate(newDate) {
                            temperature = String(format: "%.1f", existingEntry.temperature)
                            isPeriodDay = existingEntry.isPeriodDay
                        } else {
                            temperature = ""
                            isPeriodDay = false
                        }
                    }
                }
                
                Section(header: Text("Temperature")) {
                    TextField("Temperature (°C)", text: $temperature)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Toggle("Period Day", isOn: $isPeriodDay)
                }
                
                Section {
                    Button(viewModel.getEntryForDate(selectedDate) != nil ? "Update" : "Save") {
                        if let temp = Double(temperature) {
                            viewModel.addEntry(
                                date: selectedDate,
                                temperature: temp,
                                isPeriodDay: isPeriodDay
                            )
                            dismiss()
                        }
                    }
                    .disabled(temperature.isEmpty)
                }
            }
            .navigationTitle(viewModel.getEntryForDate(selectedDate) != nil ? "Edit Temperature" : "Add Temperature")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                if let existingEntry = viewModel.getEntryForDate(selectedDate) {
                    temperature = String(format: "%.1f", existingEntry.temperature)
                    isPeriodDay = existingEntry.isPeriodDay
                }
            }
        }
    }
} 