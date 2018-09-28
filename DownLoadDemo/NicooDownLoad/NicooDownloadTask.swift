//
//  NicooDownloadTask.swift
//  Nicoo
//
//  Created by yangxin on 2018/9/16.
//  Copyright © 2018年 小星星. All rights reserved.
//

import UIKit

public class NicooDownloadTask: NicooTask {

    private var task: URLSessionDataTask?
    private var outputStream: OutputStream?

    public init(_ url: URL, fileName: String? = nil, cache: NicooCache, isCacheInfo: Bool = false, progressHandler: NicooTaskHandler? = nil, successHandler: NicooTaskHandler? = nil, failureHandler: NicooTaskHandler? = nil) {

        super.init(url, cache: cache, isCacheInfo: isCacheInfo, progressHandler: progressHandler, successHandler: successHandler, failureHandler: failureHandler)
        if let fileName = fileName {
            if !fileName.isEmpty {
                self.fileName = fileName
            }
        }
        cache.storeTaskInfo(self)
    }

    
    internal override func start() {

        super.start()
        cache.createDirectory()
        // 读取缓存中已经下载了的大小
        let path = (cache.downloadTmpPath as NSString).appendingPathComponent(fileName)
        if FileManager().fileExists(atPath: path) {
            if let fileInfo = try? FileManager().attributesOfItem(atPath: path), let length = fileInfo[.size] as? Int64 {
                progress.completedUnitCount = length
            }
        }

        request?.setValue("bytes=\(progress.completedUnitCount)-", forHTTPHeaderField: "Range")
        guard let request = request else { return  }
        task = session?.dataTask(with: request)

        speed = 0
        progress.setUserInfoObject(progress.completedUnitCount, forKey: .fileCompletedCountKey)

        task?.resume()
        if startDate == 0 {
            startDate = Date().timeIntervalSince1970
        }
        status = .running

    }


    
    internal override func suspend() {
        guard status == .running || status == .waiting else { return }
        NicooLog("[downloadTask] did suspend \(self.URLString)")

        if status == .running {
            status = .preSuspend
            task?.cancel()
        }

        if status == .waiting {
            status = .suspend
            DispatchQueue.main.tr.safeAsync {
                self.progressHandler?(self)
                self.successHandler?(self)
            }
            manager?.completed()
        }
    }
    
    internal override func cancel() {
        guard status != .completed else { return }
        NicooLog("[downloadTask] did cancel \(self.URLString)")
        if status == .running {
            status = .preCancel
            task?.cancel()
        } else {
            status = .preCancel
            manager?.taskDidCancelOrRemove(URLString)
            DispatchQueue.main.tr.safeAsync {
                self.failureHandler?(self)
            }
            manager?.completed()
        }
        
    }


    internal override func remove() {
        NicooLog("[downloadTask] did remove \(self.URLString)")
        if status == .running {
            status = .preRemove
            task?.cancel()
        } else {
            status = .preRemove
            manager?.taskDidCancelOrRemove(URLString)
            DispatchQueue.main.tr.safeAsync {
                self.failureHandler?(self)
            }
            manager?.completed()
        }
    }
    
    internal override func completed() {
        guard status != .completed else { return }
        status = .completed
        endDate = Date().timeIntervalSince1970
        progress.completedUnitCount = progress.totalUnitCount
        timeRemaining = 0
        cache.store(self)
        NicooLog("[downloadTask] a task did complete URLString: \(URLString)")
        DispatchQueue.main.tr.safeAsync {
            self.progressHandler?(self)
            self.successHandler?(self)
        }

    }

}

// MARK: - info
extension NicooDownloadTask {

    internal func parseSpeed(_ cost: TimeInterval) {

        let dataCount = progress.completedUnitCount
        var lastData: Int64 = 0
        if progress.userInfo[.fileCompletedCountKey] != nil {
            lastData = progress.userInfo[.fileCompletedCountKey] as! Int64
        }
        if dataCount > lastData {
            speed = Int64(Double(dataCount - lastData) / cost)
            parseTimeRemaining()
        }

        progress.setUserInfoObject(dataCount, forKey: .fileCompletedCountKey)

    }

    private func parseTimeRemaining() {
        if speed == 0 {
            self.timeRemaining = 0
        } else {
            let timeRemaining = (Double(progress.totalUnitCount) - Double(progress.completedUnitCount)) / Double(speed)
            self.timeRemaining = Int64(timeRemaining)
            if timeRemaining < 1 && timeRemaining > 0.8 {
                self.timeRemaining += 1
            }
        }
    }
}

// MARK: - download callback
extension NicooDownloadTask {
    internal func task(didReceive response: HTTPURLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let bytesStr = response.allHeaderFields["Content-Length"] as? String, let totalBytes = Int64(bytesStr) {
            progress.totalUnitCount = totalBytes
        }
        if let contentRangeStr = response.allHeaderFields["content-range"] as? NSString {
            if contentRangeStr.length > 0 {
                progress.totalUnitCount = Int64(contentRangeStr.components(separatedBy: "/").last!)!
            }
        }
        if let contentRangeStr = response.allHeaderFields["Content-Range"] as? NSString {
            if contentRangeStr.length > 0 {
                progress.totalUnitCount = Int64(contentRangeStr.components(separatedBy: "/").last!)!
            }
        }


        if progress.completedUnitCount == progress.totalUnitCount {
            cache.store(self)
            completed()
            manager?.completed()
            completionHandler(.cancel)
            return
        }

        if progress.completedUnitCount > progress.totalUnitCount {
            cache.removeTmpFile(self)
            completionHandler(.cancel)
            // 重新下载
            progress.completedUnitCount = 0
            start()
            return
        }

        let downloadTmpPath = (cache.downloadTmpPath as NSString).appendingPathComponent(fileName)
        outputStream = OutputStream(toFileAtPath: downloadTmpPath, append: true)
        outputStream?.open()

        cache.storeTaskInfo(self)

        completionHandler(.allow)

        NicooLog("[downloadTask] start to download URLString: \(URLString)")

    }

    internal func task(didReceive data: Data) {

        progress.completedUnitCount += Int64((data as NSData).length)
         _ = data.withUnsafeBytes { outputStream?.write($0, maxLength: data.count) }
        manager?.parseSpeed()
        DispatchQueue.main.tr.safeAsync {
            if NicooManager.isControlNetworkActivityIndicator {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            self.progressHandler?(self)
            guard let manager = self.manager else { return }
            manager.progressHandler?(manager)
        }
    }

    internal func task(didCompleteWithError error: Error?) {
        if NicooManager.isControlNetworkActivityIndicator {
            DispatchQueue.main.tr.safeAsync {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }

        self.error = error as NSError?
        session = nil

        outputStream?.close()
        outputStream = nil

        if let _ = error {

            switch status {
            case .preSuspend:
                status = .suspend
                DispatchQueue.main.tr.safeAsync {
                    self.progressHandler?(self)
                    self.successHandler?(self)
                }
            case .preCancel, .preRemove:
                manager?.taskDidCancelOrRemove(URLString)
                DispatchQueue.main.tr.safeAsync {
                    self.failureHandler?(self)
                }
            default:
                status = .failed
                cache.storeTaskInfo(self)
                DispatchQueue.main.tr.safeAsync {
                    self.failureHandler?(self)
                }
            }
        } else {
            completed()
        }

        manager?.completed()
    }
}
