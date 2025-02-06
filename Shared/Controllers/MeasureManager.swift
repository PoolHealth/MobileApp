//
//  MeasureManager.swift
//  PoolHealth
//
//  Created by user on 26/01/2025.
//

import Foundation
import os
import PoolHealthSchema

class MeasureManager: ObservableObject {
    @Published var error: Error?
    @Published var lastMeasurmentLoading = false
    @Published var poolDetails: PoolDetails?
    @Published var measurementsLoading = false
    @Published var measurements: ListOfMeasurements = ListOfMeasurements(orderedKeys: [], data: [:])
    @Published var estimated: Measurement?
    @Published var recommendation: Dictionary<ChlorineChemicals, Double>?
    @Published var actions: [Action] = []
    let log = Logger(subsystem: "xax.PoolHealth", category: "MeasureManager")
    
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
            
            // refresh current measurements
            await loadMesurements(poolID: poolID)
            
        case .failure(let error):
            print(error)
        }
    }
    
    func deleteMeasurement(poolID: String, createdAt: Foundation.Date) async {
        let result = await Network.shared.apollo.performAsync(mutation: DeleteMeasurementsMutation(poolID: poolID, createdAt: createdAt.ISO8601Format()))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            await MainActor.run {
                self.error = nil
            }
            // TODO replace with loadMeasurements
            await loadMesurements(poolID: poolID)
            
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
                    
                    guard let date = try parseDate(last.createdAt) else {
                        log.error("incorrect format of data \(last.createdAt)")
                        
                        await MainActor.run {
                            self.poolDetails = nil
                        }
                        
                        throw MatchingMeasurementError.invalidateDateFormat
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
                    
                    await MainActor.run {
                        do {
                            var tmp: [Measurement]
                            try tmp = data.map({ el in
                                guard let date = try parseDate(el.createdAt) else {
                                    log.error("incorrect format of data \(el.createdAt)")
                                    
                                    self.poolDetails = nil
                                    
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
    
    func loadRecommendation(poolID:String) async {
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: RecommendQuery(poolID: poolID), cachePolicy: .fetchIgnoringCacheData) {
                guard let err = result.errors?.first else {
                    guard let data = result.data?.recommendedChemicals else {
                        await MainActor.run {
                            self.recommendation = nil
                        }
                        return
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                    
                    await MainActor.run {
                        do {
                            var result: Dictionary<ChlorineChemicals, Double> = [:]
                            
                            for el in data {
                                guard let chel = el.asChlorineChemicalValue else { continue }
                                let t = try chel.chlorineType.mapToModel()
                                result[t] = chel.value
                            }
                            
                            if result.count > 0 {
                                self.recommendation = result
                            }
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
