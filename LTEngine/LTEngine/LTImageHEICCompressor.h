// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageCompressor.h"

NS_ASSUME_NONNULL_BEGIN

/// Apply HEVC compression on images. User can define the compression \c quality.
///
/// @note the minimal configuration for image encoding is A10 chip (i.e. iPhone 7 and successors).
/// This compressor won't work on the simulator. When compression is perfromed on an unsuppored
/// device \c LTErrorCodeObjectCreationFailed error will be reported.
NS_CLASS_AVAILABLE_IOS(11_0) @interface LTImageHEICCompressor : NSObject <LTImageCompressor>

/// Initializes with default quality of 1.
- (instancetype)init;

/// Initializes with the given \c quality in the range of \c [0, 1], where \c 1 means maximal
/// storage and best quality and value of \c 0 means minimal storage but lowest quality.
- (instancetype)initWithQuality:(CGFloat)quality NS_DESIGNATED_INITIALIZER;

/// Compression quality in the range [0, 1]. Default value is \c 1 which means maximal storage and
/// best quality and value of \c 0 means minimal storage but lowest quality. Values are clamped to
/// [0, 1] range upon \c quality set.
@property (nonatomic) CGFloat quality;

@end

NS_ASSUME_NONNULL_END
