//
// Created by BLAC?KGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

struct ChargeableReceipt: Codable, Chargeable, Hashable{

    let uuid:String = UUID().uuidString
    let createdDate:Date = Date()
    let bankerVersion:Int

    let type: ChargeType
    let reward: RewardType
    var amountValue:Double // remaining amountValue

    var dateData:Date?
    var stringData:String?
    var intData:Int?
    var doubleData:Double?
    var dataData:Data?

    init(charge:Charge, bankerVersion:Int){
        self.type = charge.type
        self.reward = charge.reward
        self.amountValue = charge.priceAmount.value
        self.bankerVersion = bankerVersion
    }

    private enum CodingKeys: Int, CodingKey {
        case uuid
        case createdDate
        case bankerVersion

        case type
        case reward
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

        try container.encode(type, forKey: .type)
        try container.encode(reward, forKey: .reward)
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

    init(accessor: ChargeReceiptStorable){
        receiptsStorage = Defaults(userDefaults: UserDefaults(suiteName: String(describing: type(of: accessor))+String(describing: ChargeReceiptStorage.self)) ?? UserDefaults.standard)
        receipts = receiptsStorage.receipts.dictionary { $0.uuid }
    }

    func hasReceipt(by receiptUUID:String) -> Bool{
        return receipts[receiptUUID] != nil
    }

    func getReceipt(for chargeable:Chargeable) -> ChargeableReceipt?{
        return receipts.values.first { receipt in
            return receipt.isEqual(other: chargeable)
        }
    }

    func addReceipt(_ receipt: ChargeableReceipt){
        assert(!hasReceipt(by: receipt.uuid),"Given receipt, \(receipt) does already exist")
        if !hasReceipt(by: receipt.uuid){
            receipts[receipt.uuid] = receipt
        }
    }

    func removeReceipt(_ receiptId:String){
        receipts[receiptId] = nil
    }

    func updateReceipt(_ receipt:ChargeableReceipt){
        assert(hasReceipt(by: receipt.uuid), "Given receipt, \(receipt) does not exist")
        if hasReceipt(by: receipt.uuid){
            receipts[receipt.uuid] = receipt
        }
    }

    func commit(){
        var mutableReceiptsStorage = self.receiptsStorage
        mutableReceiptsStorage.receipts = Array(self.receipts.values)
    }
}
