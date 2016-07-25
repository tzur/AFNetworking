// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <CoreMedia/CMSampleBuffer.h>

@class CAMPixelFormat, LTTexture;

NS_ASSUME_NONNULL_BEGIN

/// Container protocol that holds one or more \c LTTextures, representing a single image. This is
/// needed, for example, for 4:2:0 YCbCr images, in which the chroma texture is subsampled and
/// can't be held in the same \c LTTexture object.
@protocol CAMVideoFrame <NSObject>

/// Pixel format of the image represented by \c textures.
@property (readonly, nonatomic) CAMPixelFormat *pixelFormat;

/// Textures held by the receiver. The number and properties of these textures is determined by \c
/// pixelFormat.
@property (readonly, nonatomic) NSArray<LTTexture *> *textures;

/// Timing info for the video frame.
@property (readonly, nonatomic) CMSampleTimingInfo sampleTimingInfo;

@end

/// \c CAMVideoFrame implementation that hold a Y'CbCr texture pair.
@interface CAMVideoFrameYCbCr : NSObject <CAMVideoFrame>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a Y'CbCr 4:2:0 texture pair and frame timing info. \c pixelFormat will be set
/// to \c CAMPixelFormat420f. Raises \c NSInvalidArgumentException if the textures' types are not
/// \c LTGLPixelFormatR8Unorm and \c LTGLPixelFormatRG8Unorm respectively.
- (instancetype)initWithYTexture:(LTTexture *)yTexture cbcrTexture:(LTTexture *)cbcrTexture
                sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo NS_DESIGNATED_INITIALIZER;

/// Luma (Y') texture.
@property (readonly, nonatomic) LTTexture *yTexture;

/// Chroma (CbCr) texture.
@property (readonly, nonatomic) LTTexture *cbcrTexture;

@end

/// \c CAMVideoFrame implementation that hold a BGRA texture.
@interface CAMVideoFrameBGRA : NSObject <CAMVideoFrame>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a single BGRA texture and frame timing info. \c pixelFormat will be set to \c
/// CAMPixelFormatBGRA. Raises \c NSInvalidArgumentException if the texture's type is not \c
/// LTGLPixelFormatRGBA8Unorm.
- (instancetype)initWithBGRATexture:(LTTexture *)bgraTexture
                   sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo NS_DESIGNATED_INITIALIZER;

/// BGRA texture.
@property (readonly, nonatomic) LTTexture *bgraTexture;

@end

NS_ASSUME_NONNULL_END
