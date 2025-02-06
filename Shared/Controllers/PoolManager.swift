//
//  Pool.swift
//  PoolHealth
//
//  Created by user on 03/01/2025.
//

import Foundation
import os
import PoolHealthSchema
import CoreSpotlight

class PoolManager: ObservableObject {
    @Published var error: Error?
    @Published var poolsLoading = true
    @Published var pools: [Pool] = []
    @Published var chemicalsLoading = false
    @Published var chemicals: [Chemicalicals] = []
    @Published var actions: [Action] = []
    @Published var migrationInProgress: Bool = false
    @Published var migrationStatus = MigrationStatus.notStarted
    var migrationID: String?
    
    let log = Logger(subsystem: "xax.PoolHealth", category: "PoolManager")
    
    func migrate(sheetLink: String) async {
        log.debug("sheetLink: \(sheetLink)")
        let result = await Network.shared.apollo.performAsync(mutation: MigrateMutation(sheetLink: sheetLink))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            guard let id = graphQLResult.data?.migrateFromSheet else { return }
            await MainActor.run {
                self.log.debug("new migration id \(id)")
                self.migrationID = id
            }
            await migration()
            
        case .failure(let error):
            print(error)
        }
    }
    
    func migration() async {
        guard let id = migrationID else { return }
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: MigrationQuery(id: id), cachePolicy: .fetchIgnoringCacheData) {
                guard let err = result.errors?.first else {
                    guard let data = result.data?.migrationStatus.status else {
                        return
                    }
                    
                    await MainActor.run {
                        switch data {
                        case .failed:
                            self.migrationStatus = .failed
                        case .done:
                            self.migrationStatus = .completed
                        case .pending:
                            self.migrationStatus = .inProgress
                        case .case(_), .unknown(_):
                            self.error = NSError(domain: "unknown", code: 0, userInfo: nil)
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
    
    func startCheckMigrationStatus() async {
        while true {
            do {
                await migration()
                try await Task.sleep(for: .seconds(10))
            } catch {
                log.error("\(error)")
                
                return
            }
        }
    }
    
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
    
    func logActions(poolID: String, actions: [ActionType]) async {
        let result = await Network.shared.apollo.performAsync(mutation: LogActionsMutation(poolID: poolID, actions: actions.map{$0.toGraphQL()}))
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors {
                print(errors)
                return
            }
            guard let createdAt = graphQLResult.data?.logActions else { return }
            await MainActor.run {
                self.log.debug("new measurement date \(createdAt)")
                self.error = nil
            }
            await loadActions(poolID: poolID)
            
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
    
    func loadActions(poolID:String) async {
        do {
            for try await result in Network.shared.apollo.fetchAsync(query: ActionsHistoryQuery(poolID: poolID), cachePolicy: .fetchIgnoringCacheData) {
                guard let err = result.errors?.first else {
                    guard let data = result.data?.historyOfActions else {
                        await MainActor.run {
                            self.actions = []
                        }
                        return
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                    dateFormatter.dateFormat = DateFormat.iso8601.rawValue
                    
                    await MainActor.run {
                        do {
                            try self.actions = data.map({ el in
                                guard let date = dateFormatter.date(from:el.createdAt) else {
                                    log.error("incorrect format of data \(el.createdAt)")
                                    
                                    throw MatchingMeasurementError.invalidateDateFormat
                                }
                                return Action(actions: el.types.map{$0.toModel()}, createdAt: date)
                            })
                        } catch {
                            self.error = error
                        }
                    }
                    
                    return
                }
                await MainActor.run {
                    self.actions = []
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
                    dateFormatter.dateFormat = DateFormat.iso8601.rawValue
                    
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
                guard let err = result.errors?.first else {
                    guard let pools = result.data?.pools else {
                        return
                    }
                    
                    let p = pools.map{Pool(id: $0.id, name: $0.name, volume: $0.volume, settings: $0.settings.toModel())}
                    
                    await MainActor.run {
                        self.pools = p
                    }
                    
                    try await CSSearchableIndex.default().indexAppEntities(p)
                    
                    return
                }
                guard let code = err.extensions?["code"] as? Int else {
                    await MainActor.run {
                        self.error = err
                    }
                    return
                }
                switch code {
                case -1:
                        return
                default:
                    await MainActor.run {
                        self.error = err
                    }
                    return
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
    
    func deletePool(_ id: String) async {
        log.debug("delete pool with id: \(id)")
        let result = await Network.shared.apollo.performAsync(mutation: DeletePoolMutation(id: id))
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print(errors)
                    return
                }
                await MainActor.run {
                    self.log.debug("pool succesfully deleted")
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


enum MigrationStatus: String, Codable {
    case notStarted = "Not started"
    case inProgress = "In progress"
    case completed = "Completed"
    case failed = "Failed"
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
