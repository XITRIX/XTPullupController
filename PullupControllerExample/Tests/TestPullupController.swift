//
//  TestPullupController.swift
//  PullupController
//
//  Created by Даниил Виноградов on 12.04.2021.
//

import UIKit
import XTPopupController

class TestPullupController: XTPullupController {
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView = tableView

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
    }
}

extension TestPullupController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Cell #\(indexPath.row)"
        return cell
    }
}
