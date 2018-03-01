//
//  CheckedInMembersCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/25/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class CheckedInMembersCell: UITableViewCell {
    
    var checkedInMembers: [Member]?
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func setUp(checkedInMembers: [Member]) {
        self.checkedInMembers = checkedInMembers
        collectionView.reloadData()
    }
    
}

extension CheckedInMembersCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return checkedInMembers?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "checkedInCell", for: indexPath) as! CheckedInCell
        let member = checkedInMembers![indexPath.row]
        cell.setUp(member: member)
        return cell
    }
    
}
