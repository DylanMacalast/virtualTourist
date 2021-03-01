//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Dylan Macalast on 06/10/2020.
//  Copyright © 2020 DylanMacalast. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
   
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var pin: Pin!
    // array populated from api call
    var photos: [Image] = []
    let reuseIdentifier = "image"
    

    var fetchedResultsController: NSFetchedResultsController<Photo>!

    
    fileprivate func setUpFetchedResultsController() {
      
        // set up fetch request for photo
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        // set up a predicate to only get photo's for the specific pin
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        // need to sort the data as we are using a fetchedRequestController
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // now using the above fetch request we can instantiate the fetchedRequestController property
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // set delegate propery of fetchedResultsController
        fetchedResultsController.delegate = self
        
        // finally load data and start tracking
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects?.count == 0 {
                // no photos found in db -> get photos from flickr api
                getFlickrImages()
            }
        } catch {
            fatalError("Fetch could not be performed : \(error.localizedDescription)")
        }
        
        collectionView.reloadData()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set up map
        mapView.delegate = self
        let myPin: MKPointAnnotation = MKPointAnnotation()
        // The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: pin.lattitude, longitude: pin.longitude)
        myPin.coordinate = coordinate
        mapView.addAnnotation(myPin)
        
        // set up collection view
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 120, height: 120)
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // tearing down the fetchedResultsController by setting it to nil
        fetchedResultsController = nil
    }
    
    
    // function to get flickr images
    func getFlickrImages() {
        
        loadingPhotos(true)
        // if there are photos for this pin in persistent store don't run this just display them
        VTClient.searchForPhotos(lat: pin.lattitude, lon: pin.longitude) {
            photos, error
            in
            if let error = error {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            } else {
                if let images = photos?.images {
                    self.photos.append(contentsOf: images)
                    DispatchQueue.main.async {
                       self.loadingPhotos(false)
                        self.collectionView.reloadData()
                    }
                // this method loops through the photos array which is populated in the completion handler so this needs to be called here otherwise it will run before the completion handler has finished running async
                    self.getPinImages()
                } else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Sorry!", message: "No images for selected location", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
  
            }
        }
    }
    
    
    // function to get images url download them as images
    func getPinImages() {
        if photos.isEmpty {
            let alert = UIAlertController(title: "Sorry!", message: "No Images for selected location", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        for photo in photos {
            let url = photo.url_n
            // assign this url to each pin in persistent store
            // need to get the image from the URL and store it as a binary data attribute in core data.
            VTClient.fetchImage(from: url!) { (data) in
                if let data = data {
                    // persistently save the images
                    self.saveImages(data: data)
                } else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: "Error loading images", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
            }
           
        }
    }
    
    
    // function to save images to persistent store
    func saveImages(data: Data) {
        let photo = Photo(context: DataController.shared.viewContext)
        photo.pin = self.pin
        photo.creationDate = Date()
        photo.image = data
        do {
            try DataController.shared.viewContext.save()
            print("images saved")
        } catch {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    // function to delete all images
    func deleteImages() {
        if let photosToDelete = self.fetchedResultsController.fetchedObjects {
            // go over all photos of current pin and delete
            for photo in photosToDelete {
                // call a method to delete that individual image
                deletePhoto(photo: photo)
            }
        }
    }
    
    // function to delete photo from DB
    func deletePhoto(photo: Photo) {
        // delete from context
        DataController.shared.viewContext.delete(photo)
        do {
            // save changes
            try DataController.shared.viewContext.save()
        } catch {
            print("Error Deleting Photo: \(error.localizedDescription)")
        }
    }
    
   
    
    @IBAction func newCollection(_ sender: Any) {
        // delete current images
        deleteImages()
        // get new flickr images
        getFlickrImages()
        // reload view
        collectionView.reloadData()
    }
    
    
    // UI loading
    func loadingPhotos(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    
    
    
    //MARK: collection view
    // number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    // number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    // each cell in collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath)
       
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotoCollectionViewCell
        
        if photo.image?.isEmpty == true {
            cell.imageView.image = UIImage(named: "VirtualTourist_120")
        } else {
            cell.imageView.image = UIImage(data: photo.image!)
        }
       
        return cell
    }
    
    // selected cell item
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        deletePhoto(photo: photo)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 120)
    }
    
   
   
}




//MARK: setting up map
extension PhotoAlbumViewController: MKMapViewDelegate{
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
    
}


//MARK: Automatic update of the collection view according to DB changes
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    // this method is called whenever the fetchedResultsController receives information that an object has been added, moved, deleted or changed.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // photo's can be added or deleted to swith on the type param for these cases
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        default:
            break
        }
    }
}


