// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTNAVImageAsset.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTRef.h>
#import <LTKit/NSFileManager+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSError+Photons.h"
#import "PTNAVImageGeneratorFactory.h"
#import "PTNImageMetadata.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNAVImageAsset ()

/// Underlying asset.
@property (readonly, nonatomic) AVAsset *asset;

/// Resizing strategy to apply on the fetched image.
@property (readonly, nonatomic) id<PTNResizingStrategy> resizingStrategy;

/// Image generator factory.
@property (readonly, nonatomic) PTNAVImageGeneratorFactory *imageGeneratorFactory;

@end

@implementation PTNAVImageAsset

- (instancetype)initWithAsset:(AVAsset *)asset
             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [self initWithAsset:asset imageGeneratorFactory:[[PTNAVImageGeneratorFactory alloc] init]
            resizingStrategy:resizingStrategy];
}

- (instancetype)initWithAsset:(AVAsset *)asset
        imageGeneratorFactory:(PTNAVImageGeneratorFactory *)imageGeneratorFactory
             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  if (self = [super init]) {
    _asset = asset;
    _imageGeneratorFactory = imageGeneratorFactory;
    _resizingStrategy = resizingStrategy;
  }
  return self;
}

- (CGSize)imageSize {
  AVAssetTrack * _Nullable videoTrack =
      [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
  CGSize inputSize = videoTrack ? videoTrack.naturalSize : CGSizeZero;
  return [self.resizingStrategy sizeForInputSize:inputSize];
}

- (RACSignal *)fetchImage {
  // The retain of the receiver promises that as long as this signal isn't disposed or completed
  // the receiver won't get deallocated.
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    AVAssetImageGenerator *imageGenerator =
        [self.imageGeneratorFactory imageGeneratorForAsset:self.asset];
    imageGenerator.maximumSize = [self imageSize];

    NSError *error;
    auto cgImage = lt::Ref<CGImageRef>{[imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:nil
                                                                   error:&error]};
    if (!cgImage) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeAVImageAssetFetchImageFailed
                                      underlyingError:error]];
    } else {
      [subscriber sendNext:[UIImage imageWithCGImage:cgImage.get()]];
      [subscriber sendCompleted];
    }
    return [RACDisposable disposableWithBlock:^{
      [imageGenerator cancelAllCGImageGeneration];
    }];
  }] subscribeOn:[RACScheduler scheduler]];
}

#pragma mark -
#pragma mark PTNImageDataAsset
#pragma mark -

- (RACSignal *)fetchData {
  return [[self fetchImage]
          tryMap:^NSData * _Nullable(UIImage *image, NSError *__autoreleasing *errorPtr) {
    // PhotoKit uses JPEG and 0.93 compression when fetching images from \c audiovisual assets.
    auto _Nullable data = UIImageJPEGRepresentation(image, 0.93);
    if (!data) {
      if (errorPtr) {
        *errorPtr = [NSError lt_errorWithCode:PTNErrorCodeAVImageAssetFetchImageDataFailed];
      }
    }
    return data;
  }];
}

- (RACSignal *)writeToFileAtPath:(LTPath *)path usingFileManager:(NSFileManager *)fileManager {
  return [[[self fetchData] flattenMap:^(NSData *data) {
    NSError *error;
    BOOL success = [fileManager  lt_writeData:data toFile:path.path options:NSDataWritingAtomic
                                        error:&error];
    if (!success) {
      return [RACSignal error:[NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                                                    url:path.url
                                        underlyingError:error]];
    }

    return [RACSignal empty];
  }] subscribeOn:RACScheduler.scheduler];
}

- (nullable NSString *)uniformTypeIdentifier {
  return (__bridge NSString *)kUTTypeJPEG;
}

- (RACSignal *)fetchImageMetadata {
  return [RACSignal return:[[PTNImageMetadata alloc] init]];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNAVImageAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  if ([self.asset isKindOfClass:AVURLAsset.class] &&
      [object.asset isKindOfClass:AVURLAsset.class]) {
    NSURL *selfURL = ((AVURLAsset *)self.asset).URL;
    NSURL *objectURL = ((AVURLAsset *)object.asset).URL;
    return [selfURL isEqual:objectURL] && [self.resizingStrategy isEqual:object.resizingStrategy];
  }

  return [self.asset isEqual:object.asset] &&
      [self.resizingStrategy isEqual:object.resizingStrategy];
}

- (NSUInteger)hash {
  return [self.asset isKindOfClass:AVURLAsset.class] ?
      ((AVURLAsset *)self.asset).URL.hash ^ self.resizingStrategy.hash :
      self.asset.hash ^ self.resizingStrategy.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, asset: %@, resizing strategy: %@>", self.class, self,
          self.asset, self.resizingStrategy];
}

@end

NS_ASSUME_NONNULL_END
