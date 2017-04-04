### Integration With Your Chat Service

The main purpose of chat messages is exchanging them over the network. The topics above only cover the message rendering aspect. However, it might be unclear how to acthaully push your messages to the network or how to render the received ones. Let's dive in...

Messages management the following two sub-tasks :
* sending realtime messages
* receivung realtime messages
* history integration (both sent and received messages)


Suppose, our chat service is limited to textin. The service, described below, can use any underlying protocol (such as XMPP, Telegram, etc.). `Disclaimer: your chat service might look differently`.

```swift
public protocol IChatMessage
{
    var text: String { get }
    var isIncoming: Bool { get }
}

public protocol IChatServiceDelegate
{
    func chatServiceDidConnect(_ sender: IChatService)
    func chatService(_ sender: IChatService, didSendMessage: IChatMessage)
    func chatService(_ sender: IChatService, didReceiveMessage: IChatMessage)
    func chatService(_ sender: IChatService, didReceiveHistory: [IChatMessage]])

    // TODO: error handling methods are skipped for conciseness
}

public protocol IChatService
{
    func connectAsync()
    func disconnectAsync()

    func sendTextAsync(_ message: String)
    func loadHistoryAsync()
}
```

Sending a message involves two phases : 
1. Find out that the user has typed something and tapped "send" button. In other words, you have to handle the user's input.
2. Pass the user's input to the networking service. This is achieved as a plain method call.

Intercepting the user's input might be not quite obvious since you do not need any delegate subscriptions. It is done by overriding the `NMessengerViewController.sendText()` instance method.


```swift
public class MyChatMessagingVC: NMessengerViewController, IChatServiceDelegate
{
    override func sendText(_ text: String, isIncomingMessage:Bool) -> GeneralMessengerCell
    {
         let shouldSendToServer = !isIncomingMessage

         if (shouldSendToServer)
         {
            // trigger network service
            self.controller?.sendMessageAsync(text)
         }

         // otherwise - just render 
         // `super` is critical to avoid recursion and "just render"
         return super.sendText(text, isIncomingMessage: isIncomingMessage)
    }
}
```

I'd like to highlight the importance of using `super.sendText()` at the end of the function. If `self` is used in this case, you're going to
1. end up with infinite recursion
2. eventually crash due to "stack overflow" reason
3. flood the chat with repeated messages

You can use some other cell contruction code instead. See the ["Content Nodes and Custom Components"](https://github.com/eBay/NMessenger#content-nodes-and-custom-components) section for details.



We can break down the process of "receiving a message" in two phases as well. Here they are: 
1. Subscribe to events from your service. Usually it's done by one of iOS mechanics such as delegates, `NSNotification` or closures.
2. Render the message using `NMessenger`

Let's see how it can be done :

```swift
public class MyChatMessagingVC: NMessengerViewController, IChatServiceDelegate
{
      func chatService(_ sender: IChatService, didReceiveMessage message: IChatMessage)
      {
           // Using `super` to avoid side effects.
           //
           super.sendText(message.text, isIncomingMessage: true)
      }
}
```

So, now your app should be ready to process realtime messaging.



When it comes to history handling, one of the approaches might be purging all the messages from `NMessenger` and re-adding them.

```swift
public class MyChatMessagingVC: NMessengerViewController, IChatServiceDelegate
{
      override func viewDidAppear(_ animated: Bool)
      {
            super.viewDidAppear(animated)

            // supposing `self._chatService` has been the setup in `viewDidLoad` 
            // or injected during the screen transition
            //
            self._chatService.loadHistoryAsync()
      }


      func chatService(_ sender: IChatService, didReceiveHistory: [IChatMessage]])
      {
            super.clearALLMessages()

            messageList.forEach
            {
                // using `super`to avoid side effects
                //
                _ = super.sendText($0.text, isIncomingMessage: $0.isIncoming)
            }
      }
}
```

This approach might result in poor performance and some unwanted visual effects.
```
TODO: describe a better approach
```
