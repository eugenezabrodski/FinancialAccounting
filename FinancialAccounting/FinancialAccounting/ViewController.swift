//
//  ViewController.swift
//  FinancialAccounting
//
//  Created by Eugene on 19/01/2024.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    let realm = try! Realm()
    var spendingArray: Results<Spending>!
    
    
    @IBOutlet weak var howManyCanSpend: UILabel!
    @IBOutlet weak var limitLabel: UILabel!
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var spendByCheck: UILabel!
    @IBOutlet weak var allSpendings: UILabel!
    @IBOutlet var numberFromKeyboard: [UIButton]! {
        didSet {
            for button in numberFromKeyboard {
                button.layer.cornerRadius = 11
            }
        }
    }
    @IBOutlet weak var tableView: UITableView!
    
    var stillTyping = false
    var categoryName = ""
    var displayValue: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spendingArray = realm.objects(Spending.self)
        leftLabels()
        allSpends()
    }
    
    
    @IBAction func numberPressed(_ sender: UIButton) {
        let number = sender.currentTitle!
        
        if number == "0" && displayLabel.text == "0" {
            stillTyping = false
        } else {
            if stillTyping {
                if displayLabel.text!.count < 15 {
                    displayLabel.text = displayLabel.text! + number
                }
            } else {
                displayLabel.text = number
                stillTyping = true
            }
        }
    }
    
    @IBAction func resetButton(_ sender: UIButton) {
        displayLabel.text = "0"
        stillTyping = false
    }
    
    
    @IBAction func categoryPressed(_ sender: UIButton) {
        categoryName = sender.currentTitle ?? ""
        displayValue = Int(displayLabel.text!)!
        displayLabel.text = "0"
        stillTyping = false
        
        let value = Spending(value: ["\(categoryName)", displayValue])
        try! realm.write {
            realm.add(value)
            leftLabels()
            allSpends()
            tableView.reloadData()
        }
    }
    
    @IBAction func setTheLimit(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Set the limit", message: "Set the sum of money and count of days", preferredStyle: .alert)
        let alertInstall = UIAlertAction(title: "Set", style: .default) { action in
            let textFieldSum = alertController.textFields?[0].text
            let textFieldDate = alertController.textFields?[1].text
            
            guard textFieldDate != "" && textFieldSum != "" else { return }
            self.limitLabel.text = textFieldSum
            
            if let day = textFieldDate {
                let dateNow = Date()
                let lastDay: Date = dateNow.addingTimeInterval(60 * 60 * 24 * Double(day)!)
                
                let limit = self.realm.objects(Limit.self)
                
                if limit.isEmpty == true {
                    let value = Limit(value: [self.limitLabel.text!, dateNow, lastDay])
                    try! self.realm.write {
                        self.realm.add(value)
                    }
                } else {
                    try! self.realm.write{
                        limit[0].limitSum = self.limitLabel.text!
                        limit[0].limitDay = dateNow as NSDate
                        limit[0].limitLastDay = lastDay as NSDate
                    }
                }
            }
            self.leftLabels()
        }
        alertController.addTextField { money in
            money.placeholder = "Sum of money"
            money.keyboardType = .asciiCapableNumberPad
        }
        alertController.addTextField { date in
            date.placeholder = "Count of days"
            date.keyboardType = .asciiCapableNumberPad
        }
        let alertCancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alertController.addAction(alertInstall)
        alertController.addAction(alertCancel)
        present(alertController, animated: true)
    }
    
    private func leftLabels() {
        let limit = self.realm.objects(Limit.self)
        
        guard limit.isEmpty == false else { return }
        limitLabel.text = limit[0].limitSum
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let firstDay = limit[0].limitDay as Date
        let lastDay = limit[0].limitLastDay as Date
        
        let firstComponents = calendar.dateComponents([.year, .month, .day], from: firstDay)
        let lastComponents = calendar.dateComponents([.year, .month, .day], from: lastDay)
        
        let startDate = formatter.date(from: "\(firstComponents.year!)/\(firstComponents.month!)/\(firstComponents.day!) 00:00") as Any
        let endDate = formatter.date(from: "\(lastComponents.year!)/\(lastComponents.month!)/\(lastComponents.day!) 23:59") as Any
        
        let filtredLimit: Int = realm.objects(Spending.self).filter("self.date >= %@ && self.date <= %@", startDate, endDate).sum(ofProperty: "cost")
        spendByCheck.text = "\(filtredLimit)"
        
        let a = Int(limitLabel.text!)!
        let b = Int(spendByCheck.text!)!
        let c = a - b
        howManyCanSpend.text = "\(c)"
    }
    
    private func allSpends() {
        let allSpend: Int = realm.objects(Spending.self).sum(ofProperty: "cost")
        allSpendings.text = "\(allSpend)"
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spendingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        let spending = spendingArray.sorted(byKeyPath: "date", ascending: false)[indexPath.row]
        cell.recordCategory.text = spending.category
        cell.recordPrice.text = "\(spending.cost)"
        
        switch spending.category {
        case "Food": cell.recordImage.image = UIImage(systemName: "fork.knife")
        case "Clothes": cell.recordImage.image = UIImage(systemName: "hanger")
        case "Mobile": cell.recordImage.image = UIImage(systemName: "teletype.answer.circle.fill")
        case "Party": cell.recordImage.image = UIImage(systemName: "party.popper")
        case "Health": cell.recordImage.image = UIImage(systemName: "heart.circle")
        case "Car": cell.recordImage.image = UIImage(systemName: "car")
        default: break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editingRow = spendingArray.sorted(byKeyPath: "date", ascending: false)[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, comletionHandler in
            try! self.realm.write{
                self.realm.delete(editingRow)
                self.leftLabels()
                self.allSpends()
                tableView.reloadData()
            }
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    
}

