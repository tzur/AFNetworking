// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageResizer.h"

#import <ImageIO/ImageIO.h>
#import <LTKit/LTCFExtensions.h>
#import <LTKit/LTCGExtensions.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageResizer

#pragma mark -
#pragma mark URL resizing
#pragma mark -

- (RACSignal *)resizeImageAtURL:(NSURL *)url toSize:(CGSize)size
                    contentMode:(PTNImageContentMode)contentMode {
  return [self resizeImageAtURL:url
               resizingStrategy:[PTNResizingStrategy contentMode:contentMode size:size]];
}

- (RACSignal *)resizeImageAtURL:(NSURL *)url
               resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  if (!url.isFileURL) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    __block CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!sourceRef) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeDescriptorCreationFailed
                                          description:@"Failed creating image source"]];
      return nil;
    }

    RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
    [disposable addDisposable:[[self resizeImageFromImageSource:sourceRef
                                               resizingStrategy:resizingStrategy
                                                  fullSizeImage:^{
      return [UIImage imageWithContentsOfFile:url.path];
    }] subscribe:subscriber]];

    [disposable addDisposable:[RACDisposable disposableWithBlock:^{
      LTCFSafeRelease(sourceRef);
    }]];

    return disposable;
  }];
}

#pragma mark -
#pragma mark Data resizing
#pragma mark -

- (RACSignal *)resizeImageFromData:(NSData *)data toSize:(CGSize)size
                       contentMode:(PTNImageContentMode)contentMode {
  return [self resizeImageFromData:data
                  resizingStrategy:[PTNResizingStrategy contentMode:contentMode size:size]];
}

- (RACSignal *)resizeImageFromData:(NSData *)data
                  resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    __block CGImageSourceRef sourceRef =
        CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!sourceRef) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeDescriptorCreationFailed
                                          description:@"Failed creating image source"]];
      return nil;
    }

    RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
    [disposable addDisposable:[[self resizeImageFromImageSource:sourceRef
                                               resizingStrategy:resizingStrategy
                                                  fullSizeImage:^{
      return [UIImage imageWithData:data];
    }] subscribe:subscriber]];

    [disposable addDisposable:[RACDisposable disposableWithBlock:^{
      LTCFSafeRelease(sourceRef);
    }]];

    return disposable;
  }];
}

#pragma mark -
#pragma mark Source reference resizing
#pragma mark -

/// Block allocating and returning a \c UIImage.
typedef UIImage *(^PTNImageBlock)(void);

// \c imageSource should be released by the caller. \c fullSizeImage should allocate and return the
// full size image pointed by \c sourceRef.
- (RACSignal *)resizeImageFromImageSource:(CGImageSourceRef)sourceRef
                         resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                            fullSizeImage:(PTNImageBlock)fullSizeImage {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    if (!properties) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeDescriptorCreationFailed
                                          description:@"Failed copying source properties"]];
      return nil;
    }

    NSDictionary *transferredProperties = (__bridge_transfer NSDictionary *)(properties);
    CGSize inputSize = [self sizeOfImageWithProperties:transferredProperties];
    CGSize size = [resizingStrategy sizeForInputSize:inputSize];

    if (isnan(inputSize.width) || isnan(inputSize.height)) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeInvalidDescriptor
                                          description:@"Image doesn't have width or height"]];
      return nil;
    } else if (inputSize.width == size.width && inputSize.height == size.height) {
      [subscriber sendNext:fullSizeImage()];
      [subscriber sendCompleted];

      return nil;
    }

    CGFloat maxPixelSize = [self maxPixelSizeForInputSize:inputSize outputSize:size
                                              contentMode:resizingStrategy.contentMode];
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
      return nil;
    }

    [subscriber sendNext:[UIImage imageWithCGImage:outputRef]];
    [subscriber sendCompleted];

    return nil;
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
