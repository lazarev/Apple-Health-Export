//
//  AppDelegate.swift
//  Apple Health Export
//
//  Created by Андрей Лазарев on 12/11/2016.
//  Copyright © 2016 Andrew Lazarev. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let taskExecutor = TaskExecutionService()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        _ = self.taskExecutor.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

}

