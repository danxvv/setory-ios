//
//  PhotoMatchFixture.swift
//  Setory
//
//  The stand-in photo for `-uitest-photo-match`, so automated tests drive the
//  match flow without opening the camera or the system photo library.
//
//  A bundled catalog thumbnail doubles as the fixture: real JPEG bytes through
//  the same preprocessing path, with no extra asset to ship.
//

#if DEBUG

import UIKit

enum PhotoMatchFixture {
    static var image: UIImage? {
        UIImage(named: "gv0025.jpg")
    }
}

#endif
