// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNResizingStrategy.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDataBackedImageAsset ()

/// Underlying \c NSData buffer backing this image asset.
@property (readonly, nonatomic) NSData *data;

/// Used to resize underlying buffer according to given \c resizingStrategy.
@property (readonly, nonatomic) PTNImageResizer *resizer;

/// Strategy to use when resizing the image backed by \c data.
@property (readonly, nonatomic) id<PTNResizingStrategy> resizingStrategy;

@end

@implementation PTNDataBackedImageAsset

@synthesize uniformTypeIdentifier = _uniformTypeIdentifier;

- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier
                     resizer:(PTNImageResizer *)resizer
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  if (self = [super init]) {
    _data = data;
    _uniformTypeIdentifier = uniformTypeIdentifier;
    _resizer = resizer;
    _resizingStrategy = resizingStrategy;
  }
  return self;
}

- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [self initWithData:data uniformTypeIdentifier:uniformTypeIdentifier
                    resizer:[[PTNImageResizer alloc] init] resizingStrategy:resizingStrategy];
}

- (instancetype)initWithData:(NSData *)data resizer:(PTNImageResizer *)resizer
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [self initWithData:data uniformTypeIdentifier:nil resizer:resizer
           resizingStrategy:resizingStrategy];
}

- (instancetype)initWithData:(NSData *)data
            resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [self initWithData:data uniformTypeIdentifier:nil
           resizingStrategy:resizingStrategy];
}

- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier {
  return [self initWithData:data uniformTypeIdentifier:uniformTypeIdentifier
           resizingStrategy:[PTNResizingStrategy identity]];
}

- (instancetype)initWithData:(NSData *)data {
  return [self initWithData:data resizingStrategy:[PTNResizingStrategy identity]];
}

#pragma mark -
#pragma mark PTNImageAsset
#pragma mark -

- (RACSignal *)fetchImage {
  return [[[self.resizer resizeImageFromData:self.data resizingStrategy:self.resizingStrategy]
      ptn_wrapErrorWithError:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed]]
      subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)fetchImageMetadata {
  return [[RACSignal
      defer:^RACSignal *{
        NSError *error;
        PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithImageData:self.data
                                                                           error:&error];
        if (error) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                            underlyingError:error]];
        }

        return [RACSignal return:metadata];
      }]
      subscribeOn:RACScheduler.scheduler];
}

#pragma mark -
#pragma mark PTNDataAsset
#pragma mark -

- (RACSignal *)fetchData {
  return [RACSignal return:self.data];
}

- (RACSignal *)writeToFileAtPath:(LTPath *)path usingFileManager:(NSFileManager *)fileManager {
  return [[RACSignal defer:^RACSignal *{
        NSError *error;
        [fileManager lt_writeData:self.data toFile:path.path options:NSDataWritingAtomic
                            error:&error];
        if (error) {
          return [RACSignal error:[NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                                                        url:path.url
                                            underlyingError:error]];
        }
        return [RACSignal empty];
      }]
      subscribeOn:RACScheduler.scheduler];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNDataBackedImageAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.data isEqual:object.data] &&
          (self.uniformTypeIdentifier == object.uniformTypeIdentifier ||
           [self.uniformTypeIdentifier isEqualToString:object.uniformTypeIdentifier]);
}

- (NSUInteger)hash {
  return self.data.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, data length: %lu>", self.class, self,
      (unsigned long)self.data.length];
}

@end

NS_ASSUME_NONNULL_END
