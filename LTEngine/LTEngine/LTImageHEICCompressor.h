// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageCompressor.h"

NS_ASSUME_NONNULL_BEGIN

/// Applies HEVC compression on images. User can define the compression \c quality.
///
/// @note the minimal configuration for image encoding is A10 chip (i.e. iPhone 7 and successors).
/// This compressor won't work on the simulator. When compression is perfromed on an unsuppored
/// device \c LTErrorCodeObjectCreationFailed error will be reported.
NS_CLASS_AVAILABLE_IOS(11_0) @interface LTImageHEICCompressor : NSObject <LTImageCompressor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c quality in the range of \c [0, 1], where \c 1 means maximal
/// storage and best quality and value of \c 0 means minimal storage but lowest quality.
- (instancetype)initWithQuality:(CGFloat)quality NS_DESIGNATED_INITIALIZER;

/// Compression quality in the range <tt>[0, 1]</tt>, where \c 1 yields largest output size and best
/// quality and \c 0 yields minimal output size but lowest quality.
@property (readonly, nonatomic) CGFloat quality;

@end

NS_ASSUME_NONNULL_END
