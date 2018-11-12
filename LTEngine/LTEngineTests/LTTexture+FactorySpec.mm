// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

#import <Metal/Metal.h>

#import "CVPixelBuffer+LTEngine.h"

SpecBegin(LTTexture_Factory)

/// Since the class is currently decided in compile time, only verify that the class methods are
/// correctly called and that the returned object is indeed a texture class.

it(@"should initialize with size pixel format max mipmap level and allocate memory", ^{
  LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                      pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                   maxMipmapLevel:0
                                   allocateMemory:YES];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with size pixel format and allocate memory", ^{
  LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                      pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                   allocateMemory:YES];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with image", ^{
  cv::Mat4b image(1, 1);

  LTTexture *texture = [LTTexture textureWithImage:image];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with UIImage", ^{
  UIGraphicsBeginImageContext(CGSizeMake(4, 4));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  LTTexture *texture = [LTTexture textureWithUIImage:image];
  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with UIImage and background", ^{
  UIGraphicsBeginImageContext(CGSizeMake(4, 4));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  LTTexture *texture = [LTTexture textureWithUIImage:image backgroundColor:[UIColor whiteColor]];
  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize as rgba texture", ^{
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize as half-float rgba texture", ^{
  LTTexture *texture = [LTTexture halfFloatRGBATextureWithSize:CGSizeMake(1, 1)];

  expect(texture).to.beKindOf([LTTexture class]);
  expect(texture.size).to.equal(CGSizeMake(1, 1));
  expect(texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA16Float));
});

it(@"should initialize as single channel half-float texture", ^{
  LTTexture *texture = [LTTexture halfFloatRedTextureWithSize:CGSizeMake(1, 1)];

  expect(texture).to.beKindOf([LTTexture class]);
  expect(texture.size).to.equal(CGSizeMake(1, 1));
  expect(texture.pixelFormat).to.equal($(LTGLPixelFormatR16Float));
});

it(@"should initialize with properties of another texture", ^{
  LTTexture *another = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
  LTTexture *texture = [LTTexture textureWithPropertiesOf:another];

  expect(texture).to.beKindOf([LTTexture class]);
  expect(texture.maxMipmapLevel).to.equal(another.maxMipmapLevel);
  expect(texture.pixelFormat).to.equal(another.pixelFormat);
});

it(@"should initialize with properties of another texture and size", ^{
  CGSize size = CGSizeMake(1, 1);
  LTTexture *another = [LTTexture halfFloatRGBATextureWithSize:CGSizeMake(2, 2)];
  LTTexture *texture = [LTTexture textureWithSize:size andPropertiesOfTexture:another];

  expect(texture).to.beKindOf([LTTexture class]);
  expect(texture.size).to.equal(size);
  expect(texture.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
  expect(texture.pixelFormat).to.equal(another.pixelFormat);
});

it(@"should initialize mipmap with base image", ^{
  LTTexture *texture = [LTTexture textureWithBaseLevelMipmapImage:cv::Mat4b(1, 1)];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize mipmap with multiple images", ^{
  Matrices images{cv::Mat4b(8, 8), cv::Mat4b(4, 4), cv::Mat4b(2, 2), cv::Mat4b(1, 1)};
  LTTexture *texture = [LTTexture textureWithMipmapImages:images];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with pixel buffer", ^{
  auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
  LTTexture *texture = [LTTexture textureWithPixelBuffer:pixelBuffer.get()];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with planar pixel buffer", ^{
  auto pixelBuffer = LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
  LTTexture *plane0 = [LTTexture textureWithPixelBuffer:pixelBuffer.get() planeIndex:0];
  LTTexture *plane1 = [LTTexture textureWithPixelBuffer:pixelBuffer.get() planeIndex:1];

  expect(plane0).to.beKindOf([LTTexture class]);
  expect(plane1).to.beKindOf([LTTexture class]);
});

dcontext(@"metal", ^{
  __block id<MTLDevice> device;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
  });

  it(@"should initialize with metal texture", ^{
    auto descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                         width:39 height:47
                                                                     mipmapped:NO];
    auto mtlTexture = [device newTextureWithDescriptor:descriptor];
    auto ltTexture = [LTTexture textureWithMTLTexture:mtlTexture];
    expect(ltTexture).to.beKindOf(LTTexture.class);
  });

  it(@"should initialize with metal mipmaped texture", ^{
    auto descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                         width:39 height:47
                                                                     mipmapped:YES];
    descriptor.mipmapLevelCount = 5;
    auto mtlTexture = [device newTextureWithDescriptor:descriptor];
    auto commandBuffer = [[device newCommandQueue] commandBuffer];
    auto blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder generateMipmapsForTexture:mtlTexture];
    [blitEncoder endEncoding];
    [commandBuffer commit];

    auto ltTexture = [LTTexture textureWithMTLTexture:mtlTexture];
    expect(ltTexture).to.beKindOf(LTTexture.class);
  });
});

SpecEnd
