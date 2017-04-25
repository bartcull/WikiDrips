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
    fileprivate var imageCache = ImageCache()
    
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
    
    fileprivate var wikiRequests = [URLSessionTask]()
    fileprivate var wikiDocs = [[WikiDoc]]()
    
    fileprivate func search(for searchText: String?) {
        guard let searchText = searchText,
            let wikiRequest = WikiRequest(searchText: searchText) else {
                return
        }
        clearPendingRequests()
        if let request = setCompletionBlock(for: wikiRequest) {
            wikiRequests.append(request)
            request.resume()
        }
    }
    
    fileprivate func clearPendingRequests() {
        for (index, request) in wikiRequests.enumerated() {
            request.cancel()
            wikiRequests.remove(at: index)
        }
    }
    
    fileprivate func setCompletionBlock(for wikiRequest: WikiRequest) -> URLSessionDataTask? {
        let task = wikiRequest.fetchWikiDocs { [weak self] newDocs in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async(){
                if newDocs.count > 0 {
                    strongSelf.imageTasks.cancelAllOperations() // Clears the OperationQueue with consecutive searches
                    strongSelf.wikiDocs = [newDocs]
                    strongSelf.tableView.reloadData()
                }
            }
        }
        return task
    }
    
    // MARK: - Image handling
    
    fileprivate let imageTasks = OperationQueue()
    
    fileprivate func checkImage(forItemAtIndex indexPath: IndexPath) {
        guard safeIndexPath(indexPath: indexPath) else { print("unsafe indexpath"); return }
        let wikiDoc = wikiDocs[indexPath.section][indexPath.row]
        checkImage(forItemAtIndex: indexPath, withWikiDoc: wikiDoc, in: nil)
    }
    
    fileprivate func checkImage(forItemAtIndex indexPath: IndexPath, withWikiDoc wikiDoc: WikiDoc, in imageView: UIImageView?) {
        guard let initials = wikiDoc.imageInitials else { print("missing initials"); return }
        if let cachedImage = imageCache.image(forKey: initials) {
            imageView?.image = cachedImage // Prefetch rows are ignored because they have no view yet
        } else {
            generateImage(forItemAtIndex: indexPath, withInitials: initials)
        }
    }
    
    fileprivate func generateImage(forItemAtIndex indexPath: IndexPath, withInitials initials: String) {
        let generator = ImageGenerator(initials: initials)
        imageTasks.addOperation(generator)
        
        generator.completionBlock = {
            OperationQueue.main.addOperation { [weak self] in
                if generator.isCancelled {
                    print("Cancelled in completion block")
                    return
                }
                guard let image = generator.image else {
                    print("Error creating image") // I'll change this to error logging later
                    return
                }
                self?.imageCache.setImage(image, forKey: initials)
                guard let wikiCell = self?.tableView.cellForRow(at: indexPath) as? WikiTableViewCell,
                    let imageView = wikiCell.wikiTitleImageView else { return }
                imageView.image = image
            }
        }
    }
    
    private func safeIndexPath(indexPath: IndexPath) -> Bool {
        return (0..<wikiDocs.count).contains(indexPath.section) && (0..<wikiDocs[indexPath.section].count).contains(indexPath.row)
    }
    
    // MARK: - Segue to document view
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "Show Document":
                    guard let sender = sender as? WikiTableViewCell else { break }
                    guard let indexPath = tableView.indexPath(for: sender),
                        safeIndexPath(indexPath: indexPath)
                        else { print("Error with indexpath"); break }
                    
                    let wikiDoc = wikiDocs[indexPath.section][indexPath.row]
                    
                    if let viewController = segue.destination as? WikiDocViewController {
                        viewController.searchText = wikiDoc.title
                    }
                default: break
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
        wikiCell.wikiTitleImageView?.image = #imageLiteral(resourceName: "PlaceHolderImage")
        checkImage(forItemAtIndex: indexPath, withWikiDoc: wikiDoc, in: wikiCell.wikiTitleImageView)
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
        indexPaths.forEach {
            checkImage(forItemAtIndex: $0)
        }
    }
    
// No need for cancelPrefetchingForRowsAt since changing search cancels pending operations and prefetchRowsAt populates a cache
}

// MARK: - ImageCache
class ImageCache: NSCache<AnyObject, AnyObject> {
    func setImage(_ image: UIImage, forKey: String) {
        let cacheKey:NSString = forKey as NSString //NSCache won't take String, so casting to NSString
        setObject(image, forKey: cacheKey)
    }

    func image(forKey: String) -> UIImage? {
        let cacheKey:NSString = forKey as NSString //NSCache won't take String, so casting to NSString
        return object(forKey: cacheKey) as? UIImage
    }
}
