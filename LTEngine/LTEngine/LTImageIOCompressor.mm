// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageIOCompressor.h"

#import <ImageIO/ImageIO.h>
#import <LTKit/LTCFExtensions.h>
#import <LTKit/NSError+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "LTCompressionFormat.h"
#import "LTImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImageIOCompressor ()

/// Optional dictionary that specifies destination parameters such as image compression quality.
@property (readonly, nonatomic, nullable) NSDictionary *options;

@end

@implementation LTImageIOCompressor

@synthesize format = _format;

- (instancetype)initWithOptions:(nullable NSDictionary *)options
                         format:(LTCompressionFormat *)format {
  if (self = [super init]) {
    _options = options;
    _format = format;
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  LTParameterAssert(image);

  NSMutableData *imageData = [NSMutableData data];
  lt::Ref<CGImageDestinationRef> destination(
    CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData,
                                     (__bridge CFStringRef)self.format.UTI, 1, NULL)
  );
  if (!destination) {
    return nil;
  }

  NSDictionary *combinedOptions = [self optionsByMerging:metadata to:self.options];
  CGImageDestinationAddImage(destination.get(), image.CGImage,
                             (__bridge CFDictionaryRef)combinedOptions);
  
  BOOL finalized = CGImageDestinationFinalize(destination.get());
  if (!finalized) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating image %@ with metadata %@", image,
                metadata];
    }
    return nil;
  }

  return imageData;
}

/// Deep merge of two dictionaries. If the same key appears in both and the object is not a
/// dictionary, object of target will be taken. Assumes that if target contains a dictionary for a
/// certain key, the source either does not have this key, or it also contains a dictionary for that
/// key.
- (NSDictionary *)optionsByMerging:(NSDictionary *)source to:(NSDictionary *)target {
  NSMutableDictionary *result = [source mutableCopy] ?: [NSMutableDictionary dictionary];

  [target enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *) {
    if (!result[key]) {
      result[key] = obj;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
      LTAssert([result[key] isKindOfClass:[NSDictionary class]], @"If target has a value of "
               "dictionary for a key, and source has this key, its value must be a dictionary as "
               "well");
      result[key] = [self optionsByMerging:result[key] to:obj];
    } else {
      result[key] = obj;
    }
  }];

  return result;
}

@end

NS_ASSUME_NONNULL_END
