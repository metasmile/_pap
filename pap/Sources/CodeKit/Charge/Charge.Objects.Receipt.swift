//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

struct ChargeableReceipt: Codable, Chargeable{

    let uuid:String = UUID().uuidString
    let createdDate:Date = Date()
    let bankerVersion:Int

    let type: ChargeType
    let reward: RewardType

    var dateData:Date?
    var stringData:String?
    var intData:Int?
    var doubleData:Double?
    var dataData:Data?

    init(chargeable:Chargeable, bankerVersion:Int){
        self.type = chargeable.type
        self.reward = chargeable.reward
        self.bankerVersion = bankerVersion
    }

    private enum CodingKeys: Int, CodingKey {
        case uuid
        case createdDate
        case bankerVersion

        case type
        case reward

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

        try container.encode(dateData, forKey: .dateData)
        try container.encode(stringData, forKey: .stringData)
        try container.encode(intData, forKey: .intData)
        try container.encode(doubleData, forKey: .doubleData)
        try container.encode(dataData, forKey: .dataData)
    }
}


private protocol ChargeReceiptAccessorStorage:DefaultsProperty{
    var receipts:[String: ChargeableReceipt] {set get} // receipt ID : object
}

extension Defaults: ChargeReceiptAccessorStorage {
    var receipts:[String: ChargeableReceipt]{
        set{ set(newValue) }
        get{ return get(or:[String: ChargeableReceipt]()) }
    }
}

// ChargeReceiptStorageAccessor allows only ChargeBanker
protocol ChargeReceiptStorageAccessor where Self:ChargeBanker{}

struct ChargeReceiptStorage { //struct means final.
    private var receiptsStorage: ChargeReceiptAccessorStorage
    private(set) var receipts:[String: ChargeableReceipt]

    init(accessor: ChargeReceiptStorageAccessor){
        receiptsStorage = Defaults(userDefaults: UserDefaults(suiteName: String(describing: type(of: accessor))+String(describing: ChargeReceiptStorage.self)) ?? UserDefaults.standard)
        receipts = receiptsStorage.receipts
    }

    mutating func addReceipt(_ receipt: ChargeableReceipt){
        receiptsStorage.receipts[receipt.uuid] = receipt
        receipts = receiptsStorage.receipts
    }

    mutating func removeReceipt(_ receiptId:String){
        receiptsStorage.receipts[receiptId] = nil
        receipts = receiptsStorage.receipts
    }

    mutating func disposeAll(){
        receiptsStorage.receipts.removeAll()
        receipts.removeAll()
    }
}
