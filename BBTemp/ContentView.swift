//
//  ContentView.swift
//  BBTemp
//
//  Created by Cynthia on 2025/6/14.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TemperatureViewModel()
    @State private var showingInputSheet = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(dateRangeText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TemperatureChartView(
                            entries: viewModel.getEntriesForCurrentRange(),
                            startDate: viewModel.visibleDateRange.start,
                            endDate: viewModel.visibleDateRange.end
                        )
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.width
                                    updateDateRange(for: value.translation.width)
                                }
                                .onEnded { _ in
                                    lastDragValue = 0
                                }
                        )
                    }
                    
                    let periodInfo = viewModel.getLastPeriodInfo()
                    PeriodInfoView(
                        startDate: periodInfo.startDate,
                        duration: periodInfo.duration,
                        daysSinceStart: periodInfo.daysSinceStart
                    )
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                viewModel.updateVisibleRange(by: -7)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            showingInputSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                viewModel.updateVisibleRange(by: 7)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                        .padding()
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Basal Body Temperature")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: PeriodView(viewModel: viewModel)) {
                            Image(systemName: "drop.fill")
                                .font(.title3)
                        }
                        
                        NavigationLink(destination: HistoryView(viewModel: viewModel)) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingInputSheet) {
                TemperatureInputView(viewModel: viewModel)
        }
        }
    }
    
    private func updateDateRange(for dragValue: CGFloat) {
        let dragThreshold: CGFloat = 20 // Adjust this value to control sensitivity
        let dragDifference = dragValue - lastDragValue
        
        if abs(dragDifference) >= dragThreshold {
            let daysToMove = Int(dragDifference / dragThreshold)
            viewModel.updateVisibleRange(by: -daysToMove)
            lastDragValue = dragValue
        }
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let startDate = formatter.string(from: viewModel.visibleDateRange.start)
        let endDate = formatter.string(from: viewModel.visibleDateRange.end)
        return "\(startDate) - \(endDate)"
    }
}

#Preview {
    ContentView()
}
