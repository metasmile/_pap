//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit
import CloudKit

struct WelcomeTutorialPayment:Payable{
    //Actually will not be used.
    private(set) static var label: String = "Welcome Free Use Pass"

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return Defaults.shared.shortVersionDescription == .first
    }
}

private protocol SecretCodeStore:DefaultsProperty{
    var secetCodeEntry:SecretCodeEntry? {set get}
}

extension Defaults: SecretCodeStore {
    fileprivate var secetCodeEntry: SecretCodeEntry? {
        set{ set(newValue) } get{ return get() }
    }
}

private struct SecretCodeEntry: Codable {
    private static var nullId:String { return "null" }
    private static var nullCode:String { return "null" }
    private static var nullDate:Date { return Date.init(timeIntervalSinceReferenceDate: 0) }
    static var invalid:SecretCodeEntry{
        return SecretCodeEntry(id:nullId, code:nullCode, codeCreationDate:nil, joinedDate:nullDate, ownerName:nil)
    }

    static var recordType:CKRecord.RecordType { return "SAC" }
    static var kCode:String { return "code" }
    static var kOwnerName:String {return "ownerName"}
    static var kJoinedAt:String {return "joinedAt"}

    let id:String //.recordID.recordName
    let code:String
    let codeCreationDate:Date?
    let joinedDate:Date
    let ownerName:String?
}

struct SecretCodeInPermanentPayment:VerifiablePayable, PreparablePayable {
    private let CkContainer = CKContainer(identifier: "iCloud.com.stells.pap")

    private(set) static var label: String = "Input"

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        let currentQueue = DispatchQueue.current

        var paid = false

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
                    currentQueue.async{
                        if let entry = self.verify(with: inputCode, toCreate:true, AsyncSignal()){

                            if entry.id == SecretCodeEntry.invalid.id{
                                DispatchQueue.main.async{
                                    UIAlertController.alert("It looks invalid code. Please Try again.".localized, title:"Access Failed.".localized, completion:{ action in
                                        asyncSignal.end()
                                    })
                                }

                            }else{
                                //Save
                                Defaults.shared.secetCodeEntry = entry
                                paid = true

                                let userName = entry.ownerName ?? "User".localized
                                DispatchQueue.main.async{
                                    UIAlertController.alert("Hello, %@!".localizedFormatted(userName) + "\n" + "Welcome to our VIP license program.".localized, title:"Access Granted.".localized, completion:{ action in
                                        asyncSignal.end()
                                    })
                                }
                            }

                        }else{
                            DispatchQueue.main.async{
                                UIAlertController.alert("Unable to verify the code currently. Please try it later".localized, title:"Verification Failed.".localized, completion:{ action in
                                    asyncSignal.end()
                                })
                            }
                        }
                    }
                }else{
                    UIAlertController.alert("It looks invalid code. Please Try again.".localized, title:"Access Failed.".localized, completion:{ action in
                        asyncSignal.end()
                    })
                }

            }
        }

        asyncSignal.waitUntilEnd()
        
        return paid
    }

    private func verify(with inputCode:String, toCreate:Bool, _ asyncSignal:AsyncWaitSignalable) -> SecretCodeEntry?{
        asyncSignal.begin()
        
        var verifiedEntry: SecretCodeEntry?

        let query = CKQuery(recordType: SecretCodeEntry.recordType, predicate: NSPredicate(value: true))
        CkContainer.publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if error == nil{
                let result = records?.compactMap { record -> (record:CKRecord, entry:SecretCodeEntry)? in
                    if let code = record[SecretCodeEntry.kCode] as? String
                        , (toCreate == (record[SecretCodeEntry.kJoinedAt] == nil)) // Code anyone not used yet/ or registerd.
                        , code == inputCode // and matched.
                    {
                        let entry = SecretCodeEntry(id: record.recordID.recordName, code: code, codeCreationDate: record.creationDate, joinedDate: Date(), ownerName: record[SecretCodeEntry.kOwnerName] as? String)
                        return (record:record, entry:entry)
                    }
                    return nil
                }.first

                if let result = result{
                    let savingRecord = result.record
                    savingRecord[SecretCodeEntry.kJoinedAt] = NSDate()
                    self.CkContainer.publicCloudDatabase.save(savingRecord, completionHandler: { (_, e) in
                        if e == nil {
                            verifiedEntry = result.entry
                        }
                        asyncSignal.end()
                    })
                }else{
                    //not found means invalid
                    verifiedEntry = SecretCodeEntry.invalid
                    asyncSignal.end()
                }
            }
        }
        asyncSignal.waitUntilEnd()
        return verifiedEntry
    }
    
    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        if let code = Defaults.shared.secetCodeEntry?.code.nilEmpty
            , let verifiedEntry = verify(with: code, toCreate:false, asyncSignal){
            return verifiedEntry.id != SecretCodeEntry.invalid.id
        }
        return nil
    }

    private static var WatcherId:String {
        return #function+String(describing: SecretCodeInPermanentPayment.self)
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

struct SecretCodeInVersionPayment:VerifiablePayable{
    private(set) static var label: String = "Hush. This is secret code for you."

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        let d = Defaults.shared.shortVersionDescription
        return d == .first || d == .normal
    }
}
