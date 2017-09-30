//
//  SwipingViewController.swift
//  Sift
//
//  Created by Lauren Champeau on 9/24/17.
//  Copyright © 2017 Lauren Champeau. All rights reserved.
//
import MDCSwipeToChoose
import UIKit
import Photos
import PhotosUI
import AVFoundation

class SwipingViewController: UIViewController, MDCSwipeToChooseDelegate {
    
    // variables
    var currPhoto: PHAsset!
    var currAlbum: PHAssetCollection!
    var picIndex: Int = 0
    var fetchResult: PHFetchResult<PHAsset>!
    var picturesToDelete = Array<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(donePressed))
        self.navigationItem.rightBarButtonItem = doneButton
        
        // Update with first image
        updateImage(index: self.picIndex)
    }

    
    func donePressed() -> Void{
        if (self.picturesToDelete.count > 0){
            // If user left-swiped any images, delete
            deletePicture()
        }
        // dismiss and go back to album collection view
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateImage(index: Int){
        view.layoutIfNeeded()
        var index2: Int = index
        
        // Reached end of album
        if (index >= self.fetchResult.count){
            donePressed()
        }
        else{
            let options = MDCSwipeToChooseViewOptions()
            options.delegate = self
            options.likedText = "Keep"
            options.nopeText = "Delete"
            options.nopeColor = UIColor.red
            options.likedColor = UIColor.green
            options.onPan = { state -> Void in
                if (state?.thresholdRatio == 1.0 && state?.direction == .right){
                    index2 += 1
                }
            }
            
            let view = MDCSwipeToChooseView(frame: (self.navigationController?.view.bounds)!, options: options)
            let newCurrPhoto = self.fetchResult.object(at: index2)
            let photoOptions = PHImageRequestOptions()
            photoOptions.deliveryMode = .highQualityFormat
            photoOptions.isNetworkAccessAllowed = true
            photoOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
            
            var targetSize: CGSize {
                let scale = UIScreen.main.scale
                return CGSize(width: view!.bounds.width * scale,
                              height: view!.bounds.height * scale)
            }
            // Request specified image
            PHImageManager.default().requestImage(for: newCurrPhoto, targetSize: targetSize, contentMode: .aspectFill, options: photoOptions, resultHandler: { image, _ in
                guard let image = image else { return }
                view?.imageView.image = image
                view?.imageView.contentMode = UIViewContentMode.scaleAspectFit
                let rect = AVMakeRect(aspectRatio: image.size, insideRect: (view?.imageView.bounds)!)
                view?.imageView.bounds = rect
                self.view.addSubview(view!)
                self.view.contentMode = UIViewContentMode.scaleAspectFit    
            })
        }
    }
    
    // MDCSwipeToChoose Delegate Functions:
    
    func deletePicture(){
        let completion = { (success: Bool, error: Error?) -> () in
            if !success {
                print("can't remove photo: \(error)")
            }
        }
        
        if currAlbum != nil {
            // Remove asset from album
            PHPhotoLibrary.shared().performChanges({
                // Combine change requests into one change block so user is not asked permission on each swipe, but only at end
                let request = PHAssetCollectionChangeRequest(for: self.currAlbum)!
                for i in 0 ... self.picturesToDelete.count - 1{

                    request.removeAssets([self.fetchResult.object(at: self.picturesToDelete[i])] as NSArray)
                }
            }, completionHandler: completion)
        } else {
            // Delete asset from library
            PHPhotoLibrary.shared().performChanges({
                for i in 0 ... self.picturesToDelete.count - 1{
                    PHAssetChangeRequest.deleteAssets([self.fetchResult.object(at: self.picturesToDelete[i])] as NSArray)
                }
            }, completionHandler: completion)

        }
        

    }
    
    func view(_ view: UIView, shouldBeChosenWith: MDCSwipeDirection) -> Bool {
        // If at end of collection, don't allow user to continue swiping (handle edge cases)
        if ((self.picIndex >= self.fetchResult.count - 1) && (shouldBeChosenWith == .right)){
            return false
        }
        return true
    }
    
    func view(_ view: UIView, wasChosenWith: MDCSwipeDirection) -> Void {
        if (wasChosenWith == .left) {
            self.picturesToDelete.append(self.picIndex)
        }
        self.picIndex += 1
        updateImage(index: self.picIndex)
    }
}

