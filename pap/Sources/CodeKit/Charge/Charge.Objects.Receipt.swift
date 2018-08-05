//
// Created by BL?AC?KGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

struct ChargeableReceipt: Codable, Chargeable, Hashable{

    let uuid:String
    let createdDate:Date
    let bankerVersion:Int

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
         bankerVersion:Int){

        self.uuid = uuid
        self.createdDate = createdDate
        self.typeRawValue = typeRawValue
        self.rewardRawValue = rewardRawValue
        self.amountValue = amountValue
        self.bankerVersion = bankerVersion
    }

    init(charge:Charge, bankerVersion:Int){
        self.init(
                uuid:UUID().uuidString,
                createdDate:Date(),
                typeRawValue: charge.type.rawValue,
                rewardRawValue: charge.reward.rawValue,
                amountValue: charge.priceAmount.value,
                bankerVersion: bankerVersion
        )
    }

    var amountValue:Double // remaining amountValue
    var dateData:Date?
    var stringData:String?
    var intData:Int?
    var doubleData:Double?
    var dataData:Data?

    private enum CodingKeys: Int, CodingKey {
        case uuid
        case createdDate
        case bankerVersion

        case typeRawValue
        case rewardRawValue
        case amountValue

        case dateData
        case stringData
        case intData
        case doubleData
        case dataData
    }

//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        let uuid = try container.decode(String.self, forKey: .uuid)
//        let createdDate = try container.decode(Date.self, forKey: .createdDate)
//        let bankerVersion = try container.decode(Int.self, forKey: .bankerVersion)
//
//        let typeRawValue = try container.decode(Int.self, forKey: .typeRawValue)
//        let rewardRawValue = try container.decode(Int.self, forKey: .rewardRawValue)
//        let amountValue = try container.decode(Double.self, forKey: .amountValue)
//
//        self.init(
//                uuid:uuid,
//                createdDate: createdDate,
//                typeRawValue: typeRawValue,
//                rewardRawValue: rewardRawValue,
//                amountValue: amountValue,
//                bankerVersion: bankerVersion
//        )
//
//        self.dateData = try container.decode(Date.self, forKey: .dateData)
//        self.stringData = try container.decode(String.self, forKey: .stringData)
//        self.intData = try container.decode(Int.self, forKey: .intData)
//        self.doubleData = try container.decode(Double.self, forKey: .doubleData)
//        self.dataData = try container.decode(Data.self, forKey: .dataData)
//        print("---------------------------------",self)
//    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(bankerVersion, forKey: .bankerVersion)

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
}


private protocol ChargeReceiptAccessorStorage:DefaultsProperty{
    var receipts:[ChargeableReceipt] {set get} // receipt ID : object
}

extension Defaults: ChargeReceiptAccessorStorage {
    var receipts:[ChargeableReceipt]{
        set{ set(newValue) }
        get{ return get(or:[ChargeableReceipt]()) }
    }
}

final class ChargeReceiptStorage {
    private let receiptsStorage: ChargeReceiptAccessorStorage
    private(set) var receipts:[String: ChargeableReceipt]

    init(banker: ChargeBanker){
        receiptsStorage = Defaults(userDefaults: UserDefaults(suiteName: banker.receiptStorageIdentifier+String(describing: ChargeReceiptStorage.self)) ?? UserDefaults.standard)
        receipts = receiptsStorage.receipts.dictionary { $0.uuid }
    }

    var balanceAmountValue:Double{
        var v = 0.0
        for r in receipts{
            v += r.value.amountValue
        }
        return clamp(v, AmountObject.minValue, AmountObject.maxValue)
    }

    func hasReceipt(by receiptUUID:String) -> Bool{
        return receipts[receiptUUID] != nil
    }

    func getReceipt(for chargeable:Chargeable) -> ChargeableReceipt?{
        return receipts.values.first { receipt in
            return receipt.isEqualTo(other: chargeable)
        }
    }

    func addReceipt(_ receipt: ChargeableReceipt){
        assert(!hasReceipt(by: receipt.uuid),"Given receipt, \(receipt) does already exist")
        if !hasReceipt(by: receipt.uuid){
            receipts[receipt.uuid] = receipt
            print("[i] Receipt Added: ", receipt, receipt.uuid)
        }
    }

    func removeReceipt(_ receiptId:String){
        assert(hasReceipt(by: receiptId), "Given id of receipt, already \(receiptId) does not exist")
        receipts[receiptId] = nil
        print("[i] INFO: Receipt Removed: ", receipts[receiptId] ?? "", receiptId)
    }

    func updateReceipt(_ receipt:ChargeableReceipt){
        assert(hasReceipt(by: receipt.uuid), "Given receipt, \(receipt) does not exist")
        if hasReceipt(by: receipt.uuid){
            receipts[receipt.uuid] = receipt
            print("[i] Receipt Updated: type: \(receipt.type), reward: \(receipt.reward), created: \(receipt.createdDate)")
        }
    }

    func commit(){
        var mutableReceiptsStorage = self.receiptsStorage
        mutableReceiptsStorage.receipts = Array(self.receipts.values)
    }
}
