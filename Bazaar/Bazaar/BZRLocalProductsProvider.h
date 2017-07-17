// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsProvider.h"

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// Provides a list of JSON-serialized \c BZRProducts from a local source.
@interface BZRLocalProductsProvider : NSObject <BZRProductsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the \c path to the product list JSON file. The provider will use the default
/// \c fileManager as provided by \c -[NSFileManager defaultManager], and \c decryptionKey set to
/// \c nil.
- (instancetype)initWithPath:(LTPath *)path;

/// Initializes with the \c path to the product list JSON file. \c decryptionKey that is the
/// key used to decrypt the products JSON file. And with \c fileManager, used to read the content
/// of the file into a JSON list. If \c decryptionKey is set to \c nil, the file is read without
/// decryption.
///
/// @note \c decryptionKey must be an hexdecimal represented string with size of 32, otherwise an
/// \c NSInvalidArgumentException is raised.
- (instancetype)initWithPath:(LTPath *)path  decryptionKey:(nullable NSString *)decryptionKey
                 fileManager:(NSFileManager *)fileManager NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
