// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Default TinCan's application group ID.
extern NSString * const kTINAppGroupID;

/// Contains all the required information to pass a message to another application. The message is
/// persistently stored in a shared directory, which can be accessed by applications with the same
/// application group. The message contains a \c userInfo dictionary which can be used to pass a
/// custom message attributes. Additionally multiple \c fileNames can be attached to a message. The
/// target application is designated by a \c scheme which is used to open an application using
/// \c -openURL:options:completionHandler:.
///
/// @important it's the responsibility of the message receiver to clean up the persistent storage
/// associated with the arriving message.
@interface TINMessage : LTValueObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c appGroupID, \c sourceScheme, \c targetScheme, \c identifier and
/// \c info.
+ (instancetype)messageWithAppGroupID:(NSString *)appGroupID sourceScheme:(NSString *)sourceScheme
                         targetScheme:(NSString *)targetScheme identifier:(NSUUID *)identifier
                             userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info;

/// Application's group ID this message belongs to.
@property (readonly, nonatomic) NSString *appGroupID;

/// Scheme of the an application who sent this message. It may be used by the message receiver when
/// replying to this message.
@property (readonly, nonatomic) NSString *sourceScheme;

/// Scheme of the application this message is targeted to. It's used to open the target application.
@property (readonly, nonatomic) NSString *targetScheme;

/// Message's unique identifier.
@property (readonly, nonatomic) NSUUID *identifier;

/// User's info dictionary, used to store custom attributes.
@property (readonly, nonatomic) NSDictionary<NSString *, id<NSSecureCoding>> *userInfo;

@end

/// Name of the TINMessage file, which is resolved relatively to message's \c directoryURL.
extern NSString * const kTINMessageFileName;

/// Category adding URL functionality to \c TINMessage.
@interface TINMessage (NSURL)

/// URL of message's designated directory. Returns \c nil if this application doesn't have an
/// entitlement to access the application group of the message.
@property (readonly, nonatomic, nullable) NSURL *directoryURL;

/// URL of a message file. Returns \c nil if this application doesn't have a valid application group
/// set in the application's capabilities.
@property (readonly, nonatomic, nullable) NSURL *url;

@end

NS_ASSUME_NONNULL_END
