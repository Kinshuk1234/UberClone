//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Kinshuk Singh on 2017-08-11.
//  Copyright © 2017 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    func displayAlert(title: String, message: String) {
        
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated: true, completion: nil)
        
    }
    
    var driverOnTheWay = false
    
    var locationManager = CLLocationManager()
    
    var riderRequestActive = true
    
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var uberButtonText: UIButton!
    
    @IBAction func uberButton(_ sender: Any) {
        
        if riderRequestActive {
        
            uberButtonText.setTitle("Call an Uber", for: [])
            riderRequestActive = false
            
            // cancelling active requests using query!!
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: PFUser.current()?.username!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                
                    for riderRequest in riderRequests {
                        
                            riderRequest.deleteInBackground()
                        
                    }
                    
                }
                
            })
            
        } else {
        
        if userLocation.latitude != 0 && userLocation.longitude != 0 { // or userLocation != nil
            
            riderRequestActive = true
            self.uberButtonText.setTitle("Cancel Uber", for: [])
        
        let riderRequest = PFObject(className: "RiderRequest")
        
        riderRequest["username"] = PFUser.current()?.username
        riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
            
        riderRequest.saveInBackground(block: { (success, error) in
            
            if success {
            
                print("called an uber!")
                
                
            } else {
                
                self.uberButtonText.setTitle("Call an Uber", for: [])
                self.riderRequestActive = false
            
                self.displayAlert(title: "Couldn't call an Uber", message: "Please Try Again!")
                
            }
            
        })
            
        } else {
            
            displayAlert(title: "Couldn't call an Uber", message: "Cannot detect your location!")
        
        }
            
        }
    
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "logoutFromRider" {
            
            locationManager.stopUpdatingLocation()
        
            PFUser.logOut()
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // on rebooting app, check for any active request
        
        uberButtonText.isHidden = true
        
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: PFUser.current()?.username!)
        
        query.findObjectsInBackground(block: { (objects, error) in
            
            if let object = objects {
                
                if object.count > 0 {
                
                self.riderRequestActive = true
                self.uberButtonText.setTitle("Cancel Uber", for: [])
                    
                }
                
            }
            
            self.uberButtonText.isHidden = false
            
        })
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = manager.location?.coordinate {
        
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            if driverOnTheWay == false {
            
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.map.setRegion(region, animated: true)
            
            self.map.removeAnnotations(self.map.annotations) // to clear all annotations to update just the latest one
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation
            annotation.title = "Your Location"
            
            self.map.addAnnotation(annotation)
            
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: PFUser.current()?.username!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        
                        riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                        
                        riderRequest.saveInBackground()
                        
                    }
                    
                }
                
            })
                
            }
            
        }
        
        // showing rider that driver has responded and coming
        
        if riderRequestActive == true {
        
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: PFUser.current()?.username!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                
                    for riderRequest in riderRequests {
                    
                        // now checking if a driver has responded
                        
                        if let driverUsername = riderRequest["driverResponded"] {
                        
                            let query = PFQuery(className: "DriverLocation")
                            
                            query.whereKey("username", equalTo: driverUsername)
                            
                            query.findObjectsInBackground(block: { (objects, error) in
                                
                                if let driverLocations = objects {
                                
                                    for driverLocationObject in driverLocations {
                                    
                                        if let driverLocation = driverLocationObject["location"] as? PFGeoPoint {
                                            
                                            //self.driverOnTheWay = true
                                            
                                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            
                                            let riderCLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            
                                            let distance = riderCLLocation.distance(from: driverCLLocation) / 1000 // to convert in kms
                                            
                                            let roundedDistance = round(distance * 100) / 100
                                        
                                            self.uberButtonText.setTitle("Your driver is \(roundedDistance) kms away!", for: [])
                                            
                                            // finally showing rider's as well as driver's location on map together
                                            
                                            
                                            let latDelta = abs(driverLocation.latitude - self.userLocation.latitude) * 2 + 0.005 // since we dont want the difference between locations more than half of the screen
                                            
                                            let lonDelta = abs(driverLocation.longitude - self.userLocation.longitude) * 2 + 0.005
                                            
                                            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                            
                                            self.map.removeAnnotations(self.map.annotations)
                                            
                                            self.map.setRegion(region, animated: true)
                                            
                                            // annotation for rider
                                            
                                            let userLocationAnnotation = MKPointAnnotation()
                                            
                                            userLocationAnnotation.coordinate = self.userLocation
                                            
                                            userLocationAnnotation.title = "Your Location"
                                            
                                            self.map.addAnnotation(userLocationAnnotation)
                                            
                                            // annotation for driver
                                            
                                            let driverLocationAnnotation = MKPointAnnotation()
                                            
                                            driverLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            
                                            driverLocationAnnotation.title = "Driver- \(driverUsername) Location"
                                            
                                            self.map.addAnnotation(driverLocationAnnotation)
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            })
                            
                        }
                        
                    }
                    
                }
                
            })
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
