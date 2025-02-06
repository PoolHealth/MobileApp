//
//  PoolAddChemicalsView.swift
//  PoolHealth
//
//  Created by user on 09/01/2025.
//

import SwiftUI

struct PoolAddChemicalsView: View {
    var poolID: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var manager: PoolManager
    @ObservedObject var measureManager: MeasureManager
    @State var chlorineChemical: ChlorineChemicals?
    @State var chlorineValue: Double?
    @State var acidChemical: AcidChemicals?
    @State var acidValue: Double?
    @State var alkalinityChemical: AlkalinityChemicals?
    @State var alkalinityValue: Double?
    var body: some View {
        VStack{
            if let estimated = measureManager.estimated {
                if let chlorine = estimated.chlorine {
                    HStack{
                        Text("Estimated Chlorine:")
                        Text(chlorine, format: .number.precision(.fractionLength(2)))
                    }
                }
                if let ph = estimated.ph {
                    HStack{
                        Text("Estimated PH:")
                        Text(ph, format: .number.precision(.fractionLength(2)))
                    }
                }
                if let alkalinity = estimated.alkalinity {
                    HStack{
                        Text("Estimated Alkalinity:")
                        Text(alkalinity, format: .number.precision(.fractionLength(2)))
                    }
                }
            }
            Spacer()
            
            AddChemicalForm<ChlorineChemicals>(title: "Chlorine chemicals", options: ChlorineChemicals.allCases, recommendedValue: recommend(), key: $chlorineChemical, value: $chlorineValue){
                Task{
                    await estimate()
                    await measureManager.loadRecommendation(poolID: poolID)
                }
            }
            
            AddChemicalForm<AcidChemicals>(title: "Acid chemicals",options: AcidChemicals.allCases, key: $acidChemical, value: $acidValue){
                Task{
                    await estimate()
                }
            }
            
            AddChemicalForm<AlkalinityChemicals>(title: "Alkalinity chemicals",options: AlkalinityChemicals.allCases, key: $alkalinityChemical, value: $alkalinityValue){
                Task{
                    await estimate()
                }
            }
            
            Spacer()
            Button("Add") {
                Task {
                    if let value = chlorineValue, let key = chlorineChemical {
                        await manager.addChemicals(poolID: poolID, chlorine: [key: value], acid: nil, alkalinity: nil)
                    }
                    
                    if let value = acidValue, let key = acidChemical {
                        await manager.addChemicals(poolID: poolID, chlorine: nil, acid: [key: value], alkalinity: nil)
                    }
                    
                    if let value = alkalinityValue, let key = alkalinityChemical {
                        await manager.addChemicals(poolID: poolID, chlorine: nil, acid: nil, alkalinity: [key: value])
                    }
                    if manager.error == nil {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }.disabled(
                (chlorineChemical == nil || chlorineValue == nil) &&
                (acidChemical == nil || acidValue == nil) &&
                (alkalinityChemical == nil || alkalinityValue == nil)
            )
            Spacer()
        }.navigationBarTitle("Add chemicals").padding(.horizontal, 20).onAppear{
            Task{
                await estimate()
            }
        }
    }
    
    private func recommend() -> Double? {
        guard let ch = chlorineChemical else {
            return nil
        }
        
        guard let recMap = measureManager.recommendation else {
            return nil
        }
        
        guard let value = recMap[ch] else {
            return nil
        }
        
        return value > 0 ? value : nil
    }
    
    private func estimate() async {
        var isValid: Bool = false
        var chlorine: Dictionary<ChlorineChemicals, Double>?
        if let value = chlorineValue, let key = chlorineChemical {
            chlorine = [key:value]
            
            isValid = true
        }
        
        var acid: Dictionary<AcidChemicals, Double>?
        if let value = acidValue, let key = acidChemical {
            acid = [key:value]
            
            isValid = true
        }
        
        var alkalinity: Dictionary<AlkalinityChemicals, Double>?
        if let value = alkalinityValue, let key = alkalinityChemical {
            alkalinity = [key:value]
            
            isValid = true
        }
        
        if isValid {
            await measureManager.estimateMeasurement(poolID: poolID, chlorine: chlorine, acid: acid, alkalinity: alkalinity)
        } else {
            measureManager.estimated = nil
        }
        
    }
}

#Preview {
    NavigationStack {
        PoolAddChemicalsView(poolID: UUID().uuidString, manager: PoolManager(), measureManager: MeasureManager())
    }
}
