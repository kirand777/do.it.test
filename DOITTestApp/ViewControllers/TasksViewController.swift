//
//  TasksViewController.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/16/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import UIKit
import MBProgressHUD
import Alamofire
import AlamofireObjectMapper
import AlamofireSwiftyJSON
import SwiftyJSON

class TasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noTasksLbl: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    var refresher: UIRefreshControl!
    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refresher = UIRefreshControl()
        self.tableView.addSubview(refresher)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        self.tableView.tableFooterView = UIView()
        
        self.addBtn.layer.cornerRadius = self.addBtn.bounds.size.width / 2

        self.loadTasks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isToolbarHidden = true
        self.tableView.reloadData()
    }
    
    func loadTasks() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Alamofire.request(ApiService.Router.allTasks([:])).responseArray(keyPath: "tasks") {
            (response: DataResponse<[Task]>) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.refresher.endRefreshing()
            if response.result.isSuccess {
                self.tasks = response.result.value!
                self.noTasksLbl.isHidden = !self.tasks.isEmpty
                self.tableView.reloadData()
            }
            else if response.response?.statusCode == 401 {
                let welVC = self.presentingViewController as! WelcomeViewController
                self.dismiss(animated: true) {
                    welVC.proceedFlow()
                }
            }
        }
    }
    
    @objc func refresh() {
        self.loadTasks()
    }
    
    
    @IBAction func unwind(_ seg: UIStoryboardSegue) {
        if seg.identifier == "backToMain",
            let source = seg.source as? TaskDetailTableViewController,
            let index = self.tasks.firstIndex(where: { $0 === source.task }) {
            self.tasks.remove(at: index)
            self.tableView.deleteRows(at: [IndexPath(row:index, section: 0)], with: .none)
        }
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        
        self.performSegue(withIdentifier: "newTaskSegue", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = tasks[indexPath.row]
        
        cell.titleLbl.text = task.title
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yy"
        cell.dateLbl.text = df.string(from: task.dueBy!)
        cell.priorityLbl.text = task.prioritySign() + task.priority.rawValue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = tasks[indexPath.row]
            guard let id = task.id else {
                return
            }
            MBProgressHUD.showAdded(to: self.view, animated: true)
            Alamofire.request(ApiService.Router.delete(id)).responseJSON {
                response in
                MBProgressHUD.hide(for: self.view, animated: true)
                if response.result.isSuccess {
                    self.tasks.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "taskDetailSegue",
            let destination = segue.destination as? TaskDetailTableViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) {
            
                let task = tasks[indexPath.row]
                destination.task = task
        }
    }

}
