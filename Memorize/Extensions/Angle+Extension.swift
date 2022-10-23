//
//  Angle+Extension.swift
//  Memorize
//
//  Created by Byeongjo Koo on 2022/10/12.
//

import SwiftUI

extension Angle {
    
    init(degreesFromTwelve: Double) {
        self.init(degrees: degreesFromTwelve - 90)
    }
}
