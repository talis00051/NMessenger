//
//  CameraStreamCellView.swift
//  nMessenger
//
//  Created by Alexander Dodatko on 5/22/17.
//  Copyright © 2017 Ebay Inc. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

public class CameraStreamCellView: UIView
{
    @IBOutlet public weak var captureView: UIView?      = nil
    @IBOutlet public weak var overlayView: UIView?      = nil
    @IBOutlet public weak var cameraIcon : UIImageView? = nil
    @IBOutlet public weak var textLabel  : UILabel?     = nil
    
    public override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.overlayView?.layer.cornerRadius = 10
        self.overlayView?.alpha = 0.6
        self.overlayView?.backgroundColor = UIColor.black
        
        self.configureVideoCaptureLayer()
        self.bringSubview(toFront: self.overlayView!)
    }
    
    private func configureVideoCaptureLayer()
    {
        let captureSession = AVCaptureSession()
        
        guard let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession),
              let captureView = self.captureView
        else
        {
            return
        }
        
        videoLayer.frame = captureView.bounds
        captureView.layer.addSublayer(videoLayer)
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        guard let rawVideoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo),
              let videoDevices = rawVideoDevices as? [AVCaptureDevice],
              let captureDevice: AVCaptureDevice = videoDevices.first
        else
        {
            return
        }
        self.configureCaptureDevice(captureDevice)
        
        
        if let captureInput = try? AVCaptureDeviceInput(device: captureDevice)
        {
            captureSession.addInput(captureInput)
            captureSession.startRunning()
        }
    }
    
    private func configureCaptureDevice(_ captureDevice: AVCaptureDevice)
    {
        // TODO: tweaks of quality and focus
    }
}

