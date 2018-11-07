// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTQuad, LTTexture;

/// Processor for executing a patch operation. The operation copies a desired area from the \c
/// source texture, identified by the \c mask texture, to an area in the \c target texture while
/// seamlessly cloning the copied data.
///
/// Since the processing is a heavy operation, it is recommended to set a small working size when a
/// real-time feedback is required, and enlarge the size to produce a high-quality result.
@interface LTPatchProcessor : LTImageProcessor

/// Initializes a new patch processor.
///
/// @param workingSizes vector of \c CGSize structs, which describe the set of possible working
/// sizes. The working size defines the patch calculations is done at. Making this size smaller will
/// give a boost in performance, but will yield a less accurate result. For each working size, both
/// given dimensions must be a power of two. The first given working size will be the default one.
/// @param mask mask texture used to define the patch region.
/// @param source texture used to take texture from.
/// @param target target texture used as the base layer. Must have the same number of channels as
/// \c source.
/// @param output contains the processing result. Size must be equal to \c target size.
- (instancetype)initWithWorkingSizes:(std::vector<CGSize>)workingSizes mask:(LTTexture *)mask
                              source:(LTTexture *)source target:(LTTexture *)target
                              output:(LTTexture *)output;

/// Quad defining a region of interest in the source texture, which the data is copied from. Default
/// value is <tt>[LTQuad quadFromRect:CGRectFromSize(source.size)]</tt>.
@property (strong, nonatomic) LTQuad *sourceQuad;

/// Quad defining a region of interest in the target texture, where the data is copied to.
/// Note that the shape of the quad can be different than \c sourceQuad, which will cause a warping
/// of the source quad to this quad. Default value is
/// <tt>[LTQuad quadFromRect:CGRectFromSize(target.size)]</tt>.
@property (strong, nonatomic) LTQuad *targetQuad;

/// Size that the patch calculations is done at. Making this size smaller will give a boost in
/// performance, but will yield a less accurate result. Given size must be one of the sizes given in
/// the initializer. Default value is the first working size given in the initializer.
@property (nonatomic) CGSize workingSize;

/// Set of possible working sizes.
@property (readonly, nonatomic) std::vector<CGSize> workingSizes;

/// Opacity of the source texture in the range <tt>[0, 1]</tt>. Default value is \c 1.
@property (nonatomic) CGFloat sourceOpacity;
LTPropertyDeclare(CGFloat, sourceOpacity, SourceOpacity);

/// \c YES if the \c sourceQuad should be used in a mirrored way. The mirroring is performed along
/// the vertical line with <tt>x = 0.5</tt>, in texture coordinate space.
@property (nonatomic) BOOL flip;
LTPropertyDeclare(BOOL, flip, Flip);

/// Interpolation factor used to compute the strength of source smoothing. If \c 1, a fully smoothed
/// version of source is used, yielding a seamless patching effect. If \c 0, the source is used
/// directly, without any smoothing. Default value is \c 1.
@property (nonatomic) CGFloat smoothingAlpha;
LTPropertyDeclare(CGFloat, smoothingAlpha, SmoothingAlpha);

@end
