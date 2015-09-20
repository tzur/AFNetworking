// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageCompression.h"

#import "LTPropertyMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// Apply JPEG compression on images. User can define the compression \c quality.
@interface LTImageJPEGCompressor : NSObject <LTImageCompression>

/// Initialize \c LTImageJPEGCompressor with \c defaultQuality.
- (instancetype)init;

/// Initialize \c LTImageJPEGCompressor with \c quality in the range of \c [0, 1], where \c 1 means
/// maximal storage and best quality and value of \c 0 means minimal storage but lowest quality.
- (instancetype)initWithQuality:(CGFloat)quality NS_DESIGNATED_INITIALIZER;

/// Quality of the source texture in the range [0, 1]. Default value is \c 1 which means maximal
/// storage and best quality and value of \c 0 means minimal storage but lowest quality.
@property (readonly, nonatomic) CGFloat quality;
LTPropertyDeclare(CGFloat, quality, Quality);

@end

NS_ASSUME_NONNULL_END
