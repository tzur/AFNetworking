// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import <Metal/Metal.h>
#import <stdatomic.h>

#import "CVPixelBuffer+LTEngine.h"
#import "LTFbo.h"
#import "LTFboAttachable.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+ColorizeFsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+ValueSetterFsh.h"
#import "LTTexture+Protected.h"
#import "LTTextureBasicExamples.h"

using half_float::half;

/// Uploads the given \c image to an \c LTMMTexture, draws it to an \c LTGLTexture and fetches the
/// resulting image.
static cv::Mat LTDrawFromMMTextureToGLTexture(const cv::Mat &image) {
  LTMMTexture *source = [[LTMMTexture alloc] initWithImage:image];
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                fragmentSource:[PassthroughFsh source]];
  LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:source];

  LTGLTexture *target = [[LTGLTexture alloc] initWithPropertiesOf:source];
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

  CGRect rect = CGRectMake(0, 0, source.size.width, source.size.height);
  [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

  return [target image];
}

@interface LTMMTexture ()
@property (nonatomic) GLsync readSyncObject;
@property (nonatomic) GLsync writeSyncObject;
@end

SpecBegin(LTMMTexture)

itShouldBehaveLike(kLTTextureBasicExamples, @{
  kLTTextureBasicExamplesTextureClass: [LTMMTexture class]
});

itShouldBehaveLike(kLTTextureMetalExamples, @{
  kLTTextureMetalExamplesTextureClass: [LTMMTexture class]
});

__block LTMMTexture *texture;

beforeEach(^{
  texture = [[LTMMTexture alloc] initWithSize:CGSizeMake(2, 2)
                                  pixelFormat:$(LTGLPixelFormatRGBA8Unorm) allocateMemory:YES];
});

afterEach(^{
  texture = nil;
});

context(@"host memory mapped texture", ^{
  __block LTFbo *fbo;
  __block LTRectDrawer *drawer;

  beforeEach(^{
    fbo = [[LTFbo alloc] initWithTexture:texture];

    LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                  fragmentSource:[ColorizeFsh source]];
    drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];
    drawer[[ColorizeFsh color]] = $(LTVector4(1.0, 0.0, 0.0, 1.0));
  });

  afterEach(^{
    fbo = nil;
    drawer = nil;
  });

  it(@"should require synchronization after draw", ^{
    CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    expect(glIsSync(texture.writeSyncObject)).to.beTruthy();
  });

  it(@"should require synchronization after sampling", ^{
    LTMMTexture *target = [[LTMMTexture alloc] initWithPropertiesOf:texture];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

    CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    expect(glIsSync(texture.readSyncObject)).to.beTruthy();
  });

  it(@"should map image without creating a copy", ^{
    [texture mappedImageForReading:^(const cv::Mat &, BOOL isCopy) {
      expect(isCopy).to.beFalsy();
    }];
  });

  it(@"should not require synchronization after mapping", ^{
    [texture mappedImageForReading:^(const cv::Mat &, BOOL) {
      expect(glIsSync(texture.writeSyncObject)).to.beFalsy();
      expect(glIsSync(texture.readSyncObject)).to.beFalsy();
    }];
  });

  dit(@"should read correct data after gpu draw", ^{
    cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
    CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
      expect($(mapped)).to.equalMat($(expected));
    }];
  });

  dit(@"should map correct data to core image after cpu write", ^{
    cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
    [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec4b(255, 0, 0, 255));
    }];

    [texture mappedCIImage:^(CIImage *image) {
      cv::Mat4b mapped(texture.size.height, texture.size.width);

      CIContext *context = [CIContext contextWithOptions:@{
        kCIContextWorkingColorSpace: [NSNull null],
        kCIContextOutputColorSpace: [NSNull null]
      }];

      [context render:image toBitmap:mapped.data rowBytes:mapped.step[0] bounds:image.extent
               format:kCIFormatRGBA8 colorSpace:NULL];

      expect($(mapped)).to.equalMat($(expected));
    }];
  });

  dit(@"should map correct data to core image after gpu draw", ^{
    cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
    CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    [texture mappedCIImage:^(CIImage *image) {
      cv::Mat4b mapped(texture.size.height, texture.size.width);

      CIContext *context = [CIContext contextWithOptions:@{
        kCIContextWorkingColorSpace: [NSNull null],
        kCIContextOutputColorSpace: [NSNull null]
      }];

      [context render:image toBitmap:mapped.data rowBytes:mapped.step[0] bounds:image.extent
               format:kCIFormatRGBA8 colorSpace:NULL];

      expect($(mapped)).to.equalMat($(expected));
    }];
  });

  dit(@"should read correct data after core image draw", ^{
    cv::Mat4b expected(texture.size.height, texture.size.width, cv::Vec4b(255, 0, 0, 255));
    [texture drawWithCoreImage:^CIImage *{
      return [CIImage imageWithColor:[CIColor colorWithRed:1 green:0 blue:0]];
    }];

    [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
      expect($(mapped)).to.equalMat($(expected));
    }];
  });
});

