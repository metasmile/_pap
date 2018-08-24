//
// Created by BLACKGENE on 8/20/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit
import CloudKit

private protocol SecretCodeStore:DefaultsProperty{
    var secretCodeEntry:SecretCodeEntry? {set get}
}

extension Defaults: SecretCodeStore {
    fileprivate var secretCodeEntry: SecretCodeEntry? {
        set{ set(newValue) } get{ return get() }
    }
}

private typealias SecretCodeResult = (state:SecretCodeEntry.AccessState, entry:SecretCodeEntry?)

private struct SecretCodeEntry: Codable, Equatable {
    enum AccessState {
        case error
        case denied
        case granted
    }

    struct ID:Codable, Equatable{
        let recordName:String
        let zoneName:String
        let ownerName:String

        func makeCKRecordID() -> CKRecord.ID{
            return CKRecord.ID(recordName: recordName, zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName))
        }

        static var null:ID{
            return ID(recordName:"null", zoneName:"null", ownerName:"null")
        }

        static func == (lhs: ID, rhs: ID) -> Bool{
            return lhs.recordName == rhs.recordName
                    && lhs.zoneName == rhs.zoneName
                    && lhs.ownerName == rhs.ownerName
        }
    }

    private static var nullId:String { return "null" }
    private static var nullCode:String { return "null" }
    private static var nullDate:Date { return Date.init(timeIntervalSinceReferenceDate: 0) }
    static var invalid:SecretCodeEntry{
        return SecretCodeEntry(id:ID.null, code:nullCode, codeCreationDate:nil, joinedDate:nullDate, ownerName:nil)
    }

    static var recordType:CKRecord.RecordType { return "SAC" }
    static var kCode:String { return "code" }
    static var kOwnerName:String {return "ownerName"}
    static var kJoinedAt:String {return "joinedAt"}

    let id:ID //.recordID.recordName
    let code:String
    let codeCreationDate:Date?
    let joinedDate:Date
    let ownerName:String?

    static func create(from record:CKRecord) -> SecretCodeEntry?{
        if let code = record[SecretCodeEntry.kCode] as? String{
            return SecretCodeEntry(
                    id: SecretCodeEntry.ID(recordName: record.recordID.recordName, zoneName: record.recordID.zoneID.zoneName, ownerName: record.recordID.zoneID.ownerName)
                    , code: code
                    , codeCreationDate: record.creationDate
                    , joinedDate: Date()
                    , ownerName: record[SecretCodeEntry.kOwnerName] as? String)
        }
        return nil
    }

    static func == (lhs: SecretCodeEntry, rhs: SecretCodeEntry) -> Bool{
        return lhs.id == rhs.id && lhs.code == rhs.code
    }
}

private extension CKDatabase{
    func set(records:[CKRecord], policy:CKModifyRecordsOperation.RecordSavePolicy=CKModifyRecordsOperation.RecordSavePolicy.allKeys, completion:((CKRecord, Error?) -> Void)?=nil){
        let o = CKModifyRecordsOperation()
        o.recordsToSave = records
        o.savePolicy = policy
        o.perRecordCompletionBlock = completion

        self.add(o)
    }

    func remove(recordIDs:[CKRecord.ID], completion:((CKRecord, Error?) -> Void)?=nil){
        let o = CKModifyRecordsOperation()
        o.recordIDsToDelete = recordIDs
        o.perRecordCompletionBlock = completion
        self.add(o)
    }
}

struct PermanentVIPProgramPayment:VerifiablePayable, PreparablePayable {
    /*
        Verification Pseudo

    -1. read from local (record id)
        if != nil
            -> granted

    if not found ->
        0. read from private database
        1. found SAC record not yet used
        2. SAC.ID/Code == public database.ID/Code
        if found
            -> granted

    if not found ->
        1. The user is first VIP
        2. Ask password (must input within 10secs)
        3. Granted
        4. joinedAt -> public -> this SAC record was LOCKED permanently
        5. add/joinedAt -> private
            -> granted

    */
    private let CkContainer = CKContainer(identifier: "iCloud.com.stells.pap")

