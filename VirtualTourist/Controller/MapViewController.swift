//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var selectedPin: Pin!
    
    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: - Setup
    fileprivate func setupMapView() {
        mapView.delegate = self
        mapView.region = MapModel.instance.loadSavedMapRegion()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        mapView.addGestureRecognizer(longPress)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "pin")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            createPinsFromArray(pins: fetchedResultsController.fetchedObjects!)
        } catch {
            fatalError("The Pin fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - completion handler
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cgPoint = sender.location(in: sender.view!)
            let coordinate = mapView.convert(cgPoint, toCoordinateFrom: sender.view!)
            savePinInCoreData(coordinate)
        }
    }
    
    // MARK: - Helpers
    func savePinInCoreData(_ coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: context)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func createPinFromCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
    }
    
    func createPinsFromArray(pins: [Pin]) {
        var annotations = [MKPointAnnotation]()
        for dictionary in pins {
            let lat = CLLocationDegrees(dictionary.latitude)
            let long = CLLocationDegrees(dictionary.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        if !mapView.annotations.isEmpty {
            mapView.removeAnnotations(mapView.annotations)
        }
        mapView.addAnnotations(annotations)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AlbumViewController {
            viewController.selectedPin = selectedPin
        }
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    // Customize pin apperance
    //    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //        let reuseId = "pin"
    //        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    //
    //        if pinView == nil {
    //            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
    //            pinView!.pinTintColor = .red
    //        }
    //        else {
    //            pinView!.annotation = annotation
    //        }
    //        return pinView
    //    }
        
    // Response to pin selection
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pins = fetchedResultsController.fetchedObjects, let coordinate = view.annotation?.coordinate {
            guard let indexPath = pins.firstIndex(where: { (pin) -> Bool in
                pin.latitude == coordinate.latitude &&
                pin.longitude == coordinate.longitude
            }) else { return }
            
            selectedPin = pins[indexPath]
            mapView.deselectAnnotation(view.annotation, animated: false)
            performSegue(withIdentifier: "albumSegue", sender: nil)
        }
    }
    
    // Response to zooming
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        MapModel.instance.saveMapRegion(region: mapView.region)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MapViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            return
        }
        switch (type) {
        case .insert:
            createPinFromCoordinate(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
            break
        default:
            break
        }
    }
}
