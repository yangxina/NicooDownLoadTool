//
//  NicooSessionDelegate.sift
//  Nicoo
//
//  Created by yangxin on 2018/9/16.
//  Copyright © 2018年 小星星. All rights reserved.
//


import UIKit

public class NicooSessionDelegate: NSObject {
    public var manager: NicooManager?

}

extension NicooSessionDelegate: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let manager = manager,
            let URLString = dataTask.originalRequest?.url?.absoluteString,
            let task = manager.fetchTask(URLString) as? NicooDownloadTask,
            let response = response as? HTTPURLResponse
            else { return  }
        task.task(didReceive: response, completionHandler: completionHandler)

    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let manager = manager,
            let URLString = dataTask.originalRequest?.url?.absoluteString,
            let task = manager.fetchTask(URLString) as? NicooDownloadTask
            else { return  }
        task.task(didReceive: data)

    }
}

extension NicooSessionDelegate: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let manager = manager,
            let URLString = task.originalRequest?.url?.absoluteString,
            let task = manager.fetchTask(URLString) as? NicooDownloadTask
            else { return  }
        task.task(didCompleteWithError: error)

    }
}