    static var action: PayableAction {
        return PayableAction(title: "Get Access".localized)
    }

    static var grantedOwnerName:String?{
        return Defaults.shared.secretCodeEntry?.ownerName
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        let result = _pay(asyncSignal)
        if result.state == .granted{
            Defaults.shared.secretCodeEntry = result.entry
            assert(Defaults.shared.secretCodeEntry != nil, "Access granted but entry is nil.")
            return result.entry != nil
        }

        Defaults.shared.secretCodeEntry = nil
        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        if let code = Defaults.shared.secretCodeEntry?.code.nilEmpty{
            let isValid = verify(code: code, shouldRegister: false, asyncSignal).state == .granted
            if isValid == false{
                Defaults.shared.secretCodeEntry = nil
            }
            return isValid
        }
        return nil
    }

    private func _pay(_ asyncSignal: AsyncWaitSignalable) -> SecretCodeResult {
        let payingQueue = DispatchQueue.current

        var result:SecretCodeResult = (state:.error, entry:nil)

        //if found local entry, granted
        if let localEntry = Defaults.shared.secretCodeEntry{
            result = verify(code: localEntry.code, shouldRegister: false, asyncSignal)
        }

        // if not found -> fetch from private
        else if let privateEntries = self.fetchPrivateEntries(asyncSignal){
            for entry in privateEntries{
                let r = verify(code: entry.code, shouldRegister: false, asyncSignal)
                if let _ = r.entry, r.state == .granted {
                    result = r
                    break
                }
            }
            // privateEntries has existed but not found granted entry -> .denied (no error)
            if result.state != .granted{
                result = (state:.denied, entry:nil)
                //remove invalid SAC data
                CkContainer.privateCloudDatabase.remove(recordIDs: privateEntries.map { $0.id.makeCKRecordID() })
            }
        }

        // if not found -> input process
        else {
            asyncSignal.begin()

            DispatchQueue.main.async{

                UIAlertController.alert(
                        "Please Input Your Secret Code".localized
                        , title: "VIP License Program".localized
                        , actions: [ UIAlertAction(title: "Cancel".localized, style: .cancel) { action in

                    asyncSignal.end()

                }]
                        , textField: { f in f.placeholder = "Input Here".localized }
                ) { a in

                    if let inputCode = UIAlertController.presenting?.textFields?.first?.text?.trimmed.nilEmpty{
                        payingQueue.async{
                            result = self.verify(code: inputCode, shouldRegister:true, AsyncSignal())
                            asyncSignal.end()
                        }
                    }else{
                        UIAlertController.alert("It looks invalid code. Please Try again.".localized, title:"Access Failed.".localized, completion:{ action in
                            asyncSignal.end()
                        })
                    }
                }
            }

            asyncSignal.waitUntilEnd()
        }


        asyncSignal.begin()

        DispatchQueue.main.async{
            switch result.state{
            case .error:
                UIAlertController.alert("Unable to verify the code currently. Please try it later.".localized, title:"Verification Failed.".localized, completion:{ action in
                    asyncSignal.end()
                })
            case .denied:
                UIAlertController.alert("Your code is invalid. Please Try again.".localized, title:"Access Denied.".localized, completion:{ action in
                    asyncSignal.end()
                })
            case .granted:
                let userName = result.entry?.ownerName ?? "User".localized
                DispatchQueue.main.async{
                    UIAlertController.alert("Hello, %@!".localizedFormatted(userName) + "\n" + "Welcome to our VIP license program.".localized, title:"Access Granted.".localized, completion:{ action in
                        asyncSignal.end()
                    })
                }
            }
        }

        asyncSignal.waitUntilEnd()

        return result
    }

