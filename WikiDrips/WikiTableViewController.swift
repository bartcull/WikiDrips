//
//  WikiTableViewController.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/1/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit

class WikiTableViewController: UITableViewController, UISearchBarDelegate {
    
    // MARK: - View Controller Lifecycle

    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar?.delegate = self
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - Searching
    
    var wikiDocs = [[WikiDoc]]()
    
    var searchText: String? = "Salesforce" {
        didSet {
            searchBar?.text = searchText
            wikiDocs.removeAll()
            tableView.reloadData() // clear out the table view
            search()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar? {
        didSet {
            searchBar?.delegate = self
            searchBar?.text = searchText
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchText = searchBar.text
        self.tableView.reloadData()
    }
    
    func search() {
//      TODO: replace with async call to Wikipedia API
        let someDateTime = Date(timeIntervalSinceNow: -(Double(wikiDocs.count) * 60))
        let testData: [String: AnyObject] = ["title": "My new title" as AnyObject, "pubDate": someDateTime as AnyObject]
        if let wikiDoc = WikiDoc(data: testData) {
            wikiDocs.insert([wikiDoc], at: 0)
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return wikiDocs.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wikiDocs[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let wikiCell = tableView.dequeueReusableCell(withIdentifier: "WikiDoc", for: indexPath) as? WikiTableViewCell else {
            // Log or ignore casting failure
            return UITableViewCell()
        }
        
        let wikiDoc = wikiDocs[indexPath.section][indexPath.row]
        wikiCell.wikiTitleLabel?.text = wikiDoc.title
        wikiCell.wikiDateLabel?.text = dateFormatter.string(from: wikiDoc.pubDate)
        
        if let rectangle = wikiCell.wikiTitleImage?.bounds {
            wikiCell.wikiTitleImage?.image = #imageLiteral(resourceName: "PlaceHolderImage").image(withInitials: wikiDoc.imageInitials, in: rectangle)
        }
        
        return wikiCell
    }

}
