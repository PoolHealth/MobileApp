//
//  PoolAddingHistoryDumbView.swift
//  PoolHealth
//
//  Created by user on 09/01/2025.
//

import SwiftUI

struct PoolAddingHistoryDumbView: View {
    var chemicals: [Chemicalicals]
    var body: some View {
        List {
            ForEach(chemicals,id: \.createdAt) { el in
                Section(header:Text(el.createdAt, format: .dateTime.day().month().year().hour().minute()) ){
                    EnumValuesView(values: el.chlorineChemicals, units: ChlorineChemicalsUnits).foregroundStyle(.orange)
                    EnumValuesView(values: el.acidChemicals, units: AcidChemicalsUnits).foregroundStyle(.red)
                    EnumValuesView(values: el.alkalinityChemical, units: AlkalinityChemicalsUnits).foregroundStyle(.blue)
                }
            }
        }
    }
}

func prepareData() -> [Chemicalicals] {
    let now = Date()
    func dateDaysAgo(_ days: Double) -> Date {
        now.addingTimeInterval(TimeInterval(86400 * -days))
    }
    func dateMinutesAgo(_ minutes: Double) -> Date {
        now.addingTimeInterval(TimeInterval(60 * -minutes))
    }
    return [
        Chemicalicals(createdAt: dateDaysAgo(0), chlorineChemicals: [.dichlor65Percent: 1.1], acidChemicals: [.hydrochloricAcid:2.1], alkalinityChemical: [.sodiumBicarbonate:3.2]),
        Chemicalicals(createdAt: dateMinutesAgo(20), chlorineChemicals: [.dichlor65Percent: 1.1], acidChemicals: [.hydrochloricAcid:2.1], alkalinityChemical: [.sodiumBicarbonate:3.2]),
        Chemicalicals(createdAt: dateDaysAgo(19), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2]),
        Chemicalicals(createdAt: dateDaysAgo(18), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2, .sodiumHypochlorite12Percent: 3.3]),
        Chemicalicals(createdAt: dateDaysAgo(17), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2, .sodiumHypochlorite12Percent: 3.3, .sodiumHypochlorite14Percent: 4.4]),
        Chemicalicals(createdAt: dateDaysAgo(16), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2, .sodiumHypochlorite12Percent: 3.3, .sodiumHypochlorite14Percent: 4.4, .multiActionTablets: 6.6, .tCCA90PercentTablets: 7.7]),
        Chemicalicals(createdAt: dateDaysAgo(15), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2, .sodiumHypochlorite12Percent: 3.3, .sodiumHypochlorite14Percent: 4.4, .multiActionTablets: 6.6]),
        Chemicalicals(createdAt: dateDaysAgo(14), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2, .sodiumHypochlorite12Percent: 3.3, .sodiumHypochlorite14Percent: 4.4]),
        Chemicalicals(createdAt: Date(), chlorineChemicals: [.dichlor65Percent: 1.1, .calciumHypochlorite65Percent: 2.2, .sodiumHypochlorite12Percent: 3.3, .sodiumHypochlorite14Percent: 4.4,  .multiActionTablets: 6.6, .tCCA90PercentTablets: 7.7, .tCCA90PercentGranules: 8.8])
    ]
}

#Preview {
    PoolAddingHistoryDumbView(chemicals: prepareData())
}
