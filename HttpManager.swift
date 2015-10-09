//
//  HttpManager.swift
//  KeyHouse
//
//  Created by Sheepy on 15/10/8.
//  Copyright © 2015年 Sheepy. All rights reserved.
//

import UIKit

public enum Error: ErrorType {
    case InvalidURL
    case NoParameter
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
}

typealias Callback = (data: NSData) -> ()

func getJsonFrom(url: String, completion: (json: JSON) -> Void) {
    do {
        try getDataFrom(url, method: HTTPMethod.GET, parameter: nil) { data in
            let json = JSON(data: data)
            //主线程进行UI操作
            dispatch_sync(dispatch_get_main_queue()) {
                completion(json: json)
            }
        }
    } catch Error.InvalidURL {
        printLog("GET: invalid url")
    } catch {
        printLog("Unknown error")
    }
    
}

func postJson(dict: [String: String], toUrl url: String, completion: (json: JSON) -> Void) {
    do {
        try getDataFrom(url, method: HTTPMethod.POST, parameter: dict) { data in
            let json = JSON(data: data)
            
            dispatch_sync(dispatch_get_main_queue()) {
                completion(json: json)
            }
        }
    } catch Error.InvalidURL {
        printLog("POST: invalid url")
    } catch Error.NoParameter {
        printLog("Parameter is empty")
    } catch {
        printLog("Unknown error")
    }
    
}

//图片缓存
//let localImage = "testimg6"
let imageCache = NSCache()
func loadImageFrom(imageUrl: String, completion: (image: UIImage!) -> Void) {
    var image: UIImage?
    guard !imageUrl.isEmpty else {
        return
    }
    //从缓存中取图片数据（如果在缓存中能找到对应数据的话）
    if let imageData = imageCache.objectForKey(imageUrl) as? NSData {
        image = UIImage(data: imageData)
        completion(image: image)
    } else {
        //创建一个线程
        let queue = dispatch_queue_create("load_image", DISPATCH_QUEUE_SERIAL)
        //异步加载图片
        dispatch_async(queue) {
            guard let url = NSURL(string: imageUrl), let data = NSData(contentsOfURL: url) else {
                return
            }
            //缓存图片
            imageCache.setObject(data, forKey: imageUrl)
            //主线程进行UI操作
            dispatch_async(dispatch_get_main_queue()) {
                completion(image: UIImage(data: data))
            }
        }
    }
}


func getDataFrom(urlString: String, method: HTTPMethod, parameter: [String: String]?, completionHandler: Callback) throws {
    //    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    //    config.timeoutIntervalForRequest = 20
    //    let session = NSURLSession(configuration: config)
    guard let url = NSURL(string: urlString) else {
        throw Error.InvalidURL
    }
    
    let session = NSURLSession.sharedSession()
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method.rawValue
    
    switch method {
    case .POST:
        //如果参数为nil或者字典中没有元素，则抛出异常
        guard let param = parameter else {
            throw Error.NoParameter
        }
        guard param.isEmpty else {
            throw Error.NoParameter
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(param, options: [])
        } catch {
            print(error)
        }
    
    case .GET:
        break
    }
    
    let task = session.dataTaskWithRequest(request) {data, response, error in
        guard let result = data where error == nil else {
            printLog("no data: \(error)")
            return
        }
        
        completionHandler(data: result)
    }
    //启动
    task.resume()
    
}

func printLog<T>(message: T, file: String = __FILE__, method: String = __FUNCTION__, line: Int = __LINE__) {
    #if DEBUG
        print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
    
}