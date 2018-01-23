# TinCan - Inter Application Communication Library

This document describes the design, features and usage examples of the TinCan library.
The intent of TinCan library is to provide convenient abstraction for message passing between two applications, while allowing arbitrary data to be passed back and forth between them.

## Introduction

Inter application communication can be implemented by message passing between the communicating parties. Message passing can be accomplished by the means of message passing channel abstraction. Message passing channels can be divided into the following types:

* Unidirectional - where the message is being sent always in one direction; from source to target.
* Bidirectional - where both channel ends can be used to send and receive messages.

In turn message send and receive routines can operate in the following ways:

* Synchronous - where a host waits for reply from the other side before proceeding to the next message.
* Asynchronous - where a host sends a message and doesn't wait for reply, but can handle replies (if they arrive) in the future.

The TinCan library implements bidirectional asynchronous message passing between applications with entitlements to the same Application Group ID (it is also possible to send messages to itself, but this flow is redundant.)

## Usage Scenarios

A typical scenario happens when an initiating application opens another application with a request to perform some kind of service. The service providing application may send a message back to the initiating application when it completes the service, or when the user closes it (the decision is made by the integrating parties and is out of TinCan's scope).

Let's take an example of *Videoleap* opening *Photofox* for asset editing. Here are some of the flows which **can** be implemented by message passing between the apps using TinCan:

* It's possible to check whether a given message can be delivered to *Photofox*, and if not, user **can** be navigated to the *App Store* to download it, _but this up to application's implementation_ and is out of TinCan's scope.
* *Videoleap* opens *Photofox* for asset editing and goes to background. Once the user accepts the changes in *Photofox* and returns to *Videoleap*, the asset's edits become visible. TinCan is agnostic to application's crashes. However it's up to the **app's implementation** to be able to recover correctly from crash, during an external asset editing flow.

## Main components

### TINMessage

Message is a metadata container, which is being passed from the source to a target application and holds:

* **Identifier** - A unique identifier of a message.
* **Source scheme** - A URL scheme of an application who sent this message. The scheme should be dedicated for TinCan's communication.
* **Target scheme** - A URL scheme of an application this message is targeted to.
* **Application group ID** - An application group ID this message belongs to.
* **User info dictionary** - A dictionary to store custom key-value pairs.

Once created, the message is persistently stored in a shared directory, which can be accessed by applications that have entitlements to the application group ID associated with the shared folder.

### TINMessage+UserInfo

Category exposing all the default supported keys `TINMessage`'s `userInfo` dictionary. Each message can be attached an arbitrary number of files. File names can be obtained by accessing the `fileNames` property of the `TINMessage`, and their URLs can be obtained by `fileURLs`. Additional convenience categories can be created on top of it, which add user's custom keys.

### TINMessenger

Does the following things:
* Sends a `TINMessage` from one app to the other. Sending a `TINMessage` to an application will result in opening that application and make it the active application running on the foreground.
* Receives a `TINMessage` (via an integration to the receiver's app delegate).
* Manages the messages received by the application by allowing to remove all of them.

## Usage examples

### Creating a message

When creating a message from an existing `UIImage`, `NSData` or file URL one can use any of the following convenience methods from `TINMessageFactory`:
* `-messageWithTargetScheme:userInfo:data:uti:error:`
* `-messageWithTargetScheme:userInfo:image:error:`
* `-messageWithTargetScheme:userInfo:fileURL:operation:error:`

In all the cases above the attached `NSData`/`UIImage`/`fileURL` will be stored persistently at the message's designated directory, and can be accessed using the `fileURLs` property.
The `userInfo` dictionary can be used to pass an arbitrary, `NSSecureCoding` conforming, data in a message. It's up to the integrating developer to define the exact keys and values which are supported. An example to such key-value pair can be “action” key with “action description” value. When the message sending application can fill “edit” or “export” as an action description based on user's request.
For example, given an image one can create message originating from `photofox` to `videoleap` using the following code (assuming `photofox` and `videoleap` are registered as schemes in *Photofox* and *Videoleap* applications):

```objc
auto messageFactory = [TINMessageFactory messageFactoryWithSourceScheme:@"photofox"];
auto _Nullable message = [messageFactory messageWithTargetScheme:@"videoleap" userInfo:@{}];

if (!message) {
  // handle an error in message creation. For example image can't be written into message
  // designated directory.
} else {
  // message created successfully.
}
```

Additionally `-messageWithTargetScheme:block:error:` method provides a URL to message designated directory for the created message. User can write any number of files to the created message's designated directory using the provided `block`. The `block` is expected to return a dictionary which will be set as `userInfo` dictionary of the created message.

Example:

```objc
NSData *data = // some data to be written
auto _Nullable message = [factory messageWithTargetScheme:@"photofox"
                          block:^NSDictionary *(NSURL *messageDirectory, NSError **) {
  auto _Nullable fileURL = nn([messageDirectory URLByAppendingPathComponent:@"foo"]);
  [data writeToFile:fileURL.path options:nil error:nil];
  return @{
    kTINMessageFileNamesKey: @[@"foo"],
    @"action": @"edit"
  };
} error:nil];
```

#### Application specific message creation

Similarly to the client-server model, a service providing application should define the interface of the messages it supports and their format. Additionally the service providing app will define the responses to these messages, if exist.
Let's take an example of *Photofox* as a provider of *image editing services*. It defines the following interface to send an image edit request:

```objc
/// Returns a \c TINMessage with the attached \c image to be edited, originated from
/// \c sourceScheme. \c context is an optional data which will be forwarded as-is in the
/// corresponding response message (with an edited image). If an error occurs the \c error will
/// be set and \c nil will be returned.
///
/// @important the response message's \c userInfo is guaranteed to have the \c context
/// accessible by \c kTINMessageContextKey, if \c context isn't \c nil. Additionally the response
/// message will have the edited image available using the \c filesURL array (first element).
TINMessage * _Nullable ENEditImageMessage(UIImage *image, NSString *sourceScheme,
                                          _Nullable id<NSSecureCoding> context, NSError **error);
```

**Notes**

* The response message format is described in the API definition above, along with the request message.
* This code should be visible to all potential service consumers, hence it must reside in TinCan project.

### Sending a message

Message can be sent to its target application, with the given `targetScheme`, using the following code:

```objc
auto messenger = [TINMessenger messenger];
if (![messenger canSendMessageToTargetScheme:targetScheme]) {
  // Messages can't be sent due to any of the following reasons:
  // 1. Source application isn't registered to perform such query for a targetScheme,
  //    check application's Info.plist
  // 2. There's no app installed on the device that is registered to handle the targetScheme.
  //
  return;
}

TINMessage message = // Create a message to be sent.

[messenger sendMessage:message block:^(BOOL success, NSError *error) {
  if (!success) {
    // handle the error
    return;
  }
  // handle message's successful completion
}];
```

### Receiving a message

Code example for receiving a message in `-[UIApplicationDelegate application:openURL:options:]` method:

```objc
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary*)options {
  auto messenger = [TINMessenger messenger];
  if ([messenger isTinCanURL:url) {
    NSError *error;
    auto _Nullable message = [messenger messageFromURL:url error:&error];
    if (!message) {
      // handle the error
    } else {
      // handle the message
    }
  }
}
```

### Deleting messages

TinCan never deletes any messages automatically, **it is up to the application to delete obsolete messages**. `-[TINMessenger removeAllMessagesForScheme:error:]` removes all the messages targeted to the provided scheme. The provided scheme must be one of the application's suppored schemes defined in applications ~Info.plist~, otherwise an error is be reported. It's **advised to remove the incoming message** right after compleating its processing.

Example:

```objc
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary*)options {
  //...
  auto messenger = [TINMessenger messenger];
  LTAssert([messenger isTinCanURL:url]);
  auto message = nn([messenger messageFromURL:url error:nil]);
  // store aside incoming message's content
  [messenger removeAllMessagesForScheme:message.targetScheme error:nil];
  // ...
}
```
