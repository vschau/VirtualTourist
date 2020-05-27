//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Vanessa on 5/25/20.
//  Copyright © 2020 Vanessa. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class AlbumViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var albumView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    private var blockOperations: [BlockOperation] = []

    var selectedPin: Pin!
    var loadFromDrive = true
    var urlArray: [String] = []

    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        setupMapView()
        setupCollectionView()
    
        if (fetchedResultsController.fetchedObjects!.count == 0) {
            // start loading photos if nothing is saved on the drive.  Disable the button
            enableCollectionButton(false)
            self.loadFromDrive = false
            PhotoClient.getImagesForCoordinate(lat: selectedPin.latitude, lon: selectedPin.longitude) {(data, error) in
                // data is an array.  If request fails, it'll just be an empty array
                self.urlArray = data
                DispatchQueue.main.async {
                    self.albumView.reloadData()
                }
            }
        } else {
            enableCollectionButton(true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    deinit {
        blockOperations.forEach { $0.cancel() }
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    // MARK: - Setup
    fileprivate func setupCollectionView() {
        albumView.dataSource = self
        albumView.delegate = self
        setUpFlowLayout()
    }
    
    fileprivate func setupMapView() {
        mapView.delegate = self
        let coordinate = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        let viewRegion = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(viewRegion, animated: false)
        createPinFromCoordinate(coordinate)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", selectedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "photo")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func setUpFlowLayout() {
        let width = (view.frame.size.width - 2) / 3
        flowLayout.estimatedItemSize = .zero
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.sectionInset = UIEdgeInsets.zero
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 1
        flowLayout.minimumInteritemSpacing = 1
    }
    
    // MARK: - IBAction
    @IBAction func refreshCollection(_ sender: Any) {
        enableCollectionButton(false)
        urlArray.removeAll()
        loadFromDrive = false
        
        // https://developer.apple.com/library/archive/featuredarticles/CoreData_Batch_Guide/BatchDeletes/BatchDeletes.html
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", selectedPin)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes = [NSDeletedObjectsKey : objectIDArray]
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [context])
        } catch {
            print(error.localizedDescription)
        }
        
        PhotoClient.getImagesForCoordinate(lat: selectedPin.latitude, lon: selectedPin.longitude) {(data, error) in
            self.urlArray = data
            // scroll to top
            DispatchQueue.main.async {
                self.albumView.scrollToItem(at: NSIndexPath(row: 0, section: 0) as IndexPath, at: .centeredVertically, animated: false)
                self.albumView.reloadData()
            }
        }
    }

    // MARK: - UI Helpers
    func enableCollectionButton(_ flag: Bool) {
        if flag {
            newCollectionButton.isEnabled = true
            newCollectionButton.alpha = 1.0
        } else {
            newCollectionButton.isEnabled = false
            newCollectionButton.alpha = 0.5
        }
    }

    func createPinFromCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
    }

    // MARK: - Data Helpers
    func savePhotoInCoreData(_ img: Data) {
        let photo = Photo(context: context)
        photo.img = img
        photo.pin = selectedPin
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - UICollectionViewController
extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if loadFromDrive {
            return fetchedResultsController.sections?.count ?? 1
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        print(fetchedResultsController.sections?[section].numberOfObjects)
        if loadFromDrive {
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        } else {
            return urlArray.count
        }
    }
    
    // load cell
    // cell gets called multiple time at the same index due to reuse: https://stackoverflow.com/questions/37169087/uicollectionview-cellforitematindexpath-called-over-and-over-again-on-scrolling
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell
        if !collectionView.isValid(indexPath: indexPath) { return cell }
        if loadFromDrive {
            let photo = fetchedResultsController.object(at: indexPath)
            if let data = photo.img {
                cell.imageView?.image = UIImage(data: data)
            }
        } else {
            PhotoClient.downloadImage(url: urlArray[indexPath.row]) { (data, error) in
                guard let data = data else {
                    return
                }
                cell.imageView?.image = UIImage(data: data)
                self.savePhotoInCoreData(data)
                // finish downloading all images
                if indexPath.row >= self.urlArray.count - 1 {
                    self.loadFromDrive = true
                }
                // finish downloading the images in the visible cells
                // can't use self.fetchedResultsController.fetchedObjects!.count because it hasn't fetched anything starting out
                if !self.newCollectionButton.isEnabled, indexPath.row >= self.albumView.visibleCells.count - 1 {
                    self.enableCollectionButton(true)
                }
            }
        }
        return cell
    }
    
    // delete
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        if urlArray.count > indexPath.row {
            urlArray.remove(at: indexPath.row)
        }
        do {
            let photoToDelete = fetchedResultsController.object(at: indexPath)
            context.delete(photoToDelete)
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            guard let indexPath = indexPath else { return }
            let op = BlockOperation { self.albumView.deleteItems(at: [indexPath]) }
            blockOperations.append(op)
            break
        default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .delete:
            let op = BlockOperation { self.albumView.deleteSections(indexSet) }
            blockOperations.append(op)
        default: break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        albumView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}
