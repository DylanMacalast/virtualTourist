//
//  TravelMapViewController.swift
//  Virtual Tourist
//
//  Created by Dylan Macalast on 06/10/2020.
//  Copyright © 2020 DylanMacalast. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    // load saved data into our app
//    var dataController: DataController!
    
    // array of pins to present on map
    var pins: [Pin] = []
    
    
    var annotations = [MKPointAnnotation()]

    override func viewDidLoad() {
        super.viewDidLoad()
        // set mapview delegate
        mapView.delegate = self

        // generate long-press UIGestureRecogniser
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        
        longPress.addTarget(self, action: #selector(recognizeLongPress(_ :)))
        
        //add long-press gesture to map view
        mapView.addGestureRecognizer(longPress)
        
        
        //Fetch Request -> Get all Pins so we can display them on the map
        // must supplie optional generic type returned by fetch request
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? DataController.shared.viewContext.fetch(fetchRequest) {
            self.pins = result
            setUpMapPins(pins: self.pins)
         
        }
     
    }
    

    // method called when long press is detected
    @objc func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        
        // get coordinates for point being pressed
        let location = sender.location(in: mapView)
                   
        // convert location to CLLocationCoordinate2D to be displayed on map
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        // we don't want to generate more then 1 pin per hold down
        if sender.state == UIGestureRecognizer.State.began {
           
            // generate pins
            let pin: MKPointAnnotation = MKPointAnnotation()
            
            // set coordinate of pin
            pin.coordinate = coordinate
            
            // add pin to map
            mapView.addAnnotation(pin)
            
            mapView.reloadInputViews()
            
        } else if sender.state == .ended {
            
            addPin(lat: coordinate.latitude, long: coordinate.longitude)
        }
        
        
        // need to refresh the pins array used to populate map as we have now added a new annotation
        // carry out another fetchRequest with the new data in DB and assign it to variable
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
               
        if let result = try? DataController.shared.viewContext.fetch(fetchRequest) {
            self.pins = result
        
        }
    }
    
    
    // function to add a pin to core data object
    func addPin(lat: Double, long: Double) {
        let pin = Pin(context: DataController.shared.viewContext)
        
        pin.lattitude = lat
        pin.longitude = long
        pin.creationDate = Date()
        
        // save
        do {
            try DataController.shared.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    // function to set up pins on map
    func setUpMapPins(pins: [Pin]) {
        for pin in pins {
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let long = CLLocationDegrees(pin.longitude)
            let lat = CLLocationDegrees(pin.lattitude)
          
          // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
          
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
          
            // Finally we place the annotation in an array of annotations.
            self.annotations.append(annotation)
        }
        self.mapView.addAnnotations(self.annotations)
    }

}

extension TravelMapViewController: MKMapViewDelegate {
    
    // Delegate method called when addAnnotation is done.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let myPinIdentifier = "PinAnnotationIdentifier"
        
        // Generate pins.
        let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
        
        // Add animation.
        myPinView.animatesDrop = true
        
        // Display callouts.
        myPinView.canShowCallout = true
        
        // Set annotation.
        myPinView.annotation = annotation
                
        return myPinView
    }
    
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let photoVC = storyboard.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        // loop through pins array which is from the persisted pins, assign that pin to the album pin property
        // if it matches the pin clicked on by the user
        for pin in self.pins {
            if view.annotation?.coordinate.latitude == pin.lattitude && view.annotation?.coordinate.longitude == pin.longitude {
                let pin: Pin = pin
                photoVC.pin = pin
            }
        }
        
        self.navigationController?.pushViewController(photoVC, animated: true)
       
    }
    
}
