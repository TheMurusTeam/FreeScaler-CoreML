//
//  Global Variables.swift
//  FreeScaler
//
//  Created by Hany El Imam on 29/11/22.
//

import Foundation

// current model path
var selectedModelPath = (Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")!)

// use ANE
var useNeuralEngine : Bool = true

// local notification center
let notificationcenter = NotificationCenter.default
