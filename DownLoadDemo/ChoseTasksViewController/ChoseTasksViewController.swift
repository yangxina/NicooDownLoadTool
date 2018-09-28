//
//  ChoseTasksViewController.swift
//  NicooDownload_Example
//
//  Created by 小星星 on 2018/9/27.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import NicooTableListViewController

struct VideoModel {
    var name: String?
    var urlString: String?
    var isSelected: Bool? = false
}


class ChoseTasksViewController: UIViewController {
    
    lazy var URLStrings: [String] = {
        return ["https://officecdn-microsoft-com.akamaized.net/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_Office_2016_16.10.18021001_Installer.pkg",
            "http://api.gfs100.cn/upload/20180126/201801261120124536.mp4",
            "http://api.gfs100.cn/upload/20180201/201802011423168057.mp4",
            "http://api.gfs100.cn/upload/20180126/201801261545095005.mp4",
            "http://api.gfs100.cn/upload/20171218/201712181643211975.mp4",
            "http://api.gfs100.cn/upload/20171219/201712191351314533.mp4",
            "http://api.gfs100.cn/upload/20180126/201801261644030991.mp4",
            "http://api.gfs100.cn/upload/20180202/201802021322446621.mp4",
            "http://api.gfs100.cn/upload/20180201/201802011038548146.mp4",
            "http://api.gfs100.cn/upload/20180201/201802011545189269.mp4",
            "http://api.gfs100.cn/upload/20180202/201802021436174669.mp4",
            "http://api.gfs100.cn/upload/20180131/201801311435101664.mp4",
            "http://api.gfs100.cn/upload/20180131/201801311059389211.mp4",
            "http://api.gfs100.cn/upload/20171219/201712190944143459.mp4"]
    }()
    lazy var nameString: [String] = {
        let names = ["Microsoft_Office","monkeyKing.mp4","TeacherCang.mp4","来个中文试试.mp4","boduoyejieyi.mp4","201712191351314533.mp4","201801261644030991.mp4","201802021322446621.mp4","201802011038548146.mp4","201802011545189269.mp4","201802021436174669.mp4","201801311435101664.mp4","201801311059389211.mp4","201712190944143459.mp4"]
        return names
       
    }()
    
    /// 构造数据源
    lazy var videoModels: [VideoModel] = {
        var videos = [VideoModel]()
        for i in 0 ..< URLStrings.count {
            let model = VideoModel(name: nameString[i], urlString: URLStrings[i], isSelected: false)
            videos.append(model)
        }
        return videos
    }()
    
    /// tableView 基类 通过代理实现复用
    private lazy var listViewController: NicooTableListViewController = {
        let listView = NicooTableListViewController()
        listView.delegate = self
        return listView
    }()
    
