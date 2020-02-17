//
//  TaskDetailTableViewController.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/16/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import UIKit
import MBProgressHUD
import RMDateSelectionViewController
import Alamofire
import AlamofireObjectMapper
import AlamofireSwiftyJSON
import SwiftyJSON

class TaskDetailTableViewController: UITableViewController {
    
    @IBOutlet weak var titleText: UITextView!
    @IBOutlet weak var prioritySeg: UISegmentedControl!
    @IBOutlet weak var dateLbl: UILabel!
    
    public var task: Task?
    public var isCreatingNewTask = false
    private var selectedDate: Date?
    private var editingCanceled = false

    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.titleText.layer.borderColor = UIColor.lightGray.cgColor
        self.titleText.layer.borderWidth = 1.0
        
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsSelectionDuringEditing = true
        
        if self.task != nil {
            self.disableEditing()
            self.navigationController?.isToolbarHidden = false
            let barBtn = UIBarButtonItem(title: "Delete event", style: .plain, target: self, action: #selector(deleteEvent))
            barBtn.tintColor = UIColor.darkGray
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            self.toolbarItems = [space, barBtn, space]
            
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        }
        else {
            
            self.isCreatingNewTask = true
            self.task = self.dummyTask()
            
            let saveBtn = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveNewTask))
            self.navigationItem.rightBarButtonItem = saveBtn
            let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
            self.navigationItem.leftBarButtonItem = cancelBtn
        }
    }
    
    @objc func deleteEvent() {
        guard let task = self.task, let id = task.id else {
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Alamofire.request(ApiService.Router.delete(id)).responseJSON {
            response in
            MBProgressHUD.hide(for: self.view, animated: true)
            if response.result.isSuccess {
                self.performSegue(withIdentifier: "backToMain", sender: nil)
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            self.enableEditing()
            let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
            self.navigationItem.leftBarButtonItem = cancelBtn
        }
        else {
            self.navigationItem.leftBarButtonItem = nil
            self.disableEditing()
            if self.editingCanceled {
                self.tableView.reloadData()
                self.editingCanceled = false
            }
            else {
                let task = self.taskFromCurrentValues()
                let json = task.toJSON()
                
                if let taskId = self.task?.id {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    Alamofire.request(ApiService.Router.update(taskId, json)).response { response in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if response.error == nil {
                            ErrorManager.showErrorWithMessage("Saved!", inViewController: self)
                            task.id = self.task?.id
                            self.task = task
                        }
                        else {
                            ErrorManager.showErrorWithMessage("Error while saving your task. Please try again", inViewController: self)
                            self.isEditing = true
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func cancelTapped() {
        if self.isCreatingNewTask {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            self.editingCanceled = true
            self.isEditing = false
        }
    }
    
    @IBAction func saveNewTask() {
        let task = self.taskFromCurrentValues()
        let json = task.toJSON()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Alamofire.request(ApiService.Router.create(json)).responseObject(keyPath: "task") { (response:DataResponse<Task>) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if response.result.isSuccess {
                self.performSegue(withIdentifier: "createdUnwind", sender: nil)
            }
            else {
                ErrorManager.showErrorWithMessage("Error while saving new task", inViewController: self)
            }
        }
    }
    
    func enableEditing() {
        self.titleText.isEditable = true
        self.titleText.isSelectable = true
        self.prioritySeg.isEnabled = true
        self.tableView.allowsSelection = true
    }
    
    func disableEditing() {
        self.titleText.isEditable = false
        self.titleText.isSelectable = false
        self.prioritySeg.isEnabled = false
        self.tableView.allowsSelection = false
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let task = self.task {
            self.titleText.text = task.title
            self.prioritySeg.selectedSegmentIndex = task.priority.asInt()
            let df = DateFormatter()
            df.dateFormat = "dd/MM/yy HH:mm"
            self.dateLbl.text = df.string(from: selectedDate ?? task.dueBy!)
        }
        
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 2 {
            let selectAct: RMAction<UIDatePicker> = RMAction<UIDatePicker>(title: "Select", style: .done) { (controller: RMActionController<UIDatePicker>) in
                self.selectedDate = controller.contentView.date
                self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
            }!
            
            let cancelAction = RMAction<UIDatePicker>(title: "Cancel", style: RMActionStyle.cancel) { _ in
                print("Date selection was canceled")
            }!
            
            let dateSelectVC = RMDateSelectionViewController(style: .default, title: nil, message: nil, select: selectAct, andCancel: cancelAction)!
            
            let in15MinAction = RMAction<UIDatePicker>(title: "15 Min", style: .additional) { controller -> Void in
                controller.contentView.date = Date(timeIntervalSinceNow: 15*60)
                print("15 Min button tapped")
            }!
            in15MinAction.dismissesActionController = false
            
            let in30MinAction = RMAction<UIDatePicker>(title: "30 Min", style: .additional) { controller -> Void in
                controller.contentView.date = Date(timeIntervalSinceNow: 30*60)
                print("30 Min button tapped")
            }!
            in30MinAction.dismissesActionController = false
            
            let in45MinAction = RMAction<UIDatePicker>(title: "45 Min", style: .additional) { controller -> Void in
                controller.contentView.date = Date(timeIntervalSinceNow: 45*60)
                print("45 Min button tapped")
            }!
            in45MinAction.dismissesActionController = false
            
            let in60MinAction = RMAction<UIDatePicker>(title: "60 Min", style: .additional) { controller -> Void in
                controller.contentView.date = Date(timeIntervalSinceNow: 60*60)
                print("60 Min button tapped")
            }!
            in60MinAction.dismissesActionController = false
            
            let groupedAction = RMGroupedAction<UIDatePicker>(style: .additional, andActions: [in15MinAction, in30MinAction, in45MinAction, in60MinAction])
            dateSelectVC.addAction(groupedAction!)
                        
            dateSelectVC.datePicker.datePickerMode = .dateAndTime
            dateSelectVC.datePicker.minimumDate = Date()
            dateSelectVC.datePicker.date = self.selectedDate ?? self.task?.dueBy ?? Date()
            
            self.present(dateSelectVC, animated: true, completion: nil)
        }
    }
    
    func dummyTask() -> Task {
        let task = Task()
        task.title = "New task"
        let date = Date(timeIntervalSinceNow: 15 * 60)
        task.dueBy = date
        task.priority = .Normal
        
        return task
    }
    
    func taskFromCurrentValues() -> Task {
        let task = Task()
        task.title = self.titleText.text
        if let priorityStr = self.prioritySeg.titleForSegment(at: self.prioritySeg.selectedSegmentIndex),
            let priority = Priority(rawValue: priorityStr) {
            task.priority = priority
        }
        if let date = self.selectedDate {
            task.dueBy = date
        }
        else {
            task.dueBy = self.task?.dueBy
        }
        
        return task
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createdUnwind",
            let tasksVC = segue.destination as? TasksViewController {
            tasksVC.loadTasks()
        }
    }
}
