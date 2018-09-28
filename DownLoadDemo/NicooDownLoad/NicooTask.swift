//
//  NicooTask.swift
//  Nicoo
//
//  Created by yangxin on 2018/9/16.
//  Copyright © 2018年 小星星. All rights reserved.
//

import Foundation

public class NicooTask: NSObject {
    
    internal weak var manager: NicooManager?
    internal var cache: NicooCache
    internal var session: URLSession?

    internal var progressHandler: NicooTaskHandler?
    internal var successHandler: NicooTaskHandler?
    internal var failureHandler: NicooTaskHandler?

    private let queue = DispatchQueue(label: "com.Nicoo.Task.queue")

    internal var request: URLRequest?

    private var internalStatus: NicooStatus = .waiting
    public var status: NicooStatus {
        get {
            return queue.sync {
                internalStatus
            }
        }
        set {
            return queue.sync {
                internalStatus = newValue
            }
        }
    }

    private var internalURLString: String
    @objc public var URLString: String {
        get {
            return queue.sync {
                internalURLString
            }
        }
        set {
            return queue.sync {
                internalURLString = newValue
            }
        }
    }

    public internal(set) var progress: Progress = Progress()


    private var internalStartDate: Double = 0
    @objc public internal(set) var startDate: Double {
        get {
            return queue.sync {
                internalStartDate
            }
        }
        set {
            return queue.sync {
                internalStartDate = newValue
            }
        }
    }

    private var internalEndDate: Double = 0
    @objc public internal(set) var endDate: Double {
        get {
            return queue.sync {
                internalEndDate
            }
        }
        set {
            return queue.sync {
                internalEndDate = newValue
            }
        }
    }


    private var internalSpeed: Int64 = 0
    public internal(set) var speed: Int64 {
        get {
            return queue.sync {
                internalSpeed
            }
        }
        set {
            return queue.sync {
                internalSpeed = newValue
            }
        }
    }

    /// 默认为url最后一部分
    private var internalFileName: String
    @objc public internal(set) var fileName: String {
        get {
            return queue.sync {
                internalFileName
            }
        }
        set {
            return queue.sync {
                internalFileName = newValue
            }
        }
    }

    private var internalTimeRemaining: Int64 = 0
    public internal(set) var timeRemaining: Int64 {
        get {
            return queue.sync {
                internalTimeRemaining
            }
        }
        set {
            return queue.sync {
                internalTimeRemaining = newValue
            }
        }
    }

    public let url: URL
    
    public var error: NSError?

    public init(_ url: URL, cache: NicooCache, isCacheInfo: Bool = false, progressHandler: NicooTaskHandler? = nil, successHandler: NicooTaskHandler? = nil, failureHandler: NicooTaskHandler? = nil) {
        self.url = url
        self.internalFileName = url.lastPathComponent
        self.progressHandler = progressHandler
        self.successHandler = successHandler
        self.failureHandler = failureHandler
        self.internalURLString = url.absoluteString
        self.cache = cache

        super.init()
    }

    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "status" {
            status = NicooStatus(rawValue: value as! String)!
        }
    }


    internal func start() {
        let requestUrl = URL(string: URLString)!
        let request = URLRequest(url: requestUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
        self.request = request
    }
    

    
    internal func suspend() {
        
        
    }
    
    internal func cancel() {
        
        
    }

    internal func remove() {


    }

    internal func completed() {


    }
    
}

// MARK: - closure
extension NicooTask {
    @discardableResult
    public func progress(_ handler: @escaping NicooTaskHandler) -> Self {
        progressHandler = handler
        return self
    }

    @discardableResult
    public func success(_ handler: @escaping NicooTaskHandler) -> Self {
        successHandler = handler
        return self
    }

    @discardableResult
    public func failure(_ handler: @escaping NicooTaskHandler) -> Self {
        failureHandler = handler
        return self
    }
}
