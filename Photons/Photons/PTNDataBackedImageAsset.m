// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataBackedImageAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "PTNImageMetadata.h"
#import "NSError+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDataBackedImageAsset ()

/// Underlying \c NSData buffer backing this image asset.
@property (strong, nonatomic) NSData *data;

@end

@implementation PTNDataBackedImageAsset

- (instancetype)initWithData:(NSData *)data {
  if (self = [super init]) {
    self.data = data;
  }
  return self;
}

- (RACSignal *)fetchImage {
  return [[RACSignal defer:^RACSignal *{
        UIImage *image = [UIImage imageWithData:self.data];
        if (!image) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed]];
        }
        return [RACSignal return:image];
      }]
      subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)fetchImageMetadata {
  return [[RACSignal defer:^RACSignal *{
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

@end

NS_ASSUME_NONNULL_END
