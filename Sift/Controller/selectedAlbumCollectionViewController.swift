//
//  selectedAlbumCollectionViewController.swift
//  Sift
//
//  Created by Lauren Champeau on 9/23/17.
//  Copyright © 2017 Lauren Champeau. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

private let reuseIdentifier = "photoCollectionViewCell"

class selectedAlbumCollectionViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {

    // Dismiss view controller to go back to table view
    @IBAction func cancelButtonDidPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Variables
    var selectedFetchResult: PHFetchResult<PHAsset>!
    var selectedAlbum: PHAssetCollection!
    let imgManager = PHCachingImageManager()
    var cellSize: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register to follow photo library changes
        PHPhotoLibrary.shared().register(self)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(donePressed))
        self.navigationItem.rightBarButtonItem = doneButton
        
    }
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func donePressed() -> Void{
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let scale = UIScreen.main.scale
        let idealCellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        cellSize = CGSize(width: idealCellSize.width * scale, height: idealCellSize.height * scale)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = (segue.destination as? UINavigationController)?.topViewController as? SwipingViewController else {
            fatalError("wrong segue destination")
        }
        
        // Set properties for destination view controller
        let indexPath = collectionView!.indexPath(for: sender as! UICollectionViewCell)!
        destination.currPhoto = selectedFetchResult.object(at: indexPath.item)
        destination.currAlbum = selectedAlbum
        destination.picIndex = indexPath.item
        destination.fetchResult = selectedFetchResult
    }
    

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedFetchResult.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let currPhoto = selectedFetchResult.object(at: indexPath.item)
        // Set up new cell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: photoCollectionViewCell.self), for: indexPath) as? photoCollectionViewCell else { fatalError("wrong cell present") }
        cell.representedAssetIdentifier = currPhoto.localIdentifier
        // Request image to display in the cell
        imgManager.requestImage(for: currPhoto, targetSize: cellSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == currPhoto.localIdentifier{
                cell.thumbnail = image
            }
        })
        return cell
    }
    
    // PHPhotoLibraryChangeObserver Delegate functions
    func photoLibraryDidChange(_ changeInstance: PHChange){
        guard let changes = changeInstance.changeDetails(for: selectedFetchResult)
            else { return }
        // Always conduct on main queue
        DispatchQueue.main.sync {
            selectedFetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges{
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                collectionView!.reloadData()
            }
        }
    }
}
