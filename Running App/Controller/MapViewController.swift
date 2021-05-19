//
//  ViewController.swift
//  Running App
//
//  Created by Rohit Jangid on 11/05/21.
//

import UIKit
import MapKit
import MessageUI

class MapViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startAndStopBtn: RoundButton!
    @IBOutlet weak var distanceView: UIView! {
        didSet {
            distanceView.layer.cornerRadius = 10
            distanceView.layer.shadowRadius = 20
            distanceView.layer.shadowColor = UIColor.black.cgColor
            distanceView.layer.shadowOpacity = 0.6
        }
    }
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var convertDistanceBtn: RoundButton!
    @IBOutlet weak var stackViewButtons: UIStackView!
    
    //MARK: - variables
    var startPointLocationCheck = false
    var distanceInKm = true {
        didSet {
            totalDistance = distanceInKm ? totalDistance / 0.62137 : totalDistance * 0.62137
        }
    }
    var startPointAnnotation: DistancePoint?
    var endPointAnnotation: DistancePoint?
    var totalDistance: Double = 0 {
        didSet {
            distanceLabel.text = distanceInKm ? "\(String(format: "%.2f", totalDistance)) Kms" : "\(String(format: "%.2f", totalDistance)) Miles"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // initailization
        
        checkLocationAuthStatus()
        mapView.delegate = self
        distanceView.isHidden = true
        convertDistanceBtn.isEnabled = false
    }
    
    
    /// recenter map and shows both the annotaion start and end
    func recenterMapForBothCoordinate() {
        guard let startCoordinate = startPointAnnotation?.coordinate, let endCoordinate = endPointAnnotation?.coordinate else { return }
        getDistanceTravelled(fromStart: startCoordinate, toEnd: endCoordinate)
    }
    
    //MARK: - IBActions
    ///recenter to the current coordinate
    @IBAction func recenterLocationBtnTapped(_ sender: RoundButton) {
        guard let coordinates = LocationService.instance.currentLocation else { return }
        centerMapOnUserLocation(coordinates: coordinates)
    }
    
    ///converts from kms to miles and vice versa
    @IBAction func convertDistanceBtnTapped(_ sender: RoundButton) {
        distanceInKm.toggle()
    }
    
    ///start and stop running button
    @IBAction func startAndStopBtnTapped(_ sender: RoundButton) {
        startPointLocationCheck.toggle()
        
        guard let coordinate = LocationService.instance.currentLocation else { return }
        
        if startPointAnnotation == nil {
            setupAnnotaion(coordinate: coordinate)
            startAndStopBtn.setTitle("Stop", for: .normal)
            return
        } else if endPointAnnotation == nil {
            setupAnnotaion(coordinate: coordinate)
            startAndStopBtn.setTitle("Start", for: .normal)
        }
       
        recenterMapForBothCoordinate()
        startAndStopBtn.setTitle("Center", for: .normal)
        distanceView.isHidden = false
        convertDistanceBtn.isEnabled = true
        
    }
    
    @IBAction func shareBtnTapped(_ sender: UIBarButtonItem) {
        
        /// AlertController for sharing link or snapshot
        let alertController = UIAlertController(title: "Select Source", message: "You can share link or map snapshot", preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Share Link", style: .default, handler: { _ in
            if let url = self.getShareLink() {
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Share Snapshot", style: .default, handler: { _ in
            self.configureMessageComposeVC()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancle", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
       
    }
    
    
    /// resets everything
    @IBAction func resetMapBtnTapped(_ sender: UIBarButtonItem) {
        guard let coordinates = LocationService.instance.currentLocation else { return }
        centerMapOnUserLocation(coordinates: coordinates)
        
        startPointAnnotation = nil
        endPointAnnotation = nil
        startAndStopBtn.setTitle("Start", for: .normal)
        distanceView.isHidden = true
        convertDistanceBtn.isEnabled = false
        mapView.removeAnnotations(mapView.annotations)
        removeOverlays()
    }
    
}

//MARK: - Setup MapKit
extension MapViewController: MKMapViewDelegate {
    
    
    /// Check for authorization
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            LocationService.instance.customUserLocationDelegate = self
        } else {
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    /// recenter to the current coordinate
    /// - Parameter coordinates: current location of the user
    func centerMapOnUserLocation(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    
    /// To setup annotaion on mapview
    /// - Parameter coordinate: location coordinate to setup annotaion
    func setupAnnotaion(coordinate: CLLocationCoordinate2D) {
        if startPointLocationCheck == true {
            startPointAnnotation = DistancePoint(title: "Starting Point", subtitle: "You started running from here", coordinate: coordinate)
        } else {
            endPointAnnotation = DistancePoint(title: "Finish Point", subtitle: "You finished here", coordinate: coordinate)
        }
        
        mapView.addAnnotation(startPointLocationCheck ? startPointAnnotation! : endPointAnnotation!)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DistancePoint {
            
            let id1 = "pin1"
            let id2 = "pin2"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: startPointLocationCheck ? id1 : id2)
            view.animatesDrop = true
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -8, y: -3)
            view.pinTintColor = startPointLocationCheck ? UIColor.systemGreen : UIColor.red
            
            return view
        }
        
        return nil
    }
    
}

//MARK: - CustomUserLocationDelgate
extension MapViewController: CustomUserLocationDelegate {
    func userLocationUpdated(location: CLLocation) {
        centerMapOnUserLocation(coordinates: location.coordinate)
    }
    
}

//MARK: - Add polyline to map (Directions on map)
extension MapViewController {
    
    
    /// getting direction between both the annotaion
    /// - Parameters:
    ///   - startPointCoordinate: starting point where user started running
    ///   - endPointCoordinate: ending point where user ended running
    func getDistanceTravelled(fromStart startPointCoordinate: CLLocationCoordinate2D, toEnd endPointCoordinate: CLLocationCoordinate2D) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPointCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endPointCoordinate))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let route = response?.routes.first else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            self.totalDistance = route.distance / 1000

            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 230, left: 50, bottom: 150, right: 50), animated: true)
        }
    }
    
    ///rendering polyline (direction on map)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let directionsRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        directionsRenderer.strokeColor = .systemBlue
        directionsRenderer.lineWidth = 5
        directionsRenderer.alpha = 0.85
        
        return directionsRenderer
    }
    
    
    /// removing overlays (direction on map)
    func removeOverlays() {
        mapView.overlays.forEach(mapView.removeOverlay(_:))
    }
    
}

