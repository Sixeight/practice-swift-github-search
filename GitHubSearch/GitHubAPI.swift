//
//  GitHub.swift
//  GitHubSearch
//
//  Created by Tomohiro Nishimura on 2015/09/21.
//  Copyright © 2015年 Tomohiro Nishimura. All rights reserved.
//

import Foundation

import AFNetworking


public enum HTTPMethod {
    case GET
//    case POST
//    case PUT
//    case DELETE
//    case HEAD
}

public enum APIError: ErrorType {
    case UnexpectedResponse
}

public struct Parameters: DictionaryLiteralConvertible {
    public private(set) var dictionary: [String : AnyObject] = [:]
    public typealias Key = String
    public typealias Value = AnyObject?

    public init(dictionaryLiteral elements: (Parameters.Key, Parameters.Value)...) {
        for case let (key, value) in elements {
            dictionary[key] = value
        }
    }
}

public protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters { get }
    typealias ResponseType: JSONDecodable
}

public class GitHubAPI {
    private let HTTPSessionManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: "https://api.github.com"))
        manager.requestSerializer.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return manager
    }()

    public init() {
    }

    public func request<Endpoint: APIEndpoint>(endpoint: Endpoint, handler: (response: Endpoint.ResponseType?, error: ErrorType?) -> Void) {
        let success = { (task: NSURLSessionDataTask!, response: AnyObject!) -> Void in
            if let json = response as? JSONObject {
                do {
                    let response = try Endpoint.ResponseType(json: json)
                    handler(response: response, error: nil)
                } catch {
                    handler(response: nil, error: error)
                }
            } else {
                handler(response: nil, error: APIError.UnexpectedResponse)
            }
        }

        let failure = { (task: NSURLSessionDataTask!, var error: NSError!) -> Void in
            if let errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData,
                let errorDescription = NSString(data: errorData, encoding: NSUTF8StringEncoding) {
                    var userInfo = error.userInfo
                    userInfo[NSLocalizedFailureReasonErrorKey] = errorDescription
                    error = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
            }
            handler(response: nil, error: error)
        }

        switch endpoint.method {
        case .GET:
            HTTPSessionManager.GET(endpoint.path, parameters: endpoint.parameters.dictionary, success: success, failure: failure)
        }
    }

    public struct SearchRepositories: APIEndpoint {
        public var path = "search/repositories"
        public var method = HTTPMethod.GET
        public var parameters: Parameters {
            return [
                "q"    : query,
                "page" : page,
            ]
        }
        public typealias ResponseType = SearchResult<Repository>

        public let query: String
        public let page: Int

        public init(query: String, page: Int) {
            self.query = query
            self.page = page
        }
    }
}

private func getValue<T>(json: JSONObject, key: String) throws -> T {
    guard let value = json[key] else {
        throw JSONDecodeError.MissingRequiredKey(key)
    }
    guard let typedValue = value as? T else {
        throw JSONDecodeError.UnexpectedTye(key: key, expected: T.self, actual: value.dynamicType)
    }
    return typedValue
}

public struct SearchResult<ItemType: JSONDecodable>: JSONDecodable {
    public let totalCount: Int
    public let incompleteResults: Bool
    public let items: [ItemType]

    public init(json: JSONObject) throws {
        self.totalCount = try getValue(json, key: "total_count")
        self.incompleteResults = try getValue(json, key: "incomplete_results")
        self.items = try (getValue(json, key: "items") as [JSONObject]).map { try ItemType(json: $0) }
    }
}

public struct Repository: JSONDecodable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let isPrivate: Bool
    public let HTMLURL: NSURL
    public let description: String?
    public let fork: Bool
    public let URL: NSURL
    public let createdAt: NSDate
    public let updatdAt: NSDate
    public let pushedAt: NSDate?
    public let homepage: String?
    public let size: Int
    public let stargazersCount: Int
    public let watchersCount: Int
    public let language: String?
    public let forksCount: Int
    public let openIssuesCount: Int
    public let masterBranch: String?
    public let defaultBranch: String
    public let score: Double
    public let owner: User

    public init(json: JSONObject) throws {
        let jsonDecoder = JSONDecoder(json: json)

        self.id = try jsonDecoder.getValue("id")
        self.name = try jsonDecoder.getValue("name")
        self.fullName = try jsonDecoder.getValue("full_name")
        self.isPrivate = try jsonDecoder.getValue("private")
        self.HTMLURL = try jsonDecoder.getURL("html_url")
        self.description = try jsonDecoder.getOptionalValue("description")
        self.fork = try jsonDecoder.getValue("fork")
        self.URL = try jsonDecoder.getURL("url")
        self.createdAt = try jsonDecoder.getDate("created_at")
        self.updatdAt = try jsonDecoder.getDate("updated_at")
        self.pushedAt = try jsonDecoder.getOptionalDate("pushed_at")
        self.homepage = try jsonDecoder.getOptionalValue("homepage")
        self.size = try jsonDecoder.getValue("size")
        self.stargazersCount = try jsonDecoder.getValue("stargazers_count")
        self.watchersCount = try jsonDecoder.getValue("watchers_count")
        self.language = try jsonDecoder.getOptionalValue("language")
        self.forksCount = try jsonDecoder.getValue("forks_count")
        self.openIssuesCount = try jsonDecoder.getValue("open_issues_count")
        self.masterBranch = try jsonDecoder.getOptionalValue("master_branch")
        self.defaultBranch = try jsonDecoder.getValue("default_branch")
        self.score = try jsonDecoder.getValue("score")
        self.owner = try User(json: jsonDecoder.getValue("owner") as JSONObject)
    }
}

public struct User: JSONDecodable {
    public let login: String
    public let id: Int
    public let avatarURL: NSURL
    public let gravatarID: String
    public let URL: NSURL
    public let receivedEventsURL: NSURL
    public let type: String

    public init(json: JSONObject) throws {
        let jsonDecoder = JSONDecoder(json: json)

        self.login = try jsonDecoder.getValue("login")
        self.id = try jsonDecoder.getValue("id")
        self.avatarURL = try jsonDecoder.getURL("avatar_url")
        self.gravatarID = try jsonDecoder.getValue("gravatar_id")
        self.URL = try jsonDecoder.getURL("url")
        self.receivedEventsURL = try jsonDecoder.getURL("received_events_url")
        self.type = try jsonDecoder.getValue("type")
    }
}

