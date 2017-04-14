//
//  WikiTableViewController.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/1/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit

class WikiTableViewController: UITableViewController, UISearchResultsUpdating {
    
    // MARK: - View Controller Lifecycle

    let dateFormatter = DateFormatter()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
    }
    
    // MARK: - Searching
    
    var wikiDocs = [[WikiDoc]]()
    
    func updateSearchResults(for: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.characters.count > 2 else { return }
        search(for: searchText)
    }
    
    func search(for searchText: String?) {
        guard let searchText = searchText,
            let wikiRequest = WikiRequest(searchText: searchText) else {
            return
        }

        wikiRequest.fetchWikiDocs { [weak self] newDocs in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async(){
                if newDocs.count > 0 {
                    strongSelf.wikiDocs = [newDocs]
                    strongSelf.tableView.reloadData()
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
        wikiCell.wikiDateLabel?.text = dateFormatter.string(from: wikiDoc.date)
        
        if let rectangle = wikiCell.wikiTitleImageView?.bounds {
            wikiCell.wikiTitleImageView?.image = UIImage.image(withInitials: wikiDoc.imageInitials, in: rectangle)
        }
        
        return wikiCell
    }
    
}
