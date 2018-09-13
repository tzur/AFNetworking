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
  [session createPreviewLayer];
  [session.session beginConfiguration];
  session.session.sessionPreset = AVCaptureSessionPresetInputPriority;

  BOOL success = [session setupVideoInputWithDevice:preset.camera.device
                                     formatStrategy:preset.formatStrategy error:error];
  if (!success) {
    return NO;
  }

  success = [session setupVideoOutputWithError:error];
  if (!success) {
    return NO;
  }
  session.videoOutput.videoSettings = preset.pixelFormat.videoSettings;

  success = [session setupPhotoOutputWithPixelFormat:preset.pixelFormat error:error];
  if (!success) {
    return NO;
  }

  session.session.automaticallyConfiguresApplicationAudioSession =
      preset.automaticallyConfiguresApplicationAudioSession;

  if (preset.enableAudio) {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    success = [session setupAudioInputWithDevice:device error:error];
    if (!success) {
      return NO;
    }

    success = [session setupAudioOutputWithError:error];
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
