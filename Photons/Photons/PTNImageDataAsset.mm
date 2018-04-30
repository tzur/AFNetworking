// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNImageDataAsset.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNImageDataAsset ()

/// Data of the image.
@property (readonly, nonatomic) NSData *data;

@end

@implementation PTNImageDataAsset

@synthesize uniformTypeIdentifier = _uniformTypeIdentifier;

- (instancetype)initWithData:(NSData *)data {
  return [self initWithData:data uniformTypeIdentifier:nil];
}

- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier {
  if (self = [super init]) {
    _data = data;
    _uniformTypeIdentifier = uniformTypeIdentifier;
  }
  return self;
}

- (RACSignal<PTNImageMetadata *> *)fetchImageMetadata {
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

- (RACSignal<NSData *> *)fetchData {
  return [RACSignal return:self.data];
}

- (RACSignal *)writeToFileAtPath:(LTPath *)path usingFileManager:(NSFileManager *)fileManager {
  return [[RACSignal defer:^RACSignal *{
      NSError *error;
      BOOL success = [fileManager lt_writeData:self.data toFile:path.path
                                       options:NSDataWritingAtomic error:&error];
      if (!success) {
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
