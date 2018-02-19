//
//  BiblePassage.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/18/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

struct Verse {
    let bookName: String
    let chapter: Int
    let number: Int
    let text: String
    
    init(item: NSDictionary) {
        bookName = item["book_name"] as! String
        chapter = item["chapter"] as! Int
        number = item["verse"] as! Int
        text = item["text"] as! String
    }
    
}
