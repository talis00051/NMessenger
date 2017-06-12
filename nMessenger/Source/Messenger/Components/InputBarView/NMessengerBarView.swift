//
// Copyright (c) 2016 eBay Software Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import AVFoundation
import Photos

//MARK: InputBarView
/**
 InputBarView class for NMessenger.
 Define the input bar for NMessenger. This is where the user would type text and open the camera or photo library.
 */
open class NMessengerBarView: InputBarView
    , UITextViewDelegate
    , CameraViewDelegate
{
    //MARK: IBOutlets
    //@IBOutlet for InputBarView
    @IBOutlet open weak var inputBarView: UIView!
    
    @IBOutlet open weak var photoPickerButton: UIButton!
    @IBOutlet open weak var badgeLabel: UILabel?
    
    //@IBOutlet for send button
    @IBOutlet open weak var sendButton: UIButton!
    //@IBOutlets NSLayoutConstraint input area view height
    @IBOutlet open weak var textInputAreaViewHeight: NSLayoutConstraint!
    //@IBOutlets NSLayoutConstraint input view height
    @IBOutlet open weak var textInputViewHeight: NSLayoutConstraint!
    
    @IBOutlet open weak var textInputViewTopMargin   : NSLayoutConstraint?
    @IBOutlet open weak var textInputViewBottomMargin: NSLayoutConstraint?
    
    
    //MARK: Public Parameters
    //Reference to CameraViewController
    open lazy var cameraVC: UIViewController /*protocol<ICameraViewController>*/ = CameraViewController()
    
    open var cameraVcProto: ICameraViewController
    {
        return self.cameraVC as! ICameraViewController
    }
    
    
    //CGFloat to the fine the number of rows a user can type
    open var numberOfRows:CGFloat = 3
    open var maxSymolsCountInMessage: Int? = nil
    
    //String as placeholder text in input view
    open var inputTextViewPlaceholder: String =
        Bundle.main.localizedString(forKey: "Chat.InputField.PlaceholderText",
                                     value: "==Write a message==",
                                     table: nil)
    {
        willSet(newVal)
        {
            self.textInputView.text = newVal
        }
    }
    
    //MARK: Private Parameters
    //CGFloat as defualt height for input view
    public var textInputViewHeightConst:CGFloat = 30
    
    // MARK: Initialisers
    /**
     Initialiser the view.
     */
    public required init()
    {
        super.init()
    }
    
    /**
     Initialiser the view.
     - parameter controller: Must be NMessengerViewController. Sets controller for the view.
     Calls helper method to setup the view
     */
    public required init(controller:NMessengerViewController)
    {
        super.init(controller: controller)
        loadFromBundle()
    }
    
    public required init(controller: NMessengerViewController,
                            nibName: String,
                             bundle: Bundle)
    {
        super.init(controller: controller)
        
        self.loadFrom(bundle: bundle, nibName: nibName)
    }
    
    /**
     Initialiser the view.
     - parameter controller: Must be NMessengerViewController. Sets controller for the view.
     - parameter frame: Must be CGRect. Sets frame for the view.
     Calls helper method to setup the view
     */
    public required init(controller: NMessengerViewController,
                              frame: CGRect)
    {
        super.init(controller: controller,
                        frame: frame)
        
        loadFromBundle()
    }
    /**
     - parameter aDecoder: Must be NSCoder
     Calls helper method to setup the view
     */
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        loadFromBundle()
    }
    
    // MARK: Initialiser helper methods
    /**
     Loads the view from nib file InputBarView and does intial setup.
     */
    fileprivate func loadFromBundle()
    {
        let nmessengerBundle = Bundle(for: NMessengerViewController.self)
        let nibName = "NMessengerBarView"
        
        
        self.loadFrom(bundle: nmessengerBundle, nibName: nibName)
    }
    
    fileprivate func loadFrom(bundle: Bundle,
                             nibName: String)
    {
        let nibObjects = bundle.loadNibNamed( nibName,
                                       owner: self,
                                     options: nil)
        /*let fileOwnerSelf*/ _ = nibObjects?[0] as! UIView
        
        self.addSubview(inputBarView)
        inputBarView.frame                = self.bounds
        textInputView.delegate            = self
        self.sendButton.isEnabled         = false
        self.cameraVcProto.cameraDelegate = self

    }
    
    //MARK: TextView delegate methods
    
    /**
     Implementing textViewShouldBeginEditing in order to set the text indictor at position 0
     */
    open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        textView.text = ""
        textView.textColor = UIColor.n1DarkestGreyColor()
        UIView.animate(withDuration: 0.1)
        {
            self.sendButton.isEnabled = true
        }
        
        DispatchQueue.main.async
        {
            textView.selectedRange = NSMakeRange(0, 0)
        }
        return true
    }
    
    /**
     Implementing textViewShouldEndEditing in order to re-add placeholder and hiding send button when lost focus
    */
    open func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    {
        if self.textInputView.text.isEmpty
        {
            self.addInputSelectorPlaceholder()
        }
        
        UIView.animate(withDuration: 0.1)
        {
            self.sendButton.isEnabled = false
        }
        
        self.textInputView.resignFirstResponder()
        return true
    }
    /**
     Implementing shouldChangeTextInRange in order to remove placeholder when user starts typing and to show send button
     Re-sizing the text area to default values when the return button is tapped
     Limit the amount of rows a user can write to the value of numberOfRows
    */
    open func textView(_ textView: UITextView,
         shouldChangeTextIn range: NSRange   ,
             replacementText text: String    )
    -> Bool
    {
        let isEmptyText = (textView.text == "")
        let isNewLineReplacementText = (text == "\n")
        
        
        if (isEmptyText && !isNewLineReplacementText)
        {
            UIView.animate(withDuration: 0.1)
            {
                self.sendButton.isEnabled = true
            }
            return true
        }
        else if isNewLineReplacementText && !isEmptyText
        {
            if textView == self.textInputView
            {
                self.doSend()
                
                return false
            }
        }
        else if (!isNewLineReplacementText)
        {
            let castedText: NSString = textView.text as NSString
            let newText = castedText.replacingCharacters(in: range, with: text)
            let lengthOfNewText = newText.characters.count
            
            
            let numberOfLines = self.getNumberOfLines(forText: newText,
                                                   inTextView: textView)
            let isLineLimitOk = (numberOfLines <= self.numberOfRows)
            
            if let maxSymolsCountInMessage = self.maxSymolsCountInMessage
            {
                let isSymbolLimitOk = (lengthOfNewText <= maxSymolsCountInMessage)
                let result = isSymbolLimitOk && isLineLimitOk
                
                return result
            }
            else
            {
                // legacy behaviour
                return isLineLimitOk
            }
        }
        return false
    }
    
    private func getNumberOfLines(forText newText: String,
                              inTextView textView: UITextView) -> CGFloat
    {
        let textViewInsets =
            UIEdgeInsetsInsetRect(
                textView.frame,
                textView.textContainerInset)
        
        let textWidth: CGFloat =
            textViewInsets.width
                - 2.0 * textView.textContainer.lineFragmentPadding
        
        
        let options: NSStringDrawingOptions =
        [
            NSStringDrawingOptions.usesLineFragmentOrigin,
            NSStringDrawingOptions.usesFontLeading
        ]
        
        let attributes: [String : Any] =
        [
            NSFontAttributeName: textView.font!
        ]
        
        
        let textBounds = CGSize(width: textWidth, height: 0)
        let boundingRect: CGRect =
            newText.boundingRect(
                   with: textBounds,
                options: options,
             attributes: attributes,
                context: nil)
        
        let numberOfLines = boundingRect.height / textView.font!.lineHeight;

        return numberOfLines
    }
    
    private func topAndBottomMarginsForTextView() -> CGFloat
    {
        guard let textInputViewTopMargin    = self.textInputViewTopMargin   ,
              let textInputViewBottomMargin = self.textInputViewBottomMargin
        else
        {
            // legacy value
            //
            return 10
        }
        
        let result = textInputViewTopMargin.constant + textInputViewBottomMargin.constant
        return result
    }
    
    /**
     Implementing textViewDidChange in order to resize the text input area
     */
    open func textViewDidChange(_ textView: UITextView)
    {
        let fixedWidth = textView.frame.size.width
    
        let rawNewSize = CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)
        let newSize = textView.sizeThatFits(rawNewSize)
        
        var newFrame = textView.frame
        let newFrameWidth  = max(newSize.width , fixedWidth)
        let newFrameHeight = max(newSize.height, self.textInputViewHeightConst)
        newFrame.size = CGSize(width: newFrameWidth,
                              height: newFrameHeight)
        
        let textViewMarginsHeight = self.topAndBottomMarginsForTextView()
        self.textInputViewHeight.constant = newFrame.size.height
        self.textInputAreaViewHeight.constant =
            newFrame.size.height
          + textViewMarginsHeight
    }
    
    //MARK: TextView helper methods
    /**
     Adds placeholder text and change the color of textInputView
     */
    fileprivate func addInputSelectorPlaceholder()
    {
        self.textInputView.text = self.inputTextViewPlaceholder
        self.textInputView.textColor = UIColor.lightGray
    }
    
    //MARK: @IBAction selectors
    /**
     Send button selector
     Sends the text in textInputView to the controller
     */
    @IBAction open func sendButtonClicked(_ sender: AnyObject)
    {
        self.doSend()
    }
    
    private func doSend()
    {
        guard let currentText = self.textInputView.text,
              !currentText.isEmpty
        else
        {
            return
        }

        self.controller.onSendButtonTapped(havingText: currentText)
//        images.forEach
//        {
//            _ = self.sendImage($0, isIncomingMessage: false)
//        }
        
        
        self.cleanupTextFieldAndResize()
    }
    
    private func cleanupTextFieldAndResize()
    {
        let textViewMarginsHeight = self.topAndBottomMarginsForTextView()
        self.textInputViewHeight.constant = self.textInputViewHeightConst
        
        
        self.textInputAreaViewHeight.constant =
            self.textInputViewHeightConst
            + textViewMarginsHeight

        self.textInputView.text = ""
    }
    
    
    /**
     Plus button selector
     Requests camera and photo library permission if needed
     Open camera and/or photo library to take/select a photo
     */
    @IBAction open func plusClicked(_ sender: AnyObject?)
    {
        // TODO: check callbacks for memory leaks and retain cycles
        
        let authStatus = self.cameraVcProto.cameraAuthStatus
        let photoLibAuthStatus = self.cameraVcProto.photoLibAuthStatus
        
        if(authStatus != AVAuthorizationStatus.authorized)
        {
            self.cameraVcProto.isCameraPermissionGranted(
            {
                (granted) in
                
                if(granted)
                {
                    NSLog("[NMessenger] showPickerView - camera requested and granted")
                    self.showPickerView(executeAfterTransition: nil)
                }
                else
                {
                    if(photoLibAuthStatus != PHAuthorizationStatus.authorized)
                    {
                        self.cameraVcProto.requestPhotoLibraryPermissions
                        {
                            (granted) in
                            
                            if(granted)
                            {
                                NSLog("[NMessenger] showPickerView - camera request [-]; photo request[x]")
                                self.showPickerView()
                                {
                                    ModalAlertUtilities.postGoToSettingToEnableCameraModal(fromController: self.cameraVC)
                                }
                            }
                            else
                            {
                                NSLog("[NMessenger] showPickerView - camera request [-]; photo request [-]")
                                ModalAlertUtilities.postGoToSettingToEnableCameraAndLibraryModal(fromController: self.controller)
                            }
                        }
                    }
                    else
                    {
                        NSLog("[NMessenger] showPickerView - camera request[-]; photo [x]")
                        self.showPickerView(executeAfterTransition: nil)
                    }
                }
            })
        }
        else
        {
            NSLog("[NMessenger] showPickerView - camera already authorized")
            self.showPickerView(executeAfterTransition: nil)
        }
    }
    
    
    //MARK: CameraView delegate methods
    /**
     Implemetning CameraView delegate method
     Close the CameraView and sends the image to the controller
     */
    open func pickedImages(_ images: [UIImage])
    {
        self.hidePickerView()
        
        self.controller.onImagesPicked(images)
        
//        images.forEach
//        {
//            _ = self.controller.sendImage($0, isIncomingMessage: false)
//        }
    }
    
    
    private typealias ShowPickerViewCompletion = () -> Swift.Void
    private func showPickerView(
        executeAfterTransition callback: ShowPickerViewCompletion?)
    {
        DispatchQueue.main.async
        {
            self.doShowPickerView(executeAfterTransition: callback)
        }
    }
    
    private func doShowPickerView(
        executeAfterTransition callback: ShowPickerViewCompletion?)
    {
        if (self.isPickerCameraVc())
        {
            // legacy behaviour
            //
            self.controller.present( self.cameraVC,
                           animated: true,
                         completion: callback)
        }
        else if let navBar = self.controller.navigationController
        {
            navBar.pushViewController(self.cameraVC, animated: true)
            
            if let callbackUnwrap = callback
            {
                DispatchQueue.main.async
                {
                    // a hack to let the transition complete
                    callbackUnwrap()
                }
            }
        }
        else
        {
            // legacy behaviour
            //
            self.controller.present( self.cameraVC,
                                     animated: true,
                                     completion: callback)
        }
    }
    
    private func hidePickerView()
    {
        DispatchQueue.main.async
        {
            self.doHidePickerView()
        }
    }
    
    private func doHidePickerView()
    {
        if (self.isPickerCameraVc())
        {
            // legacy behaviour
            //
            self.cameraVC.dismiss(animated: true, completion: nil)
        }
        else if let navBar = self.controller.navigationController
        {
            navBar.popViewController(animated: true)
        }
        else
        {
            self.cameraVC.dismiss(animated: true, completion: nil)
        }
    }
    
    
    private func isPickerCameraVc() -> Bool
    {
        if let _ = self.cameraVC as? UIImagePickerController
        {
           return true
        }
    
        return false
    }
    
    /**
     Implemetning CameraView delegate method
     Close the CameraView
     */
    open func cameraCancelSelection()
    {
        self.hidePickerView()
    }

}
