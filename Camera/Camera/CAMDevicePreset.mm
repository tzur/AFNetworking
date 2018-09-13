// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMDevicePreset.h"

#import "CAMFormatStrategy.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, CAMPixelFormat,
  CAMPixelFormatBGRA,
  CAMPixelFormat420f
);

@implementation CAMPixelFormat (Utility)

- (OSType)cvPixelFormat {
  switch (self.value) {
    case CAMPixelFormatBGRA:
      return kCVPixelFormatType_32BGRA;
    case CAMPixelFormat420f:
      return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
  }
  LTAssert(NO, @"Unknown value");
}

- (NSDictionary *)videoSettings {
  return @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(self.cvPixelFormat)};
}

@end

LTEnumImplement(NSUInteger, CAMDeviceCamera,
  CAMDeviceCameraFront,
  CAMDeviceCameraBack
);

@implementation CAMDeviceCamera (Utility)

- (nullable AVCaptureDevice *)device {
  auto devices = [AVCaptureDeviceDiscoverySession
                  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                  mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified].devices;

  for (AVCaptureDevice *device in devices) {
    if (device.position == self.position) {
      return device;
    }
  }
  return nil;
}

- (AVCaptureDevicePosition)position {
  switch (self.value) {
    case CAMDeviceCameraFront:
      return AVCaptureDevicePositionFront;
    case CAMDeviceCameraBack:
      return AVCaptureDevicePositionBack;
  }
  return AVCaptureDevicePositionUnspecified;
}

@end

@implementation CAMDevicePreset

- (instancetype)initWithPixelFormat:(CAMPixelFormat *)pixelFormat camera:(CAMDeviceCamera *)camera
    enableAudio:(BOOL)enableAudio automaticallyConfiguresApplicationAudioSession:
    (BOOL)automaticallyConfiguresApplicationAudioSession
    formatStrategy:(id<CAMFormatStrategy>)formatStrategy outputQueue:(dispatch_queue_t)outputQueue {
  if (self = [super init]) {
    _pixelFormat = pixelFormat;
    _camera = camera;
    _enableAudio = enableAudio;
    _automaticallyConfiguresApplicationAudioSession =
        automaticallyConfiguresApplicationAudioSession;
    _formatStrategy = formatStrategy;
    _outputQueue = outputQueue;
  }
  return self;
}

- (instancetype)initWithPixelFormat:(CAMPixelFormat *)pixelFormat
                             camera:(CAMDeviceCamera *)camera
                        enableAudio:(BOOL)enableAudio
                     formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                        outputQueue:(dispatch_queue_t)outputQueue {
  return [self initWithPixelFormat:pixelFormat camera:camera enableAudio:enableAudio
      automaticallyConfiguresApplicationAudioSession:YES formatStrategy:formatStrategy
      outputQueue:outputQueue];
}

@end

NS_ASSUME_NONNULL_END
