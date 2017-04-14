# This document contains some tutorials for typical tasks which are not covered by README

## 1 - A Node With both Text and Avatar

```swift
    override func sendText(_ text: String, isIncomingMessage:Bool) -> GeneralMessengerCell
    {
        let shouldSendToServer = !isIncomingMessage
        if (shouldSendToServer)
        {
            self.controller?.sendMessageAsync(text)
        }
        
        // not calling `super.sendText()` since we do some customization now
        let result = self.buildNodeForTextMessage(text, isIncomingMessage: isIncomingMessage)
        
        return result
    }
    
    fileprivate func buildNodeForTextMessage(_ text: String, isIncomingMessage:Bool) -> GeneralMessengerCell
    {
        // Node for text content 
        //
        let contentNode = TextContentNode(textMessageString: text,
                                      currentViewController: self,
                                        bubbleConfiguration: self.sharedBubbleConfiguration)


        // Node for the entire "text + avatar"
        //
        let result = MessageNode(content: contentNode)
        
        // Setting `isIncomingMessage` to choose side
        result.isIncomingMessage = isIncomingMessage
        
        // Creating AsyncDisplayKit avatar
        //
        let avatar = ASImageNode()
        avatar.image = self.myAvatarMock()
        
        // !!! If you do not specify this size, you will not see the message at all
        // 
        avatar.preferredFrameSize = CGSize(width: 35, height: 35)
        
        // add the avatar to 
        //
        result.avatarNode = avatar

        return result
    }
```


## 2 - Customize Chat Placeholder String

https://github.com/eBay/NMessenger/issues/120

An appropriate approach is manually creating an instance of `NMessengerBarView` and configuring it properly. However, this approach might be hard for newcommers and those who do not need much customization.


There is no separate property for a placeholder string, so you can use the plain text in your `viewDidLoad` method.

```swift
self.inputBarView.textInputView.text =
            NSLocalizedString("Chat.InputField.PlaceholderText", comment: "Write a message")
```

After the camera shows up and is dismissed, the placeholder text is set from the `NMessengerBarView.inputTextViewPlaceholder` property.
So far there is no control over it from the `NMessengerViewController` except having an explicit instance of `NMessengerBarView`.

As a quick workaround, you can try changing the property initialization. Unfortunately, does not work well for `Cocoapods` and `Carthage` users since you need to have your own copy of `NMessenger` code base.
```swift
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

```



## 3 - Custom Bubble Shape

Not composed yet. The details can be found in the issue listed below
https://github.com/eBay/NMessenger/issues/115


