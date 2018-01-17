// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c TINMessage by defining the supported keys for \c TINMessage's \c userInfo
/// dictionary and their values.
@interface TINMessage (UserInfo)

/// Key for message's attached file names, each is resolved as a relative path to the message's
/// directory. Key's value is \c NSArray<NSString *> *.
extern NSString * const kTINMessageFileNamesKey;

/// Key for message's attached user defined context.
extern NSString * const kTINMessageContextKey;

/// Message's attached file names, each is resolved as a relative path to the message's directory,
/// or \c nil if no files name array is provided. It's equivalent to the following code:
///
/// @code
/// message.userInfo[kTINMessageFileNamesKey];
/// @endcode
@property (readonly, nonatomic, nullable) NSArray<NSString *> *fileNames;

/// \c NSArray holding the URL representation of message's attached \c fileNames, in corresponding
/// indices. \c nil is returend in any of the following is true:
///
/// - This application doesn't have an entitlement to access the application group.
/// - \c fileNames isn't attached to this message.
/// - There is a file name in \c fileNames which is not a relative path.
/// - There is a file name in \c fileNames which is resolved outside of message's \c directoryURL.
@property (readonly, nonatomic, nullable) NSArray<NSURL *> *fileURLs;

/// User defined context. It's equivalent to the following code:
///
/// @code
/// message.userInfo[kTINMessageContextKey];
/// @endcode
@property (readonly, nonatomic, nullable) NSDictionary<NSString *, id<NSSecureCoding>> *context;

@end

NS_ASSUME_NONNULL_END
