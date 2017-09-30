//
//  albumTableViewController.swift
//  Sift
//
//  Created by Lauren Champeau on 9/12/17.
//  Copyright © 2017 Lauren Champeau. All rights reserved.
//

import UIKit
import Photos

class albumTableViewController: UITableViewController, PHPhotoLibraryChangeObserver {
    
    // Divide table view into sections based on album type
    enum Section: Int {
        case allPhotos = 0
        case userMadeAlbums

        static let count = 2
    }
    
    // enum for segue identifiers
    enum SegueID: String {
        case showAllPhotosID
        case showAlbumPhotosID
    }
    
    var allPhotos: PHFetchResult<PHAsset>!
    var userMadeAlbums: PHFetchResult<PHCollection>!
    let sectionTitles = ["All Photos", "Albums", "Collections"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch all photos from the Photo Library, save into variables
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        userMadeAlbums = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        
        // Register albumTableViewController as PHPhotoLibraryChangeObserver
        PHPhotoLibrary.shared().register(self)

    }
    deinit {
        // Unregister albumTableViewController as PHPhotoLibraryChangeObserver
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)!{
            case .allPhotos: return 1
            case .userMadeAlbums: return userMadeAlbums.count
        }
    }
    
    // PHPhotoLibraryChangeObserver required functions
    func photoLibraryDidChange(_ changeInstance: PHChange){
        if let change = changeInstance.changeDetails(for: allPhotos){
            allPhotos = change.fetchResultAfterChanges
        }
        if let change = changeInstance.changeDetails(for: userMadeAlbums){
            userMadeAlbums = change.fetchResultAfterChanges
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)!{
            case .allPhotos:
                let cell = tableView.dequeueReusableCell(withIdentifier: "allPhotosReuseID", for: indexPath)
                cell.textLabel!.text = sectionTitles[0]
                return cell
            case .userMadeAlbums:
                let cell = tableView.dequeueReusableCell(withIdentifier: "photoCollectionReuseID", for: indexPath)
                // Get name of specific album/collection & place on cell
                let albumName = userMadeAlbums.object(at: indexPath.row)
                cell.textLabel!.text = albumName.localizedTitle
                return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = (segue.destination as? UINavigationController)?.topViewController as? selectedAlbumCollectionViewController else {fatalError("wrong view controller")}
        let optionTapped = sender as! UITableViewCell
        destinationVC.navigationItem.title = optionTapped.textLabel?.text
        navigationItem.title = optionTapped.textLabel?.text
        
        // Determine the destination view controller based on the segue identifier
        switch SegueID(rawValue: segue.identifier!)!{
            case .showAllPhotosID:
                destinationVC.selectedFetchResult = allPhotos
            case .showAlbumPhotosID:
                let indexPath = tableView.indexPath(for: optionTapped)!
                let photoCollection: PHCollection
                switch Section(rawValue: indexPath.section)!{
                    case .userMadeAlbums:
                    photoCollection = userMadeAlbums.object(at: indexPath.row)
                    default: return
                }
                
                // Fetch photos in appropriate album
                let photosToDisplay = photoCollection as? PHAssetCollection
                destinationVC.selectedFetchResult = PHAsset.fetchAssets(in: photosToDisplay!, options: nil)
                destinationVC.selectedAlbum = photosToDisplay
        }
    }
}
