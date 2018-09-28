//
//  NicooCache.swift
//  Nicoo
//
//  Created by yangxin on 2018/9/16.
//  Copyright © 2018年 小星星. All rights reserved.
//

import UIKit

public class NicooCache {
    
    public static let `default` = NicooCache("default")
    
    public typealias DiskCachePathClosure = (String?, String) -> String

    private let ioQueue: DispatchQueue
    
    public let downloadPath: String

    internal var isStoreInfo: Bool

    public let downloadTmpPath: String
    
    public let downloadFilePath: String
    
    public let name: String
    
    private let fileManager = FileManager.default
    
    public final class func defaultDiskCachePathClosure(_ cacheName: String) -> String {
        let dstPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return (dstPath as NSString).appendingPathComponent(cacheName)
    }
    
    // MARK: - life cycle


    /// 初始化方法
    ///
    /// - Parameters:
    ///   - name: 设置NicooCache对象的名字，一般由NicooManager对象创建时传递
    ///   - isStoreInfo: 是否把下载任务的相关信息持久化到沙盒，一般由NicooManager对象创建时传递
    public init(_ name: String, isStoreInfo: Bool = false) {
        self.name = name

        self.isStoreInfo = isStoreInfo
        
        let ioQueueName = "Nicoo.Cache.ioQueue.\(name)"
        ioQueue = DispatchQueue(label: ioQueueName)
        
        let cacheName = "Nicoo.Cache.\(name)"
        
        let diskCachePath = NicooCache.defaultDiskCachePathClosure(cacheName)
        
        downloadPath = (diskCachePath as NSString).appendingPathComponent("Downloads")

        downloadTmpPath = (downloadPath as NSString).appendingPathComponent("Tmp")
        
        downloadFilePath = (downloadPath as NSString).appendingPathComponent("File")
                
        createDirectory()
        
    }

}


