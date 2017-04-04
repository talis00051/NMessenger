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
