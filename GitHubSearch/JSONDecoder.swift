//
//  JSONDecoder.swift
//  GitHubSearch
//
//  Created by Tomohiro Nishimura on 2015/09/21.
//  Copyright © 2015年 Tomohiro Nishimura. All rights reserved.
//

import Foundation

public typealias JSONObject = [String : AnyObject]

public protocol JSONDecodable {
    init(json: JSONObject) throws
}

public enum JSONDecodeError: ErrorType, CustomDebugStringConvertible {
    case MissingRequiredKey(String)
    case UnexpectedTye(key: String, expected: Any.Type, actual: Any.Type)
    case CannotParseURL(key: String, value: String)
    case CannotParseDate(key: String, value: String)

    public var debugDescription: String {
        switch self {
        case .MissingRequiredKey(let key):
            return "JSON Decode Error: Required key '\(key)' missing"
        case let .UnexpectedTye(key: key, expected: expected, actual: actual):
            return "JSON Decode Error: Unexpected type '\(actual)' was supplied for '\(key)': \(expected)"
        case let .CannotParseURL(key: key, value: value):
            return "JSON Decode Error: Cannot parse URL '\(value)' for key '\(key)'"
        case let .CannotParseDate(key: key, value: value):
            return "JSON Decode Error: Cannot parse date '\(value)' for key '\(key)'"
        }
    }
}

public class JSONDecoder {
    private let json: JSONObject

    public init(json: JSONObject) {
        self.json = json
    }

    public func getValue<T>(key: String) throws -> T {
        guard let value = json[key] else {
            throw JSONDecodeError.MissingRequiredKey(key)
        }
        guard let typedValue = value as? T else {
            throw JSONDecodeError.UnexpectedTye(key: key, expected: T.self, actual: value.dynamicType)
        }
        return typedValue
    }

    public func getOptionalValue<T>(key: String) throws -> T? {
        guard let value = json[key] else {
            return nil
        }
        if value is NSNull {
            return nil
        }
        guard let typedValue = value as? T else {
            throw JSONDecodeError.UnexpectedTye(key: key, expected: T.self, actual: value.dynamicType)
        }
        return typedValue
    }

    public func getURL(key: String) throws -> NSURL {
        let URLString: String = try getValue(key)
        guard let URL = NSURL(string: URLString) else {
            throw JSONDecodeError.CannotParseURL(key: key, value: URLString)
        }
        return URL
    }

    public func getOptionalURL(key: String) throws -> NSURL? {
        guard let URLString: String = try getOptionalValue(key) else { return nil }
        guard let URL = NSURL(string: URLString) else {
            throw JSONDecodeError.CannotParseURL(key: key, value: URLString)
        }
        return URL
    }

    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()

    public func getDate(key: String) throws -> NSDate {
        let dateString: String = try getValue(key)
        guard let date = dateFormatter.dateFromString(dateString) else {
            throw JSONDecodeError.CannotParseDate(key: key, value: dateString)
        }
        return date
    }

    public func getOptionalDate(key: String) throws -> NSDate? {
        guard let dateString: String = try getOptionalValue(key) else { return nil }
        guard let date = dateFormatter.dateFromString(dateString) else {
            throw JSONDecodeError.CannotParseDate(key: key, value: dateString)
        }
        return date
    }
}
