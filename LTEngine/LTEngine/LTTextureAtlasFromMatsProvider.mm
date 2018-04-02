// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureAtlasFromMatsProvider.h"

#import "LTTexture+Factory.h"
#import "LTTextureAtlas.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureAtlasFromMatsProvider ()

/// Non empty of map of unpacked images stored as \c cv::Mat objects with identifiyng string keys.
@property (readonly, nonatomic) lt::unordered_map<NSString *, cv::Mat> matrices;

/// Packing rects provider that produces the \c atlas.areas rects out of the \c matrices sizes.
@property (readonly, nonatomic) id<LTPackingRectsProvider> packingRectsProvider;

/// Pixel format of the produced atlas texture.
@property (readonly, nonatomic) LTGLPixelFormat *atlasTexturePixelFormat;

@end

@implementation LTTextureAtlasFromMatsProvider

- (instancetype)initWithMatrices:(const lt::unordered_map<NSString *, cv::Mat> &)matrices
            packingRectsProvider:(id<LTPackingRectsProvider>)packingRectsProvider {
  LTParameterAssert(matrices.size(), @"Matrices vector cannot be empty");
  LTParameterAssert(packingRectsProvider);

  [LTTextureAtlasFromMatsProvider validateMatricesHavePositiveSize:matrices];
  [LTTextureAtlasFromMatsProvider validateMatricesHaveTheSameType:matrices];

  if (self = [super init]) {
    _matrices = matrices;
    _packingRectsProvider = packingRectsProvider;
    [self createAtlasTexturePixelFormat];
  }

  return self;
}

+ (void)validateMatricesHavePositiveSize:(const lt::unordered_map<NSString *, cv::Mat> &)matrices {
  for (const auto &keyValue : matrices) {
    NSString *key = keyValue.first;
    cv::Mat mat = keyValue.second;

    LTParameterAssert(mat.cols > 0 && mat.rows > 0, @"Matrix widths and heights must be positive "
                      "but matrix size at key %@ is (%d, %d)", key, mat.cols, mat.rows);
  }
}

+ (void)validateMatricesHaveTheSameType:(const lt::unordered_map<NSString *, cv::Mat> &)matrices {
  NSString *matReferenceKey = matrices.begin()->first;
  int matsReferenceType = matrices.begin()->second.type();

  for (const auto &keyValue : matrices) {
    NSString *key = keyValue.first;
    cv::Mat mat = keyValue.second;

    LTParameterAssert(mat.type() == matsReferenceType, @"All matrices must have the same "
                      "type but matrix type at key %@ is %d and matrix type at key %@ is %d",
                      matReferenceKey, matsReferenceType, key, mat.type());
  }
}

- (void)createAtlasTexturePixelFormat {
  int matsType = self.matrices.begin()->second.type();
  _atlasTexturePixelFormat = [[LTGLPixelFormat alloc] initWithMatType:matsType];
}

- (LTTextureAtlas *)atlas {
  lt::unordered_map<NSString *, CGRect> packingRects =
      [self.packingRectsProvider packingOfSizes:[self imageSizes]];

  LTTexture *atlasTexture = [LTTexture textureWithSize:[self boundingSizeOfRects:packingRects]
                                           pixelFormat:self.atlasTexturePixelFormat
                                        allocateMemory:YES];
  [atlasTexture clearColor:LTVector4::zeros()];
  [atlasTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    for (const auto &keyValue : self.matrices) {
      NSString *key = keyValue.first;
      cv::Mat unpackedImageMat = keyValue.second;
      CGRect targetRect = packingRects.find(key)->second;
      unpackedImageMat.copyTo((*mapped)(cv::Rect(targetRect.origin.x, targetRect.origin.y,
                                                 targetRect.size.width, targetRect.size.height)));
    }
  }];

  return [[LTTextureAtlas alloc] initWithAtlasTexture:atlasTexture imageAreas:packingRects];
}

- (lt::unordered_map<NSString *, CGSize>)imageSizes {
  lt::unordered_map<NSString *, CGSize> sizes;

  for (const auto &keyValue : _matrices) {
    NSString *key = keyValue.first;
    cv::Mat mat = keyValue.second;

    sizes[key] = CGSizeMake(mat.cols, mat.rows);
  }

  return sizes;
}

- (CGSize)boundingSizeOfRects:(const lt::unordered_map<NSString *, CGRect> &)packingRects {
  CGRect rect = CGRectZero;
  for (const auto &keyValue : packingRects) {
    rect = CGRectUnion(rect, keyValue.second);
  }
  return rect.size;
}

@end

NS_ASSUME_NONNULL_END
