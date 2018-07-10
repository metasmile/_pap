//
// Created by BLACKGENE on 29.06.18.
// C?opyright (c) 2018 Stells. All rights reserved.
//

//
//  CodeKit.EventKit.swift
//
//  Created by Albert Montserrat on 16/02/17.
//  Copyright (c) 2015 Albert Montserrat. All rights reserved.
//

//https://github.com/AlbertMontserrat/AMGCalendarManager/blob/master/AMGCalendarManager/Classes/AMGCalendarManager.swift

import EventKit

public class EventKitUtil {

    public static let shared = EventKitUtil()

    public let defaultEventStore = EKEventStore()
    public var defaultCalendarForNewEvents:EKCalendar{
        return self.defaultEventStore.defaultCalendarForNewEvents
                ?? self.defaultEventStore.calendars(for: .event).first
                ?? EKCalendar(for: .event, eventStore: self.defaultEventStore)
    }


    public var calendarName: String

    public var calendar: EKCalendar? {
        get {
            return defaultEventStore.calendars(for: .event).filter { (element) in
                return element.title == calendarName
            }.first
        }
    }

    public init(calendarName: String = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String){
        self.calendarName = calendarName
    }

    //MARK: - Authorization

    public func requestAuthorization(completion: @escaping (_ allowed:Bool) -> ()){
        switch EKEventStore.authorizationStatus(for: EKEntityType.event) {
        case .authorized:
            if self.calendar == nil {
                _ = self.createCalendar()
            }
            completion(true)
        case .denied:
            completion(false)
        case .notDetermined:
            defaultEventStore.requestAccess(to: .event, completion: { (allowed, error) -> Void in
                if allowed {
                    self.reset()
                    if self.calendar == nil {
                        completion(self.createCalendar()==nil)
                    }else{
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            })
        default:
            completion(false)
        }
    }

    //MARK: - Calendar

    public func addCalendar(commit: Bool = true, completion: ((_ error:NSError?) -> ())? = nil) {
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            let error = weakSelf.createCalendar(commit: commit)
            completion?(error)
        }
    }

    public func removeCalendar(commit: Bool = true, completion: ((_ error:NSError?)-> ())? = nil) {
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            if let cal = weakSelf.calendar, EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
                do {
                    try weakSelf.defaultEventStore.removeCalendar(cal, commit: true)
                    completion?(nil)
                } catch let error as NSError {
                    completion?(error)
                }
            }
        }

    }

    //MARK: - New and update events

    public func newEvent(completion: ((_ event:EKEvent?) -> Void)?) {

        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(nil)
                return
            }

            if let c = weakSelf.calendar {
                let event = EKEvent(eventStore: weakSelf.defaultEventStore)
                event.calendar = c
                completion?(event)
                return
            }
            completion?(nil)
        }
    }

    public func saveEvent(event: EKEvent, span: EKSpan = .thisEvent, completion: ((_ error:NSError?) -> Void)? = nil) {

        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }

            if !weakSelf.insertEvent(event: event, span: span) {
                completion?(weakSelf.getGeneralError())
            } else {
                completion?(nil)
            }
        }
    }

    //MARK: - Remove events

    public func removeEvent(eventId: String, completion: ((_ error:NSError?)-> ())? = nil) {
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            weakSelf.getEvent(eventId: eventId, completion: { (error, event) in
                if let e = event {
                    if !weakSelf.deleteEvent(event: e) {
                        completion?(weakSelf.getGeneralError())
                    } else {
                        completion?(nil)
                    }
                } else {
                    completion?(weakSelf.getGeneralError())
                }
            })
        }
    }

    public func removeAllEvents(filter: ((EKEvent) -> Bool)? = nil, completion: ((_ error:NSError?) -> ())? = nil){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError())
                return
            }
            weakSelf.getAllEvents(completion: { (error, events) in
                guard error == nil, let events = events else {
                    completion?(weakSelf.getGeneralError())
                    return
                }
                for event in events {
                    if let f = filter, !f(event) {
                        continue
                    }
                    _ = weakSelf.deleteEvent(event: event)
                }
                completion?(nil)
            })
        }
    }

    //MARK: - Get events

    public func getAllEvents(completion: ((_ error:NSError?, _ events:[EKEvent]?)-> ())?){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError(), nil)
                return
            }
            guard let c = weakSelf.calendar else {
                completion?(weakSelf.getGeneralError(),nil)
                return
            }
            let range = 31536000 * 100 as TimeInterval /* 100 Years */
            var startDate = Date(timeIntervalSince1970: -range)
            let endDate = Date(timeIntervalSinceNow: range * 2) /* 200 Years */
            let four_years = 31536000 * 4 as TimeInterval /* 4 Years */

            var events = [EKEvent]()

            while startDate < endDate {
                var currentFinish = Date(timeInterval: four_years, since: startDate)
                if currentFinish > endDate {
                    currentFinish = Date(timeInterval: 0, since: endDate)
                }

                let pred = weakSelf.defaultEventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [c])
                events.append(contentsOf: weakSelf.defaultEventStore.events(matching: pred))

                startDate = Date(timeInterval: four_years + 1, since: startDate)
            }

            completion?(nil, events)
        }
    }

    public func getEvents(startDate: Date, endDate: Date, completion: ((_ error:NSError?, _ events:[EKEvent]?)-> ())?){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError(), nil)
                return
            }
            if let c = weakSelf.calendar {
                let pred = weakSelf.defaultEventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [c])
                completion?(nil, weakSelf.defaultEventStore.events(matching: pred))
            } else {

                completion?(weakSelf.getGeneralError(),nil)

            }

        }
    }

    public func getEvent(eventId: String, completion: ((_ error:NSError?, _ event:EKEvent?)-> ())?){
        requestAuthorization() { [weak self] (allowed) in
            guard let weakSelf = self else { return }
            if !allowed {
                completion?(weakSelf.getDeniedAccessToCalendarError(), nil)
                return
            }
            let event = weakSelf.defaultEventStore.event(withIdentifier: eventId)
            completion?(nil,event)
        }
    }

    //MARK: - Privates

    private func createCalendar(commit: Bool = true, source: EKSource? = nil) -> NSError? {
        let newCalendar = EKCalendar(for: .event, eventStore: self.defaultEventStore)
        newCalendar.title = self.calendarName

        // defaultCalendarForNewEvents will always return a writtable source, even when there is no iCloud support.
        if let calendar = self.defaultEventStore.defaultCalendarForNewEvents{
            newCalendar.source = source ?? calendar.source
        }else{
            return NSError(domain: #file, code: 0)
        }

        do {
            try self.defaultEventStore.saveCalendar(newCalendar, commit: commit)
            return nil
        } catch let error as NSError {
            if source != nil {
                return error
            } else {
                for source in self.defaultEventStore.sources {
                    if source.sourceType == .birthdays {
                        continue
                    }
                    let err = createCalendar(source: source)
                    if err == nil {
                        return nil
                    }
                }
                if let calendar = self.defaultEventStore.defaultCalendarForNewEvents{
                    self.calendarName = calendar.title
                }
                return error
            }
        }
    }

    private func insertEvent(event: EKEvent, span: EKSpan = .thisEvent, commit: Bool = true) -> Bool {
        do {
            try defaultEventStore.save(event, span: .thisEvent, commit: commit)
            return true
        } catch {
            return false
        }
    }

    private func deleteEvent(event: EKEvent, commit: Bool = true) -> Bool {
        do {
            try defaultEventStore.remove(event, span: .futureEvents, commit: commit)
            return true
        } catch {
            return false
        }
    }

    //MARK: - Generic

    public func commit() -> Bool {
        do {
            try defaultEventStore.commit()
            return true
        } catch {
            return false
        }
    }

    public func reset(){
        defaultEventStore.reset()
    }
}

extension EventKitUtil {
    fileprivate func getErrorForDomain(domain: String, description: String, reason: String, code: Int = 999) -> NSError {
        let userInfo = [
            NSLocalizedDescriptionKey: description,
            NSLocalizedFailureReasonErrorKey: reason
        ]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }

    fileprivate func getGeneralError() -> NSError {
        return getErrorForDomain(domain: "CalendarError", description: "Unknown Error", reason: "An unknown error ocurred while trying to sync your calendar. Syncing will be turned off.", code: 999)
    }

    fileprivate func getDeniedAccessToCalendarError() -> NSError {
        return getErrorForDomain(domain: "CalendarAuthorization", description: "Calendar access was denied", reason: "To continue syncing your calendars re-enable Calendar access for Técnico Lisboa in Settings->Privacy->Calendars.", code: 987)
    }

}