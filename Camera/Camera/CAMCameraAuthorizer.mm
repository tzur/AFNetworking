// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMCameraAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMCameraAuthorizer()

/// Media type for which authorization is requested.
@property (readonly, nonatomic) AVMediaType mediaType;

@end

@implementation CAMCameraAuthorizer

- (instancetype)initWithMediaType:(AVMediaType)mediaType {
  if (self = [super init]) {
    _mediaType = mediaType;
  }
  return self;
}

- (void)requestAuthorization:(CAMAuthorizationStatusHandler)handler {
  [AVCaptureDevice requestAccessForMediaType:self.mediaType completionHandler:handler];
}

- (AVAuthorizationStatus)authorizationStatus {
  return [AVCaptureDevice authorizationStatusForMediaType:self.mediaType];
}

@end

NS_ASSUME_NONNULL_END