// MARK: - file
extension NicooCache {
    public func createDirectory() {
        
        if !fileManager.fileExists(atPath: downloadPath) {
            do {
                try fileManager.createDirectory(atPath: downloadPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {}
        }
        
        if !fileManager.fileExists(atPath: downloadTmpPath) {
            do {
                try fileManager.createDirectory(atPath: downloadTmpPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {}
        }
        
        if !fileManager.fileExists(atPath: downloadFilePath) {
            do {
                try fileManager.createDirectory(atPath: downloadFilePath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {}
        }
    }
    
    
    public func filePtah(URLString: String) -> String? {
        guard let fileName = URL(string: URLString)?.lastPathComponent else { return nil }
        return filePtah(fileName: fileName)
    }

    public func fileURL(URLString: String) -> URL? {
        guard let path = filePtah(URLString: URLString) else { return nil }
        return URL(fileURLWithPath: path)
    }

    public func fileExists(URLString: String) -> Bool {
        guard let path = filePtah(URLString: URLString) else { return false }
        return fileManager.fileExists(atPath: path)
    }


    public func filePtah(fileName: String) -> String? {
        if fileName.isEmpty {
            return nil
        }
        let path = (downloadFilePath as NSString).appendingPathComponent(fileName)
        print("downLoadFilePath: = \(path)")
        return path
    }
    
    public func fileURL(fileName: String) -> URL? {
        guard let path = filePtah(fileName: fileName) else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    public func fileExists(fileName: String) -> Bool {
        guard let path = filePtah(fileName: fileName) else { return false }
        return fileManager.fileExists(atPath: path)
    }
    
    
    public func clearDiskCache() {
        ioQueue.async {
            guard self.fileManager.fileExists(atPath: self.downloadPath) else { return }
            try? self.fileManager.removeItem(atPath: self.downloadPath)
            self.createDirectory()
        }
    }
}


// MARK: - retrieve
extension NicooCache {
    public func retrieveTasks() -> [NicooTask] {
        guard let taskInfoArray = retrieveTaskInfos() else { return [NicooTask]() }
        return taskInfoArray.map { (info) -> NicooDownloadTask in
            let url = URL(string: info["URLString"] as! String)!
            let task = NicooDownloadTask(url, fileName: info["fileName"] as? String, cache: self, isCacheInfo: isStoreInfo)

            task.setValuesForKeys(info)

            task.status = NicooStatus(rawValue: info["status"] as! String)!
            task.progress.totalUnitCount = info["totalBytes"] as! Int64
            if task.status == .completed {
                task.progress.completedUnitCount = task.progress.totalUnitCount
            } else {
                let path = (self.downloadTmpPath as NSString).appendingPathComponent(task.fileName)
                if self.fileManager.fileExists(atPath: path) {
                    if let fileInfo = try? FileManager().attributesOfItem(atPath: path), let length = fileInfo[.size] as? Int64 {
                        task.progress.completedUnitCount = length
                    }
                }
            }
            if task.status == .running {
                task.status = .suspend
            }

            if task.status == .waiting {
                task.status = .suspend
            }
            
            storeTaskInfo(task)
            return task
        }
    }
    
    public func retrieveTaskInfos() -> [[String: Any]]? {
        let path = (downloadPath as NSString).appendingPathComponent(name + "Tasks.plist")
        if fileManager.fileExists(atPath: path) {
            guard let array = NSArray(contentsOfFile: path) as? [[String: Any]] else { return nil }
            return array
        } else {
            return nil
        }
    }

}


// MARK: - store
extension NicooCache {
    public func store(_ task: NicooDownloadTask) {
        storeTaskInfo(task)
        storeTmpFile(task)
    }
    
    
    public func storeTaskInfo(_ task: NicooDownloadTask) {
        ioQueue.async {
            guard self.isStoreInfo else { return }
            let info: [String : Any] = ["fileName": task.fileName,
                                        "startDate": task.startDate,
                                        "endDate": task.endDate,
                                        "totalBytes": task.progress.totalUnitCount,
                                        "completedBytes": task.progress.completedUnitCount,
                                        "status": task.status.rawValue,
                                        "URLString": task.URLString]
            let path = (self.downloadPath as NSString).appendingPathComponent("\(self.name)Tasks.plist")
            
            if let taskInfoArray = self.retrieveTaskInfos() {
                var isExists = false
                var newTaskInfoArray = taskInfoArray.map({ (taskInfo) -> [String : Any] in
                    if taskInfo["URLString"] as! String == info["URLString"] as! String {
                        isExists = true
                        return info
                    } else {
                        return taskInfo
                    }
                })
                if !isExists {
                    newTaskInfoArray.append(info)
                }
                (newTaskInfoArray as NSArray).write(toFile: path, atomically: true)
            } else {
                ([info] as NSArray).write(toFile: path, atomically: true)
                
            }

        }

    }
    
    public func storeTmpFile(_ task: NicooDownloadTask) {
        ioQueue.sync {
            if task.fileName.isEmpty { return }
            let path = (self.downloadTmpPath as NSString).appendingPathComponent(task.fileName)
            if self.fileManager.fileExists(atPath: path) {
                let destination = (self.downloadFilePath as NSString).appendingPathComponent(task.fileName)
                try? self.fileManager.moveItem(atPath: path, toPath: destination)
            }
        }
    }

}


// MARK: - remove
extension NicooCache {
    public func remove(_ task: NicooDownloadTask, completely: Bool) {
        removeTmpFile(task)
        removeTaskInfo(task)

        if completely {
            removeFile(task)
        }
    }
    
    public func removeFile(_ task: NicooDownloadTask) {
        ioQueue.async {
            if task.fileName.isEmpty { return }
            let path = (self.downloadFilePath as NSString).appendingPathComponent(task.fileName)
            if self.fileManager.fileExists(atPath: path) {
                try? self.fileManager.removeItem(atPath: path)
            }
        }
    }
    
    public func removeTaskInfo(_ task: NicooDownloadTask) {
        ioQueue.async {
            guard var taskInfoArray = self.retrieveTaskInfos() else { return }
            let path = (self.downloadPath as NSString).appendingPathComponent("\(self.name)Tasks.plist")
            if let index = taskInfoArray.index(where: { $0["URLString"] as! String == task.URLString }) {
                taskInfoArray.remove(at: index)
                let _ = (taskInfoArray as NSArray).write(toFile: path, atomically: true)
            }
        }
    }
    


    /// 删除保留在本地的缓存文件
    ///
    /// - Parameter task:
    public func removeTmpFile(_ task: NicooDownloadTask) {
        objc_sync_enter(self)
        ioQueue.async {
            if task.fileName.isEmpty { return }
            let path = (self.downloadTmpPath as NSString).appendingPathComponent(task.fileName)
            if self.fileManager.fileExists(atPath: path) {
                try? self.fileManager.removeItem(atPath: path)
            }
        }
        objc_sync_exit(self)
    }
}


