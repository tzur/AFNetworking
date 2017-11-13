// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTImageIOExtensions.h"

#import "LTCompressionFormat.h"

NS_ASSUME_NONNULL_BEGIN

NSData * _Nullable LTCombineImageWithMetadata(NSData *imageData, NSDictionary * _Nullable metadata,
                                              NSError *__autoreleasing *error) {
  auto source = lt::makeRef(CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil));
  NSString *uti = (NSString *)CGImageSourceGetType(source.get());

  NSMutableData *combinedData = [NSMutableData data];
  auto destination = lt::makeRef(CGImageDestinationCreateWithData(
    (__bridge CFMutableDataRef)combinedData, (__bridge CFStringRef)uti, 1, NULL)
  );

  if (!destination) {
    return nil;
  }

  CGImageDestinationAddImageFromSource(destination.get(), source.get(), 0,
                                       (__bridge CFDictionaryRef)metadata);

  if (!CGImageDestinationFinalize(destination.get())) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed combining image data with metadata %@",
                metadata];
    }
    return nil;
  }

  return combinedData;
}

BOOL LTCombineImageWithMetadataAndSavetoURL(NSData *imageData, NSDictionary * _Nullable metadata,
                                            NSURL *url, NSError *__autoreleasing *error) {
  auto source = lt::makeRef(CGImageSourceCreateWithData((__bridge CFDataRef)imageData, nil));
  NSString *uti = (NSString *)CGImageSourceGetType(source.get());

  auto destination = lt::makeRef(
    CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)uti, 1, NULL)
  );
  if (!destination) {
    return NO;
  }

  CGImageDestinationAddImageFromSource(destination.get(), source.get(), 0,
                                       (__bridge CFDictionaryRef)metadata);

  if (!CGImageDestinationFinalize(destination.get())) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed combining image data with metadata %@",
                metadata];
    }
    return NO;
  }

  return YES;
}

NS_ASSUME_NONNULL_END
