//
//  NetworkClient.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/18/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

class NetworkClient: NSObject {
    
    let BASE_URL = "https://bible-api.com/"
    
    func getBibleVerses(parameters: String, completion: @escaping(_ reference: String?, _ text: String?, _ verses: [Verse]?) -> ()) {
        let urlString = BASE_URL + parameters
        print(urlString)
        let url = URL(string: urlString)
        let session = URLSession.shared
        
        if let url = url {
            session.dataTask(with: url, completionHandler: { (data, response, error) in
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                        let jsonDictionary = json as! NSDictionary
                        let reference = jsonDictionary["reference"] as? String
                        let text = jsonDictionary["text"] as? String
                        let versesDictionary = jsonDictionary["verses"] as? [NSDictionary]
                        var verses: [Verse] = []
                        if let versesDictionary = versesDictionary {
                            for item in versesDictionary {
                                let verse = Verse(item: item)
                                verses.append(verse)
                            }
                        }
                        completion(reference, text, verses)
                    } catch {
                        completion(nil, nil, nil)
                    }
                }
            }).resume()
        }
        
    }

    static let shared = NetworkClient()
    private override init() {
        super.init()
    }
    
}
