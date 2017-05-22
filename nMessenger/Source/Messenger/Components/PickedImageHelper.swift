//
//  PickedImageHelper.swift
//  nMessenger
//
//  Created by Alexander Dodatko on 5/22/17.
//  Copyright © 2017 Ebay Inc. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

internal enum PickedImageHelper
{
    static func getImageFromPicker(_ picker: UIImagePickerController,
                     completionOptions info: [String : Any])
    -> UIImage?
    {
        var myImage:UIImage? = nil
        
        if let tmpImage = info[UIImagePickerControllerEditedImage] as? UIImage
        {
            myImage = tmpImage
            return myImage
        }
        else
        {
            print("[NMEssenger] PickedImageHelper : Something went wrong - UIImagePickerControllerEditedImage")

            if let tmpImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            {
                myImage = tmpImage
            }
            else
            {
                print("[NMEssenger] PickedImageHelper : Something went wrong - UIImagePickerControllerOriginalImage")
            }
            
            //myImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            /* Correctly flip the mirrored image of front-facing camera */
            
            let isFrontSideCameraUsed =
                (picker.cameraDevice == UIImagePickerControllerCameraDevice.front)
            if (isFrontSideCameraUsed)
            {
                if let im      = myImage,
                   let cgImage = im.cgImage
                {
                    myImage =
                        UIImage(cgImage: cgImage,
                                  scale: im.scale,
                            orientation: .leftMirrored)
                }
            }
        }

        return myImage
    }
}