context(@"synchronization", ^{
  it(@"should not allow sampling while writing", ^{
    __block atomic_bool inRead = false;

    [texture writeToAttachableWithBlock:^{
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [texture sampleWithGPUWithBlock:^{
          inRead = true;
        }];
      });
      expect(inRead).to.beFalsy();
    }];
    expect(inRead).will.beTruthy();
  });

  it(@"should not allow writing while reading", ^{
    __block atomic_bool inWrite = false;

    [texture sampleWithGPUWithBlock:^{
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [texture writeToAttachableWithBlock:^{
          inWrite = true;
        }];
      });
      expect(inWrite).to.beFalsy();
    }];
    expect(inWrite).will.beTruthy();
  });
});

context(@"cpu gpu memory synchronization", ^{
  dit(@"should synchronize byte rgba texture", ^{
    cv::Mat4b image = cv::Mat4b(16, 16);
    image.setTo(cv::Vec4b(128));

    cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

    expect(LTCompareMat(image, actual)).to.beTruthy();
  });

  dit(@"should synchronize byte red texture", ^{
    cv::Mat1b image(16, 16);
    image.setTo(128);

    cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

    expect(LTCompareMat(image, actual)).to.beTruthy();
  });

  dit(@"should synchronize byte rg texture", ^{
    cv::Mat2b image(16, 16);
    image.setTo(cv::Vec2b(128, 255));

    cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

    expect(LTCompareMat(image, actual)).to.beTruthy();
  });

  dit(@"should synchronize half-float rgba texture", ^{
    cv::Mat4hf image(16, 16);
    image.setTo(cv::Vec4hf(half(1), half(2), half(3), half(4)));

    cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

    expect(LTCompareMat(image, actual)).to.beTruthy();
  });

  dit(@"should synchronize half-float red texture", ^{
    cv::Mat1hf image(16, 16);
    std::transform(image.begin(), image.end(), image.begin(), [](half) {
      return half(1);
    });

    cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

    expect(LTCompareMat(image, actual)).to.beTruthy();
  });

  dit(@"should synchronize half-float rg texture", ^{
    cv::Mat2hf image(16, 16);
    image.setTo(cv::Vec2hf(half(1), half(2)));

    cv::Mat actual = LTDrawFromMMTextureToGLTexture(image);

    expect(LTCompareMat(image, actual)).to.beTruthy();
  });

  dit(@"should have fresh values on CPU after GPU rendering", ^{
    CGSize size = CGSizeMake(16, 16);
    LTMMTexture *source = [[LTMMTexture alloc] initWithSize:size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];
    LTMMTexture *target = [[LTMMTexture alloc] initWithSize:size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];
    LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                  fragmentSource:[ValueSetterFsh source]];
    LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:source];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    float values[] = {0, 0.25, 0.5, 0.75, 1.0};

    for (int i = 0; i < 5; ++i) {
      drawer[[ValueSetterFsh value]] = @(values[i]);
      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

      float value = values[i];
      [target mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
        cv::Mat4b expected = cv::Mat4b(size.height, size.width);
        expected.setTo(cv::Vec4b(value * 255, value * 255, value * 255, value * 255));

        expect(LTFuzzyCompareMat(expected, mapped)).to.beTruthy();
      }];
    }
  });

  dit(@"should wait until gpu finished reading when mapping for writing", ^{
    CGSize size = CGSizeMake(16, 16);
    LTMMTexture *source = [[LTMMTexture alloc] initWithSize:size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];
    LTMMTexture *target = [[LTMMTexture alloc] initWithSize:size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];

    LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                  fragmentSource:[PassthroughFsh source]];
    LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:source];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];
    CGRect rect = CGRectMake(0, 0, size.width, size.height);

    for (int i = 0; i < 5; ++i) {
      [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4b(255, 0, 0, 255));
      }];

      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

      [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4b(0, 255, 0, 255));
      }];

      cv::Mat4b expected(target.size.height, target.size.width, cv::Vec4b(255, 0, 0, 255));
      expect($(target.image)).to.equalMat($(expected));
    }
  });

  dit(@"should have fresh values on GPU after CPU rendering", ^{
    CGSize size = CGSizeMake(16, 16);
    LTMMTexture *source = [[LTMMTexture alloc] initWithSize:size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];
    LTGLTexture *target = [[LTGLTexture alloc] initWithSize:size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];

    float values[] = {0, 0.25, 0.5, 0.75, 1.0};

    for (int i = 0; i < 5; ++i) {
      __block float value = values[i];
      [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4b(value, value, value, value));
      }];

      [source cloneTo:target];

      cv::Scalar scalar(value, value, value, value);
      expect(LTFuzzyCompareMatWithValue(scalar, [target image])).to.beTruthy();
    }
  });
});

