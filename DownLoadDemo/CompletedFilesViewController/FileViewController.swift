//
//  FileViewController.swift
//  NicooDownload_Example
//
//  Created by 小星星 on 2018/9/26.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

/// 展示已下载的文件列表

class FileViewController: UIViewController {

    static let cellId = "FileListTableViewCell"
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: self.view.bounds, style: .plain)
        table.showsHorizontalScrollIndicator = false
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 120
        table.tableFooterView = UIView()
        return table
    }()
    private lazy var rightBarButton: UIBarButtonItem = {
        let barBtn = UIBarButtonItem(title: "清空",  style: .plain, target: self, action: #selector(cleanTasks(_:)))
        barBtn.tintColor = UIColor.lightGray
        barBtn.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.purple], for: .normal)
        return barBtn
    }()
    
    static let cache = NicooCache("TaskListViewController")
    
    lazy var tasks: [NicooTask] = {
        var allTasks = FileViewController.cache.retrieveTasks()
        let completedTasks = allTasks.filter { (taskModel) -> Bool in
            taskModel.status == .completed
        }
        return completedTasks
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor .white
        navigationItem.title = "已下载(侧滑删除)"
        navigationItem.rightBarButtonItem = rightBarButton
       
        view.addSubview(tableView)
        tableView.register(UINib(nibName: "FileListTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: FileViewController.cellId)

    }
    
    /// 全部删除
    @objc func cleanTasks(_ sender: UIBarButtonItem) {
        FileViewController.cache.clearDiskCache()
        tasks.removeAll()
        tableView.reloadData()
    }
    
    /// 1.删除本地文件。 2.删除数据源。3.刷新表。 （删除本地文件时，需要根据数据源来删除，所以 1、2 顺序不能互换）
    private func deleteFileAndTask(indexPath: IndexPath) {
        FileViewController.cache.remove(tasks[indexPath.row] as! NicooDownloadTask, completely: true)
        tasks.remove(at: indexPath.row)
        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileViewController.cellId, for: indexPath) as! FileListTableViewCell
        let task = tasks[indexPath.row]
        cell.configCell(task: task)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let filePath = String(format: "%@/%@", FileViewController.cache.downloadFilePath, tasks[indexPath.row].fileName)
        print("filepath = \(filePath)")
        
    }
    
    private func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        tableView.setEditing(true, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style:.default, title: "删除") { [weak self] (action, index) in
            print("deleted")
            guard let strongSelf = self else { return }
            strongSelf.deleteFileAndTask(indexPath: index)
            
        }
        let likeAction = UITableViewRowAction(style: .default, title: "😓") { (action, indexPath) in
            print("like")
        }
        deleteAction.backgroundColor = UIColor.purple
        likeAction.backgroundColor = UIColor.lightGray
       
        return [deleteAction, likeAction]
    }
}
