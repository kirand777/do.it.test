//
//  Task.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/15/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import ObjectMapper

enum Priority: String, CaseIterable {
    case Low
    case Normal
    case High
    
    static var asArray: [Priority] {return self.allCases}

    func asInt() -> Int {
        return Priority.asArray.firstIndex(of: self)!
    }
}

class Task: Mappable {
    var id: Int?
    var title: String?
    var dueBy: Date?
    var priority: Priority = .Normal
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        id <- map["id"]
        title <- map["title"]
        
        let transform = TransformOf<Date, Int>(fromJSON: { (intDate:Int?) -> Date? in
            return Date(timeIntervalSince1970: TimeInterval(intDate!))
        }) { (date:Date?) -> Int? in
            return Int(date!.timeIntervalSince1970)
        }
        
        dueBy <- (map["dueBy"], transform)
        priority <- (map["priority"], EnumTransform<Priority>())
    }
    
    
    
    public func prioritySign() -> String {
        switch self.priority {
        case .Low: return "↓"
        case .Normal: return ""
        case .High: return "↑"
        }
    }
}