context(@"pixel buffer", ^{
  it(@"should create texture from pixel buffer", ^{
    auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
    LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];
    expect(texture).toNot.beNil();
    expect(texture.size).to.equal(CGSizeMake(1, 1));
  });

  it(@"should create texture from planes of planar pixel buffer", ^{
    auto pixelBuffer =
        LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

    LTMMTexture *plane0 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                         planeIndex:0];
    LTMMTexture *plane1 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                         planeIndex:1];
    expect(plane0).toNot.beNil();
    expect(plane0.size).to.equal(CGSizeMake(2, 2));

    expect(plane1).toNot.beNil();
    expect(plane1.size).to.equal(CGSizeMake(1, 1));
  });

  it(@"should raise when creating texture with invalid plane index", ^{
    __block auto pixelBuffer =
        LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

    expect(^{
      LTMMTexture __unused *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                            planeIndex:10];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when creating texture with plane index and non planar pixel buffer", ^{
    __block auto pixelBuffer = LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_32BGRA);

    expect(^{
      LTMMTexture __unused *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                                    planeIndex:0];
    }).to.raise(NSInvalidArgumentException);
  });

  dit(@"should raise when initializing with non IOSurface backed pixel buffer", ^{
    CVPixelBufferRef pixelBufferRef;
    CVReturn result = CVPixelBufferCreate(NULL, 2, 2, kCVPixelFormatType_32BGRA, NULL,
                                          &pixelBufferRef);
    expect(result).to.equal(kCVReturnSuccess);

    expect(^{
      __unused auto texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBufferRef];
    }).to.raise(kLTTextureCreationFailedException);
  });

  dit(@"should raise when initializing with non IOSurface backed planar pixel buffer", ^{
    CVPixelBufferRef pixelBufferRef;
    CVReturn result = CVPixelBufferCreate(NULL, 2, 2,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, NULL,
                                          &pixelBufferRef);
    expect(result).to.equal(kCVReturnSuccess);

    expect(^{
      __unused auto texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBufferRef
                                                            planeIndex:0];
    }).to.raise(kLTTextureCreationFailedException);
  });

  it(@"should preserve pixel buffer content", ^{
    static const cv::Vec4b kPixelValue{0, 20, 30, 40};

    auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
      image->at<cv::Vec4b>(0, 0) = kPixelValue;
    });

    LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];
    LTVector4 expected = LTVector4(kPixelValue);
    LTVector4 actual = [texture pixelValue:CGPointMake(0, 0)];
    expect(actual).to.equal(expected);
  });

  dit(@"should make pixel buffer content visible to gpu", ^{
    static const cv::Vec4b kPixelValue{0, 20, 30, 40};

    auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
      image->at<cv::Vec4b>(0, 0) = kPixelValue;
    });

    // Cloning is done via GPU, thus clonned texture shows only data visible to GPU.
    LTTexture *cloned = [[[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()] clone];

    LTVector4 expected = LTVector4(kPixelValue);
    LTVector4 actual = [cloned pixelValue:CGPointMake(0, 0)];
    expect(actual).to.equal(expected);
  });

  it(@"should return pixel buffer that backs the texture", ^{
    auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
    LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];
    auto returnedPixelBuffer = [texture pixelBuffer];

    CVPixelBufferRef expected = pixelBuffer.get();
    CVPixelBufferRef actual = returnedPixelBuffer.get();
    expect(expected).to.equal(actual);
  });

  it(@"should return planar pixel buffer that backs the texture", ^{
    auto pixelBuffer =
        LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);

    LTMMTexture *plane0 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                        planeIndex:0];
    LTMMTexture *plane1 = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()
                                                        planeIndex:1];

    __block auto pixelBufferPlane0 = [plane0 pixelBuffer];
    __block auto pixelBufferPlane1 = [plane1 pixelBuffer];

    expect(pixelBufferPlane0.get()).to.equal(pixelBuffer.get());
    expect(pixelBufferPlane1.get()).to.equal(pixelBuffer.get());
  });

  it(@"should wait for pending GPU writes before returning pixel bufer", ^{
    auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
    LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];

    [texture clearColor:LTVector4(0.5, 0.5, 0.5, 1)];
    expect(glIsSync(texture.writeSyncObject)).to.beTruthy();

    auto returnedPixelBuffer = [texture pixelBuffer];
    expect(glIsSync(texture.writeSyncObject)).to.beFalsy();
  });

  it(@"should wait for pending GPU reads before returning pixel bufer", ^{
    auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
    LTMMTexture *texture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer.get()];

    LTMMTexture *target = [[LTMMTexture alloc] initWithPropertiesOf:texture];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:target];

    LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                  fragmentSource:[PassthroughFsh source]];
    LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];
    CGRect rect = CGRectMake(0, 0, texture.size.width, texture.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    expect(glIsSync(texture.readSyncObject)).to.beTruthy();

    auto returnedPixelBuffer = [texture pixelBuffer];
    expect(glIsSync(texture.readSyncObject)).to.beFalsy();
  });
});

