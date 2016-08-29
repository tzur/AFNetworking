// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRModel;

/// Provides product content by fetching the content from a local path.
@interface BZRLocalContentFetcher : NSObject <BZRProductContentFetcher>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c fileManager, used to copy the content with.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
