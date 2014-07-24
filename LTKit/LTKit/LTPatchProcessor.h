// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTRotatedRect, LTTexture;

/// Processor for executing a patch operation. The operation copies a desired area from the \c
/// source texture, identified by the \c mask texture, to an area in the \c target texture while
/// seamlessly cloning the copied data.
///
/// Since the processing is a heavy operation, it is recommended to set a small working size when a
/// real-time feedback is required, and enlarge the size to produce a high-quality result.
@interface LTPatchProcessor : LTImageProcessor

/// Initializes with mask, source texture, target texture and an output texture. The target texture
/// and the output texture must have the same size.
- (instancetype)initWithMask:(LTTexture *)mask source:(LTTexture *)source
                      target:(LTTexture *)target output:(LTTexture *)output;

/// Rotated rect defining a region of interest in the source texture, which the data is copied from.
/// The default value is an axis aligned rect of (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *sourceRect;

/// Rotated rect defining a region of interest in the target texture, where the data is copied to.
/// Note that the size and orientation of the rect can be different than \c sourceRect, which will
/// cause a warping of the source rect to this rect. The default value is an axis aligned rect of
/// (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *targetRect;

/// Size that the patch calculations is done at. Making this size smaller will give a boost in
/// performance, but will yield a less accurate result. Both given dimensions must be a power of
/// two. The default value is (64, 64).
@property (nonatomic) CGSize workingSize;

/// Opacity of the source texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat sourceOpacity;
LTPropertyDeclare(CGFloat, sourceOpacity, SourceOpacity);

@end
