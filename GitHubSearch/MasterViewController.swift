//
//  MasterViewController.swift
//  GitHubSearch
//
//  Created by Tomohiro Nishimura on 2015/09/21.
//  Copyright © 2015年 Tomohiro Nishimura. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var searchManager: SearchRepositoriesManager?

    lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.delegate = self
        controller.searchBar.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = searchController.searchBar
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let repository = searchManager?.repositories[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.repository = repository
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    private func executeSearch(refresh: Bool) {
        searchManager?.search(refresh) { [unowned self] (error) in
            if let error = error {
                print(error)
            } else {
                self.tableView.reloadData()
                self.searchController.active = false
            }
        }
    }

    // MARK: - Table View

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchManager?.repositories.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel!.text = searchManager?.repositories[indexPath.row].fullName
        return cell
    }

    private let updateThrethold = 5

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let searchManager = searchManager else { return }

        let updateIndex = searchManager.repositories.count - updateThrethold
        if indexPath.row >= updateIndex {
            executeSearch(false)
        }
    }
}

extension MasterViewController: UISearchControllerDelegate {
}

extension MasterViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        guard let searchManager = SearchRepositoriesManager(api: GitHubAPI(), query: searchText) else { return }
        self.searchManager = searchManager
        executeSearch(true)
    }
}
