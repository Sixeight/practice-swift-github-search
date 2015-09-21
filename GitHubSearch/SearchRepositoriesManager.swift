//
//  SearchRepositoriesManager.swift
//  GitHubSearch
//
//  Created by Tomohiro Nishimura on 2015/09/21.
//  Copyright © 2015年 Tomohiro Nishimura. All rights reserved.
//

import Foundation

public class SearchRepositoriesManager {

    public private(set) var repositories: [Repository] = []
    private var page: Int

    private let api: GitHubAPI
    private let query: String

    private var networking: Bool = false
    private var completed: Bool = false

    public init?(api: GitHubAPI, query: String) {
        self.api = api
        self.query = query
        self.page = 1

        guard !self.query.isEmpty else { return nil }
    }

    public func search(refresh: Bool, completion: (error: ErrorType?) -> Void) -> Bool {
        if (networking || completed) {
            return false
        }

        networking = true
        let endpoint = GitHubAPI.SearchRepositories(query: query, page: refresh ? 1 : page)
        api.request(endpoint) { [unowned self] (response, error) in

            if let response = response {
                if refresh {
                    self.repositories.removeAll()
                    self.page = 1 
                }
                self.repositories.appendContentsOf(response.items)
                self.page++
                self.completed = response.totalCount <= self.repositories.count
            }
            self.networking = false

            completion(error: error)
        }

        return true
    }
}