//
//  SpendingModel.swift
//  FinancialAccounting
//
//  Created by Eugene on 23/01/2024.
//

import Foundation
import RealmSwift

class Spending: Object {
    @objc dynamic var category = ""
    @objc dynamic var cost = 1
    @objc dynamic var date = NSDate()
}

class Limit: Object {
    @objc dynamic var limitSum = ""
    @objc dynamic var limitDay = NSDate()
    @objc dynamic var limitLastDay = NSDate()
}
