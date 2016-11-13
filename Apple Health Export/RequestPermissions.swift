//
//  RequestPermissions.swift
//  Apple Health Export
//
//  Created by Андрей Лазарев on 13/11/2016.
//  Copyright © 2016 Andrew Lazarev. All rights reserved.
//

import UIKit
import HealthKit

class RequestPermissions: Operation {
    
    let store  : HKHealthStore!
    let types  : Set<HKObjectType>!
    var error  : Error?
    var done      = false
    var inprogress = false
    
    override var isExecuting: Bool {
        return self.inprogress
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isFinished: Bool {
        return self.done
    }

    init(store: HKHealthStore!, types: Set<HKObjectType>!) {
        self.store = store
        self.types = types
        super.init()
    }

    override func start() {
        self.willChangeValue(forKey: "isExecuting")
        self.inprogress = true
        self.store?.requestAuthorization(toShare: nil, read: self.types)
        { (success, error) in
            self.willChangeValue(forKey: "isExecuting")
            self.willChangeValue(forKey: "isFinished")
            self.inprogress = false
            self.error      = error
            self.done       = true
            self.didChangeValue(forKey: "isFinished")
            self.didChangeValue(forKey: "isExecuting")
        }
        self.didChangeValue(forKey: "isExecuting")
    }
}
