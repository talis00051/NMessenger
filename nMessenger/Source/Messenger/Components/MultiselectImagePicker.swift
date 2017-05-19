//
//  MultiselectImagePicker.swift
//  nMessenger
//
//  Created by Alexander Dodatko on 5/18/17.
//  Copyright © 2017 Ebay Inc. All rights reserved.
//

import Foundation

import UIKit
import Photos
import AVFoundation

open class MultiselectImagePicker: UIViewController
{
    // MARK: - ICameraViewController
    //
    open weak var cameraDelegate: CameraViewDelegate?
    

    fileprivate static let cellId = "PhotoCell"
    fileprivate var _controller = MultiselectImagePickerController()
    fileprivate var _grid: UICollectionView?
    
    
    // MARK: - UIViewController
    //
    open override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.addGridViewFullScreen()
        self._controller.delegate = self
        
        self.setupColours()
    }
    
    open override func viewDidAppear(_ animated: Bool)
    {
        self.loadImagesAsync()
        super.viewDidAppear(animated)
    }
    
    private func addGridViewFullScreen()
    {
        guard let myView = self.view
        else
        {
            return
        }
        
        let layout = UICollectionViewFlowLayout()
        
        let margin: CGFloat = 3
        let viewWidth: CGFloat = myView.bounds.width
        
        let numberOfRows = 3
        let numberOfRowsF = CGFloat(numberOfRows)
        
        let numberOfMarginsForThreeRows = numberOfRows + 1
        let numberOfMarginsForThreeRowsF = CGFloat(numberOfMarginsForThreeRows)
        
        let threeInRow = (viewWidth - numberOfMarginsForThreeRowsF * margin) / numberOfRowsF
        layout.itemSize = CGSize(width: threeInRow, height: threeInRow)
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = margin
        
        
        let grid = UICollectionView(frame: myView.bounds,
                     collectionViewLayout: layout)
        
             grid.register( UICollectionViewCell.self,
forCellWithReuseIdentifier: MultiselectImagePicker.cellId)
        
        self._grid      = grid
        grid.dataSource = self
        grid.delegate   = self
        
        self.view.addSubview(grid)
        
        self.addFullScreenConstraintsForGrid(grid)
    }
    
    private func addFullScreenConstraintsForGrid(_ grid: UICollectionView)
    {
        grid.autoresizingMask =
            UIViewAutoresizing.flexibleWidth.union(UIViewAutoresizing.flexibleHeight)
    }
    
    private func setupColours()
    {
        self.view.backgroundColor   = UIColor.white
        self._grid?.backgroundColor = UIColor.white
    }
    
    // MARK: - logic
    private func loadImagesAsync()
    {
        
    }
}

extension MultiselectImagePicker: ICameraViewController
{
    open var cameraAuthStatus   : AVAuthorizationStatus
    {
        // TODO: maybe use ivar
        //
        
        let result =
            AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        return result
    }
    
    open var photoLibAuthStatus : PHAuthorizationStatus
    {
        // TODO: maybe use ivar
        //
        
        let result = PHPhotoLibrary.authorizationStatus()
        return result
    }
    
    open func isCameraPermissionGranted(
        _ completion:@escaping CameraPermissionCallback)
    {
        // TODO: maybe set status to ivar
        //
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
                                      completionHandler: completion)
    }
    
    open func requestPhotoLibraryPermissions(
        _ completion: @escaping PhotoLibraryPermissionCallback)
    {
        PHPhotoLibrary.requestAuthorization
        {
            status in
            
            // TODO: maybe set status to ivar
            //
            
            switch status
            {
                case .authorized: completion(true)
                case .denied, .notDetermined, .restricted : completion(false)
            }
        }
    }
}

extension MultiselectImagePicker: MultiselectImagePickerControllerDelegate
{
    public func pickerDidLoadImagesMetadata(sender: Any)
    {
        self._grid?.reloadData()
    }
}

extension MultiselectImagePicker: UICollectionViewDataSource
{
    public func collectionView(_ collectionView: UICollectionView,
                 numberOfItemsInSection section: Int)
    -> Int
    {
        return self._controller.numberOfImages()
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell
    {
        let itemIndex = indexPath.item
        let isCameraCell = (0 == itemIndex)
        
        let cellId = MultiselectImagePicker.cellId
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId,
                                                                      for: indexPath)
        let cellContentView = cell.contentView
        let cellContentViewBounds = cell.contentView.bounds
        let subviews: [UIView] = cellContentView.subviews
        
        var imageStatusView: ImagePickerCellView? = nil
        
        if (subviews.isEmpty)
        {
            if let newStatusView = self.loadCellContentView()
            {
                newStatusView.frame = cellContentViewBounds
                cellContentView.addSubview(newStatusView)
                
                imageStatusView = newStatusView
            }
        }
        else if let oldStatusView = subviews[0] as? ImagePickerCellView
        {
            imageStatusView = oldStatusView
        }
        
        guard let statusViewUnwrap: ImagePickerCellView = imageStatusView
        else
        {
            return cell
        }

        
        if (isCameraCell)
        {
            // TODO: make a properly looking overlay, etc.
            //
            let openCameraImageName = "photo-camera-icon"
            let nmessengerBundle = Bundle(for: MultiselectImagePicker.self)
            let openCameraImage = UIImage(named: openCameraImageName,
                                             in: nmessengerBundle,
                                 compatibleWith: nil)
            
            statusViewUnwrap.imageView?.image = openCameraImage
            statusViewUnwrap.statusView?.isHidden = true
        }
        else
        {
            statusViewUnwrap.statusView?.isHidden = false
            statusViewUnwrap.statusView?.alpha =
                self._controller.isImageSelectedAt(index: itemIndex)
                    ? 1
                    : 0.5
            
            // set content
            //
            let loader = self._controller.imageLoaderAt(index: itemIndex)
            let callback: PHImageFetchCallback =
            {
                (image, _) in
                
                statusViewUnwrap.imageView?.image = image
            }
            
            // TODO: make it cancellable in case of bugs
            //
            loader(callback)
        }
        
        
        // DEBUG
        //
        cell.backgroundColor = UIColor.cyan
        
        return cell
    }
    
    private func loadCellContentView() -> ImagePickerCellView?
    {
        // TODO: allow custom nib from external bundles
        //
        let nmessengerBundle = Bundle(for: ImagePickerCellView.self)
        let nib = UINib(nibName: "ImagePickerCellView", bundle: nmessengerBundle)
        let nibObjects = nib.instantiate(withOwner: nil, options: nil)
        
        let newStatusView = nibObjects[0] as? ImagePickerCellView
        newStatusView?.imageView?.contentMode = .scaleAspectFill
        newStatusView?.imageView?.clipsToBounds = true
        
        return newStatusView
    }
}


extension MultiselectImagePicker: UICollectionViewDelegate
{
    public func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath)
    {
        let itemIndex = indexPath.item
        let isCameraCell = (0 == itemIndex)
        
        if (isCameraCell)
        {
            self.onCameraCellSelected()
        }
        else
        {
            self._controller.toggleSelectionAt(index: indexPath.item)
            self._grid?.reloadItems(at: [indexPath])
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                    didDeselectItemAt indexPath: IndexPath)
    {
        let itemIndex = indexPath.item
        let isCameraCell = (0 == itemIndex)
        
        if (isCameraCell)
        {
            self.onCameraCellSelected()
        }
        else
        {
            self._controller.toggleSelectionAt(index: indexPath.item)
            self._grid?.reloadItems(at: [indexPath])
        }
    }
    
    fileprivate func onCameraCellSelected()
    {
        // TODO: shoot a photo with camera
    }
}

