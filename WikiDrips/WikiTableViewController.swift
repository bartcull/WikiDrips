//
//  WikiTableViewController.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/1/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit

class WikiTableViewController: UITableViewController {
    
    // MARK: - View Controller Lifecycle

    let dateFormatter = DateFormatter()
    let searchController = UISearchController(searchResultsController: nil)
    fileprivate var imageCache = NSCache<NSString, UIImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.prefetchDataSource = self

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
    
    fileprivate var wikiDocs = [[WikiDoc]]()
    
    fileprivate func search(for searchText: String?) {
        guard let searchText = searchText,
            let wikiRequest = WikiRequest(searchText: searchText) else {
            return
        }

        wikiRequest.fetchWikiDocs { [weak self] newDocs in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async(){
                if newDocs.count > 0 {
                    strongSelf.imageTasks.cancelAllOperations() // This doesn't seem to do anything yet
                    strongSelf.wikiDocs = [newDocs]
                    strongSelf.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Image handling
    
    fileprivate let imageTasks = OperationQueue()
    
    fileprivate func generateImage(forItemAtIndex indexPath: IndexPath) {
        guard safeIndexPath(indexPath: indexPath) else { return }
        let wikiDoc = wikiDocs[indexPath.section][indexPath.row]
        guard let initials = wikiDoc.imageInitials else {
            return
        }
        
        let generator = ImageGenerator(initials: initials)
        imageTasks.addOperation(generator)
        
        generator.completionBlock = {
            sleep(4)
            OperationQueue.main.addOperation { [weak self] in
//                guard let strongSelf = self else { return }
                guard let image = generator.image else {
                    print("Error creating image") // I'll change this to error logging latero
                    return
                }
                // Following is still throwing "fatal error: Index out of range"
                guard (self?.safeIndexPath(indexPath: indexPath) ?? false) && self?.wikiDocs[indexPath.section][indexPath.row].imageInitials == initials else { return } // Ignore because WikiDoc no longer matches
                
                self?.wikiDocs[indexPath.section][indexPath.row].image = image
                if self?.tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                    guard let wikiCell = self?.tableView.cellForRow(at: indexPath) as? WikiTableViewCell else { return }
                    wikiCell.wikiTitleImageView?.image = image
                }
            }
        }
    }
    
    private func safeIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section <= wikiDocs.count && indexPath.row <= wikiDocs[indexPath.section].count
    }
    
    fileprivate func cancelImage(forItemAtIndex indexPath: IndexPath) {
        // Still figuring out how to cancel
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
        if let image = wikiDoc.image {
            print("From WikiDoc")
            wikiCell.wikiTitleImageView?.image = image
        } else {
            wikiCell.wikiTitleImageView?.image = nil
            generateImage(forItemAtIndex: indexPath)
        }
        
        return wikiCell
    }
    
}

// MARK: - UISearchResultsUpdating
extension WikiTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.characters.count > 2 else { return }
        search(for: searchText)
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension WikiTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetchRowsAt \(indexPaths)")
        indexPaths.forEach { generateImage(forItemAtIndex: $0) }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("cancelPrefetchingForRowsAt \(indexPaths)")
        indexPaths.forEach { cancelImage(forItemAtIndex: $0) }
    }
}
