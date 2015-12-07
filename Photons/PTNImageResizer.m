// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageResizer.h"

#import <ImageIO/ImageIO.h>
#import <LTKit/LTCGExtensions.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageResizer

- (RACSignal *)resizeImageAtURL:(NSURL *)url toSize:(CGSize)size
                    contentMode:(PTNImageContentMode)contentMode {
  if (!url.isFileURL) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACDisposable *disposable = nil;

    __block CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    @onExit {
      if (sourceRef) {
        CFRelease(sourceRef);
      }
    };
    if (!sourceRef) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeDescriptorCreationFailed
                                          description:@"Failed creating image source"]];
      return disposable;
    }

    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if (!properties) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeDescriptorCreationFailed
                                          description:@"Failed copying source properties"]];
      return disposable;
    }

    NSDictionary *transferredProperties = (__bridge_transfer NSDictionary *)(properties);
    CGSize inputSize = [self sizeOfImageWithProperties:transferredProperties];

    if (inputSize.width == CGSizeNull.width || inputSize.height == CGSizeNull.height) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeInvalidDescriptor url:url
                                          description:@"Image doesn't have width or height"]];
      return disposable;
    } else if (inputSize.width == size.width && inputSize.height == size.height) {
      [subscriber sendNext:[UIImage imageWithContentsOfFile:url.path]];
      [subscriber sendCompleted];

      return disposable;
    }

    CGFloat maxPixelSize = [self maxPixelSizeForInputSize:inputSize outputSize:size
                                              contentMode:contentMode];
    NSDictionary *options = @{
      (NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
      (NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize),
      (NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
    };

    CGImageRef outputRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0,
                                                               (CFDictionaryRef)options);
    @onExit {
      if (outputRef) {
        CGImageRelease(outputRef);
      }
    };
    if (!outputRef) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeDescriptorCreationFailed
                                          description:@"Failed creating output thumbnail"]];
      return disposable;
    }

    [subscriber sendNext:[UIImage imageWithCGImage:outputRef]];
    [subscriber sendCompleted];

    return disposable;
  }];
}

- (CGSize)sizeOfImageWithProperties:(NSDictionary *)properties {
  PTNImageMetadata *metadata = [[PTNImageMetadata alloc] initWithMetadataDictionary:properties];
  return metadata.size;
}

- (CGFloat)maxPixelSizeForInputSize:(CGSize)inputSize outputSize:(CGSize)outputSize
                        contentMode:(PTNImageContentMode)contentMode {
  CGFloat ratio;

  switch (contentMode) {
    case PTNImageContentModeAspectFit:
      ratio = MIN(outputSize.width / inputSize.width, outputSize.height / inputSize.height);
      break;
    case PTNImageContentModeAspectFill:
      ratio = MAX(outputSize.width / inputSize.width, outputSize.height / inputSize.height);
      break;
  }

  CGSize scaledSize = CGSizeMake(ratio * inputSize.width, ratio * inputSize.height);
  return ceil(MAX(scaledSize.width, scaledSize.height));
}

@end

NS_ASSUME_NONNULL_END
