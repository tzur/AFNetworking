// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/LTUTICache.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNResizingStrategy.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileBackedImageAsset ()

/// Local \c LTPath path to underlying file backing this image asset.
@property (readonly, nonatomic) LTPath *path;

/// Resizing strategy to be used when fetching underlying image.
@property (nullable, readonly, nonatomic) id<PTNResizingStrategy> resizingStrategy;

/// Used for resizing underlying image.
@property (readonly, nonatomic) PTNImageResizer *imageResizer;

/// File manager for file system interaction.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation PTNFileBackedImageAsset

@synthesize uniformTypeIdentifier = _uniformTypeIdentifier;

- (instancetype)initWithFilePath:(LTPath *)path fileManager:(NSFileManager *)fileManager
                    imageResizer:(PTNImageResizer *)imageResizer
                resizingStrategy:(nullable id<PTNResizingStrategy>)resizingStrategy {
  if (self = [super init]) {
    _path = path;
    _uniformTypeIdentifier = path.url.pathExtension ?
        [LTUTICache.sharedCache preferredUTIForFileExtension:path.url.pathExtension] : nil;
    _fileManager = fileManager;
    _imageResizer = imageResizer;
    _resizingStrategy = resizingStrategy ?: [PTNResizingStrategy identity];
  }
  return self;
}

- (RACSignal *)fetchImage {
  return [[[self.imageResizer resizeImageAtURL:self.path.url resizingStrategy:self.resizingStrategy]
      ptn_wrapErrorWithError:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                   url:self.path.url]]
      subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)fetchImageMetadata {
  return [[RACSignal defer:^RACSignal *{
        NSError *error;
        PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithImageURL:self.path.url
                                                                          error:&error];
        if (error) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                        url:self.path.url
                                            underlyingError:error]];
        }

        return [RACSignal return:metadata];
      }]
      subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)fetchData {
  return [[RACSignal defer:^RACSignal *{
        NSError *error;
        NSData *data = [self.fileManager lt_dataWithContentsOfFile:self.path.path
                                                           options:NSDataReadingMappedIfSafe
                                                             error:&error];
        if (!data) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                        url:self.path.url
                                            underlyingError:error]];
        }

        return [RACSignal return:data];
      }]
      subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)writeToFileAtPath:(LTPath *)path usingFileManager:(NSFileManager *)fileManager {
  return [[RACSignal defer:^RACSignal *{
        NSError *error;
        BOOL success = [fileManager copyItemAtURL:self.path.url toURL:path.url error:&error];
        if (!success) {
          return [RACSignal error:[NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                                                        url:self.path.url
                                            underlyingError:error]];
        }

        return [RACSignal empty];
      }]
      subscribeOn:RACScheduler.scheduler];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNFileBackedImageAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqual:object.path] && [self.resizingStrategy isEqual:object.resizingStrategy];
}

- (NSUInteger)hash {
  return self.path.hash ^ self.resizingStrategy.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, resizing strategy: %@>", self.class, self,
      self.path, self.resizingStrategy];
}

@end

NS_ASSUME_NONNULL_END
