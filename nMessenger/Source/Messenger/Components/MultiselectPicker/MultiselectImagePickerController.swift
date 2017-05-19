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


internal protocol MultiselectImagePickerControllerDelegate: class
{
    func pickerDidLoadImagesMetadata(sender: Any)
}

internal class MultiselectImagePickerController
{
    private let _imageManager = PHCachingImageManager()
    private var _allPhotosDataset  : PHFetchResult<PHAsset>
    private var _multiselectIndices: Set<Int> = []
    
    public weak var delegate: MultiselectImagePickerControllerDelegate?
    
    public init()
    {
        let allPhotosLatestOnTop = PHFetchOptions()
        allPhotosLatestOnTop.sortDescriptors =
            [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        self._allPhotosDataset = PHAsset.fetchAssets(with: allPhotosLatestOnTop)
    }
    
    public func loadImagesAsync()
    {
        // IDLE: all work done in a constructor
        
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
        let photosCount = self._allPhotosDataset.count
        let photosAndCameraCellCount = photosCount + 1
        
        let result = photosAndCameraCellCount
        return result
    }
    
    public func imageLoaderAt(index: Int) -> PHImageLoaderBlock
    {
        precondition(index > 0)
        
        let indexWithoutCameraButton = index - 1
        
        let asset: PHAsset = self._allPhotosDataset.object(at: indexWithoutCameraButton)
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
}
