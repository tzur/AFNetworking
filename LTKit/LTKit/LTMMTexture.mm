// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTBoundaryCondition.h"
#import "LTGLKitExtensions.h"

@interface LTTexture ()

- (GLKVector4)pixelValueFromImage:(const cv::Mat &)image location:(cv::Point2i)location;
- (BOOL)inTextureRect:(CGRect)rect;

@property (nonatomic) BOOL needsSynchronizationBeforeHostAccess;
@property (readonly, nonatomic) int matType;

@end

@interface LTMMTexture ()

/// Reference to the pixel buffer that backs the texture.
@property (nonatomic) CVPixelBufferRef pixelBufferRef;

/// Reference to the texture object.
@property (nonatomic) CVOpenGLESTextureRef textureRef;

// Reference to the texture cache object.
@property (nonatomic) CVOpenGLESTextureCacheRef textureCacheRef;

@end

@implementation LTMMTexture

#pragma mark -
#pragma mark Abstract implementation
#pragma mark -

- (void)create:(BOOL __unused)allocateMemory {
  // It's impossible to avoid memory allocation since the shared memory texture buffer must be
  // allocated via CV* functions to allow updates to reflect to OpenGL.
  [self createTextureForMatType:self.matType];
}

- (void)createTextureForMatType:(int)type {
  [self createPixelBufferForMatType:type];
  [self allocateTexture];
}

- (void)createPixelBufferForMatType:(int)type {
  OSType pixelFormat = [self pixelFormatForMatType:type];
  NSDictionary *attributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}};

  CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault, self.size.width, self.size.height,
                                        pixelFormat, (__bridge CFDictionaryRef)attributes,
                                        &_pixelBufferRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating pixel buffer with error %d", result];
  }
}

- (void)allocateTexture {
  // TODO: (yaron) test performance on device for GL_BGRA and GL_RGBA.
  CVReturn result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                 self.textureCacheRef,
                                                                 self.pixelBufferRef,
                                                                 NULL,
                                                                 GL_TEXTURE_2D,
                                                                 GL_RGBA,
                                                                 self.size.width, self.size.height,
                                                                 GL_RGBA,
                                                                 self.precision,
                                                                 0,
                                                                 &_textureRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating texture with error %d", result];
  }
}

- (OSType)pixelFormatForMatType:(int)type {
  switch (LTTextureChannelsFromMatType(type)) {
    case LTTextureChannelsRGBA:
      switch (LTTexturePrecisionFromMatType(type)) {
        case LTTexturePrecisionByte:
          return kCVPixelFormatType_32BGRA;
        case LTTexturePrecisionHalfFloat:
          return kCVPixelFormatType_64RGBAHalf;
        case LTTexturePrecisionFloat:
          return kCVPixelFormatType_128RGBAFloat;
      }
  }
}

- (CVOpenGLESTextureCacheRef)textureCacheRef {
  if (!_textureCacheRef) {
    EAGLContext *context = [EAGLContext currentContext];
    LTAssert(context, @"Must have an active OpenGL ES context");

    CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL,
                                                   &_textureCacheRef);
    if (result != kCVReturnSuccess) {
      [LTGLException raise:kLTTextureCreationFailedException
                    format:@"Failed creating texture cache with error %d", result];
    }
  }
  return _textureCacheRef;
}

- (void)destroy {
  if (self.pixelBufferRef) {
    CVPixelBufferRelease(self.pixelBufferRef);
    self.pixelBufferRef = NULL;
  }
  if (self.textureRef) {
    CFRelease(self.textureRef);
    self.textureRef = NULL;
  }
  if (self.textureCacheRef) {
    CVOpenGLESTextureCacheFlush(self.textureCacheRef, 0);
    CFRelease(self.textureCacheRef);
    self.textureCacheRef = NULL;
  }
}

- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image {
  // Preconditions.
  LTParameterAssert([self inTextureRect:rect],
                    @"Rect for retrieving matrix from texture is out of bounds: (%g, %g, %g, %g)",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  [self updateTexture:^(cv::Mat texture) {
    cv::Rect roi(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    texture(roi).copyTo(*image);
  }];
}

- (void)load:(const cv::Mat &)image {
  [self loadRect:CGRectMake(0, 0, image.cols, image.rows) fromImage:image];
}

- (void)loadRect:(CGRect)rect fromImage:(const cv::Mat &)image {
  // Preconditions.
  LTParameterAssert([self inTextureRect:rect],
                    @"Rect for retrieving image from texture is out of bounds: (%g, %g, %g, %g)",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
  LTParameterAssert(image.cols == rect.size.width && image.rows == rect.size.height,
                    @"Trying to load to rect with size (%g, %g) from a Mat with different size: "
                    "(%d, %d)", rect.size.width, rect.size.height, image.cols, image.rows);

  if (!self.textureRef) {
    [self createTextureForMatType:image.type()];
  }

  [self updateTexture:^(cv::Mat texture) {
    LTParameterAssert(image.type() == texture.type(), @"Source image's type (%d) must match "
                      "texture's type (%d)", image.type(), texture.type());
    cv::Rect roi(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    image.copyTo(texture(roi));
  }];
}

- (LTTexture *)clone {
  LTMMTexture *cloned = [[LTMMTexture alloc] initWithSize:self.size precision:self.precision
                                                 channels:self.channels allocateMemory:YES];
  [self copyContentsToTexture:cloned];

  return cloned;
}

- (void)cloneTo:(LTTexture *)texture {
  LTAssert([texture isKindOfClass:[LTMMTexture class]], @"At the moment, only cloning to "
           "LTMMTexture is supported");
  [self copyContentsToTexture:(LTMMTexture *)texture];
}

- (void)copyContentsToTexture:(LTMMTexture *)target {
  [target updateTexture:^(cv::Mat texture) {
    [self storeRect:CGRectMake(0, 0, self.size.width, self.size.height) toImage:&texture];
  }];
}

#pragma mark -
#pragma mark Overridden methods
#pragma mark -

- (GLKVector4s)pixelValues:(const CGPoints &)locations {
  __block GLKVector4s values(locations.size());

  [self updateTexture:^(cv::Mat texture) {
    for (CGPoints::size_type i = 0; i < locations.size(); ++i) {
      // Use boundary conditions similar to Matlab's 'symmetric'.
      GLKVector2 location = [LTSymmetricBoundaryCondition
                             boundaryConditionForPoint:GLKVector2Make(locations[i].x,
                                                                      locations[i].y)
                             withSignalSize:cv::Size2i(self.size.width, self.size.height)];
      cv::Point2i point = cv::Point2i(std::floor(location.x), std::floor(location.y));

      values[i] = [self pixelValueFromImage:texture location:point];
    }
  }];

  return values;
}

#pragma mark -
#pragma mark Memory mapping
#pragma mark -

- (void)updateTexture:(LTTextureUpdateBlock)block {
  if (!block) {
    return;
  }

  // TODO: (yaron) this can be synchronized on the texture only, but it's not an OpenGL object, so
  // explicit locking is required instead.
  @synchronized(self) {
    LTAssert(self.pixelBufferRef, @"Pixelbuffer must be created before calling updateTexture:");

    if (self.needsSynchronizationBeforeHostAccess) {
      glFinish();
      self.needsSynchronizationBeforeHostAccess = NO;
    }

    [self executeWhileBufferIsLocked:^{
      void *base = CVPixelBufferGetBaseAddress(self.pixelBufferRef);
      cv::Mat mat(self.size.height, self.size.width, self.matType, base,
                  CVPixelBufferGetBytesPerRow(self.pixelBufferRef));
      block(mat);
    }];
  }
}

- (void)executeWhileBufferIsLocked:(LTVoidBlock)block {
  CVReturn lockResult = CVPixelBufferLockBaseAddress(self.pixelBufferRef, 0);
  if (kCVReturnSuccess != lockResult) {
    [LTGLException raise:kLTMMTextureBufferLockingFailedException
                  format:@"Failed locking base address of buffer with error %d", lockResult];
  }

  if (block) block();

  CVReturn unlockResult = CVPixelBufferLockBaseAddress(self.pixelBufferRef, 0);
  if (kCVReturnSuccess != unlockResult) {
    [LTGLException raise:kLTMMTextureBufferLockingFailedException
                  format:@"Failed unlocking base address of buffer with error %d", unlockResult];
  }
}

#pragma mark -
#pragma mark Public properties
#pragma mark -

- (GLuint)name {
  return self.textureRef ? CVOpenGLESTextureGetName(self.textureRef) : 0;
}

@end
