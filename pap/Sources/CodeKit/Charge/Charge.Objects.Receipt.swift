//
// Created by BL?AC?KGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

struct ChargeableReceiptVerificationResult{
    let valid:Set<ChargeableReceipt>
    let invalid:Set<ChargeableReceipt>
    let failed:Set<ChargeableReceipt>
}

struct ChargeableReceipt: Codable, Hashable{

    let uuid:String
    let createdDate:Date
    let bankerVersion:Int
    let chargeableIdentifier:String

    private let typeRawValue: Int
    var type: ChargeType{
        return ChargeType(rawValue: typeRawValue) ?? .deprecated
    }

    private let rewardRawValue: Int
    var reward: RewardType{
        return RewardType(rawValue: rewardRawValue) ?? .deprecated
    }

    init(uuid:String,
         createdDate:Date,
         typeRawValue:Int,
         rewardRawValue:Int,
         amountValue:Double,
         bankerVersion:Int,
         chargeableIdentifier:String){

        self.uuid = uuid
        self.createdDate = createdDate
        self.typeRawValue = typeRawValue
        self.rewardRawValue = rewardRawValue
        self.amountValue = amountValue
        self.bankerVersion = bankerVersion
        self.chargeableIdentifier = chargeableIdentifier
    }

    init(charge:Charge, bankerVersion:Int){
        self.init(
                uuid:UUID().uuidString,
                createdDate:Date(),
                typeRawValue: charge.type.rawValue,
                rewardRawValue: charge.reward.rawValue,
                amountValue: charge.priceAmount.value,
                bankerVersion: bankerVersion,
                chargeableIdentifier: charge.identifier
        )
    }

    //remaining amountValue, Will not be used with NonConsumable Rewards
    var amountValue:Double

    var dateData:Date?
    var stringData:String?
    var intData:Int?
    var doubleData:Double?
    var dataData:Data?

    private enum CodingKeys: Int, CodingKey {
        case uuid
        case createdDate
        case bankerVersion
        case chargeableIdentifier

        case typeRawValue
        case rewardRawValue
        case amountValue

        case dateData
        case stringData
        case intData
        case doubleData
        case dataData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(bankerVersion, forKey: .bankerVersion)
        try container.encode(chargeableIdentifier, forKey: .chargeableIdentifier)

        try container.encode(typeRawValue, forKey: .typeRawValue)
        try container.encode(rewardRawValue, forKey: .rewardRawValue)
        try container.encode(amountValue, forKey: .amountValue)

        try container.encode(dateData, forKey: .dateData)
        try container.encode(stringData, forKey: .stringData)
        try container.encode(intData, forKey: .intData)
        try container.encode(doubleData, forKey: .doubleData)
        try container.encode(dataData, forKey: .dataData)
    }

    var hashValue: Int {
        return self.uuid.hashValue
    }

    func isFrom(charge:Chargeable) -> Bool{
        return charge.identifier == chargeableIdentifier
    }

    //INFO: insert uuid via this method, matched receipt will fail to verify
    //INFO: This is Only way to delete receipt
    private static var shouldFailVerificationUUIDs = Set<String>()
    static func reserveShouldFailVerification(uuid:String){
        shouldFailVerificationUUIDs.insert(uuid)
    }

    func verify() -> Bool{
        if type == .deprecated{
            return false
        }

        if reward == .deprecated{
            return false
        }

        // - amountValue is incorrect
        if amountValue < 0{
            return false
        }

        // Consumable must be higher than 0 of its amountValue
        if reward.isNonConsumable == false && amountValue == 0{
            return false
        }

        if ChargeableReceipt.shouldFailVerificationUUIDs.contains(self.uuid){
            ChargeableReceipt.shouldFailVerificationUUIDs.remove(self.uuid)
            return false
        }

        return true
    }
}


private protocol ChargeReceiptAccessorStorage:PropertyDefaults{
    var receipts:[ChargeableReceipt] {set get} // receipt ID : object
}

extension Defaults: ChargeReceiptAccessorStorage {
    var receipts:[ChargeableReceipt]{
        set{ set(newValue) }
        get{ return get(or:[ChargeableReceipt]()) }
    }
}

protocol ChargeReceiptStorageDelegate{

}

final class ChargeReceiptStorage {
    private let syncQueue = DispatchQueue(label: String(describing: ChargeReceiptStorage.self), qos: .userInteractive)

    private let receiptsStorage: ChargeReceiptAccessorStorage

    var receipts:[String: ChargeableReceipt]{
        return syncQueue.sync{
            return _receipts
        }
    }

    private var _receipts:[String: ChargeableReceipt] //INFO: [{uuid} : {receipt object}]

    private var _delegate:ChargeReceiptStorageDelegate?

    init(identifier: String, delegate:ChargeReceiptStorageDelegate?=nil){
        receiptsStorage = Defaults(suiteName: identifier+String(describing: ChargeReceiptStorage.self))
        _receipts = receiptsStorage.receipts.dictionary { $0.uuid }
        _delegate = delegate
    }

    var balanceAmountValue:Double{
        var v = 0.0
        for r in _receipts {
            v += r.value.amountValue
        }
        return clamp(v, AmountObject.minValue, AmountObject.maxValue)
    }

    func hasReceipt(by receiptUUID:String) -> Bool{
        return syncQueue.sync {
            return _receipts[receiptUUID] != nil
        }
    }

    func getReceipt(for chargeable:Chargeable) -> ChargeableReceipt?{
        return syncQueue.sync {
            return _receipts.values.first { receipt in
                return receipt.chargeableIdentifier == chargeable.identifier
            }
        }
    }

    func addReceipt(_ receipt: ChargeableReceipt){
        assert(!hasReceipt(by: receipt.uuid),"Given receipt, \(receipt) does already exist")
        if !hasReceipt(by: receipt.uuid){
            syncQueue.async(flags:.barrier) {
                self._receipts[receipt.uuid] = receipt
                print("[i] INFO: Receipt Added: ", receipt, receipt.uuid)
            }
        }
    }

    func removeReceipt(_ receiptId:String){
        assert(hasReceipt(by: receiptId), "Given id of receipt, already \(receiptId) does not exist")
        syncQueue.async(flags:.barrier) {
            print("[i] INFO: Receipt Removed:", self._receipts[receiptId] ?? "", receiptId)
            self._receipts[receiptId] = nil
        }
    }

    func updateReceipt(_ receipt:ChargeableReceipt){
        assert(hasReceipt(by: receipt.uuid), "Given receipt, \(receipt) does not exist")
        if hasReceipt(by: receipt.uuid){
            syncQueue.async(flags:.barrier) {
                self._receipts[receipt.uuid] = receipt
                print("[i] Receipt Updated: type: \(receipt.type), reward: \(receipt.reward), created: \(receipt.createdDate)")
            }
        }
    }

    func commit(){
        syncQueue.async(flags:.barrier) {
            var mutableReceiptsStorage = self.receiptsStorage
            mutableReceiptsStorage.receipts = Array(self._receipts.values)
        }
    }
}
