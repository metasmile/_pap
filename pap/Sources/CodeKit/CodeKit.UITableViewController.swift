//
// Created by BLACKGENE on 10.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
//
// MARK :- TableViewController
//
class TableViewController: UITableViewController {

    private let headerId = "headerId"
    private let footerId = "footerId"
    private let cellId = "cellId"

    //
    // MARK :- HEADER
    //
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//
//        return 150
//    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerId) as! CustomTableViewHeader
        return header
    }

    //
    // MARK :- FOOTER
    //
//    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 150
//    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerId) as! CustomTableViewFooter
        return footer
    }

    //
    // MARK :- CELL
    //
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//
//        return 150
//    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CustomTableCell
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "TableView Demo"
        view.backgroundColor = .white
        setupTableView()
    }

    func setupTableView() {

        tableView.backgroundColor = .lightGray
        tableView.register(CustomTableViewHeader.self, forHeaderFooterViewReuseIdentifier: headerId)
        tableView.register(CustomTableViewFooter.self, forHeaderFooterViewReuseIdentifier: footerId)
        tableView.register(CustomTableCell.self, forCellReuseIdentifier: cellId)
    }
}

//
// MARK :- HEADER
//
class CustomTableViewHeader: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .orange
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
// MARK :- FOOTER
//
class CustomTableViewFooter: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .green
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
// MARK :- CELL
//
class CustomTableCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}