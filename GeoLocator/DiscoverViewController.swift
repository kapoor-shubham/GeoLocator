//
//  DiscoverViewController.swift
//  NetworkLayer
//
//  Created by Shubham Kapoor on 19/01/19.
//  Copyright © 2019 Shubham Kapoor. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class DiscoverViewController : UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var latitude: UILabel!
    @IBOutlet weak var longitude: UILabel!
    @IBOutlet weak var currentLoctionLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    
    let locationManager = CLLocationManager()
    var center = CLLocationCoordinate2D() {
        didSet {
            updateMap(center: center)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func searchLocation(_ sender: UIButton) {
        if (searchTextField.text?.count)! > 0 {
            updateSearchResults(serachLocation: searchTextField.text!)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        center = mapView.centerCoordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
    
    func updateMap(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: true)
            self.latitude.text = "\(region.center.latitude)"
            self.longitude.text = "\(region.center.longitude)"
            self.getAddressFromLatLon(latitude: "\(region.center.latitude)", longitude: "\(region.center.longitude)")
        }
    }
    
    func getAddressFromLatLon(latitude: String, longitude: String) {
    
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = Double("\(latitude)")!
        center.longitude = Double("\(longitude)")!
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        ceo.reverseGeocodeLocation(loc, completionHandler: {(placeMarks, error) in
            
            if error != nil {
                print("Reverse geodcode fail: \(error!.localizedDescription)")
                return
            }
            self.getLocationString(placeMarks: placeMarks!)
        })
    }
    
    func getLocationString(placeMarks: [CLPlacemark]) {
        let pm = placeMarks
        var addressString = String()
        if pm.count > 0 {
            let pm = placeMarks[0]
            
            if pm.subLocality != nil {
                addressString = addressString + pm.subLocality! + ", "
            }
            if pm.thoroughfare != nil {
                addressString = addressString + pm.thoroughfare! + ", "
            }
            if pm.locality != nil {
                addressString = addressString + pm.locality! + ", "
            }
            if pm.country != nil {
                addressString = addressString + pm.country! + ", "
            }
            if pm.postalCode != nil {
                addressString = addressString + pm.postalCode! + " "
            }
            
            DispatchQueue.main.async {
                self.currentLoctionLabel.text = addressString
            }
        }
    }

    func updateSearchResults(serachLocation: String) {
        guard let mapView = mapView else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = serachLocation
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            print(response.mapItems[0].name!)
            self.center = response.mapItems[0].placemark.coordinate
            self.getLocationString(placeMarks: [response.mapItems[0].placemark])
        }
    }
}
