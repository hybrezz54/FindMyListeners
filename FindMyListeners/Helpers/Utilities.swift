//
//  Utilities.swift
//  FindMyListeners
//
//  Created by Hamzah Chaudhry on 12/6/20.
//

import Foundation

class Utilities {
    
    static func isPasswordValid(_ password: String) -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@",
                                       "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
    
}
