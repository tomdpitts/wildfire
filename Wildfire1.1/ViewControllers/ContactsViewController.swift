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
    var contactsList = [Contact]()
    var contactsGrouped = [[Contact]]()
    
    var phonebook = [String: String]()
    var namesDict = [[String: String]]()
    var section = 0
    var row = 0
    
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
        if let startsWith = contactsGrouped[section].first?.givenName.prefix(1) {
            label.text = String(startsWith)
        }
        return label
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsGrouped[section].count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return contactsGrouped.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        let nameLocation = contactsGrouped[indexPath.section][indexPath.row]
        // slightly safer than using fullName as these two are non-optional
        cell.textLabel?.text = nameLocation.givenName + " " + nameLocation.familyName
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
                        
                        // if they don't have a mobile number we don't need to include them in the list
                        if number.isEmpty == false {
                            var mobile = ""
                            for n in number {
                                if n.label == CNLabelPhoneNumberMobile {
                                    mobile = n.value.stringValue
                                }
                            }
                            let allowedCharset = CharacterSet
                                .decimalDigits
                            let mobileClean = String(mobile.unicodeScalars.filter(allowedCharset.contains))
                            
                            
                            let person = Contact(givenName: contact.givenName, familyName: contact.familyName, fullName: name, phoneNumber: mobileClean, uid: nil)
                            
                            
                            self.contactsList.append(person)
                        }
//                        self.names.append(name)
//                        self.phonebook[name] = mobile
                    })
                } catch let err {
                    print("error fetching contact", err)
                }
                
                var letters: [Character] = []
                var capitalLetters: [Character] = []
                
//                letters = self.contactsList.map { (name) -> Character in
//                    return name[name.startIndex]
//                }
                
                for x in self.contactsList {
                    let m = x.fullName.trimmingCharacters(in: .whitespaces)
                    let y = String(m.prefix(1))
                    if y != "" {
                        let z = Character(y)
                        letters.append(z)
                    }
                }
                
                letters = letters.sorted()
                
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
                
//                let sortedPhonebook = self.phonebook.sorted{ $0.key < $1.key }
                
                let sortedContactsList = self.contactsList.sorted{ $0.givenName < $1.givenName }
                
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
                
//                for x in capitalLetters {
//                    var group: [String] = []
//                    for (i,_) in sortedPhonebook {
//                        if let j = i.first {
//                            if Character(j.uppercased()) == x {
//                                group.append(i)
//                            }
//                        }
//
//                    }
//                    self.namesList.append(group)
//                }
                
                // sorting the Contacts into groups by first letter of full name (NB not by family name)
                for x in capitalLetters {
                    var group: [Contact] = []
                    for i in sortedContactsList {
                        let m = i.fullName.trimmingCharacters(in: .whitespaces)
                        let j = m.prefix(1)
                        if j != "" {
                            if Character(j.uppercased()) == x {
                                group.append(i)
                            }
                        }
                    }
                    self.contactsGrouped.append(group)
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
        self.row = indexPath.row
        
        performSegue(withIdentifier: "goToSend2", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let selectedContact = contactsGrouped[self.section][self.row]

        if let Send2ViewController = segue.destination as? Send2ViewController {
            Send2ViewController.contact = selectedContact
        }
    }
    
    @IBAction func unwindToPrevious(_ unwindSegue: UIStoryboardSegue) {
    }
}