//MARK: - MapKit screenshot
extension MapViewController: MFMessageComposeViewControllerDelegate {
    
    
    /// configuratiuon for sms and preparing to load messageVC with attachment
    func configureMessageComposeVC() {
        
        guard MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments() else {
            print("Can not share message")
            return
        }
        
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        guard let image = takeScreenshot()?.jpegData(compressionQuality: 1) else {
            print("Not able to generate jpeg image for MFMessageVC")
            return
        }
        messageComposeVC.addAttachmentData(image, typeIdentifier: "public.data", filename: "image.jpeg")
        messageComposeVC.body = "Here is your running route"
        
        self.present(messageComposeVC, animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if result == .failed {
            print("could not send message")
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    /// capturing screen (current mapview which is displayed)
    /// - Returns: image of the current screen
    func takeScreenshot() -> UIImage? {
        stackViewButtons.isHidden = true
        UIGraphicsBeginImageContextWithOptions(mapView.bounds.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        stackViewButtons.isHidden = false
         
        if image != nil {
            return image
        }
        print("NO IMAGE")
        return nil
    }
    
    
}

//MARK: - MapKit sharelink
extension MapViewController {
    
    
    /// create a custom url for both the location (start and end)
    /// - Returns: url of starting point and ending point
    func getShareLink() -> URL? {
        guard let startCoordinate = startPointAnnotation?.coordinate, let endCoordinate = endPointAnnotation?.coordinate else {
            return nil
        }
        
        let url = URL(string: "http://maps.apple.com/maps?saddr=\(startCoordinate.latitude),\(startCoordinate.longitude)&daddr=\(endCoordinate.latitude),\(endCoordinate.longitude)")
        
        return url
    }
    
}

//MARK: - MapKit Snapshot without overlays
//extension MapViewController {
//
//    func shareMapSnapshot(_ completion: @escaping (UIImage?) -> Void) {
//
//        let mapSnapshotOptions = MKMapSnapshotter.Options()
//
//        recenterMapForBothCoordinate()
//        mapSnapshotOptions.region = mapView.region
//        mapSnapshotOptions.size = mapView.frame.size
//        mapSnapshotOptions.scale = UIScreen.main.scale
//
//        mapSnapshotOptions.showsBuildings = true
//        mapSnapshotOptions.pointOfInterestFilter = .includingAll
//
//        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
//
//        snapShotter.start(with: DispatchQueue.global(qos: .userInitiated)) { snap, error in
//            guard let snapshot = snap?.image else {
//                if let error = error {
//                    print("Error: ========> \(error)")
//                }
//                return
//            }
//            completion(snapshot)
//        }
//    }
//}
