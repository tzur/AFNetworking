// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNImageDataAsset.h"

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNImageDataAsset ()

/// Data of the image.
@property (readonly, nonatomic) NSData *data;

@end

@implementation PTNImageDataAsset

@synthesize uniformTypeIdentifier = _uniformTypeIdentifier;
@synthesize orientation = _orientation;

- (instancetype)initWithData:(NSData *)data {
  return [self initWithData:data uniformTypeIdentifier:nil orientation:UIImageOrientationUp];
}

- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier
                 orientation:(UIImageOrientation)orientation {
  if (self = [super init]) {
    _data = data;
    _uniformTypeIdentifier = uniformTypeIdentifier;
    _orientation = orientation;
  }
  return self;
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

- (RACSignal *)fetchImageData {
  return [RACSignal return:self.data];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNImageDataAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.data isEqual:object.data] && self.orientation == object.orientation;
}

- (NSUInteger)hash {
  return self.data.hash ^ self.orientation;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, data legnth: %lu, UTI: %@, Orientation %ld>",
          self.class, self, self.data.length, self.uniformTypeIdentifier, (long)self.orientation];
}

@end

NS_ASSUME_NONNULL_END
