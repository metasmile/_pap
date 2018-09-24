//
// Created by BLACKGENE on 8/20/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit
import CloudKit

private protocol SecretCodeStore:PropertyDefaults{
    var secretCodeEntry:[String:SecretCodeEntry] {set get} //[String:SecretCodeEntry] - localStoreKey : SecretCodeEntry

    var expiredCodeEntry:[String:SecretCodeEntry] {set get} //[String:SecretCodeEntry] - localStoreKey : SecretCodeEntry
}

extension Defaults: SecretCodeStore {
    fileprivate var secretCodeEntry:[String:SecretCodeEntry] {
        set{ set(newValue) } get{ return get(or:[String:SecretCodeEntry]()) }
    }

    fileprivate var expiredCodeEntry:[String:SecretCodeEntry] {
        set{ set(newValue) } get{ return get(or:[String:SecretCodeEntry]()) }
    }
}

private typealias SecretCodeResult = (state:SecretCodeEntry.AccessState, entry:SecretCodeEntry?)

private struct SecretCodeEntry: Codable, Equatable {
    static let container = CKContainer(identifier: "iCloud.com.stells.pap")
    
    static var local:SecretCodeStore = Defaults(suiteName: "SecretCodeEntry")

    fileprivate static var nullString:String { return "null" }

    static func commitValue(in database:CKDatabase, localStoreKey:String, key:String, value:__CKRecordObjCValue?, completion:((CKRecord, Error?) -> Void)?=nil){
        if let e = SecretCodeEntry.local.secretCodeEntry[localStoreKey]{
            database.fetch(withRecordID: e.id.makeCKRecordID()) { record, error in
                if let fetchedCKRecord = record, error == nil{
                    fetchedCKRecord[key] = value
                    database.set(records: [fetchedCKRecord], completion:completion)
                }
            }
        }
    }

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
            return ID(recordName:SecretCodeEntry.nullString, zoneName:SecretCodeEntry.nullString, ownerName:SecretCodeEntry.nullString)
        }

        static func == (lhs: ID, rhs: ID) -> Bool{
            return lhs.recordName == rhs.recordName
                    && lhs.zoneName == rhs.zoneName
                    && lhs.ownerName == rhs.ownerName
        }
    }

    private static var nullDate:Date { return Date.init(timeIntervalSinceReferenceDate: 0) }
    static var invalid:SecretCodeEntry{
        return SecretCodeEntry(
                id:ID.null,
                code:SecretCodeEntry.nullString,
                codeCreationDate:nil,
                joinedDate:nullDate,
                ownerName:nil,
                program: nil,
                expiredDate:nil
        )
    }

    static var recordType:String { return "SAC" }
    static var kCode:String { return "code" }
    static var kOwnerName:String {return "ownerName"}
    static var kJoinedAt:String {return "joinedAt"}
    static var kProgram:String {return "program"}
    static var kExpiredAt:String {return "expiredAt"}

    let id:ID //.recordID.recordName
    let code:String
    let codeCreationDate:Date?
    let joinedDate:Date
    let ownerName:String?
    let program:String?
    var expiredDate:Date?

    static func create(from record:CKRecord) -> SecretCodeEntry?{
        if let code = record[SecretCodeEntry.kCode] as? String{
            return SecretCodeEntry(
                    id: SecretCodeEntry.ID(recordName: record.recordID.recordName, zoneName: record.recordID.zoneID.zoneName, ownerName: record.recordID.zoneID.ownerName)
                    , code: code
                    , codeCreationDate: record.creationDate
                    , joinedDate: Date()
                    , ownerName: record[SecretCodeEntry.kOwnerName] as? String
                    , program: record[SecretCodeEntry.kProgram] as? String
                    , expiredDate: record[SecretCodeEntry.kExpiredAt] as? Date
            )
        }
        return nil
    }

    static func == (lhs: SecretCodeEntry, rhs: SecretCodeEntry) -> Bool{
        return lhs.id == rhs.id
                && lhs.code == rhs.code
                && lhs.ownerName == rhs.ownerName
                && lhs.program == rhs.program
    }
}

