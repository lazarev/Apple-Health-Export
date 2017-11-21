//
//  SaveHealthChunkOperation.swift
//  Apple Health Export
//
//  Created by Андрей Лазарев on 13/11/2016.
//  Copyright © 2016 Andrew Lazarev. All rights reserved.
//

import UIKit
import HealthKit

protocol HealthSaveOperationDelegate {
    func operationDidSaveChunk(anchor: HKQueryAnchor, type: HKSampleType!)
    func operationDidFinishWith(anchor: HKQueryAnchor, type: HKSampleType!)
    func operationDidFailed(error: Error!, type: HKSampleType!)
}

class HealthSaveOperation: Operation {
    
    let delegate: HealthSaveOperationDelegate!
    let anchor  : HKQueryAnchor?
    let store   : HKHealthStore!
    let type    : HKSampleType!
    var query   : HKAnchoredObjectQuery?
    var done = false
    
    override var isAsynchronous : Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return self.query == nil
    }
    
    override var isFinished: Bool {
        return self.done
    }

    init(store: HKHealthStore!, anchor: HKQueryAnchor?, type: HKSampleType!, delegate: HealthSaveOperationDelegate!) {
        self.delegate = delegate
        self.store    = store
        self.anchor   = anchor
        self.type     = type
        super.init()
    }
    
    override func start() {
        if self.isCancelled {
            return
        }
        self.willChangeValue(forKey: "isExecuting")
        let predicate = NSPredicate(format: "%K == nil", argumentArray: [HKPredicateKeyPathCorrelation])
        
        let query = HKAnchoredObjectQuery(type: self.type,
                                          predicate: predicate,
                                          anchor: self.anchor,
                                          limit: 1,
                                          resultsHandler: self.resultsHandler)
        self.store.execute(query)
        self.didChangeValue(forKey: "isExecuting")
    }
    
    override func cancel() {
        if !self.isExecuting {
            return
        }
        
        self.willChangeValue(forKey: "isFinished")
        self.willChangeValue(forKey: "isExecuting")
        self.store.stop(self.query!)
        self.query = nil
        self.done  = true
        self.didChangeValue(forKey: "isExecuting")
        self.didChangeValue(forKey: "isFinished")

    }
    
    
    func resultsHandler(query: HKAnchoredObjectQuery, added:[HKSample]?, deleted:[HKDeletedObject]?, anchor: HKQueryAnchor?, error: Error?) -> Void
    {
        self.willChangeValue(forKey: "isFinished")
        self.willChangeValue(forKey: "isExecuting")
        
        self.query = nil
        self.done  = true
        
        if error != nil {
            self.delegate.operationDidFailed(error: error!, type: self.type)
        } else {
            if added?.count == 0 && deleted?.count == 0 {
                self.delegate.operationDidFinishWith(anchor: anchor!, type: self.type)
            } else {
                self.delegate.operationDidSaveChunk(anchor: anchor!, type: self.type)
            }
        }
        
        self.didChangeValue(forKey: "isExecuting")
        self.didChangeValue(forKey: "isFinished")
    }
    
}