    private func fetchPrivateEntries(_ asyncSignal:AsyncWaitSignalable) -> [SecretCodeEntry]?{
        asyncSignal.begin()
        var entries:[SecretCodeEntry]?
        let query = CKQuery(recordType: SecretCodeEntry.recordType, predicate: NSPredicate(value: true))
        CkContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if error == nil{
                entries = records?.compactMap { record -> SecretCodeEntry? in
                    return SecretCodeEntry.create(from: record)
                }
            }
            asyncSignal.end()
        }
        asyncSignal.waitUntilEnd()
        return entries?.nilEmpty
    }

    private func verify(code inputCode:String, shouldRegister:Bool, _ asyncSignal:AsyncWaitSignalable) -> SecretCodeResult{
        assert(asyncSignal.began == false, "Use new signal or remove calling begin().")
        asyncSignal.begin()

        var state:SecretCodeEntry.AccessState = .error
        var verifiedEntry: SecretCodeEntry?

        let query = CKQuery(recordType: SecretCodeEntry.recordType, predicate: NSPredicate(value: true))
        CkContainer.publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if error == nil{

                let resultMatchedCode = records?.compactMap { record -> (record:CKRecord, entry:SecretCodeEntry)? in
                    if let code = record[SecretCodeEntry.kCode] as? String
                    , (shouldRegister == (record[SecretCodeEntry.kJoinedAt] == nil)) // [i] Code anyone not used yet/ or registerd.
                    , code == inputCode // and matched.
                    , let entry = SecretCodeEntry.create(from: record)
                    {
                        return (record:record, entry: entry)
                    }
                    return nil
                }.first

                if let result = resultMatchedCode {

                    if shouldRegister{ // if shouldRegister

                        let savingRecord = result.record
                        savingRecord[SecretCodeEntry.kJoinedAt] = NSDate()

                        //1. touch public
                        self.CkContainer.publicCloudDatabase.set(records: [savingRecord]) { (r, e) in

                            //2. add to private
                            self.CkContainer.privateCloudDatabase.set(records: [savingRecord]){ (r, e) in
                                assert(result.record.recordID == r.recordID, "Record ID was unmatched")
                                assert(e == nil, "Error \(String(describing: e)) was occurred.")

                                if result.record.recordID == r.recordID && e == nil{
                                    state = .granted
                                    verifiedEntry = result.entry
                                }

                                asyncSignal.end()
                            }
                        }

                    }else{ // only confirm
                        state = .granted
                        verifiedEntry = result.entry
                        asyncSignal.end()
                    }

                }else{
                    //not found means invalid
                    verifiedEntry = SecretCodeEntry.invalid
                    state = .denied
                    asyncSignal.end()
                }
            }
        }

        asyncSignal.waitUntilEnd()
        return (state:state, entry:verifiedEntry)
    }

    private static var WatcherId:String {
        return #function+String(describing: PermanentVIPProgramPayment.self)
    }

    private(set) static var isEnable: Bool = false

    private static var currentAppIDStack:[String]?

    private static let passCodeAppIDStack = [
        PDFactoryApp.info.identifier,
        ConverterApp.info.identifier,
        TransformApp.info.identifier,
        FiltersApp.info.identifier
    ]

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        AppCenter.default.watch(\.currentIdentifier, id:WatcherId){
            if AppCenter.default.previous?.info.identifier == ShopApp.info.identifier{
                //Exit from Shop
                currentAppIDStack = nil
                isEnable = false

            } else if AppCenter.default.current?.info.identifier == ShopApp.info.identifier{
                //Entered with secret code.

            }

            if let id = AppCenter.default.currentIdentifier{
                if currentAppIDStack == nil && id == passCodeAppIDStack.first{
                    currentAppIDStack = [String]()
                }

                if currentAppIDStack != nil && currentAppIDStack?.contains(id) == false{
                    currentAppIDStack?.append(id)
                }

                if currentAppIDStack?.count == passCodeAppIDStack.count{
                    isEnable = currentAppIDStack == passCodeAppIDStack
                    currentAppIDStack = nil

                    if isEnable{
                        Timer.scheduledTimer(identifier: #function, withTimeInterval: 10, block: { _ in
                            isEnable = false
                        })
                    }
                }
            }
        }
    }
}