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
    
    fileprivate var searchText: String?
    fileprivate var semaphore: Timer?
    fileprivate let timerInterval: TimeInterval = 0.4
    fileprivate var latestWikiRequest: WikiRequest?
    fileprivate var wikiDocs = [[WikiDoc]]()
    fileprivate var pageIndex = 0
    fileprivate var pendingSearch = false
    
    fileprivate func search() {
        if let semaphore = semaphore, semaphore.isValid {
            semaphore.invalidate()
        }
        createSemaphore()
    }
    
    fileprivate func shouldGetNextPage(indexPath: IndexPath) -> Bool {
        guard !pendingSearch else { return false }
        
        let docCount = wikiDocs[indexPath.section].count
        let expectedDocCount = WikiRequest.searchLimit * (1 + pageIndex)
        // we've reached the end if docCount is lower than expected
        guard expectedDocCount == docCount else { return false }
        
        let threshhold = docCount - (WikiRequest.searchLimit / 2)
        return (indexPath.row >= threshhold)
    }
    
    fileprivate func createSemaphore() {
        semaphore = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: false, block: { [weak self] _ in
            self?.createSearchRequest()
        })
        semaphore?.tolerance = timerInterval * 0.2
    }
    
    fileprivate func createSearchRequest() {
        latestWikiRequest?.cancel()
        guard let searchText = searchText,
            !searchText.isEmpty,
            let wikiRequest = WikiRequest(searchText: searchText, pageIndex: pageIndex)
            else { return }
        latestWikiRequest = wikiRequest
        pendingSearch = true
        setCompletionBlock(for: wikiRequest)
        wikiRequest.task?.resume()
    }
    
    fileprivate func setCompletionBlock(for wikiRequest: WikiRequest) {
        let isFirstResult = (wikiRequest.offset == 0)
        wikiRequest.fetchWikiDocs { [weak self] newDocs in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async(){
                if wikiRequest.isCancelled {
                    print("Cancelled in search completion block")
                    return
                }
                if newDocs.count > 0 {
                    strongSelf.clearPendingImageTasks() // Remove stale tasks created by consecutive searches
                    strongSelf.pendingSearch = false
                    if isFirstResult {
                        strongSelf.wikiDocs = [newDocs]
                    } else {
                        strongSelf.wikiDocs[0] += (newDocs)
                    }
                    strongSelf.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Image handling
    
    fileprivate let imageTasks = OperationQueue()
    fileprivate var pendingImageTasks = [IndexPath: ImageGenerator]()
    
    fileprivate func clearPendingImageTasks() {
        imageTasks.cancelAllOperations()
        pendingImageTasks = [:]
    }
    
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
        pendingImageTasks[indexPath] = generator
        imageTasks.addOperation(generator)
        
        generator.completionBlock = {
            OperationQueue.main.addOperation { [weak self] in
                self?.pendingImageTasks[indexPath] = nil
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
        return (0..<wikiDocs.count) ~= indexPath.section && (0..<wikiDocs[indexPath.section].count) ~= indexPath.row
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
        guard let text = searchController.searchBar.text else { return }
        pageIndex = 0
        wikiDocs = [[WikiDoc]]()
        clearPendingImageTasks()
        latestWikiRequest?.cancel()
        tableView.reloadData()
        searchText = text
        search()
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension WikiTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            checkImage(forItemAtIndex: $0)
            if shouldGetNextPage(indexPath: $0) {
                pendingSearch = true
                pageIndex += 1
                search()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            pendingImageTasks[$0]?.cancel()
            pendingImageTasks[$0] = nil
        }
    }
}

// MARK: - ImageCache
class ImageCache: NSCache<NSString, AnyObject> {
    func setImage(_ image: UIImage, forKey: String) {
        let cacheKey = forKey as NSString //NSCache won't take String, so casting to NSString
        setObject(image, forKey: cacheKey)
    }
    
    func image(forKey: String) -> UIImage? {
        let cacheKey:NSString = forKey as NSString //NSCache won't take String, so casting to NSString
        return object(forKey: cacheKey) as? UIImage
    }
}
