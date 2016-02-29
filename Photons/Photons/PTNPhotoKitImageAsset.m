// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitImageAsset.h"

#import <Photos/Photos.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNProgress.h"
#import "PhotoKit+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitImageAsset ()

/// Image backing this image asset.
@property (readonly, nonatomic) UIImage *image;

/// PhotoKit asset backing this image asset.
@property (readonly, nonatomic) PHAsset *asset;

@end

@implementation PTNPhotoKitImageAsset

- (instancetype)initWithImage:(UIImage *)image asset:(PHAsset *)asset {
  if (self = [super init]) {
    _image = image;
    _asset = asset;
  }
  return self;
}

- (RACSignal *)fetchImage {
  return [RACSignal return:self.image];
}

- (RACSignal *)fetchImageMetadata {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @weakify(self)
    void (^completionHandler)(PHContentEditingInput *contentEditingInput, NSDictionary *info) =
        ^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
          @strongify(self)
          // \c PHContentEditingInputResultIsInCloudKey is always \c YES, even if photo has already
          // been downloaded. Check the \c fullSizeImageURL instead.
          if (!contentEditingInput.fullSizeImageURL || info[PHContentEditingInputErrorKey]) {
            NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                          url:self.asset.ptn_identifier
                                              underlyingError:info[PHContentEditingInputErrorKey]];
            [subscriber sendError:wrappedError];
            return;
          }

          NSError *metadataError;
          PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
                                        initWithImageURL:contentEditingInput.fullSizeImageURL
                                        error:&metadataError];
          if (metadataError) {
            NSError *wrappedError = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                          url:self.asset.ptn_identifier
                                              underlyingError:metadataError];
            [subscriber sendError:wrappedError];
            return;
          }

          [subscriber sendNext:metadata];
          [subscriber sendCompleted];
        };

    PHContentEditingInputRequestID requestID =
        [self.asset requestContentEditingInputWithOptions:nil completionHandler:completionHandler];

    return [RACDisposable disposableWithBlock:^{
      [self.asset cancelContentEditingInputRequest:requestID];
    }];
  }];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNPhotoKitImageAsset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.image isEqual:object.image] && [self.asset isEqual:object.asset];
}

- (NSUInteger)hash {
  return self.image.hash ^ self.asset.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, image: %@, PhotoKit asset: %@>", self.class, self,
      self.image, self.asset];
}

@end

NS_ASSUME_NONNULL_END
