//
//  ApiService.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/15/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import Foundation
import Alamofire

struct ApiService {
    
    enum Router: URLRequestConvertible {
        
        var baseURL: URL {
            return URL(string: "https://testapi.doitserver.in.ua/api")!
        }
        
        // tasks
        case allTasks([String: Any])
        case create([String: Any])
        case details(Int)
        case update(Int, [String: Any])
        case delete(Int)
        // user
        case newUser([String: Any])
        case authUser([String: Any])
        
        var tokenId: String? {
            switch self {
            case .newUser(_), .authUser(_):
                return nil
            default:
                return TokenKeychainStore().retrieveAccessToken()?.id
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .allTasks, .details:
                return .get
            case .create, .newUser, .authUser:
                return .post
            case .update:
                return .put
            case .delete:
                return .delete
            }
        }
        
        var params: ([String: Any]?) {
            switch self {
            case .newUser(let params), .authUser(let params), .create(let params), .update(_, let params):
                return (params)
            default:
                return nil
            }
        }
        
        var encoding: ParameterEncoding {
            switch self {
            case .allTasks(_): return URLEncoding.default
            default: return JSONEncoding.default
            }
        }
        
        var path: String {
            switch self {
            case .allTasks(_), .create(_): return "tasks"
            case .details(let task), .update(let task, _), .delete(let task): return "tasks/\(task)"
            case .newUser(_): return "users"
            case .authUser(_): return "auth"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            let url = self.baseURL.appendingPathComponent(path)
            var request = URLRequest(url: url)
            request.httpMethod = self.method.rawValue
            
            if let token = self.tokenId {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            request = try self.encoding.encode(request, with: self.params)
            
            return request
        }
    }
    
}
