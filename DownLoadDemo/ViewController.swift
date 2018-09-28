//
//  ViewController.swift
//  DownLoadDemo
//
//  Created by 小星星 on 2018/9/28.
//  Copyright © 2018年 yangxin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    static let cellId = "ViewControllerCell"
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: self.view.bounds, style: .plain)
        table.showsHorizontalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 60
        table.tableFooterView = UIView()
        return table
    }()
    let videoleUrls: [String] = {
        return ["https://dn-mykplus.qbox.me/1.mp4","https://dn-mykplus.qbox.me/2.mp4","https://dn-mykplus.qbox.me/3.mp4"]
    }()
    let videoNames: [String] = {
        return ["老男孩第1集.mp4", "老男孩第2集.mp4", "老男孩第3集.mp4"]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: ViewController.cellId)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.cellId, for: indexPath)
        cell.textLabel?.text = ["多选单选下载", "单个任务追加下载", "正在下载...","已下载目录"][indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let choseVC = ChoseTasksViewController()
            navigationController?.pushViewController(choseVC, animated: true)
        }
        
        if indexPath.row == 1 {
            
            let actionSheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            for i in 0 ..< videoleUrls.count {
                let url = videoleUrls[i]
                let name = videoNames[i]
                actionSheet.addAction(UIAlertAction.init(title: url, style: .default, handler: { (action) in
                    let manager = NicooManager("TaskListViewController", MaximumRunning: 3, isStoreInfo: true)
                    manager.download(url, fileName: name, progressHandler: nil, successHandler: nil, failureHandler: nil)
                }))
            }
            actionSheet.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true, completion: nil)
            
        }
        if indexPath.row == 2 {
            let taskListVC = TasksListViewController()
            taskListVC.tasksManager.totalStart()
            navigationController?.pushViewController(taskListVC, animated: true)
            
        }
        
        if indexPath.row == 3 {
            let filevc = FileViewController()
            navigationController?.pushViewController(filevc, animated: true)
        }
    }
}



