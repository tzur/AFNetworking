// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNImageResizer.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileBackedImageAsset ()

/// Local \c LTPath path to underlying file backing this image asset.
@property (strong, nonatomic) LTPath *path;

/// Resizing strategy to be used when fetching underlying image.
@property (strong, nonatomic) id<PTNResizingStrategy> resizingStrategy;

/// Used for resizing underlying image.
@property (strong, nonatomic) PTNImageResizer *imageResizer;

/// File manager for file system interaction.
@property (strong, nonatomic) NSFileManager *fileManager;

@end

@implementation PTNFileBackedImageAsset

- (instancetype)initWithFilePath:(LTPath *)path fileManager:(NSFileManager *)fileManager
                    imageResizer:(PTNImageResizer *)imageResizer
                resizingStrategy:(nullable id<PTNResizingStrategy>)resizingStrategy {
  if (self = [super init]) {
    self.path = path;
    self.fileManager = fileManager;
    self.imageResizer = imageResizer;
    self.resizingStrategy = resizingStrategy ?: [PTNResizingStrategy identity];
  }
  return self;
}

- (RACSignal *)fetchImage {
  return [[[self.imageResizer resizeImageAtURL:self.path.url resizingStrategy:self.resizingStrategy]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                      url:self.path.url
                                          underlyingError:error]];
      }] subscribeOn:RACScheduler.scheduler];
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

@end

NS_ASSUME_NONNULL_END
