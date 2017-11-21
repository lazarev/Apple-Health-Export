//
//  TaskExecutionService.swift
//  Apple Health Export
//
//  Created by Андрей Лазарев on 21/11/2017.
//  Copyright © 2017 Andrew Lazarev. All rights reserved.
//

import UIKit
import HealthKit
import UserNotifications

class TaskExecutionService: NSObject {
    var store : HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.setupQuery()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [UNAuthorizationOptions.alert]) { (success, error) in
            if let error = error {
                print("*** An error occured while requesting permissions for notifications. \(error.localizedDescription) ***")
                return
            }
        }
        
        return true
    }
    
    func setupQuery() {
        let sampleType =
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)
        
        let types: Set<HKSampleType> = [sampleType!]
    
        self.store?.requestAuthorization(toShare: nil, read: types, completion: { (success, error) in
            let query = HKObserverQuery(sampleType: sampleType!, predicate: nil) {
                query, completionHandler, error in
                
                if let error = error {
                    print("*** An error occured while setting up the stepCount observer. \(error.localizedDescription) ***")
                    return
                }
                
                // Take whatever steps are necessary to update your app's data and UI
                // This may involve executing other queries
                self.fetchTotalCarbohydradesConsumedWithCompletionHandler(completionHandler: { (result, error) in
                    if let error = error {
                        print("*** An error occured \(error.localizedDescription) ***")
                    } else if let result = result {
                        DispatchQueue.main.async {
                            let message = "\(result) gramms of carbohydrades for today"
                            if UIApplication.shared.applicationState==UIApplicationState.active {
                                if let controller = UIApplication.shared.delegate?.window??.rootViewController {
                                    let alert = UIAlertController()
                                    alert.message = message
                                    alert.show(controller, sender: nil)
                                }
                            } else {
                                let content = UNMutableNotificationContent()
                                content.title = "Appple health update"
                                content.body = message
                                content.sound = UNNotificationSound.default()
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5,
                                                                                repeats: false)
                                
                                // Schedule the notification.
                                let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger)
                                let center = UNUserNotificationCenter.current()
                                center.add(request, withCompletionHandler: nil)
                            }
                        }
                    }
                })
                
                // If you have subscribed for background updates you must call the completion handler here.
                completionHandler()
            }
            
            self.store?.enableBackgroundDelivery(for: sampleType!, frequency: .immediate, withCompletion: { (success, error) in
                if let error = error {
                    print("*** An error occured while setting up background delivery. \(error.localizedDescription) ***")
                }
                print("setup delivery successfully")
            })
            
            self.store?.execute(query)
        })
    }
    
    func fetchTotalCarbohydradesConsumedWithCompletionHandler(
        completionHandler:@escaping (Double?, Error?)->()) {
        
        let calendar = NSCalendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day] as Set<Calendar.Component>, from: now)

        let startDate = calendar.date(from: components)
        
        let endDate = calendar.date(byAdding: DateComponents(day: 1), to: startDate!)

        let sampleType = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: endDate,
                                                    options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: sampleType!,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { query, result, error in
                                        
                                        if error != nil {
                                            completionHandler(nil, error)
                                            return
                                        }
                                        
                                        var total = 0.0
                                        
                                        if let quantity = result?.sumQuantity() {
                                            let unit = HKUnit.gram()
                                            total = quantity.doubleValue(for: unit)
                                        }
                                        
                                        completionHandler(total, error)
        }
        
        self.store!.execute(query)
    }
}
