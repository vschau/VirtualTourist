//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import Foundation

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
