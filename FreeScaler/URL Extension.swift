//
//  URL Extension.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Foundation

// UTI Docs: https://developer.apple.com/documentation/uniformtypeidentifiers/system-declared_uniform_type_identifiers

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var isImage: Bool { typeIdentifier == "public.image" }
    var isMovie: Bool { typeIdentifier == "public.audiovisual-content" }
    var isPNG: Bool { typeIdentifier == "public.png" }
    var isJPEG: Bool { typeIdentifier == "public.jpeg" }
    var isFolder: Bool { typeIdentifier == "public.folder" }
    var isDirectory: Bool { typeIdentifier == "public.directory" }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
    var hasHiddenExtension: Bool {
        get { (try? resourceValues(forKeys: [.hasHiddenExtensionKey]))?.hasHiddenExtension == true }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.hasHiddenExtension = newValue
            try? setResourceValues(resourceValues)
        }
    }
}
