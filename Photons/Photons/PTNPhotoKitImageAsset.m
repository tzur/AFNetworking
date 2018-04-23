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
        ^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary *info) {
          @strongify(self)
          if (!contentEditingInput) {
            NSError *error = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                                   url:self.asset.ptn_identifier
                                       underlyingError:info[PHContentEditingInputErrorKey]];
            [subscriber sendError:error];
            return;
          }

          NSError *error;
          PTNImageMetadata *metadata = [self metadataForContentEditingInput:contentEditingInput
                                                                       info:info error:&error];
          if (!metadata) {
            [subscriber sendError:error];
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

- (nullable PTNImageMetadata *)metadataForContentEditingInput:(PHContentEditingInput *)input
                                                         info:(NSDictionary *)info
                                                        error:(NSError * __autoreleasing *)error {
  if (input.mediaType == PHAssetMediaTypeImage) {
    // \c PHContentEditingInputResultIsInCloudKey is always \c YES, even if photo has
    // already been downloaded. Check the \c fullSizeImageURL instead.
    if (!input.fullSizeImageURL || info[PHContentEditingInputErrorKey]) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                       url:self.asset.ptn_identifier
                           underlyingError:info[PHContentEditingInputErrorKey]];
      }
      return nil;
    }

    NSError *metadataError;
    PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithImageURL:input.fullSizeImageURL
                                                                      error:&metadataError];
    if (metadataError) {
      *error = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                     url:self.asset.ptn_identifier
                         underlyingError:metadataError];
      return nil;
    }

    return metadata;
  } else if (input.mediaType == PHAssetMediaTypeVideo) {
    if (!input.audiovisualAsset) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                       url:self.asset.ptn_identifier
                           underlyingError:info[PHContentEditingInputErrorKey]];
      }
      return nil;
    }

    return [[PTNImageMetadata alloc] init];
  } else {
    if (error) {
      *error = [NSError lt_errorWithCode:PTNErrorCodeAssetMetadataLoadingFailed
                                     url:self.asset.ptn_identifier
                             description:@"Unsupported media type given: %lu, UTI: %@, full size "
                @"URL: %@", (unsigned long)input.mediaType, input.uniformTypeIdentifier,
                input.fullSizeImageURL];
    }
    return nil;
  };
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
