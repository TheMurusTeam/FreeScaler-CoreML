//
//  Version.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Foundation


func freescalerVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0"
}
func freescalerBuild() -> String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
func freescalerFullVersion() -> String {
    return ((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0") + " (build " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000") + ")")
}
