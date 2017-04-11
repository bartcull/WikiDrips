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
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - Searching
    
    var wikiDocs = [[WikiDoc]]()
    
    var searchText: String? {
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
        guard let searchText = searchText else {
            return
        }
        if let wikiRequest = WikiRequest(searchText: searchText) {
            wikiRequest.fetchWikiDocs { (newDocs) -> Void in
                DispatchQueue.main.async(){
                    if newDocs.count > 0 {
                        self.wikiDocs = wikiRequest.wikiDocs
                        self.tableView.reloadData()
                    }
                }
            }
        }
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
        wikiCell.wikiDateLabel?.text = formattedDate(isoDate: wikiDoc.pubDate)
        
        if let rectangle = wikiCell.wikiTitleImageView?.bounds {
            wikiCell.wikiTitleImageView?.image = UIImage.image(withInitials: wikiDoc.imageInitials, in: rectangle)
        }
        
        return wikiCell
    }
    
    private func formattedDate(isoDate: String?) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let isoDate = isoDate, let date = dateFormatter.date(from: isoDate) {
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        } else {
            return ""
        }
    }

}