private extension CKDatabase{
    func set(records:[CKRecord], policy:CKRecordSavePolicy=CKRecordSavePolicy.allKeys, completion:((CKRecord, Error?) -> Void)?=nil){
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

protocol SecretCodeProgram {
    static var title:String{get}
    static var grantedMessage:String{get}

    //INFO: if unspecified ownerName in CKRecord`
    static var defaultOwnerName:String{get}

    //INFO: key to store. Does NOT used by iCloud
    static var localStoreKey:String{get}

    //INFO: this used by SAC 'program' field
    static var program:String?{get}

    //INFO: max period to reuse code since joinedAt.
    // Set '0' or Period.min if synchronize with the moment of removing receipt.
    // Set nil if permanently available.
    static var maxValidPeriod:Period? {get}

    //temp value storage for operations.
    static var isEnable:Bool{set get}
    static var currentAppIDStack:[String]?{set get}
    static var passCodeAppIDStack:[String]{get}
}

extension SecretCodeProgram{
    static var maxValidPeriod: Period? {
        return nil
    }

    static var localStoreKey: String {
        return String(describing: self)
    }
}

struct SecretCodeProgramPayment<P:SecretCodeProgram>:VerifiablePayable, PreparablePayable, ReceiptObservablePayable {
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
    
    static var action: PayableAction {
        return PayableAction(title: "Get Access".localized)
    }

    static var grantedOwnerName:String?{
        return SecretCodeEntry.local.secretCodeEntry[P.localStoreKey]?.ownerName
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        let result = _pay(asyncSignal)
        if result.state == .granted{
            SecretCodeEntry.local.secretCodeEntry[P.localStoreKey] = result.entry
            assert(SecretCodeEntry.local.secretCodeEntry[P.localStoreKey] != nil, "Access granted but entry is nil.")
            return result.entry != nil
        }

        SecretCodeEntry.local.secretCodeEntry[P.localStoreKey] = nil
        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        if let entry = SecretCodeEntry.local.secretCodeEntry[P.localStoreKey]
        , let code = entry.code.nilEmpty{
            // INFO: if expired -> false
            if entry.expiredDate != nil{
                return false
            }

            // Start verification process with iCloud.
            let isValid = verify(code: code, shouldRegister: false, asyncSignal).state == .granted
            if isValid == false{
                SecretCodeEntry.local.secretCodeEntry[P.localStoreKey] = nil
            }
            return isValid
        }
        return nil
    }

    private func _pay(_ asyncSignal: AsyncWaitSignalable) -> SecretCodeResult {
        let payingQueue = DispatchQueue.current

        var result:SecretCodeResult = (state:.error, entry:nil)

        //if found local entry, granted
        if let localEntry = SecretCodeEntry.local.secretCodeEntry[P.localStoreKey]{
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
                SecretCodeEntry.container.privateCloudDatabase.remove(recordIDs: privateEntries.map { $0.id.makeCKRecordID() })
            }
        }

        // if not found -> input process
        else {
            papLog.charge.scp.triedToAccess()

            asyncSignal.begin()

            DispatchQueue.main.async{

                UIAlertController.alert(
                        "Please Input Your Secret Code".localized
                        , title: P.title.localized
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
                papLog.charge.scp.accessError()

                UIAlertController.alert("Unable to verify the code currently. Please try it later.".localized, title:"Verification Failed.".localized, completion:{ action in
                    asyncSignal.end()
                })
            case .denied:
                papLog.charge.scp.accessDenied(recordName: result.entry?.id.recordName)

                let title:String
                let msg:String

                if let _ = SecretCodeEntry.local.expiredCodeEntry[P.localStoreKey]?.expiredDate{
                    title = "Your code was expired.".localized
                    msg = "Please try again with another code.".localized

                }else{
                    title = "Access Denied.".localized
                    msg = "Your code is invalid. Please try again.".localized
                }

                UIAlertController.alert(msg, title:title, completion:{ action in
                    asyncSignal.end()
                })

            case .granted:
                papLog.charge.scp.accessGranted(recordName: result.entry?.id.recordName)

                let userName = result.entry?.ownerName?.trimmed.nilEmpty ?? P.defaultOwnerName
                DispatchQueue.main.async{
                    UIAlertController.alert("Hello, %@!".localizedFormatted(userName) + "\n" + P.grantedMessage, title:"Access Granted.".localized, completion:{ action in
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
        SecretCodeEntry.container.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
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
        SecretCodeEntry.container.publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if error == nil{

                let resultMatchedCode = records?.compactMap { record -> (record:CKRecord, entry:SecretCodeEntry)? in

                    if let code = record[SecretCodeEntry.kCode] as? String
                    /*
                        INFO: core matching conditions
                    */
                    // [i] Code anyone not used yet/ or registerd.
                    , (shouldRegister == (record[SecretCodeEntry.kJoinedAt] == nil))
                    // Did not expired
                    , (record[SecretCodeEntry.kExpiredAt] as? Date) == nil
                    // and code was matched.
                    , code.trimmed == inputCode.trimmed
                    // is matched program
                    , P.program?.trimmed == (record[SecretCodeEntry.kProgram] as? String)?.trimmed

                    , let entry = SecretCodeEntry.create (from: record) {
                        return (record:record, entry: entry)
                    }
                    return nil
                }.first

                if let result = resultMatchedCode {

                    if shouldRegister{ // if shouldRegister

                        let savingRecord = result.record
                        savingRecord[SecretCodeEntry.kJoinedAt] = NSDate()

                        //1. touch public
                        SecretCodeEntry.container.publicCloudDatabase.set(records: [savingRecord]) { (r, e) in

                            //2. add to private
                            SecretCodeEntry.container.privateCloudDatabase.set(records: [savingRecord]){ (r, e) in
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

    private static func expireCurrentCodeIfNeeded(){
        if let period = P.maxValidPeriod, let e = SecretCodeEntry.local.secretCodeEntry[P.localStoreKey], e.expiredDate == nil{
            let currentDate = Date()
            if period.within(dueDate: currentDate, since: e.joinedDate) {
                return
            }

            SecretCodeEntry.local.secretCodeEntry[P.localStoreKey]?.expiredDate = currentDate
            SecretCodeEntry.local.expiredCodeEntry[P.localStoreKey] = SecretCodeEntry.local.secretCodeEntry[P.localStoreKey]
            SecretCodeEntry.commitValue(in: SecretCodeEntry.container.publicCloudDatabase, localStoreKey: P.localStoreKey, key: SecretCodeEntry.kExpiredAt, value: currentDate as __CKRecordObjCValue)
            { record, error in
                if let e = error{
                    papLog.error.recordedError(e, parameters: ["publicCloudDatabase":"expireCurrentCodeIfNeeded"])

                }
            }
            SecretCodeEntry.commitValue(in: SecretCodeEntry.container.privateCloudDatabase, localStoreKey: P.localStoreKey, key: SecretCodeEntry.kExpiredAt, value: currentDate as __CKRecordObjCValue)
            { record, error in
                if let e = error{
                    papLog.error.recordedError(e, parameters: ["privateCloudDatabase": "expireCurrentCodeIfNeeded"])
                }
            }
        }
    }

    private static var WatcherId:String {
        return #function+String(describing: self)
    }

    static var isEnable: Bool {
        return P.isEnable
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        AppCenter.default.watch(\.currentIdentifier, id:WatcherId){
            if AppCenter.default.previous?.info.identifier == ShopApp.info.identifier{
                //Exit from Shop
                P.currentAppIDStack = nil
                P.isEnable = false

            } else if AppCenter.default.current?.info.identifier == ShopApp.info.identifier{
                //Entered with secret code.

            }

            if let id = AppCenter.default.currentIdentifier{
                if P.currentAppIDStack == nil && id == P.passCodeAppIDStack.first{
                    P.currentAppIDStack = [String]()
                }

                if P.currentAppIDStack != nil && P.currentAppIDStack?.contains(id) == false{
                    P.currentAppIDStack?.append(id)
                }

                if P.currentAppIDStack?.count == P.passCodeAppIDStack.count{
                    P.isEnable = P.currentAppIDStack == P.passCodeAppIDStack
                    P.currentAppIDStack = nil

                    if isEnable{
                        papLog.charge.scp.activationStarted()

                        Timer.scheduledTimer(identifier: #function, withTimeInterval: 10, block: { _ in
                            P.isEnable = false

                            papLog.charge.scp.activationTimeout()
                        })
                    }
                }
            }
        }
    }

    /*
        Receipt Handlers
    */
    static func didInitializeReceipt() {
        DispatchQueue.global(priority: .background).async{
            self.expireCurrentCodeIfNeeded()
        }
    }

    static func didAddReceipt() {}

    static func didUpdateReceipt() {}

    static func willRemoveReceipt() {
        expireCurrentCodeIfNeeded()
    }

    static func didCommitReceipt() {}
}