dcontext(@"metal", ^{
  __block id<MTLDevice> device;

  beforeEach(^{
    device = MTLCreateSystemDefaultDevice();
  });

  if (@available(iOS 11.0, *)) {
    it(@"should raise when initialize with buffer backed metal texture", ^{
      auto format = MTLPixelFormatR8Unorm;
      NSUInteger length = [device minimumLinearTextureAlignmentForPixelFormat:format];
      id<MTLBuffer> buffer = [device newBufferWithLength:length
                                                 options:MTLResourceStorageModeShared];
      auto textureDescriptor = [MTLTextureDescriptor
                                texture2DDescriptorWithPixelFormat:format width:length height:1
                                mipmapped:NO];
      auto mtlTexture = [buffer newTextureWithDescriptor:textureDescriptor offset:0
                                             bytesPerRow:length];
      expect(^{
        __unused auto ltTexture = [[LTMMTexture alloc] initWithMTLTexture:mtlTexture];
      }).to.raise(NSInternalInconsistencyException);
    });

#if COREVIDEO_SUPPORTS_IOSURFACE
    it(@"should initialize with parent backed metal texture", ^{
      IOSurface *iosurface = [[IOSurface alloc] initWithProperties:@{
        IOSurfacePropertyKeyWidth: @16,
        IOSurfacePropertyKeyHeight: @1,
        IOSurfacePropertyKeyPixelFormat: @(kCVPixelFormatType_OneComponent8),
      }];
      auto descriptor = [MTLTextureDescriptor
                         texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Snorm width:16 height:1
                         mipmapped:NO];
      auto mtlTexture = [device newTextureWithDescriptor:descriptor
                                               iosurface:(__bridge IOSurfaceRef)iosurface plane:0];
      auto mtlTexture2 = [mtlTexture newTextureViewWithPixelFormat:MTLPixelFormatR8Unorm];
      auto ltTexture = [[LTMMTexture alloc] initWithMTLTexture:mtlTexture2];
      expect(ltTexture.size).to.equal(CGSizeMake(16, 1));
    });
#endif
  }
});

SpecEnd
