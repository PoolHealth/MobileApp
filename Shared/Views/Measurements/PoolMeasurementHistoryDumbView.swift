//
//  PoolMeasurementHistoryDumbView.swift
//  PoolHealth
//
//  Created by user on 07/01/2025.
//

import SwiftUI

struct PoolMeasurementHistoryDumbView: View {
    var measurements: ListOfMeasurements
    var onDelete: (_ createdAt: Date) -> Void
    var body: some View {
        ForEach(measurements.orderedKeys, id: \.self) { key in
            Section(header: Text(key).fontWeight(.bold)) {
                ForEach(measurements.data[key]!, id: \.createdAt) { el in
                      HStack{
                          Text(el.createdAt, format: .dateTime.minute().hour().day())
                          Spacer()
                          if let value = el.chlorine {
                              VStack{
                                  Text("Cl")
                                  Text(value, format: .number.precision(.fractionLength(2)))
                              }.foregroundStyle(.orange)
                          }
                          if let value = el.alkalinity {
                              VStack{
                                  Text("Alk")
                                  Text(value, format: .number.precision(.fractionLength(2)))
                              }.foregroundStyle(.blue)
                          }
                          if let value = el.ph {
                              VStack{
                                  Text("pH")
                                  Text(value, format: .number.precision(.fractionLength(2)))
                              }.foregroundStyle(.red)
                          }
                      }
                }.onDelete(perform: { indexSet in
                    guard let el = measurements.data[key] else {
                        return
                    }
                    
                    for index in indexSet {
                        Task{
                            onDelete(el[index].createdAt)
                        }
                    }
                })
            }
        }
    }
}

#Preview {
    let now = Date()
    func dateDaysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(TimeInterval(86400 * -days))
    }
    let data = [Measurement(createdAt: dateDaysAgo(900), chlorine: 100, ph: 100, alkalinity: 100),
   Measurement(createdAt: dateDaysAgo(899), chlorine: 200, ph: 200, alkalinity: 200),
   Measurement(createdAt: dateDaysAgo(890), chlorine: 100, ph: 100, alkalinity: 100),
   Measurement(createdAt: dateDaysAgo(500), chlorine: 200, ph: 200, alkalinity: 200),
   Measurement(createdAt: dateDaysAgo(499), chlorine: 100, ph: 100, alkalinity: 100),
   Measurement(createdAt: dateDaysAgo(498), chlorine: 200, ph: 200, alkalinity: 200),
   Measurement(createdAt: dateDaysAgo(490), chlorine: 100, ph: 100, alkalinity: 100),
   Measurement(createdAt: dateDaysAgo(300), chlorine: 200, ph: 200, alkalinity: 200),
   Measurement(createdAt: dateDaysAgo(200), chlorine: 100, ph: 100, alkalinity: 100),
   Measurement(createdAt: dateDaysAgo(100), chlorine: 200, ph: 200, alkalinity: 200),
   Measurement(createdAt: dateDaysAgo(50), chlorine: 100, ph: 100, alkalinity: 100)]
    
    return NavigationStack{
        List{
            PoolMeasurementHistoryDumbView(measurements: measurementsByMonth(measurements: data), onDelete: { createdAt in
                print(createdAt)
            })
        }
    }
}
