//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, PullToRefreshDelegate {

    @IBOutlet weak var tableView: UITableView!
    var texts = ["Swift", "Java", "Objective-C", "Perl", "C", "C++", "Ruby", "Javascript", "Go", "PHP", "Python", "Scala"]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Sample"

        self.tableView.separatorColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        self.tableView.addPullToRefresh(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
       
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return texts.count
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.font = UIFont.italicSystemFont(ofSize: 18)
        cell.textLabel?.textColor = UIColor(red: 44/255, green: 62/255, blue: 88/255, alpha: 1.0)
        cell.textLabel?.text = texts[indexPath.row]
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.tableView.fixedPullToRefreshViewForDidScroll()
    }

    func didCompletePullToRefresh() {
        // some code
        sleep(1)
        texts.shuffle()
        tableView.reloadData()
        //self?.tableView.stopPullToRefresh()
    }
}

