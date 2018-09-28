//
//  FileListTableViewCell.swift
//  NicooDownload_Example
//
//  Created by 小星星 on 2018/9/27.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

class FileListTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLable: UILabel!
    @IBOutlet weak var statuLable: UILabel!
    @IBOutlet weak var sizeLable: UILabel!
    
    @IBOutlet weak var filePathLable: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configCell(task: NicooTask) {
        sizeLable.text = "总大小：\(task.progress.totalUnitCount.tr.convertBytesToString())"
        nameLable.text = task.fileName
        statuLable.text = "状态：\(task.status)"
        let filePath = String(format: "%@/%@", FileViewController.cache.downloadFilePath, task.fileName)
        filePathLable.text = filePath
    }
    
}
