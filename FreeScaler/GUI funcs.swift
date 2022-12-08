//
//  GUI funcs.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Foundation
import Cocoa

// apply view constraints
func applyConstraints(view:NSView,containerView:NSView,_ translate:Bool = false) {
    view.translatesAutoresizingMaskIntoConstraints = translate
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0))
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute:.bottom, multiplier: 1, constant: 0))
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0))
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute:.leading, multiplier: 1, constant: 0))
}
