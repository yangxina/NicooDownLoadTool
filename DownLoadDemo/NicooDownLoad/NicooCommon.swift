//
//  TRCommon.swift
//  Nicoo
//
//  Created by yangxin on 2018/9/16.
//  Copyright © 2018年 小星星. All rights reserved.
//

import UIKit

public enum NicooStatus: String {
    case waiting
    case running
    case suspend
    case cancel
    case failed
    case remove
    case completed

    // 预操作标记，解决操作运行中的任务是异步回调而导致的问题
    case preSuspend
    case preCancel
    case preRemove
}

public enum NicooLogLevel {
    case high
    case low
    case none
}


public typealias NicooTaskHandler = (NicooTask) -> ()
public typealias NicooManagerHandler = (NicooManager) -> ()

public class Nicoo<Base> {
    private let base: Base
    init(_ base: Base) {
        self.base = base
    }
}


public protocol NicooCompatible {
    associatedtype CompatibleType
    var tr: CompatibleType { get }
}


extension NicooCompatible {
    public var tr: Nicoo<Self> {
        get { return Nicoo(self) }
    }
}

extension Int64: NicooCompatible {}
extension Double: NicooCompatible {}
extension UIDevice: NicooCompatible {}
extension DispatchQueue: NicooCompatible {}


extension Nicoo where Base == Int64 {

    /// 返回下载速度的字符串，如：1MB/s
    ///
    /// - Returns:
    public func convertSpeedToString() -> String {
        let length = Double(base)
        if length >= pow(1024, 3) {
            return "\(String(format: "%.2f", length / pow(1024, 3)))GB/s"
        } else if length >= pow(1024, 2) {
            return "\(String(format: "%.2f", length / pow(1024, 2)))MB/s"
        } else if length >= 1024 {
            return "\(String(format: "%.0f", length / 1024))KB/s"
        } else {
            return "\(base)B/s"
        }
    }

    /// 返回 00：00格式的字符串
    ///
    /// - Returns:
    public func convertTimeToString() -> String {
        let time = Double(base)
        let date = Date(timeIntervalSinceNow: time)
        var timeString = ""
        let calender = Calendar.current
        let set: Set<Calendar.Component> = [.hour, .minute, .second]
        let dateCmp = calender.dateComponents(set, from: Date(), to: date)
        if let hour = dateCmp.hour, let minute = dateCmp.minute {
            if hour > 0 {
                timeString = timeString + "\(String(format: "%02d", hour)):"
            }
            timeString = timeString + "\(String(format: "%02d", minute)):"
            let second = time - Double(hour * 3600 + minute * 60)
            timeString = timeString + "\(String(format: "%02d", Int(second)))"
        }
        return timeString
    }

    /// 返回字节大小的字符串
    ///
    /// - Returns:
    public func convertBytesToString() -> String {
        let length = Double(base)
        if length >= pow(1024, 3) {
            return "\(String(format: "%.2f", length / pow(1024, 3)))GB"
        } else if length >= pow(1024, 2) {
            return "\(String(format: "%.2f", length / pow(1024, 2)))MB"
        } else if length >= 1024 {
            return "\(String(format: "%.0f", length / 1024))KB"
        } else {
            return "\(base)B"
        }
    }


}

extension Nicoo where Base == Double {
    /// 返回 yyyy-MM-dd HH:mm:ss格式的字符串
    ///
    /// - Returns:
    public func convertTimeToDateString() -> String {
        let time = base + 3600 * 8
        let date = Date(timeIntervalSince1970: time)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

}

extension Nicoo where Base: UIDevice {
    public var freeDiskSpaceInBytes: Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space ?? 0
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
}

extension Nicoo where Base: DispatchQueue {
    internal func safeAsync(_ block: @escaping ()->()) {
        if base === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            base.async { block() }
        }
    }
}




extension Array {
    public func safeObjectAtIndex(_ index: Int) -> Element? {
        if index < self.count {
            return self[index]
        } else {
            return nil
        }
    }
}


public func NicooLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {

    switch NicooManager.logLevel {
    case .high:
        print("")
        print("***************NicooLog****************")
        let threadNum = (Thread.current.description as NSString).components(separatedBy: "{").last?.components(separatedBy: ",").first ?? ""

        print("File    :  \((file as NSString).lastPathComponent)\n" +
            "Thread  :  \(threadNum)\n" +
            "line    :  \(line)\n" +
            "Info    :  \(message)"
        )
        print("")
    case .low: print(message)
    case .none: break
    }
}


