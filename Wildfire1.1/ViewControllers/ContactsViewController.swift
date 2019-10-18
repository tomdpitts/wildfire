//
//  ContactsViewController.swift
//  Wildfire1.1
//
//  Created by Thomas Pitts on 17/10/2019.
//  Copyright © 2019 Wildfire. All rights reserved.
//

import UIKit
import Contacts

class ContactsViewController: UITableViewController {

    let cellID = "cell123123"
    
    var names = [String]()
    var namesList = [[String]]()
    var phonebook = [String: String]()
    var namesDict = [[String: String]]()
    var section = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        navigationItem.title = "Send"
        navigationController?.navigationBar.prefersLargeTitles = true
    
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        fetchContacts()
    }
    
    func backAction() -> Void {
        performSegue(withIdentifier: "unwindToPay", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.backgroundColor = UIColor.lightGray
        if let startsWith = namesList[section].first?.prefix(1) {
            label.text = String(startsWith)
        }
        return label
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesList[section].count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return namesList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        let name = namesList[indexPath.section][indexPath.row]
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = "test"
        
        return cell
    }
    
    private func fetchContacts() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print(error)
                return
            }
            
            if granted {
                
                // user gave access
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                do {
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        
                        let name = contact.givenName + " " + contact.familyName
                        let number = contact.phoneNumbers
                        var mobileNumber = ""
                        for n in number {
                            if n.label == "_$!<Mobile>!$_" {
                                mobileNumber = number[0].value.stringValue
                            }
                        }
                        
                        
                        self.names.append(name)
                        self.phonebook[name] = mobileNumber
                    })
                    
                } catch let err {
                    print("error fetching contact", err)
                }
                
                var letters: [Character]
                
                letters = self.names.map { (name) -> Character in
                    return name[name.startIndex]
                }
                
                letters = letters.sorted()
                
                var capitalLetters: [Character] = []
                
                for x in letters {
                    let y = String(x)
                    let z = y.uppercased()
                    let a = Character(z)
                    capitalLetters.append(a)
                }
                
                capitalLetters = capitalLetters.reduce([], { (list, name) -> [Character] in
                    if !list.contains(name) {
                        return list + [name]
                    }
                    
                    return list
                })
                
                // get the empty space Character to the end of the list so the output starts with A
                if capitalLetters.contains(Character(" ")) {
                    capitalLetters = capitalLetters.filter({ $0 != Character(" ")})
                    capitalLetters.append(Character(" "))
                }
                
                
                
//                let sortedNames = self.names.sorted()
                
                let sortedPhonebook = self.phonebook.sorted{ $0.key < $1.key }
                
                
//
//                for x in capitalLetters {
//                    var group: [String] = []
//                    for i in sortedNames {
//                        if let j = i.first {
//                            if Character(j.uppercased()) == x {
//                                group.append(i)
//                            }
//                        }
//
//                    }
//                    self.namesList.append(group)
//                }
                
                // sorry
                for x in capitalLetters {
                    var group: [String] = []
                    for (i,_) in sortedPhonebook {
                        if let j = i.first {
                            if Character(j.uppercased()) == x {
                                group.append(i)
                            }
                        }
                        
                    }
                    self.namesList.append(group)
                }
                
            } else {
                // denied access
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // without this line, the cell remains (visually) selected after end of tap
        tableView.deselectRow(at: indexPath, animated: true)
        self.section = indexPath.section
        // TODO perform segue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let row = tableView.indexPathForSelectedRow?.row else {
            return
        }
        let section = self.section
        print(row)
        
        let selectedContact = namesList[section][row]
        
//        if let Send2ViewController = segue.destination as? Send2ViewController {
//            Send2ViewController.contact = selectedContact
//        }
    }
}