    private lazy var buttonsView: MutableButtonsView = {
        let view = MutableButtonsView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        view.titlesForNormalStatus = ["全选","下载"]
        view.titlesForSelectedStatus = ["取消全选", "下载"]
        view.colorsForNormalStatus = [UIColor.darkGray, UIColor.purple]
        view.delegate = self
        return view
    }()
    private lazy var editBarButton: UIBarButtonItem = {
        let barBtn = UIBarButtonItem(title: "选择下载",  style: .plain, target: self, action: #selector(choseTasks(_:)))
        barBtn.tintColor = UIColor.lightGray
        barBtn.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.purple], for: .normal)
        return barBtn
    }()
    
    fileprivate var isEdit = false {
        didSet {
            if !isEdit {
                updateButtonViewlayout()     // 取消编辑时，重置底部按钮
            }
            navigationItem.rightBarButtonItem?.title = isEdit ? "取消" : "选择下载"
            listViewController.tableEditing = isEdit
            updateButtonViewlayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 底部删除，全选栏
        view.addSubview(buttonsView)
        navigationItem.rightBarButtonItem = editBarButton
        
        view.addSubview(listViewController.view)
        self.addChild(listViewController)
        
        layoutPageSubviews()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listViewController.reloadData()
    }
    
    
    @objc func choseTasks(_ sender: UIBarButtonItem) {

        isEdit = !isEdit
    }
 
    /// 全选或者全反选
    private func selectedAllRows(_ isAllSelected: Bool) {
        for index in 0 ..< videoModels.count {
            if !isAllSelected {
                videoModels[index].isSelected = false
                listViewController.deselectedRowAtIndexPath(IndexPath(row: index, section: 0))
            } else {
                videoModels[index].isSelected = true
                listViewController.selectedRowAtIndexPath(IndexPath(row: index, section: 0))
            }
        }
        updateSelectedRows()
    }
    
    /// 更新数据源 以及 table的选中非选中cell
    private func updateSelectedRows() {
        if let selectedIndexPaths = listViewController.getAllSelectedRows(), selectedIndexPaths.count > 0 {   /// 有选中
            updateButtonView(selectedIndexPaths.count, videoModels.count)
        } else {
            updateButtonView(0, videoModels.count)
        }
    }
    
    /// 刷新底部按钮的删除个数
    private func updateButtonView(_ selectedCount: Int, _ allCount: Int) {
        if selectedCount == 0 {
            buttonsView.buttons?[0].isSelected = false
            buttonsView.updateButtonTitle(title: "下载", at: 1, for: .normal)
            buttonsView.updateButtonTitle(title: "下载", at: 1, for: .selected)
        } else {
            buttonsView.buttons?[0].isSelected = selectedCount == allCount
            buttonsView.updateButtonTitle(title: "下载(\(selectedCount))", at: 1, for: .normal)
            buttonsView.updateButtonTitle(title: "下载(\(selectedCount))", at: 1, for: .selected)
        }
    }
    
    /// 筛选选中的Model
    private func screenSelectedModel() {
        var urls = [String]()
        var names = [String]()
        for model in videoModels {
            if model.isSelected == true {  // 选中的
                urls.append(model.urlString ?? "")
                names.append(model.name ?? "")
            }
        }
    
        downLoad(names: names, urls: urls)
        
        isEdit = false //
        for i in 0 ..< videoModels.count {
            videoModels[i].isSelected = false
        }
    }
    
    /// 开始下载
    private func downLoad(names: [String], urls: [String]) {
        let downloadVC = TasksListViewController()
        let tasksManager = downloadVC.tasksManager
        tasksManager.maxConcurrentTasksLimit = 3
        tasksManager.isStartDownloadImmediately = true
        tasksManager.multiDownload(urls, fileNames: names, progressHandler: nil, successHandler: nil, failureHandler: nil)
        downloadVC.nameString = names
        downloadVC.urlStrings = urls
        navigationController?.pushViewController(downloadVC, animated: true)
    }
    
}

// MARK: - MutableButtonsViewDelegate

extension ChoseTasksViewController: MutableButtonsViewDelegate {
    
    func didClickButton(button: UIButton, at index: Int) {
        
        if index == 0 {         // 全选
            
            selectedAllRows(button.isSelected)
            
        } else if index == 1 {  // 下载
            // 筛选选中的Model
            screenSelectedModel()
        }
    }
    
}


// MARK: - NicooTableViewDelegate

extension ChoseTasksViewController: NicooTableViewDelegate {
    
    func listTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoModels.count
    }
    
    func configCell(_ tableView: UITableView, for cell: UITableViewCell, cellForRowAt indexPath: IndexPath) {
        cell.textLabel?.text = videoModels[indexPath.row].name ?? "video"+"\(indexPath.row)"
        if videoModels[indexPath.row].name != nil {
            if NicooCache("TaskListViewController").fileExists(fileName: videoModels[indexPath.row].name!){
                cell.textLabel?.textColor = UIColor.purple
            } else {
                cell.textLabel?.textColor = UIColor.darkText
            }
            
        }
       
       // cell.textLabel?.textColor = videoModels[indexPath.row].isSelected == true ? UIColor.purple : UIColor.darkText
    }
    
    func listTableView(_ tableView: UITableView, didSelectedAtIndexPath indexPath: IndexPath) {
        
    }
    
    func editingListTableView(_ tableView: UITableView, didSelectedAtIndexPath indexPath: IndexPath, didSelected indexPaths: [IndexPath]?) {
        videoModels[indexPath.row].isSelected = true   // 选中
        updateSelectedRows()
    }
    
    func editingListTableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath, didSelected indexPaths: [IndexPath]?) {
        videoModels[indexPath.row].isSelected = false  // 反选
        updateSelectedRows()
    }
    
    func editingSelectedViewColor() -> UIColor {
        return UIColor.darkText
    }
    
}


// MARK: - Layout

extension ChoseTasksViewController {
    func layoutPageSubviews() {
        layoutButtonsView()
        layoutBaseListTableView()
    }
    
    private func layoutButtonsView() {
        buttonsView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(0)
            if #available(iOS 11.0, *) {  // 适配X
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalToSuperview()
            }
            make.height.equalTo(0)
        }
    }
    
    func layoutBaseListTableView() {
        listViewController.view.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(buttonsView.snp.top)
        }
    }
    
    private func updateButtonViewlayout() {
        buttonsView.snp.updateConstraints { (make) in
            if isEdit {
                make.height.equalTo(50)
            } else {
                make.height.equalTo(0)
            }
        }
        buttonsView.redrawButtonLines()   // 重新绘制线条
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
}
