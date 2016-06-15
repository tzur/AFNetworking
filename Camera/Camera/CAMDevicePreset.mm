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

- (FourCharCode)cvPixelFormat {
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
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
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

- (instancetype)initWithPixelFormat:(CAMPixelFormat *)pixelFormat
                             camera:(CAMDeviceCamera *)camera
                        enableAudio:(BOOL)enableAudio
                     formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                        outputQueue:(dispatch_queue_t)outputQueue {
  if (self = [super init]) {
    _pixelFormat = pixelFormat;
    _camera = camera;
    _enableAudio = enableAudio;
    _formatStrategy = formatStrategy;
    _outputQueue = outputQueue;
  }
  return self;
}

@end

@implementation CAMDevicePreset (Factory)

+ (CAMDevicePreset *)stillCamera {
  return [self stillCameraWithQueue:dispatch_get_main_queue()];
}

+ (CAMDevicePreset *)stillCameraWithQueue:(dispatch_queue_t)outputQueue {
  return [[CAMDevicePreset alloc]
      initWithPixelFormat:$(CAMPixelFormat420f)
                   camera:$(CAMDeviceCameraBack)
              enableAudio:NO
           formatStrategy:[CAMFormatStrategy highestResolution420f]
              outputQueue:outputQueue];
}

+ (CAMDevicePreset *)selfieCamera {
  return [self selfieCameraWithQueue:dispatch_get_main_queue()];
}

+ (CAMDevicePreset *)selfieCameraWithQueue:(dispatch_queue_t)outputQueue {
  return [[CAMDevicePreset alloc]
      initWithPixelFormat:$(CAMPixelFormatBGRA)
                   camera:$(CAMDeviceCameraFront)
              enableAudio:NO
           formatStrategy:[CAMFormatStrategy highestResolution420f]
              outputQueue:outputQueue];
}

+ (CAMDevicePreset *)videoCamera {
  return [self videoCameraWithQueue:dispatch_get_main_queue()];
}

+ (CAMDevicePreset *)videoCameraWithQueue:(dispatch_queue_t)outputQueue {
  return [[CAMDevicePreset alloc]
      initWithPixelFormat:$(CAMPixelFormat420f)
                   camera:$(CAMDeviceCameraBack)
              enableAudio:YES
           formatStrategy:[CAMFormatStrategy exact420fWidth:1920 height:1080]
              outputQueue:outputQueue];
}

@end

NS_ASSUME_NONNULL_END
