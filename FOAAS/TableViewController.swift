//
//  ViewController.swift
//  FOAAS
//
//  Created by Stephen Heaps on 2018-07-26.
//  Copyright © 2018 Stephen Heaps. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    let fuck = FOAAS()
    var operations: [FOAASOperation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "All Operations"
        
        fuck.fetchAllOperations { [weak self] (operations, error) in
            self?.operations = operations
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    private func operation(for indexPath: IndexPath) -> FOAASOperation {
        if indexPath.row > self.operations.count { fatalError("Index out of bounds") }
        return self.operations[indexPath.row]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return operations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") else {
                return UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
            }
            return cell
        }()
        
        let operation = self.operation(for: indexPath)
        cell.textLabel?.text = operation.name

        if let field1 = operation.fields.first, let field2 = operation.fields.last,
            field1.name != field2.name {
            cell.detailTextLabel?.text = "field1: \(field1.name) \tfield2: \(field2.name)"
        } else if let field = operation.fields.first {
            cell.detailTextLabel?.text = "field: \(field.name)"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let operation = self.operation(for: indexPath)
        let alertController = self.createAlertController(operation: operation)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func createAlertController(operation: FOAASOperation) -> UIAlertController {
        let alert = UIAlertController(title: operation.name, message: nil, preferredStyle: UIAlertController.Style.alert)
        if operation.fields.count == 3 {
            let field1 = operation.fields[0]
            let field2 = operation.fields[1]
            let field3 = operation.fields[2]
            alert.addTextField { (textField) in
                textField.placeholder = field1.name
            }
            alert.addTextField { (textField) in
                textField.placeholder = field2.name
            }
            alert.addTextField { (textField) in
                textField.placeholder = field3.name
            }
            let alertAction = UIAlertAction(title: "Send", style: .default) { (alertAction) in
                // build URL
                guard let textFields = alert.textFields else { return }
                let textField1 = textFields[0]
                let textField2 = textFields[1]
                let textField3 = textFields[2]
                var newURLString = operation.url.relativePath.replacingOccurrences(of: ":\(field1.field)", with: textField1.text ?? "noname", options: String.CompareOptions.literal, range: nil)
                newURLString = newURLString.replacingOccurrences(of: ":\(field2.field)", with: textField2.text ?? "noname", options: .literal, range: nil)
                newURLString = newURLString.replacingOccurrences(of: ":\(field3.field)", with: textField3.text ?? "noname", options: .literal, range: nil)
                newURLString = self.fuck.baseURLString + newURLString
                if let newURL = URL(string: newURLString) {
                    self.fuck.fetchResponse(url: newURL, completion: { [weak self] (response, error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        if let response = response {
                            self.showResponse(response: response)
                        } else {
                            print("error")
                        }
                    })
                }
            }
            alert.addAction(alertAction)
        }
        if let field1 = operation.fields.first, let field2 = operation.fields.last,
            operation.fields.count == 2 { // 2 fields
            alert.addTextField { (textField) in
                textField.placeholder = field1.name
            }
            alert.addTextField { (textField) in
                textField.placeholder = field2.name
            }
            let alertAction = UIAlertAction(title: "Send", style: .default) { (alertAction) in
                // build URL
                guard let textFields = alert.textFields else { return }
                if let textField1 = textFields.first, let textField2 = textFields.last, textField1 != textField2 {
                    var newURLString = operation.url.relativePath.replacingOccurrences(of: ":\(field1.field)", with: textField1.text ?? "noname", options: String.CompareOptions.literal, range: nil)
                    newURLString = newURLString.replacingOccurrences(of: ":\(field2.field)", with: textField2.text ?? "noname", options: .literal, range: nil)
                    newURLString = self.fuck.baseURLString + newURLString
                    if let newURL = URL(string: newURLString) {
                        self.fuck.fetchResponse(url: newURL, completion: { [weak self] (response, error) in
                            if let error = error {
                                print(error)
                                return
                            }
                            if let response = response {
                                self?.showResponse(response: response)
                            } else {
                                print("error")
                            }
                        })
                    }
                }
            }
            alert.addAction(alertAction)
        } else if let field1 = operation.fields.first, operation.fields.count == 1 {
            alert.addTextField { (textField) in
                textField.placeholder = field1.name
            }
            let alertAction = UIAlertAction(title: "Send", style: .default) { (alertAction) in
                // build URL
                guard let textFields = alert.textFields else { return }
                if let textField1 = textFields.first {
                    var newURLString = operation.url.relativePath.replacingOccurrences(of: ":\(field1.field)", with: textField1.text ?? "noname", options: String.CompareOptions.literal, range: nil)
                    newURLString = self.fuck.baseURLString + newURLString
                    if let newURL = URL(string: newURLString) {
                        self.fuck.fetchResponse(url: newURL, completion: { [weak self] (response, error) in
                            if let error = error {
                                print(error)
                                return
                            }
                            if let response = response {
                                self?.showResponse(response: response)
                            } else {
                                print("error")
                            }
                        })
                    }
                }
            }
            alert.addAction(alertAction)
        }
        return alert
    }
    
    private func showResponse(response: FOAASResponse) {
        DispatchQueue.main.async { // guarantee we are on the main queue so we can interact with UIKit
            let alert = UIAlertController(title: response.message, message: response.subtitle, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Alright", style: .default) { (alert) in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

