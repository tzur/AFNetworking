// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Adds UTI related methods. All calls to the MobileCoreServices library are cached.
@interface NSString (UTI)

/// Returns \c YES if the receiver is a UTI conforming to "public.camera-raw-image", \c NO
/// otherwise.
- (BOOL)ptn_isRawImageUTI;

/// Returns \c YES if the receiver is a UTI conforming to "com.compuserve.gif", \c NO otherwise.
- (BOOL)ptn_isGIFUTI;

@end

NS_ASSUME_NONNULL_END
