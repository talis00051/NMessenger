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
    public weak var cameraDelegate: CameraViewDelegate?
    
    public var localizer: MultiselectPickerLocalizer?
    {
        didSet
        {
            self.setupNavbarTitles()
        }
    }

    fileprivate static let cellId       = "PhotoCell"
    fileprivate static let cameraCellId = "CameraCell"
    
    fileprivate var _controller = MultiselectImagePickerController()
    fileprivate var _grid: UICollectionView?
    
    
    // MARK: - UIViewController
    //
    open override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.addSaveButtonToNavbar()
        self.addGridViewFullScreen()
        self._controller.delegate = self
        
        self.setupColours()
    }
    
    open override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.setupNavbarTitles()
        self.loadImagesAsync()
    }
    
    private func setupNavbarTitles()
    {
        self.navigationItem.title = self.localizer?.pickerNameForNavBar
        if let backButtonName = self.localizer?.backButtonName
        {
            //self.navigationItem.backBarButtonItem?.title = backButtonName
            self.navigationController?.navigationBar.topItem?.title = backButtonName
        }
    }
    
    private func addSaveButtonToNavbar()
    {
        let handler: Selector = #selector(MultiselectImagePicker.onSaveBarButtonTapped)
        let rightItemToAdd = UIBarButtonItem(barButtonSystemItem: .save  ,
                                                          target: self   ,
                                                          action: handler)
        
        let navItem = self.navigationItem
        navItem.rightBarButtonItem = rightItemToAdd
    }
    
    @objc
    private func onSaveBarButtonTapped()
    {
        self.performSave()
    }
    
    
    private var loadedImages: [UIImage] = []
    private func performSave()
    {
        let loaders = self._controller.imageLoadersForSelectedImages()
        let assets  = self._controller.assetsForSelectedImages()
        
        self.loadedImages = []
        
        // TODO: maybe move group and mutex to ivars
        //
        let group = DispatchGroup()
        let imageListGuard = NSLock()
        
        loaders.forEach
        {
            (singleLoader) in
            
            group.enter()
            
            let loaderCallback: PHImageFetchCallback =
            {
                [weak weakSelf = self]
                (maybeImage, _) in
                
                defer
                {
                    group.leave()
                }
                
                if let singleImage = maybeImage
                {
                    imageListGuard.lock()
                    defer
                    {
                        imageListGuard.unlock()
                    }
                    
                    weakSelf?.loadedImages.append(singleImage)
                }
            }
            singleLoader(loaderCallback)
        }
        
        group.notify(queue: DispatchQueue.main)
        {
            self.performSave(
                withImages: self.loadedImages,
                assets: assets)
        }
    }
    
    private func performSave(
        withImages images: [UIImage],
                   assets: [PHAsset])
    {
        // popping current controller will be made by NMessengerBarView
        //
        self.cameraDelegate?.pickedImages(images)
        self.cameraDelegate?.pickedImageAssets(assets)
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

             grid.register( UICollectionViewCell.self,
forCellWithReuseIdentifier: MultiselectImagePicker.cameraCellId)

        
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
        self._controller.loadImagesAsync()
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
        
        let cellId =
            isCameraCell
                ? MultiselectImagePicker.cameraCellId
                : MultiselectImagePicker.cellId
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId,
                                                                      for: indexPath)
        
        
        if (isCameraCell)
        {
            self.configureCameraCell(cell)
        }
        else
        {
            self.configureImagePreviewCell(cell, atIndex: itemIndex)
        }
                
        return cell
    }
    
    
    // MARK: - camera cell
    //
    private func configureCameraCell(_ cell: UICollectionViewCell)
    {
        let cellContentView       = cell.contentView
        let cellContentViewBounds = cell.contentView.bounds
        let subviews: [UIView]    = cellContentView.subviews
        
        
        var cameraView: CameraStreamCellView? = nil
  
        if (subviews.isEmpty)
        {
            if let newCameraView = self.loadCameraCellView()
            {
                newCameraView.frame = cellContentViewBounds
                cellContentView.addSubview(newCameraView)
                
                cameraView = newCameraView
            }
        }
        else if let oldCameraView = subviews.first as? CameraStreamCellView
        {
            cameraView = oldCameraView
        }
        
        
        guard let cameraViewUnwrap = cameraView
        else
        {
            return
        }
        
        // TODO: localize and allow customuzation from app bundle
        //
        cameraViewUnwrap.textLabel?.text = "Take Photo"
        let nmessengerBundle = Bundle(for: CameraStreamCellView.self)
        cameraViewUnwrap.cameraIcon?.image = UIImage(named: "Icon_add_photo",
                                                        in: nmessengerBundle,
                                            compatibleWith: nil)
    }
    
    private func loadCameraCellView() -> CameraStreamCellView?
    {
        guard let bundleFromLocalizer  = self.localizer?.cameraCellViewBundle,
              let nibNameFromLocalizer = self.localizer?.cameraCellViewNibName
        else
        {
            return self.loadCameraCellViewDefault()
        }
        
        let nib = UINib(nibName: nibNameFromLocalizer, bundle: bundleFromLocalizer)
        let nibObjects = nib.instantiate(withOwner: nil, options: nil)
        
        if let result = nibObjects[0] as? CameraStreamCellView
        {
            return result
        }
        else
        {
            return self.loadCameraCellViewDefault()
        }
    }
    
    private func loadCameraCellViewDefault() -> CameraStreamCellView?
    {
        let nmessengerBundle = Bundle(for: CameraStreamCellView.self)
        let nib = UINib(nibName: "CameraStreamCellView", bundle: nmessengerBundle)
        let nibObjects = nib.instantiate(withOwner: nil, options: nil)
        
        let result = nibObjects[0] as? CameraStreamCellView
        
        return result
    }
    
    // MARK: - image cell
    //
    private func configureImagePreviewCell(_ cell: UICollectionViewCell,
                                atIndex itemIndex: Int)
    {
        let cellContentView = cell.contentView
        let cellContentViewBounds = cell.contentView.bounds
        let subviews: [UIView] = cellContentView.subviews

        
        var imageStatusView: ImagePickerCellView? = nil
        
        if (subviews.isEmpty)
        {
            if let newStatusView = self.loadImageCellContentView()
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
            return
        }
        
        statusViewUnwrap.statusView?.image = self.checkmarkIcon()
        
        
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
    
    private func loadImageCellContentView() -> ImagePickerCellView?
    {
        guard let bundleFromLocalizer  = self.localizer?.imageCellViewBundle,
              let nibNameFromLocalizer = self.localizer?.imageCellViewNibName
        else
        {
            return self.loadImageCellContentViewDefault()
        }
        
        let nib = UINib(nibName: nibNameFromLocalizer, bundle: bundleFromLocalizer)
        let nibObjects = nib.instantiate(withOwner: nil, options: nil)
        
        if let newStatusView = nibObjects[0] as? ImagePickerCellView
        {
            newStatusView.imageView?.contentMode = .scaleAspectFill
            newStatusView.imageView?.clipsToBounds = true
            
            return newStatusView
        }
        else
        {
            return self.loadImageCellContentViewDefault()
        }
    }
    
    private func loadImageCellContentViewDefault() -> ImagePickerCellView?
    {
        let nmessengerBundle = Bundle(for: ImagePickerCellView.self)
        let nib = UINib(nibName: "ImagePickerCellView", bundle: nmessengerBundle)
        let nibObjects = nib.instantiate(withOwner: nil, options: nil)
        
        let newStatusView = nibObjects[0] as? ImagePickerCellView
        newStatusView?.imageView?.contentMode = .scaleAspectFill
        newStatusView?.imageView?.clipsToBounds = true
        
        return newStatusView
    }
    
    private func checkmarkIcon() -> UIImage
    {
        if let fromLocalizer = self.localizer?.checkmarkIcon
        {
            return fromLocalizer
        }
        
        let imageName = "Checkmark-green"
        let nmessengerBundle = Bundle(for: MultiselectImagePicker.self)
        let result = UIImage(named: imageName       ,
                                in: nmessengerBundle,
                    compatibleWith: nil)
        
        return result!
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
        let cameraVC = UIImagePickerController()
        cameraVC.delegate = self
     
        cameraVC.sourceType = .camera
        
        self.present( cameraVC,
            animated: true    ,
          completion: nil     )
    }
}

extension MultiselectImagePicker: UIImagePickerControllerDelegate
{
    public func imagePickerController(_ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [String : Any])
    {
        let maybePhotoFromCamera:UIImage? =
            PickedImageHelper.getImageFromPicker(picker, completionOptions: info)
        
        if let photoFromCamera = maybePhotoFromCamera
        {
            self._controller.saveImageFromCameraAsync(photoFromCamera)
        }
        
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
}


extension MultiselectImagePicker: UINavigationControllerDelegate
{
    
}
