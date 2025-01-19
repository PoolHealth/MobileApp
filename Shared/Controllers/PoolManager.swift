//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import Foundation
import os
import PoolHealthSchema

class PoolManager: ObservableObject {
    @Published var error: Error?
    @Published var poolsLoading = true
    @Published var pools: [Pool] = []
    @Published var lastMeasurmentLoading = false
    @Published var poolDetails: PoolDetails?
    @Published var measurementsLoading = false
    @Published var measurements: ListOfMeasurements = ListOfMeasurements(orderedKeys: [], data: [:])
    @Published var chemicalsLoading = false
    @Published var chemicals: [Chemicalicals] = []
    @Published var estimated: Measurement?
    let log = Logger(subsystem: "xax.PoolHealth", category: "PoolManager")
    
    func addPool(name: String, volume: Double) async {
        log.debug("name: \(name), volume: \(volume)")
        let result = await Network.shared.apollo.performAsync(mutation: AddPoolMutation(name: name, volume: volume))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            guard let id = graphQLResult.data?.addPool.id else { return }
            await MainActor.run {
                self.log.debug("new pool id \(id)")
                self.error = nil
            }
            await loadPools()
            
        case .failure(let error):
            print(error)
        }
    }
    
    func addMeasurement(poolID: String, chlorine: Double?, alkalinity: Double?, pH: Double?) async {
        let result = await Network.shared.apollo.performAsync(mutation: AddMeasurementMutation(poolID: poolID, chlorine: chlorine ?? nil, alkalinity: alkalinity ?? nil, ph: pH ?? nil))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            guard let createdAt = graphQLResult.data?.addMeasurement.createdAt else { return }
            await MainActor.run {
                self.log.debug("new measurement date \(createdAt)")
                self.error = nil
            }
            // TODO replace with loadMeasurements
            await loadMesurements(poolID: poolID)
            
        case .failure(let error):
            print(error)
        }
    }
    
    func addChemicals(poolID: String, chlorine: Dictionary<ChlorineChemicals,Double>?,acid: Dictionary<AcidChemicals,Double>?,alkalinity: Dictionary<AlkalinityChemicals,Double>?) async {
        
        let result = await Network.shared.apollo.performAsync(mutation: AddChemicalsMutation(input: ChemicalInput(poolID: poolID, chlorine: chlorine.graphQLValue(), acid: acid.graphQLValue(), alkalinity: alkalinity.graphQLValue())))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            guard let createdAt = graphQLResult.data?.addChemicals.createdAt else { return }
            await MainActor.run {
                self.log.debug("new addition chemicals date \(createdAt)")
                self.error = nil
            }
            // TODO replace with loadMeasurements
            await loadChemicals(poolID: poolID)
            
        case .failure(let error):
            print(error)
        }
    }
    
    func poolDetails(poolID:String) async {
        await MainActor.run {
            self.lastMeasurmentLoading = true
        }
        defer {
            Task {
                await MainActor.run {
                    self.lastMeasurmentLoading = false
                }
            }
        }
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: PoolDetailsQuery(poolID: poolID), cachePolicy: .fetchIgnoringCacheData) {
                guard let err = result.errors?.first else {
                    guard let data = result.data?.historyOfMeasurement else {
                        await MainActor.run {
                            self.poolDetails = nil
                        }
                        return
                    }
                    
                    if data.count == 0 {
                        await MainActor.run {
                            self.poolDetails = nil
                        }
                        
                        return
                    }
                    
                    guard let last = data.first else {
                        await MainActor.run {
                            self.poolDetails = nil
                        }
                        
                        return
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                    guard let date = dateFormatter.date(from:last.createdAt) else {
                        log.error("incorrect format of data \(last.createdAt)")
                        await MainActor.run {
                            self.poolDetails = nil
                        }
                        
                        return
                    }
                    
                    var details = PoolDetails(freeChlorine: last.measurement.chlorine, ph: last.measurement.ph, alkalinity: last.measurement.alkalinity, measurementsCreatedAt: date)
                    
                    if let demand = result.data?.demandMeasurement {
                        details.alkalinityChanges = demand.alkalinity
                        details.chlorineDemand = demand.chlorine
                        details.phChanges = demand.ph
                    }
                    
                    let theDetails = details
                    
                    await MainActor.run {
                        self.poolDetails = theDetails
                    }
                    
                    return
                }
                await MainActor.run {
                    self.poolDetails = nil
                    guard let code = err.extensions?["code"] as? Int else {
                        self.error = err
                        return
                    }
                    switch code {
                    case -1:
                            return
                    default:
                            self.error = err
                        return
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func loadMesurements(poolID:String) async {
        await MainActor.run {
            self.measurementsLoading = true
        }
        defer {
            Task {
                await MainActor.run {
                    self.measurementsLoading = false
                }
            }
        }
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: HistoryOfMeasurementQuery(poolID: poolID), cachePolicy: .fetchIgnoringCacheData) {
                guard let err = result.errors?.first else {
                    guard let data = result.data?.historyOfMeasurement else {
                        await MainActor.run {
                            self.measurements = ListOfMeasurements(orderedKeys: [], data: [:])
                        }
                        return
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                    
                    await MainActor.run {
                        do {
                            var tmp: [Measurement]
                            try tmp = data.map({ el in
                                guard let date = dateFormatter.date(from:el.createdAt) else {
                                    log.error("incorrect format of data \(el.createdAt)")
                                    
                                    throw MatchingMeasurementError.invalidateDateFormat
                                }
                                return Measurement(createdAt: date, chlorine: el.measurement.chlorine, ph: el.measurement.ph, alkalinity: el.measurement.alkalinity)
                            })
                            
                            self.measurements = measurementsByMonth(measurements: tmp)
                        } catch {
                            self.error = error
                        }   
                    }
                    
                    return
                }
                await MainActor.run {
                    self.poolDetails = nil
                    guard let code = err.extensions?["code"] as? Int else {
                        self.error = err
                        return
                    }
                    switch code {
                    case -1:
                            return
                    default:
                            self.error = err
                        return
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func loadChemicals(poolID:String) async {
        await MainActor.run {
            self.chemicalsLoading = true
        }
        defer {
            Task {
                await MainActor.run {
                    self.chemicalsLoading = false
                }
            }
        }
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: HistoryOfAdditivesQuery(poolID: poolID), cachePolicy: .fetchIgnoringCacheData) {
                guard let err = result.errors?.first else {
                    guard let data = result.data?.historyOfAdditives else {
                        await MainActor.run {
                            self.chemicals = []
                        }
                        return
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    
                    await MainActor.run {
                        do {
                            try self.chemicals = data.map({ el in
                                guard let date = dateFormatter.date(from:el.createdAt) else {
                                    log.error("incorrect format of data \(el.createdAt)")
                                    
                                    throw MatchingMeasurementError.invalidateDateFormat
                                }
                                
                                var chemicals = Chemicalicals(createdAt: date)
                                
                                var chlorineChemicals: Dictionary<ChlorineChemicals, Double> = [:]
                                var acidChemicals: Dictionary<AcidChemicals, Double> = [:]
                                var alkalinityChemicals: Dictionary<AlkalinityChemicals, Double> = [:]
                                
                                for val in el.value {
                                    if let ch = val.asChlorineChemicalValue {
                                        let type = try ch.chlorineType.mapToModel()
                                        chlorineChemicals[type] = ch.value
                                    }
                                    
                                    if let ch = val.asAcidChemicalValue {
                                        let type = try ch.acidType.mapToModel()
                                        acidChemicals[type] = ch.value
                                    }
                                    
                                    if let ch = val.asAlkalinityChemicalValue {
                                        let type = try ch.alkalinityType.mapToModel()
                                        alkalinityChemicals[type] = ch.value
                                    }
                                }
                                
                                chemicals.chlorineChemicals = chlorineChemicals
                                chemicals.acidChemicals = acidChemicals
                                chemicals.alkalinityChemical = alkalinityChemicals
                                
                                return chemicals
                            })
                        } catch {
                            self.error = error
                        }
                    }
                    
                    return
                }
                await MainActor.run {
                    guard let code = err.extensions?["code"] as? Int else {
                        self.error = err
                        return
                    }
                    switch code {
                    case -1:
                            return
                    default:
                            self.error = err
                        return
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func estimateMeasurement(poolID: String, chlorine: Dictionary<ChlorineChemicals,Double>?,acid: Dictionary<AcidChemicals,Double>?,alkalinity: Dictionary<AlkalinityChemicals,Double>?) async {
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: EstimateMeasurementQuery(poolID: poolID, chlorine: chlorine.graphQLValue(), acid: acid.graphQLValue(), alkalinity: alkalinity.graphQLValue())) {
                
                guard let err = result.errors?.first else {
                    guard let data = result.data else {
                        await MainActor.run {
                            self.estimated = nil
                        }
                        return
                    }
                    
                    await MainActor.run {
                        self.error = nil
                        self.estimated = Measurement(createdAt: Date())
                        if let chlorine = data.estimateMeasurement.chlorine {
                            self.estimated?.chlorine = chlorine
                        }
                        
                        if let ph = data.estimateMeasurement.ph {
                            self.estimated?.ph = ph
                        }
                        
                        if let alkalinity = data.estimateMeasurement.alkalinity {
                            self.estimated?.alkalinity = alkalinity
                        }
                    }
                    
                    return
                }
                await MainActor.run {
                    self.estimated = nil
                    guard let code = err.extensions?["code"] as? Int else {
                        self.error = err
                        return
                    }
                    switch code {
                    case -1:
                            return
                    default:
                            self.error = err
                        return
                    }
                }
                
            }
        
        } catch {
            await MainActor.run {
                self.estimated = nil
                self.error = error
            }
        }
    }
    
    func loadPools() async {
        await MainActor.run {
            self.poolsLoading = true
        }
        defer {
            Task {
                await MainActor.run {
                    self.poolsLoading = false
                }
            }
        }
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: ListQuery(), cachePolicy: .fetchIgnoringCacheData) {
                await MainActor.run {
                    guard let err = result.errors?.first else {
                        guard let pools = result.data?.pools else {
                            return
                        }
                        
                        self.pools = pools.map({ el in
                            Pool(id: el.id, name: el.name, volume: el.volume, settings: el.settings.toModel())
                        })
                        
                        return
                    }
                    guard let code = err.extensions?["code"] as? Int else {
                        self.error = err
                        return
                    }
                    switch code {
                    case -1:
                            return
                    default:
                            self.error = err
                        return
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func setSettings(id: String, settings: PoolSettings) async {
        log.debug("latitude \(settings.coordinates.latitude), longtitude \(settings.coordinates.longitude)")
        let result = await Network.shared.apollo.performAsync(mutation: AddSettingsMutation(poolID: id, settings: settings.toGql()))
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print(errors)
                    return
                }
                await MainActor.run {
                    self.log.debug("settings updated")
                    self.error = nil
                }
                await loadPools()
                
            case .failure(let error):
                await MainActor.run {
                    self.error = error
                }
            }
    }
        
}




enum MatchingMeasurementError: Error {
    case invalidateDateFormat
    case invalidInput
}


enum InputErrors: Error {
    case invalidInput
}


extension InputErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return NSLocalizedString("Invalid input", comment: "ch or alk or pH is nil")
        }
    }
}

struct ListOfMeasurements {
    var orderedKeys:[String]
    var data: [String:[Measurement]]
}

func measurementsByMonth(measurements:[Measurement]) -> ListOfMeasurements {
    guard !measurements.isEmpty else { return ListOfMeasurements(orderedKeys: [], data: [:]) }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM y"
    var result = [String:[Measurement]]()
    var orderedKeys:[String] = []
    for measurement in measurements {
        let k = formatter.string(from: measurement.createdAt)
        print(k)
        guard let el = result[k] else {
            result[k] = [measurement]
            orderedKeys.append(k)
            continue
        }
        result[k] =  el + [measurement]
    }
    
    return ListOfMeasurements(orderedKeys: orderedKeys, data: result)
}

extension GraphQLEnum<ChlorineChemical> {
    func mapToModel() throws -> ChlorineChemicals {
        switch self {
        case .calciumHypochlorite65Percent:
            return ChlorineChemicals.calciumHypochlorite65Percent
        case .dichlor65Percent:
            return ChlorineChemicals.dichlor65Percent
        case .multiActionTablets:
            return ChlorineChemicals.multiActionTablets
        case .sodiumHypochlorite12Percent:
            return ChlorineChemicals.sodiumHypochlorite12Percent
        case .sodiumHypochlorite14Percent:
            return ChlorineChemicals.sodiumHypochlorite14Percent
        case .tCCA90PercentTablets:
            return ChlorineChemicals.tCCA90PercentTablets
        case .tCCA90PercentGranules:
            return ChlorineChemicals.tCCA90PercentGranules
        case .case(_):
            throw UnknownChemicals.chlorine
        case .unknown(_):
            throw UnknownChemicals.chlorine
        }
    }
}

extension GraphQLEnum<AcidChemical> {
    func mapToModel() throws -> AcidChemicals {
        switch self {
        case .hydrochloricAcid:
            return AcidChemicals.hydrochloricAcid
        case .sodiumBisulphate:
            return AcidChemicals.sodiumBisulphate
        case .case(_):
            throw UnknownChemicals.acid
        case .unknown(_):
            throw UnknownChemicals.acid
        }
    }
}

extension GraphQLEnum<AlkalinityChemical> {
    func mapToModel() throws -> AlkalinityChemicals {
        switch self {
        case .sodiumBicarbonate:
            return AlkalinityChemicals.sodiumBicarbonate
        case .case(_):
            throw UnknownChemicals.alkalinity
        case .unknown(_):
            throw UnknownChemicals.alkalinity
        }
    }
}

extension ChlorineChemicals {
    func graphQLValue() -> GraphQLEnum<ChlorineChemical> {
        var ch: ChlorineChemical
        switch self {
        case .calciumHypochlorite65Percent:
            ch = ChlorineChemical.calciumHypochlorite65Percent
        case .sodiumHypochlorite14Percent:
            ch = ChlorineChemical.sodiumHypochlorite14Percent
        case .sodiumHypochlorite12Percent:
            ch = ChlorineChemical.sodiumHypochlorite12Percent
        case .dichlor65Percent:
            ch = ChlorineChemical.dichlor65Percent
        case .multiActionTablets:
            ch = ChlorineChemical.multiActionTablets
        case .tCCA90PercentTablets:
            ch = ChlorineChemical.tCCA90PercentTablets
        case .tCCA90PercentGranules:
            ch = ChlorineChemical.tCCA90PercentGranules
        }
        
        return GraphQLEnum(ch)
    }
}

extension AcidChemicals {
    func graphQLValue() -> GraphQLEnum<AcidChemical> {
        var ac: AcidChemical
        switch self {
        case .sodiumBisulphate:
            ac = AcidChemical.sodiumBisulphate
        case .hydrochloricAcid:
            ac = AcidChemical.hydrochloricAcid
        }
        
        return GraphQLEnum(ac)
    }
}

extension AlkalinityChemicals {
    func graphQLValue() -> GraphQLEnum<AlkalinityChemical> {
        var al: AlkalinityChemical
        switch self {
        case .sodiumBicarbonate:
            al = AlkalinityChemical.sodiumBicarbonate
        }
        
        return GraphQLEnum(al)
    }
}

extension Dictionary<ChlorineChemicals,Double>? {
    func graphQLValue() -> GraphQLNullable<[ChlorineChemicalValueInput]> {
        let chlorineInput = self?.map({el in
            return ChlorineChemicalValueInput(
                type: el.key.graphQLValue(),
                value: el.value
            )
        })
        
        return (chlorineInput == nil || chlorineInput!.isEmpty) ? GraphQLNullable.none : GraphQLNullable.some(chlorineInput!)
    }
}

extension Dictionary<AcidChemicals,Double>? {
    func graphQLValue() -> GraphQLNullable<[AcidChemicalValueInput]> {
        let input = self?.map({el in
            return AcidChemicalValueInput(
                type: el.key.graphQLValue(),
                value: el.value
            )
        })
        
        return (input == nil || input!.isEmpty) ? GraphQLNullable.none : GraphQLNullable.some(input!)
    }
}

extension Dictionary<AlkalinityChemicals,Double>? {
    func graphQLValue() -> GraphQLNullable<[AlkalinityChemicalValueInput]> {
        let input = self?.map({el in
            return AlkalinityChemicalValueInput(
                type: el.key.graphQLValue(),
                value: el.value
            )
        })
        
        return (input == nil || input!.isEmpty) ? GraphQLNullable.none : GraphQLNullable.some(input!)
    }
}
