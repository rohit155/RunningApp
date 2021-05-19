//
//  DistancePoints.swift
//  Running App
//
//  Created by Rohit Jangid on 11/05/21.
//

import UIKit
import MapKit

class DistancePoint: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
