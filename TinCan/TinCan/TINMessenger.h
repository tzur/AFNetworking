// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

@class TINMessage;

/// Contains the functionality for delivering messages between applications. \c TINMessage is
/// delivered from source to a target application. A \c TINMessage is being sent to a target
/// application by the means of <tt>-[UIApplication openURL:options:completionHandler:]</tt>. Where
/// the format of the URL which is passed to a target application is as follows:
/// <tt><target application scheme>://message?app_group_id=<appGroupID>&message_id=<messageID></tt>
///
/// Where:
/// - \c appGroupID is the application group ID this message belongs to.
/// - \c messageID is the message identifier.
///
/// Code example for sending a message:
///
/// @code
/// auto message = // create a TINMessage
/// auto messenger = [TINMessenger messenger];
/// if (![messenger canSendMessage:message]) {
///   // message can't be sent due to any of the following reasons:
///   // 1. Source application isn't registered to perform such query for a target scheme,
///   //    check application's Info.plist
///   // 2. There's no app installed on the device that is registered to handle the target scheme.
///   //
///   return;
/// }
/// [messenger sendMessage:message block:^(BOOL success, NSError *error) {
///   if (!success) {
///     // handle the error
///     return;
///   }
///   // handle message's successful completion
/// }];
/// @endcode
///
/// Code example for receiving a message in
/// <tt>-[UIApplicationDelegate application:openURL:options:]</tt> method:
///
/// @code
/// - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
///             options:(NSDictionary*)options {
///   auto messenger = [TINMessenger messenger];
///   if ([messenger isTinCanURL:url) {
///     NSError *error;
///     auto _Nullable message = [messenger messageFromURL:url error:&error];
///     if (!message) {
///       // handle the error
///     } else {
///       // handle the message
///     }
///   }
/// }
/// @endcode
@interface TINMessenger : NSObject

/// Initializes with the given \c application, which is used to open the target application during
/// message delivery process, and the \c fileManager, which is used to store and retrieve messages
/// from the file system.
+ (instancetype)messengerWithApplication:(UIApplication *)application
                             fileManager:(NSFileManager *)fileManager
    NS_EXTENSION_UNAVAILABLE_IOS("");

/// Initializes with shared \c UIApplication application and the default \c NSFileManager.
/// Equivalent to calling:
///
/// @code
/// [TINMessenger messengerWithApplication:[UIApplication sharedApplication]
///                            fileManager:[NSFileManager defaultManager]];
/// @endcode
+ (instancetype)messenger NS_EXTENSION_UNAVAILABLE_IOS("");

/// Sends the given \c message, by opening the application this message is targeted to, and executes
/// the given \c block on an arbitrary thread to report the message sending status. The message is
/// stored in its designated directory before it's sent. Error is reported when the \c message can't
/// be stored or the target application can't handle this \c message.
- (void)sendMessage:(TINMessage *)message completion:(LTSuccessOrErrorBlock)block
    NS_EXTENSION_UNAVAILABLE_IOS("");

/// Returns \c YES if the given \c message can be sent to the target application.
///
/// @note all message's target schemes should be registerd in application's \c Info.plist, otherwise
/// \c NO will always be returned.
- (BOOL)canSendMessage:(TINMessage *)message;

/// Returns a \c TINMessage from the given \c url. Returns \c nil if an error occurred and sets the
/// \c error.
///
/// @note \c url is the URL which is used to open the target application:
- (nullable TINMessage *)messageFromURL:(NSURL *)url error:(NSError **)error;

/// Returns \c YES if the given \c url represents a valid \c TINMessenger's url, which can be
/// handled by \c -messageFromURL:error: method.
///
/// @note \c url is the URL which is used to open the target application:
///
/// @see \c TINMessenger's class documentation for the URL format definition.
+ (BOOL)isTinCanURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
