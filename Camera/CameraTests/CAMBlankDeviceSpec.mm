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

    it(@"should raise when setting exposure compensation out of bounds", ^{
      expect(^{
        [device setExposureCompensation:device.maxExposureCompensation + 1];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [device setExposureCompensation:device.minExposureCompensation - 1];
      }).to.raise(NSInvalidArgumentException);
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

  context(@"torch", ^{
    it(@"should not support torch", ^{
      expect(device.hasTorch).to.beFalsy();

      LLSignalTestRecorder *recorder = [[device setTorchLevel:0.5] testRecorder];
      expect(recorder).to
          .sendError([NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported]);
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

    it(@"should raise when setting manual focus out of bounds", ^{
      expect(^{
        [device setLockedFocusPosition:1.5];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [device setLockedFocusPosition:-0.5];
      }).to.raise(NSInvalidArgumentException);
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

    it(@"should raise when setting zoom to any other value", ^{
      expect(^{
        [device setZoom:device.zoomFactor + 1];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [device setZoom:device.zoomFactor - 1];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [device setZoom:device.zoomFactor + 1 rate:1];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [device setZoom:device.zoomFactor - 1 rate:1];
      }).to.raise(NSInvalidArgumentException);
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
      return [device stillFramesWithTrigger:[RACSignal never]];
    }
  });

  itShouldBehaveLike(@"retaining and completing", @{
    @"signalBlock": ^RACSignal *(CAMBlankDevice *device) {
      return [device subjectAreaChanged];
    }
  });
});

SpecEnd
