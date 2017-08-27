// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "CAMHardwareSessionFactory.h"

#import "CAMDevicePreset.h"
#import "CAMHardwareSession+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMHardwareSessionFactory

- (RACSignal *)sessionWithPreset:(CAMDevicePreset *)preset {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    CAMHardwareSession *session = [[CAMHardwareSession alloc]
                                   initWithPreset:preset session:[[AVCaptureSession alloc] init]];
    NSError *error;
    BOOL success = [self configureSession:session withPreset:preset error:&error];
    if (success) {
      [subscriber sendNext:session];
      [subscriber sendCompleted];
    } else {
      [subscriber sendError:error];
    }
    return nil;
  }];
}

- (BOOL)configureSession:(CAMHardwareSession *)session withPreset:(CAMDevicePreset *)preset
                   error:(NSError * __autoreleasing *)error {
  BOOL success;

  [session createPreviewLayer];
  [session.session beginConfiguration];
  session.session.sessionPreset = AVCaptureSessionPresetInputPriority;

  success = [session setupVideoInputWithDevice:preset.camera.device
                                formatStrategy:preset.formatStrategy error:error] &&
  [session setupVideoOutputWithError:error];
  if (!success) {
    return NO;
  }
  session.videoOutput.videoSettings = preset.pixelFormat.videoSettings;

  success = [session setupStillOutputGenericWithPixelFormat:preset.pixelFormat error:error];
  if (!success) {
    return NO;
  }

  if (preset.enableAudio) {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    success = [session setupAudioInputWithDevice:device error:error] &&
    [session setupAudioOutputWithError:error];
    if (!success) {
      return NO;
    }
  }

  [session.session commitConfiguration];
  [session.session startRunning];

  return YES;
}

@end

NS_ASSUME_NONNULL_END
