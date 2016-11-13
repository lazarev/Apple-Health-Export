//
//  ViewController.swift
//  Apple Health Export
//
//  Created by Андрей Лазарев on 12/11/2016.
//  Copyright © 2016 Andrew Lazarev. All rights reserved.
//

import UIKit
import HealthKit


class ViewController: UIViewController, HealthSaveOperationDelegate {
    
    @IBOutlet var progressIndicator: UIProgressView?
    
    var store : HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    var queue = OperationQueue()
    
    @IBAction func doExport(button: UIButton) {
        button.isEnabled = false
        
        let typeSet = Set(self.typesToRead)
        
        let requestPermissions = RequestPermissions(store: self.store, types: typeSet)
        self.queue.addOperation(requestPermissions)
        
        let bootStraps = typeSet.map { (type: HKSampleType) -> Operation in
            let operation = HealthSaveOperation(store: self.store, anchor: nil, type: type, delegate: self)
            operation.addDependency(requestPermissions)
            return operation
        }

        self.queue.addOperations(bootStraps, waitUntilFinished: true)
        button.isEnabled = true
    }
    
    let typesToRead = { () -> [HKSampleType] in
        let path = Bundle.main.path(forResource: "TypesToImport", ofType: "plist")
        let settings = Array(NSArray(contentsOfFile: path!)!)
        
        return settings.map {
            (object) -> HKSampleType? in
            let dictionary = object as! NSDictionary
            
            guard let typeName = dictionary["key"] as! String? else {
                return nil
            }
            
            switch typeName {
            case let name where name.hasPrefix("HKQuantityTypeIdentifier"):
                let identifier = HKQuantityTypeIdentifier(rawValue: typeName)
                return HKObjectType.quantityType(forIdentifier: identifier)
            case let name where name.hasPrefix("HKCategoryTypeIdentifier"):
                let identifier = HKCategoryTypeIdentifier(rawValue: typeName)
                return HKObjectType.categoryType(forIdentifier: identifier)
                //            case let name where name.hasPrefix("HKCorrelationTypeIdentifier"):
                //                let identifier = HKCorrelationTypeIdentifier(rawValue: typeName)
            //                return HKObjectType.correlationType(forIdentifier: identifier)
            default:
                return nil
            }
            }.flatMap { $0 }
    }()
 
    // MARK: - Delegate
    func operationDidSaveChunk(anchor: HKQueryAnchor, type: HKSampleType!) {
        let operation = HealthSaveOperation(store: self.store, anchor: anchor, type: type, delegate: self)
        self.queue.addOperation(operation)
    }
    func operationDidFinishWith(anchor: HKQueryAnchor, type: HKSampleType!) {
        print("\(type.identifier) finished")
    }
    func operationDidFailed(error: Error!, type: HKSampleType!) {
        print(error)
    }
}

