// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNDescriptor.h"

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// Represents a File System file.
@interface PTNFileSystemFileDescriptor : NSObject <PTNAssetDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c path as the path to the file this descriptor points to.
- (instancetype)initWithPath:(LTPath *)path;

/// Initializes with \c path as the path to the file this descriptor points to, \c creationDate as
/// the date the file associated with this descriptor was originally created and \c modificationDate
/// as the date the file associated with this descriptor was last modified. If the given
/// \c creationDate or \c modificationDate are \c nil these dates are considered unavilable.
- (instancetype)initWithPath:(LTPath *)path creationDate:(nullable NSDate *)creationDate
            modificationDate:(nullable NSDate *)modificationDate NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
