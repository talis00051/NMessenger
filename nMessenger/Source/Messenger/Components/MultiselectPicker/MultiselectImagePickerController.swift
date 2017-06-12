//
//  MultiselectImagePickerController.swift
//  nMessenger
//
//  Created by Alexander Dodatko on 5/18/17.
//  Copyright © 2017 Ebay Inc. All rights reserved.
//

import Foundation

import Photos
import AVFoundation



internal typealias PHImageFetchCallback = (UIImage?, [AnyHashable : Any]?) -> Swift.Void
internal typealias PHImageLoaderBlock   = (@escaping PHImageFetchCallback) -> Swift.Void

// TODO: fix signature appropriately
//
internal typealias NMSaveImageCallback = (Bool, Error?) -> Swift.Void

internal protocol MultiselectImagePickerControllerDelegate: class
{
    func pickerDidLoadImagesMetadata(sender: Any)
}

internal class MultiselectImagePickerController: NSObject
{
    // if this one is not `lazy`, 
    // you'll see an unwanted system dialog 
    // about "photo access permission"
    //
    private lazy var _imageManager      : PHCachingImageManager = PHCachingImageManager()
    
    
    private      var _allPhotosDataset  : PHFetchResult<PHAsset>?
    private      var _multiselectIndices: Set<Int> = []
    
    public weak var delegate: MultiselectImagePickerControllerDelegate?
    
    private func incrementSelectionIndicesOnNewPhotoInsertion()
    {
        // TODO: fix for the case when time settings of the device are changed
        //
        
        let updatedIndices: [Int] = self._multiselectIndices.map { $0 + 1 }
        let indexOfNewPhoto: Int = 1
        
        let newIndices = updatedIndices + [indexOfNewPhoto]
        
        self._multiselectIndices = Set<Int>(newIndices)
    }
    
    private func updatePhotosDataset() -> PHFetchResult<PHAsset>
    {
        return MultiselectImagePickerController.updatePhotosDataset()
    }
    
    private static func updatePhotosDataset() -> PHFetchResult<PHAsset>
    {
        let allPhotosLatestOnTop = PHFetchOptions()
        
        if #available(iOS 9.0, *)
        {
            allPhotosLatestOnTop.includeAssetSourceTypes = PHAssetSourceType.typeUserLibrary
        }
        
        allPhotosLatestOnTop.sortDescriptors =
            [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result: PHFetchResult<PHAsset>?
        result = PHAsset.fetchAssets(with: allPhotosLatestOnTop)
        
        return result!
    }
    
    
    private static func getCameraRollAlbum() -> PHAssetCollection?
    {
        // http://stackoverflow.com/questions/25730830/how-to-get-only-images-in-the-camera-roll-using-photos-framework
        
        // https://gist.github.com/Koze/f8b3adf542c5dae6e9cf
        //
        let query = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                         subtype: .smartAlbumUserLibrary,
                                                         options: nil)
        let result: PHAssetCollection? = query.firstObject
        print("[nmessenger] [debug] camera roll name" + (result?.localizedTitle ?? ""))
        
        return result
    }
    
    private func getCameraRollAlbum() -> PHAssetCollection?
    {
        return MultiselectImagePickerController.getCameraRollAlbum()
    }
    
    public func loadImagesAsync()
    {
        self._allPhotosDataset = MultiselectImagePickerController.updatePhotosDataset()
        
        self.delegate?.pickerDidLoadImagesMetadata(sender: self)
    }
    
    public func toggleSelectionAt(index: Int)
    {
        if (self._multiselectIndices.contains(index))
        {
            self._multiselectIndices.remove(index)
        }
        else
        {
            self._multiselectIndices.insert(index)
        }
    }
    
    public func isImageSelectedAt(index: Int) -> Bool
    {
        let result = self._multiselectIndices.contains(index)
        return result
    }
    
    public func numberOfImages() -> Int
    {
        let photosCount = self._allPhotosDataset?.count ?? 0
        let photosAndCameraCellCount = photosCount + 1
        
        let result = photosAndCameraCellCount
        return result
    }
    
    public func imageLoaderAt(index: Int) -> PHImageLoaderBlock
    {
        precondition(index > 0)
        precondition(nil != self._allPhotosDataset)
        
        let indexWithoutCameraButton = index - 1
        
        let asset: PHAsset = self._allPhotosDataset!.object(at: indexWithoutCameraButton)
        let imageSize = CGSize(width: 100, height: 100)
        
        let result: PHImageLoaderBlock =
        {
            callback in
            
            self._imageManager.requestImage(for: asset     ,
                                     targetSize: imageSize ,
                                    contentMode: .aspectFit,
                                        options: nil       ,
                                  resultHandler: callback  )
        }
        
        return result
    }
    
    public func imageLoadersForSelectedImages() -> [PHImageLoaderBlock]
    {
        let result = self._multiselectIndices.map
        {
            currentIndex -> PHImageLoaderBlock in
            
            let blockResult = self.imageLoaderAt(index: currentIndex)
            return blockResult
        }
        
        return result
    }
    
    public func saveImageFromCameraAsync(_ image: UIImage
                                /*, callback: @escaping NMSaveImageCallback*/)
    {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(MultiselectImagePickerController.image(_:didFinishSavingWithError:contextInfo:)),
            nil)
    }
    
    
    @objc(image:didFinishSavingWithError:contextInfo:)
    private func image(_  image: UIImage,
 didFinishSavingWithError error: NSError?,
                    contextInfo: UnsafeRawPointer)
    {
        self.incrementSelectionIndicesOnNewPhotoInsertion()
        self._allPhotosDataset = self.updatePhotosDataset()
        self.delegate?.pickerDidLoadImagesMetadata(sender: self)
    }

    private func saveImageFromCameraAsync_photos_framework(
        _ image: UIImage,
        callback: @escaping NMSaveImageCallback)
    {
        let transactionBlock: () -> Void =
        {
            let cameraRollAlbum  = self.getCameraRollAlbum()!
            let saveImageRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            let notSavedYetImageAsset = saveImageRequest.placeholderForCreatedAsset
            let editAlbumRequest = PHAssetCollectionChangeRequest(for: cameraRollAlbum)
            editAlbumRequest?.addAssets([notSavedYetImageAsset] as NSArray)
        }
        
        let saveCallback: (Bool, Error?) -> Swift.Void =
        {
            [weak weakSelf = self]
            (status, maybeError) in
            
            if let strongSelf = weakSelf
            {
                strongSelf.incrementSelectionIndicesOnNewPhotoInsertion()
                strongSelf._allPhotosDataset = strongSelf.updatePhotosDataset()
                strongSelf.delegate?.pickerDidLoadImagesMetadata(sender: strongSelf)
            }
            
            callback(status, maybeError)
        }
        
        PHPhotoLibrary.shared().performChanges( transactionBlock,
                                                completionHandler: saveCallback    )
    }
}
