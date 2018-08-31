// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMBlankDevice.h"

#import "CAMDevicePreset.h"

SpecBegin(CAMBlankDevice)

context(@"setters", ^{
  static const CGPoint kPoint = CGPointMake(0.2, 0.3);

  __block CAMBlankDevice *device;

  beforeEach(^{
    device = [[CAMBlankDevice alloc] init];
  });

  context(@"exposure", ^{
    it(@"should complete setting exposure", ^{
      LLSignalTestRecorder *recorder = [[device setSingleExposurePoint:kPoint] testRecorder];
      expect(recorder).to.sendValues(@[$(kPoint)]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting continuous exposure", ^{
      LLSignalTestRecorder *recorder = [[device setContinuousExposurePoint:kPoint] testRecorder];
      expect(recorder).to.sendValues(@[$(kPoint)]);
      expect(recorder).to.complete();
    });

    it(@"should complete locking exposure", ^{
      LLSignalTestRecorder *recorder = [[device setLockedExposure] testRecorder];
      expect(recorder).to.sendValues(@[$(CGPointNull)]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting exposure compensation", ^{
      LLSignalTestRecorder *recorder = [[device setExposureCompensation:0] testRecorder];
      expect(recorder).to.sendValues(@[@0]);
      expect(recorder).to.complete();
    });

    it(@"should err when setting exposure compensation out of bounds", ^{
      expect([device setExposureCompensation:device.maxExposureCompensation + 1]).to.error();
      expect([device setExposureCompensation:device.maxExposureCompensation - 1]).to.error();
      expect([device setExposureCompensation:NAN]).to.error();
    });
  });

  context(@"flash", ^{
    it(@"should not support flash", ^{
      expect(device.hasFlash).to.beFalsy();

      LLSignalTestRecorder *recorder = [[device setFlashMode:AVCaptureFlashModeOn] testRecorder];
      expect(recorder).to
          .sendError([NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported]);
    });
  });

  context(@"flip", ^{
    it(@"should start with back camera", ^{
      expect(device.activeCamera).to.equal($(CAMDeviceCameraBack));
    });

    it(@"should not support flipping camera", ^{
      expect(device.canChangeCamera).to.beFalsy();

      LLSignalTestRecorder *recorder = [[device setCamera:$(CAMDeviceCameraFront)] testRecorder];
      expect(recorder).to.sendError([NSError lt_errorWithCode:CAMErrorCodeCameraUnavailable]);
    });
  });

  context(@"focus", ^{
    it(@"should complete setting focus", ^{
      LLSignalTestRecorder *recorder = [[device setSingleFocusPoint:kPoint] testRecorder];
      expect(recorder).to.sendValues(@[$(kPoint)]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting continuous focus", ^{
      LLSignalTestRecorder *recorder = [[device setContinuousFocusPoint:kPoint] testRecorder];
      expect(recorder).to.sendValues(@[$(kPoint)]);
      expect(recorder).to.complete();
    });

    it(@"should complete locking focus", ^{
      LLSignalTestRecorder *recorder = [[device setLockedFocus] testRecorder];
      expect(recorder).to.sendValues(@[$(CGPointNull)]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting manual focus", ^{
      LLSignalTestRecorder *recorder = [[device setLockedFocusPosition:0.5] testRecorder];
      expect(recorder).to.sendValues(@[@0.5]);
      expect(recorder).to.complete();
    });

    it(@"should err when setting manual focus out of bounds", ^{
      expect([device setLockedFocusPosition:1.5]).to.error();
      expect([device setLockedFocusPosition:-0.5]).to.error();
      expect([device setLockedFocusPosition:NAN]).to.error();
    });
  });

  context(@"white balance", ^{
    it(@"should complete setting white balance", ^{
      LLSignalTestRecorder *recorder = [[device setSingleWhiteBalance] testRecorder];
      expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting continuous white balance", ^{
      LLSignalTestRecorder *recorder = [[device setContinuousWhiteBalance] testRecorder];
      expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
      expect(recorder).to.complete();
    });

    it(@"should complete locking white balance", ^{
      LLSignalTestRecorder *recorder = [[device setLockedWhiteBalance] testRecorder];
      expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting manual white balance", ^{
      LLSignalTestRecorder *recorder =
          [[device setLockedWhiteBalanceWithTemperature:0.5 tint:0.4] testRecorder];
      expect(recorder).to.sendValues(@[RACTuplePack(@0.5f, @0.4f)]);
      expect(recorder).to.complete();
    });
  });

  context(@"zoom", ^{
    it(@"should not support zoom", ^{
      expect(device.hasZoom).to.beFalsy();
      expect(device.minZoomFactor).to.equal(device.maxZoomFactor);
      expect(device.zoomFactor).to.equal(0);
    });

    it(@"should complete setting zoom to current factor", ^{
      LLSignalTestRecorder *recorder = [[device setZoom:0] testRecorder];
      expect(recorder).to.sendValues(@[@0]);
      expect(recorder).to.complete();
    });

    it(@"should complete setting zoom to current factor with rate", ^{
      LLSignalTestRecorder *recorder = [[device setZoom:0 rate:1] testRecorder];
      expect(recorder).to.sendValues(@[@0]);
      expect(recorder).to.complete();
    });

    it(@"should err when setting zoom to any other value", ^{
      expect([device setZoom:device.zoomFactor + 1]).to.error();
      expect([device setZoom:device.zoomFactor - 1]).to.error();
      expect([device setZoom:device.zoomFactor + 1 rate:1]).to.error();
      expect([device setZoom:device.zoomFactor - 1 rate:1]).to.error();
      expect([device setZoom:NAN]).to.error();
    });
  });

  context(@"torch", ^{
    static const auto kTorchNotSupportedError =
        [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];

    it(@"should not support torch", ^{
      expect(device.hasTorch).to.beFalsy();
    });

    it(@"should err when setting torch level", ^{
      expect([device setTorchLevel:2]).to.sendError(kTorchNotSupportedError);
      expect([device setTorchLevel:0.5]).to.sendError(kTorchNotSupportedError);
      expect([device setTorchLevel:0]).to.sendError(kTorchNotSupportedError);
      expect([device setTorchLevel:-0.5]).to.sendError(kTorchNotSupportedError);
      expect([device setTorchLevel:NAN]).to.sendError(kTorchNotSupportedError);
    });

    it(@"should err when setting torch mode", ^{
      expect([device setTorchMode:AVCaptureTorchModeOn]).to.sendError(kTorchNotSupportedError);
      expect([device setTorchMode:AVCaptureTorchModeOff]).to.sendError(kTorchNotSupportedError);
      expect([device setTorchMode:AVCaptureTorchModeAuto]).to.sendError(kTorchNotSupportedError);
    });
  });
});

context(@"audio and video", ^{
  typedef RACSignal *(^CAMSignalBlock)(CAMBlankDevice *device);

  sharedExamplesFor(@"retaining and completing", ^(NSDictionary *data) {
    it(@"should not retain from signal", ^{
      __weak CAMBlankDevice *weakDevice;
      CAMSignalBlock signalBlock = data[@"signalBlock"];
      RACSignal *signal;
      @autoreleasepool {
        CAMBlankDevice *strongDevice = [[CAMBlankDevice alloc] init];
        weakDevice = strongDevice;
        signal = signalBlock(strongDevice);
      }
      expect(signal).notTo.beNil();
      expect(weakDevice).to.beNil();
    });

    it(@"should complete when device deallocates", ^{
      __weak CAMBlankDevice *weakDevice;
      RACSignal *signal;
      CAMSignalBlock signalBlock = data[@"signalBlock"];
      @autoreleasepool {
        CAMBlankDevice *strongDevice = [[CAMBlankDevice alloc] init];
        weakDevice = strongDevice;
        signal = signalBlock(strongDevice);
      }
      expect(weakDevice).to.beNil();
      expect(signal).to.complete();
    });
  });

  itShouldBehaveLike(@"retaining and completing", @{
    @"signalBlock": ^RACSignal *(CAMBlankDevice *device) {
      return [device audioFrames];
    }
  });

  itShouldBehaveLike(@"retaining and completing", @{
    @"signalBlock": ^RACSignal *(CAMBlankDevice *device) {
      return [device videoFrames];
    }
  });

  itShouldBehaveLike(@"retaining and completing", @{
    @"signalBlock": ^RACSignal *(CAMBlankDevice *device) {
      return [device subjectAreaChanged];
    }
  });
});

context(@"still frames signal", ^{
  __block CAMBlankDevice *device;

  beforeEach(^{
    device = [[CAMBlankDevice alloc] init];
  });

  it(@"should not retain from signal", ^{
    __weak CAMBlankDevice *weakDevice;
    RACSignal *signal;
    @autoreleasepool {
      CAMBlankDevice *strongDevice = [[CAMBlankDevice alloc] init];
      weakDevice = strongDevice;
      signal = [strongDevice stillFramesWithTrigger:[RACSignal return:[RACUnit defaultUnit]]];
    }
    expect(signal).notTo.beNil();
    expect(weakDevice).to.beNil();
  });

  it(@"should err", ^{
    RACSignal *stillFrames =
        [device stillFramesWithTrigger:[RACSignal return:[RACUnit defaultUnit]]];
    NSError *expectedError = [NSError lt_errorWithCode:CAMErrorCodeFailedCapturingFromStillOutput];
    expect(stillFrames).to.sendError(expectedError);
  });
});

SpecEnd
