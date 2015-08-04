// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageIOCompressor.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "LTCFExtensions.h"
#import "LTImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImageIOCompressor()

/// Optional dictionary that specifies destination parameters such as image compression quality.
@property (strong, nonatomic, nullable) NSDictionary *options;

/// Output compression format.
@property (nonatomic) CFStringRef UTI;

@end

@implementation LTImageIOCompressor

- (instancetype)init {
  return nil;
}

- (instancetype)initWithOptions:(nullable NSDictionary *)options UTI:(CFStringRef)UTI {
  LTParameterAssert(UTI);
  if (self = [super init]) {
    self.options = options;
    self.UTI = UTI;
  }
  return self;
}

- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error {
  LTParameterAssert(image);

  NSMutableData *imageData = [NSMutableData data];
  __block CGImageDestinationRef destination =
      CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, self.UTI, 1, NULL);
  if (!destination) {
    return nil;
  }
  @onExit {
    LTCFSafeRelease(destination);
  };

  NSDictionary *combinedOptions = [self optionsByMerging:metadata to:self.options];
  CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)combinedOptions);
  
  BOOL finalized = CGImageDestinationFinalize(destination);
  if (!finalized) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed];
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
