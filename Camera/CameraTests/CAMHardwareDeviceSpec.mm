// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareDevice.h"

#import <LTEngine/LTMMTexture.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "CAMDevicePreset.h"
#import "CAMFakeAVCaptureDevice.h"
#import "CAMHardwareSession.h"
#import "CAMSampleTimingInfo.h"
#import "CAMVideoFrame.h"

@interface CAMHardwareDevice (ForTesting) <AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate>
@end

@interface CAMHardwareSession (ForTesting)
- (instancetype)initWithPreset:(CAMDevicePreset *)preset session:(AVCaptureSession *)session;
@property (readwrite, nonatomic, nullable) AVCaptureVideoPreviewLayer *previewLayer;
@property (readwrite, nonatomic, nullable) AVCaptureDevice *videoDevice;
@property (readwrite, nonatomic, nullable) AVCaptureDeviceInput *videoInput;
@property (readwrite, nonatomic, nullable) AVCaptureVideoDataOutput *videoOutput;
@property (readwrite, nonatomic, nullable) AVCaptureConnection *videoConnection;
@property (readwrite, nonatomic, nullable) AVCaptureStillImageOutput *stillOutput;
@property (readwrite, nonatomic, nullable) AVCaptureConnection *stillConnection;
@property (readwrite, nonatomic, nullable) AVCaptureDevice *audioDevice;
@property (readwrite, nonatomic, nullable) AVCaptureDeviceInput *audioInput;
@property (readwrite, nonatomic, nullable) AVCaptureAudioDataOutput *audioOutput;
@property (readwrite, nonatomic, nullable) AVCaptureConnection *audioConnection;
@end

@interface CAMFakeAVCaptureDeviceFormat : AVCaptureDeviceFormat
@property (nonatomic) CGFloat videoMaxZoomFactorToReturn;
@end

@implementation CAMFakeAVCaptureDeviceFormat
- (CGFloat)videoMaxZoomFactor {
  return self.videoMaxZoomFactorToReturn;
}
@end

static CMSampleBufferRef CAMCreateEmptySampleBuffer() {
  CMSampleBufferRef sampleBuffer;
  OSStatus status = CMSampleBufferCreate(kCFAllocatorDefault, NULL, YES, NULL, NULL, NULL,
                                         0, 0, NULL, 0, NULL, &sampleBuffer);
  LTAssert(status == 0, @"CMSampleBufferCreate failed - check code");
  return sampleBuffer;
}

static CMSampleBufferRef CAMCreateImageSampleBuffer(CGSize size) {
  CVImageBufferRef imageBuffer;
  CVReturn pixelBufferCreate =
      CVPixelBufferCreate(NULL, (size_t)size.width, (size_t)size.height, kCVPixelFormatType_32BGRA,
                          NULL, &imageBuffer);
  LTAssert(pixelBufferCreate == kCVReturnSuccess, @"CVPixelBufferCreate failed - check code");

  CMVideoFormatDescriptionRef videoFormat;
  CVReturn videoFormatCreate =
      CMVideoFormatDescriptionCreateForImageBuffer(NULL, imageBuffer, &videoFormat);
  LTAssert(videoFormatCreate == kCVReturnSuccess,
      @"CMVideoFormatDescriptionCreateForImageBuffer failed - check code");

  CMSampleTimingInfo sampleTimingInfo = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};

  CMSampleBufferRef sampleBuffer;
  OSStatus sampleBufferCreate =
      CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, imageBuffer, YES, NULL, NULL,
                                         videoFormat, &sampleTimingInfo, &sampleBuffer);
  LTAssert(sampleBufferCreate == 0, @"CMSampleBufferCreateForImageBuffer failed - check code");

  CFRelease(videoFormat);
  CFRelease(imageBuffer);

  return sampleBuffer;
}

SpecBegin(CAMHardwareDevice)

static NSError * const kError = [NSError lt_errorWithCode:123];

context(@"", ^{
  __block CAMHardwareSession *session;
  __block CAMHardwareDevice *device;

  beforeEach(^{
    session = [[CAMHardwareSession alloc] initWithPreset:nil session:nil];
    device = [[CAMHardwareDevice alloc] initWithSession:session];
  });

  context(@"video", ^{
    it(@"should set pixel format", ^{
      id videoOutput = OCMClassMock([AVCaptureVideoDataOutput class]);
      session.videoOutput = videoOutput;

      CAMPixelFormat *pixelFormat = $(CAMPixelFormat420f);
      LLSignalTestRecorder *recorder = [[device setPixelFormat:pixelFormat] testRecorder];
      OCMVerify([videoOutput setVideoSettings:pixelFormat.videoSettings]);
      expect(recorder).to.sendValues(@[pixelFormat]);
      expect(recorder).to.complete();
    });

    it(@"should not set pixel format without subscribing", ^{
      id videoOutput = OCMClassMock([AVCaptureVideoDataOutput class]);
      session.videoOutput = videoOutput;

      OCMReject([videoOutput setVideoSettings:OCMOCK_ANY]);
      [device setPixelFormat:$(CAMPixelFormat420f)];
    });

    it(@"should capture still frames", ^{
      id stillOutput = OCMClassMock([AVCaptureStillImageOutput class]);
      session.stillOutput = stillOutput;

      RACSubject *trigger = [RACSubject subject];
      RACSignal *stillFrames = [device stillFramesWithTrigger:trigger];

      CMSampleBufferRef sampleBuffer = CAMCreateEmptySampleBuffer();
      NSValue *boxedSampleBuffer = [NSValue value:&sampleBuffer
                                     withObjCType:@encode(CMSampleBufferRef)];
      OCMStub([stillOutput
               captureStillImageAsynchronouslyFromConnection:OCMOCK_ANY
               completionHandler:
                   ([OCMArg invokeBlockWithArgs:boxedSampleBuffer, [NSNull null], nil])]);

      id avcaptureClassMock = OCMClassMock([AVCaptureStillImageOutput class]);
      [[[[avcaptureClassMock stub] ignoringNonObjectArgs] andReturn:nil]
          jpegStillImageNSDataRepresentation:NULL];

      UIImage *image = LTLoadImage([self class], @"Lena.png");
      expect(image).toNot.beNil();
      id uiimageClassMock = OCMClassMock([UIImage class]);
      OCMStub([uiimageClassMock imageWithData:OCMOCK_ANY]).andReturn(image);

      LLSignalTestRecorder *recorder = [stillFrames testRecorder];

      [trigger sendNext:nil];
      expect(recorder).to.sendValues(@[image]);
      [trigger sendNext:nil];
      expect(recorder).to.sendValues(@[image, image]);
      expect(recorder).toNot.complete();
      [trigger sendCompleted];
      expect(recorder).to.complete();

      [uiimageClassMock stopMocking];
      [avcaptureClassMock stopMocking];
      boxedSampleBuffer = nil;
      CFRelease(sampleBuffer);
    });

    it(@"should send video frames", ^{
      CGSize size = CGSizeMake(3, 6);
      CMSampleBufferRef sampleBuffer = CAMCreateImageSampleBuffer(size);
      CMSampleTimingInfo sampleTimingInfo;
      OSStatus status = CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &sampleTimingInfo);
      expect(status).to.equal(noErr);

      id output = OCMClassMock([AVCaptureVideoDataOutput class]);
      id connection = OCMClassMock([AVCaptureConnection class]);
      LLSignalTestRecorder *recorder = [[device videoFrames] testRecorder];

      [device captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
      expect(recorder).to.sendValuesWithCount(1);
      expect(recorder).to.matchValue(0, ^BOOL(CAMVideoFrameBGRA *frame) {
        return [frame isKindOfClass:[CAMVideoFrameBGRA class]] && frame.bgraTexture.size == size &&
            CAMSampleTimingInfoIsEqual(sampleTimingInfo, frame.sampleTimingInfo);
        ;
      });
      [device captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
      expect(recorder).to.sendValuesWithCount(2);
      expect(recorder).to.matchValue(1, ^BOOL(CAMVideoFrameBGRA *frame) {
        return [frame isKindOfClass:[CAMVideoFrameBGRA class]] && frame.bgraTexture.size == size &&
            CAMSampleTimingInfoIsEqual(sampleTimingInfo, frame.sampleTimingInfo);
      });
      expect(recorder).toNot.complete();

      CFRelease(sampleBuffer);
    });

    it(@"should update frames orientation correctly", ^{
      id previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      id previewConnection = OCMClassMock([AVCaptureConnection class]);
      OCMStub([previewLayer connection]).andReturn(previewConnection);
      id videoConnection = OCMClassMock([AVCaptureConnection class]);
      id stillConnection = OCMClassMock([AVCaptureConnection class]);
      session.previewLayer = previewLayer;
      session.videoConnection = videoConnection;
      session.stillConnection = stillConnection;
      UIInterfaceOrientation deviceOrientation = UIInterfaceOrientationLandscapeRight;
      AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;

      device.videoFramesWithPortraitOrientation = NO;
      device.previewLayerWithPortraitOrientation = NO;
      device.deviceOrientation = deviceOrientation;

      expect(device.deviceOrientation).to.equal(deviceOrientation);
      OCMVerify([stillConnection setVideoOrientation:videoOrientation]);
      OCMVerify([previewConnection setVideoOrientation:videoOrientation]);
      OCMVerify([videoConnection setVideoOrientation:videoOrientation]);
    });

    it(@"should update frames orientation correctly when locked on portrait orientation", ^{
      id previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      id previewConnection = OCMClassMock([AVCaptureConnection class]);
      OCMStub([previewLayer connection]).andReturn(previewConnection);
      id videoConnection = OCMClassMock([AVCaptureConnection class]);
      id stillConnection = OCMClassMock([AVCaptureConnection class]);
      session.previewLayer = previewLayer;
      session.videoConnection = videoConnection;
      session.stillConnection = stillConnection;
      UIInterfaceOrientation deviceOrientation = UIInterfaceOrientationLandscapeRight;
      AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
      OCMReject([previewConnection setVideoOrientation:videoOrientation]);
      OCMReject([videoConnection setVideoOrientation:videoOrientation]);

      device.videoFramesWithPortraitOrientation = YES;
      device.previewLayerWithPortraitOrientation = YES;
      device.deviceOrientation = deviceOrientation;

      expect(device.deviceOrientation).to.equal(deviceOrientation);
      OCMVerify([stillConnection setVideoOrientation:videoOrientation]);
    });

    it(@"should update video frames orientation correctly", ^{
      id videoConnection = OCMClassMock([AVCaptureConnection class]);
      session.videoConnection = videoConnection;
      UIInterfaceOrientation deviceOrientation = UIInterfaceOrientationLandscapeRight;
      AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;

      device.videoFramesWithPortraitOrientation = NO;
      device.deviceOrientation = deviceOrientation;
      OCMVerify([videoConnection setVideoOrientation:videoOrientation]);

      device.videoFramesWithPortraitOrientation = YES;
      OCMVerify([videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait]);

      device.videoFramesWithPortraitOrientation = NO;
      OCMVerify([videoConnection setVideoOrientation:videoOrientation]);
    });
    
    it(@"should send subject changed updates", ^{
      LLSignalTestRecorder *recorder = [device.subjectAreaChanged testRecorder];
      [[NSNotificationCenter defaultCenter]
          postNotificationName:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
      expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
      expect(recorder).toNot.complete();
    });

    it(@"should return error from still output", ^{
      id stillOutput = OCMClassMock([AVCaptureStillImageOutput class]);
      session.stillOutput = stillOutput;
      OCMStub([stillOutput
               captureStillImageAsynchronouslyFromConnection:OCMOCK_ANY
               completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], kError, nil])]);

      RACSubject *trigger = [RACSubject subject];
      RACSignal *stillFrames = [device stillFramesWithTrigger:trigger];

      LLSignalTestRecorder *recorder = [stillFrames testRecorder];
      [trigger sendNext:nil];

      NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFailedCapturingFromStillOutput
                                    underlyingError:kError];
      expect(recorder).to.sendError(expected);
    });
  });

  context(@"audio", ^{
    it(@"should send audio frame", ^{
      CMSampleBufferRef sampleBuffer = CAMCreateEmptySampleBuffer();

      id output = OCMClassMock([AVCaptureAudioDataOutput class]);
      id connection = OCMClassMock([AVCaptureConnection class]);
      LLSignalTestRecorder *recorder = [[device audioFrames] testRecorder];
      NSValue *expected = [NSValue value:&sampleBuffer withObjCType:@encode(CMSampleBufferRef)];

      [device captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
      expect(recorder).to.sendValues(@[expected]);
      [device captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
      expect(recorder).to.sendValues(@[expected, expected]);
      expect(recorder).toNot.complete();

      CFRelease(sampleBuffer);
    });
  });

  context(@"preview layer", ^{
    __block id previewLayer;

    beforeEach(^{
      previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      session.previewLayer = previewLayer;
    });

    it(@"should return preview layer", ^{
      expect(device.previewLayer).to.equal(previewLayer);
    });

    it(@"should convert point from device to view coordinates", ^{
      CGPoint point = CGPointMake(1, 2);
      CGPoint convertedPoint = CGPointMake(3, 4);
      OCMStub([previewLayer captureDevicePointOfInterestForPoint:point]).andReturn(convertedPoint);

      expect([device devicePointFromPreviewLayerPoint:point]).to.equal(convertedPoint);
    });

    it(@"should convert point from view to device coordinates", ^{
      CGPoint point = CGPointMake(1, 2);
      CGPoint convertedPoint = CGPointMake(3, 4);
      OCMStub([previewLayer pointForCaptureDevicePointOfInterest:point]).andReturn(convertedPoint);

      expect([device previewLayerPointFromDevicePoint:point]).to.equal(convertedPoint);
    });

    it(@"should update preview layer orientation correctly", ^{
      id previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      id previewConnection = OCMClassMock([AVCaptureConnection class]);
      OCMStub([previewLayer connection]).andReturn(previewConnection);
      session.previewLayer = previewLayer;
      UIInterfaceOrientation deviceOrientation = UIInterfaceOrientationLandscapeRight;
      AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;

      device.previewLayerWithPortraitOrientation = NO;
      device.deviceOrientation = deviceOrientation;
      OCMVerify([previewConnection setVideoOrientation:videoOrientation]);

      device.previewLayerWithPortraitOrientation = YES;
      OCMVerify([previewConnection setVideoOrientation:AVCaptureVideoOrientationPortrait]);

      device.previewLayerWithPortraitOrientation = NO;
      OCMVerify([previewConnection setVideoOrientation:videoOrientation]);
    });
  });

  context(@"focus", ^{
    static const CGPoint kPoint = CGPointMake(0.2, 0.3);

    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = videoDevice;
    });

    context(@"positive", ^{
      beforeEach(^{
        videoDevice.focusModeSupported = YES;
        videoDevice.focusPointOfInterestSupported = YES;
      });

      it(@"should set focus", ^{
        LLSignalTestRecorder *recorder = [[device setSingleFocusPoint:kPoint] testRecorder];
        expect(recorder).will.sendValues(@[$(kPoint)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeAutoFocus);
        expect(videoDevice.focusPointOfInterest).to.equal(kPoint);
      });

      it(@"should set continuous focus", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousFocusPoint:kPoint] testRecorder];
        expect(recorder).will.sendValues(@[$(kPoint)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeContinuousAutoFocus);
        expect(videoDevice.focusPointOfInterest).to.equal(kPoint);
      });

      it(@"should lock focus", ^{
        LLSignalTestRecorder *recorder = [[device setLockedFocus] testRecorder];
        expect(recorder).will.sendValues(@[$(CGPointNull)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeLocked);
        expect(videoDevice.focusPointOfInterest).toNot.equal(CGPointNull);
      });

      it(@"should set manual focus", ^{
        LLSignalTestRecorder *recorder = [[device setLockedFocusPosition:0.3] testRecorder];
        expect(recorder).will.sendValues(@[@((CGFloat)0.3)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeLocked);
        expect(videoDevice.lensPosition).to.equal(0.3);
      });
    });

    context(@"require subscription", ^{
      beforeEach(^{
        videoDevice.focusModeSupported = YES;
        videoDevice.focusPointOfInterestSupported = YES;
      });

      it(@"should not set focus", ^{
        [device setSingleFocusPoint:kPoint];
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeAutoFocus);
        expect(videoDevice.focusPointOfInterest).toNot.equal(kPoint);
      });

      it(@"should not set continuous focus", ^{
        [device setContinuousFocusPoint:kPoint];
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeContinuousAutoFocus);
        expect(videoDevice.focusPointOfInterest).toNot.equal(kPoint);
      });

      it(@"should not lock focus", ^{
        videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
        [device setLockedFocus];
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeLocked);
      });

      it(@"should not set manual focus", ^{
        videoDevice.focusMode = AVCaptureFocusModeAutoFocus;
        [device setLockedFocusPosition:0.3];
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeLocked);
        expect(videoDevice.lensPosition).toNot.equal(0.3);
      });
    });

    context(@"negative", ^{
      it(@"should return error from focus", ^{
        LLSignalTestRecorder *recorder = [[device setSingleFocusPoint:kPoint] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeAutoFocus);
        expect(videoDevice.focusPointOfInterest).toNot.equal(kPoint);
      });

      it(@"should return error from continuous focus", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousFocusPoint:kPoint] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeContinuousAutoFocus);
        expect(videoDevice.focusPointOfInterest).toNot.equal(kPoint);
      });

      it(@"should return error from lock focus", ^{
        LLSignalTestRecorder *recorder = [[device setLockedFocus] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        expect(recorder).will.sendError(expected);
      });

      it(@"should return error from manual focus", ^{
        LLSignalTestRecorder *recorder = [[device setLockedFocusPosition:0.3] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.lensPosition).toNot.equal(0.3);
      });
    });
  });

  context(@"exposure", ^{
    static const CGPoint kPoint = CGPointMake(0.2, 0.3);

    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = videoDevice;
    });

    context(@"positive", ^{
      beforeEach(^{
        videoDevice.exposureModeSupported = YES;
        videoDevice.exposurePointOfInterestSupported = YES;
      });

      it(@"should set exposure", ^{
        LLSignalTestRecorder *recorder = [[device setSingleExposurePoint:kPoint] testRecorder];
        expect(recorder).will.sendValues(@[$(kPoint)]);
        expect(recorder).to.complete();
        expect(videoDevice.exposureMode).to.equal(AVCaptureExposureModeAutoExpose);
        expect(videoDevice.exposurePointOfInterest).to.equal(kPoint);
      });

      it(@"should set continuous exposure", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousExposurePoint:kPoint] testRecorder];
        expect(recorder).will.sendValues(@[$(kPoint)]);
        expect(recorder).to.complete();
        expect(videoDevice.exposureMode).to.equal(AVCaptureExposureModeContinuousAutoExposure);
        expect(videoDevice.exposurePointOfInterest).to.equal(kPoint);
      });

      it(@"should lock exposure", ^{
        LLSignalTestRecorder *recorder = [[device setLockedExposure] testRecorder];
        expect(recorder).will.sendValues(@[$(CGPointNull)]);
        expect(recorder).to.complete();
        expect(videoDevice.exposureMode).to.equal(AVCaptureExposureModeLocked);
        expect(videoDevice.exposurePointOfInterest).toNot.equal(CGPointNull);
      });

      it(@"should set exposure compensation", ^{
        videoDevice.minExposureTargetBias = 0;
        videoDevice.maxExposureTargetBias = 1;
        LLSignalTestRecorder *recorder = [[device setExposureCompensation:0.3] testRecorder];
        expect(recorder).will.sendValues(@[@0.3f]);
        expect(recorder).to.complete();
        expect(videoDevice.exposureTargetBias).to.equal(0.3);
      });

      it(@"should update min exposure compensation", ^{
        expect(device.minExposureCompensation).to.equal(0);
        videoDevice.minExposureTargetBias = 6;
        expect(device.minExposureCompensation).will.equal(6);
      });

      it(@"should update max exposure compensation", ^{
        expect(device.maxExposureCompensation).to.equal(0);
        videoDevice.maxExposureTargetBias = 6;
        expect(device.maxExposureCompensation).will.equal(6);
      });

      it(@"should raise when exposure compensation out of bounds", ^{
        videoDevice.minExposureTargetBias = 2;
        videoDevice.maxExposureTargetBias = 3;

        expect(^{
          __unused id x = [[device setExposureCompensation:1.9] testRecorder];
        }).will.raise(NSInvalidArgumentException);

        expect(^{
          __unused id x = [[device setExposureCompensation:3.1] testRecorder];
        }).will.raise(NSInvalidArgumentException);
      });
    });

    context(@"require subscription", ^{
      beforeEach(^{
        videoDevice.exposureModeSupported = YES;
        videoDevice.exposurePointOfInterestSupported = YES;
      });

      it(@"should not set exposure", ^{
        [device setSingleExposurePoint:kPoint];
        expect(videoDevice.exposureMode).toNot.equal(AVCaptureExposureModeAutoExpose);
        expect(videoDevice.exposurePointOfInterest).toNot.equal(kPoint);
      });

      it(@"should not set continuous exposure", ^{
        [device setContinuousExposurePoint:kPoint];
        expect(videoDevice.exposureMode).toNot.equal(AVCaptureExposureModeContinuousAutoExposure);
        expect(videoDevice.exposurePointOfInterest).toNot.equal(kPoint);
      });

      it(@"should not lock exposure", ^{
        videoDevice.exposureMode = AVCaptureExposureModeAutoExpose;
        [device setLockedExposure];
        expect(videoDevice.exposureMode).toNot.equal(AVCaptureExposureModeLocked);
      });

      it(@"should not set exposure compensation", ^{
        videoDevice.minExposureTargetBias = 0;
        videoDevice.maxExposureTargetBias = 1;
        [device setExposureCompensation:0.3];
        expect(videoDevice.exposureTargetBias).toNot.equal(0.3);
      });
    });

    context(@"negative", ^{
      it(@"should return error from exposure", ^{
        LLSignalTestRecorder *recorder = [[device setSingleExposurePoint:kPoint] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.exposureMode).toNot.equal(AVCaptureExposureModeAutoExpose);
        expect(videoDevice.exposurePointOfInterest).toNot.equal(kPoint);
      });

      it(@"should return error from continuous exposure", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousExposurePoint:kPoint] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.exposureMode).toNot.equal(AVCaptureExposureModeContinuousAutoExposure);
        expect(videoDevice.exposurePointOfInterest).toNot.equal(kPoint);
      });

      it(@"should return error from lock exposure", ^{
        LLSignalTestRecorder *recorder = [[device setLockedExposure] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported];
        expect(recorder).will.sendError(expected);
      });
    });
  });

  context(@"white balance", ^{
    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = videoDevice;
    });

    context(@"positive", ^{
      beforeEach(^{
        videoDevice.whiteBalanceModeSupported = YES;
      });

      it(@"should set white balance", ^{
        LLSignalTestRecorder *recorder = [[device setSingleWhiteBalance] testRecorder];
        expect(recorder).will.sendValues(@[[RACUnit defaultUnit]]);
        expect(recorder).to.complete();
        expect(videoDevice.whiteBalanceMode).to.equal(AVCaptureWhiteBalanceModeAutoWhiteBalance);
      });

      it(@"should set continuous white balance", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousWhiteBalance] testRecorder];
        expect(recorder).will.sendValues(@[[RACUnit defaultUnit]]);
        expect(recorder).to.complete();
        expect(videoDevice.whiteBalanceMode).to.
            equal(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance);
      });

      it(@"should lock white balance", ^{
        LLSignalTestRecorder *recorder = [[device setLockedWhiteBalance] testRecorder];
        expect(recorder).will.sendValues(@[[RACUnit defaultUnit]]);
        expect(recorder).to.complete();
        expect(videoDevice.whiteBalanceMode).to.equal(AVCaptureWhiteBalanceModeLocked);
      });

      it(@"should manual white balance", ^{
        AVCaptureWhiteBalanceGains gains({0.1, 0.2, 0.3});
        videoDevice.gainsToReturnFromConversion = gains;
        LLSignalTestRecorder *recorder =
            [[device setLockedWhiteBalanceWithTemperature:0.2 tint:0.4] testRecorder];
        expect(recorder).will.sendValues(@[RACTuplePack(@0.2f, @0.4f)]);
        expect(recorder).to.complete();
        expect(videoDevice.whiteBalanceMode).to.equal(AVCaptureWhiteBalanceModeLocked);
        expect(videoDevice.deviceWhiteBalanceGains).to.equal(gains);
      });

      it(@"should update exposure offset", ^{
        videoDevice.exposureTargetOffset = 3;
        expect(device.exposureOffset).will.equal(3);
        videoDevice.exposureTargetOffset = -1;
        expect(device.exposureOffset).will.equal(-1);
      });
    });

    context(@"require subscription", ^{
      beforeEach(^{
        videoDevice.whiteBalanceModeSupported = YES;
      });

      it(@"should not set white balance", ^{
        [device setSingleWhiteBalance];
        expect(videoDevice.whiteBalanceMode).toNot.equal(AVCaptureWhiteBalanceModeAutoWhiteBalance);
      });

      it(@"should not set continuous white balance", ^{
        [device setContinuousWhiteBalance];
        expect(videoDevice.whiteBalanceMode).toNot.
            equal(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance);
      });

      it(@"should not lock white balance", ^{
        videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
        [device setLockedWhiteBalance];
        expect(videoDevice.whiteBalanceMode).toNot.equal(AVCaptureWhiteBalanceModeLocked);
      });

      it(@"should not manual white balance", ^{
        videoDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
        AVCaptureWhiteBalanceGains gains({0.1, 0.2, 0.3});
        videoDevice.gainsToReturnFromConversion = gains;
        [device setLockedWhiteBalanceWithTemperature:0.2 tint:0.4];
        expect(videoDevice.whiteBalanceMode).toNot.equal(AVCaptureWhiteBalanceModeLocked);
        expect(videoDevice.deviceWhiteBalanceGains).toNot.equal(gains);
      });
    });

    context(@"negative", ^{
      it(@"should return error from white balance", ^{
        LLSignalTestRecorder *recorder = [[device setSingleWhiteBalance] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.whiteBalanceMode).toNot.equal(AVCaptureWhiteBalanceModeAutoWhiteBalance);
      });

      it(@"should return error from continuous white balance", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousWhiteBalance] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.whiteBalanceMode).toNot.
            equal(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance);
      });

      it(@"should return error from lock white balance", ^{
        LLSignalTestRecorder *recorder = [[device setLockedWhiteBalance] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        expect(recorder).will.sendError(expected);
      });

      it(@"should return error from manual white balance", ^{
        AVCaptureWhiteBalanceGains gains({0.1, 0.2, 0.3});
        videoDevice.gainsToReturnFromConversion = gains;
        LLSignalTestRecorder *recorder =
            [[device setLockedWhiteBalanceWithTemperature:0.2 tint:0.4] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.deviceWhiteBalanceGains).toNot.equal(gains);
      });
    });
  });

  context(@"zoom", ^{
    __block CAMFakeAVCaptureDevice *videoDevice;
    __block CAMFakeAVCaptureDeviceFormat *format;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = videoDevice;

      format = [[CAMFakeAVCaptureDeviceFormat alloc] init];
      format.videoMaxZoomFactorToReturn = 4;
      videoDevice.activeFormat = format;
    });

    context(@"positive", ^{
      it(@"should set zoom", ^{
        LLSignalTestRecorder *recorder = [[device setZoom:2.3] testRecorder];
        expect(recorder).will.sendValues(@[@((CGFloat)2.3)]);
        expect(recorder).to.complete();
        expect(videoDevice.videoZoomFactor).to.equal(2.3);
      });

      it(@"should set zoom ramped", ^{
        LLSignalTestRecorder *recorder = [[device setZoom:2.3 rate:0.5] testRecorder];
        expect(recorder).will.sendValues(@[@((CGFloat)2.3)]);
        expect(recorder).to.complete();
        expect(videoDevice.videoZoomFactor).to.equal(2.3);
      });

      it(@"should update zoom factor", ^{
        videoDevice.videoZoomFactor = 3;
        expect(device.zoomFactor).will.equal(3);
        videoDevice.videoZoomFactor = 2.3;
        expect(device.zoomFactor).will.equal(2.3);
      });

      it(@"should update max zoom factor", ^{
        expect(device.maxZoomFactor).to.equal(4);
        format.videoMaxZoomFactorToReturn = 3;
        videoDevice.activeFormat = format;
        expect(device.maxZoomFactor).will.equal(3);
      });

      it(@"should raise when zoom out of bounds", ^{
        expect(^{
          __unused id x = [[device setZoom:5] testRecorder];
        }).will.raise(NSInvalidArgumentException);

        expect(^{
          __unused id x = [[device setZoom:0.2] testRecorder];
        }).will.raise(NSInvalidArgumentException);
      });

      it(@"should update hasZoom", ^{
        expect(device.hasZoom).to.beTruthy();
        format.videoMaxZoomFactorToReturn = 1;
        videoDevice.activeFormat = format;
        expect(device.maxZoomFactor).will.equal(1);
        expect(device.minZoomFactor).will.equal(1);
        expect(device.hasZoom).will.beFalsy();
      });
    });

    context(@"require subscription", ^{
      it(@"should not set zoom", ^{
        [device setZoom:0.3];
        expect(videoDevice.videoZoomFactor).toNot.equal(0.3);
      });

      it(@"should not set zoom ramped", ^{
        [device setZoom:0.3 rate:0.5];
        expect(videoDevice.videoZoomFactor).toNot.equal(0.3);
      });
    });
  });

  context(@"flash", ^{
    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = videoDevice;
    });

    context(@"positive", ^{
      beforeEach(^{
        videoDevice.flashModeSupported = YES;
      });

      it(@"should set flash mode and update currentFlashMode", ^{
        LLSignalTestRecorder *recorder =
            [[device setFlashMode:AVCaptureFlashModeAuto] testRecorder];
        expect(recorder).will.sendValues(@[@(AVCaptureFlashModeAuto)]);
        expect(recorder).to.complete();
        expect(videoDevice.flashMode).to.equal(AVCaptureFlashModeAuto);
        expect(device.currentFlashMode).to.equal(AVCaptureFlashModeAuto);
      });

      it(@"should update hasFlash", ^{
        expect(device.hasFlash).to.beFalsy();
        videoDevice.hasFlash = YES;
        expect(device.hasFlash).will.beTruthy();
      });

      it(@"should update flashWillFire", ^{
        expect(device.flashWillFire).to.beFalsy();
        videoDevice.flashActive = YES;
        expect(device.flashWillFire).will.beTruthy();
      });
    });

    context(@"require subscription", ^{
      beforeEach(^{
        videoDevice.flashModeSupported = YES;
      });

      it(@"should not set flash mode and update currentFlashMode", ^{
        [device setFlashMode:AVCaptureFlashModeAuto];
        expect(videoDevice.flashMode).toNot.equal(AVCaptureFlashModeAuto);
        expect(device.currentFlashMode).toNot.equal(AVCaptureFlashModeAuto);
      });
    });

    context(@"negative", ^{
      it(@"should return error from flash mode", ^{
        LLSignalTestRecorder *recorder =
            [[device setFlashMode:AVCaptureFlashModeAuto] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.flashMode).toNot.equal(AVCaptureFlashModeAuto);
      });
    });
  });

  context(@"torch", ^{
    static const float kTorchLevel = 0.0625;

    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = videoDevice;
    });

    context(@"positive", ^{
      beforeEach(^{
        videoDevice.torchModeSupported = YES;
      });

      it(@"should set torch level", ^{
        LLSignalTestRecorder *recorder = [[device setTorchLevel:kTorchLevel] testRecorder];
        expect(recorder).to.sendValues(@[@(kTorchLevel)]);
        expect(recorder).to.complete();
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOn);
        expect(videoDevice.torchLevel).to.equal(kTorchLevel);
      });

      it(@"should set torch on and off", ^{
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOff);
        [[device setTorchLevel:1] subscribeNext:^(id) {}];
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOn);
        expect(videoDevice.torchLevel).to.equal(1);
        LLSignalTestRecorder *recorder = [[device setTorchLevel:0] testRecorder];
        expect(recorder).to.sendValues(@[@(AVCaptureTorchModeOff)]);
        expect(recorder).to.complete();
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOff);
      });

      it(@"should update hasTorch", ^{
        expect(device.hasTorch).to.beFalsy();
        videoDevice.hasTorch = YES;
        expect(device.hasTorch).to.beTruthy();
      });

      it(@"should rais for illegal level", ^{
        expect(^{
          [[device setTorchLevel:2] testRecorder];
        }).to.raise(NSInvalidArgumentException);

        expect(^{
          [[device setTorchLevel:-0.5] testRecorder];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"require subscription", ^{
      beforeEach(^{
        videoDevice.torchModeSupported = YES;
      });

      it(@"should not set torch level", ^{
        [device setTorchLevel:kTorchLevel];
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeOn);
        expect(videoDevice.torchLevel).to.equal(0);
      });
    });

    context(@"negative", ^{
      it(@"should return error from torch mode", ^{
        LLSignalTestRecorder *recorder = [[device setTorchLevel:0] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
        expect(recorder).to.sendError(expected);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeAuto);
      });

      it(@"should return error from torch level", ^{
        LLSignalTestRecorder *recorder = [[device setTorchLevel:kTorchLevel] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
        expect(recorder).to.sendError(expected);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeAuto);
      });
    });
  });
});

context(@"flip", ^{
  __block id session;
  __block CAMHardwareDevice *device;

  beforeEach(^{
    session = OCMClassMock([CAMHardwareSession class]);
    device = [[CAMHardwareDevice alloc] initWithSession:session];
  });

  it(@"should set new camera", ^{
    OCMStub([session setCamera:OCMOCK_ANY error:[OCMArg setTo:nil]]).andReturn(YES);
    LLSignalTestRecorder *recorder = [[device setCamera:$(CAMDeviceCameraBack)] testRecorder];
    expect(recorder).will.sendValues(@[$(CAMDeviceCameraBack)]);
    expect(recorder).to.complete();
    OCMVerify([session setCamera:$(CAMDeviceCameraBack) error:[OCMArg anyObjectRef]]);
  });

  it(@"should not set new camera", ^{
    OCMReject([session setCamera:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
    [device setCamera:$(CAMDeviceCameraBack)];
  });

  it(@"should return error from setting new camera", ^{
    OCMStub([session setCamera:OCMOCK_ANY error:[OCMArg setTo:kError]]).andReturn(NO);
    LLSignalTestRecorder *recorder = [[device setCamera:$(CAMDeviceCameraBack)] testRecorder];
    expect(recorder).will.sendError(kError);
  });
});

context(@"lock", ^{
  __block CAMHardwareSession *session;
  __block CAMHardwareDevice *device;
  __block CAMFakeAVCaptureDevice *videoDevice;

  beforeEach(^{
    session = [[CAMHardwareSession alloc] initWithPreset:nil session:nil];
    device = [[CAMHardwareDevice alloc] initWithSession:session];
    videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
    session.videoDevice = videoDevice;
  });

  it(@"should lock and unlock device", ^{
    expect([device setLockedFocus]).will.finish();
    expect(videoDevice.didLock).to.beTruthy();
    expect(videoDevice.didUnlock).to.beTruthy();
    expect(videoDevice.didUnlockWhileLocked).to.beTruthy();
  });

  it(@"should return error from locking", ^{
    videoDevice.lockError = kError;
    expect([device setLockedFocus]).will.sendError(kError);
  });
});

context(@"retaining", ^{
  __block CAMHardwareSession *session;

  beforeEach(^{
    session = [[CAMHardwareSession alloc] initWithPreset:nil session:nil];
  });

  it(@"should not retain itself", ^{
    __weak id weakDevice;
    @autoreleasepool {
      CAMHardwareDevice *device = [[CAMHardwareDevice alloc] initWithSession:session];
      weakDevice = device;
    }
    expect(weakDevice).to.beNil();
  });

  typedef RACSignal *(^CAMSignalBlock)(CAMHardwareDevice *device);

  sharedExamplesFor(@"retaining", ^(NSDictionary *data) {
    it(@"should not retain from signal", ^{
      __weak id weakDevice;
      CAMSignalBlock signalBlock = data[@"signalBlock"];
      RACSignal *signal;
      @autoreleasepool {
        CAMHardwareDevice *device = [[CAMHardwareDevice alloc] initWithSession:session];
        weakDevice = device;
        signal = signalBlock(device);
      }
      expect(signal).toNot.beNil();
      expect(weakDevice).to.beNil();
    });
  });

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setPixelFormat:$(CAMPixelFormat420f)];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device stillFramesWithTrigger:[RACSubject subject]];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device videoFrames];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device subjectAreaChanged];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device audioFrames];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setSingleFocusPoint:CGPointZero];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setContinuousFocusPoint:CGPointZero];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setLockedFocus];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setLockedFocusPosition:0];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setSingleExposurePoint:CGPointZero];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setContinuousExposurePoint:CGPointZero];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setLockedExposure];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setExposureCompensation:0];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setSingleWhiteBalance];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setContinuousWhiteBalance];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setLockedWhiteBalance];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setLockedWhiteBalanceWithTemperature:0 tint:0];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setZoom:0];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setZoom:0 rate:0];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setFlashMode:AVCaptureFlashModeOff];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setTorchLevel:0];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setTorchLevel:0.01];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setCamera:$(CAMDeviceCameraBack)];
  }});
});

context(@"multiple setters", ^{
  __block CAMHardwareSession *session;
  __block CAMHardwareDevice *device;
  __block CAMFakeAVCaptureDevice *videoDevice;

  beforeEach(^{
    session = [[CAMHardwareSession alloc] initWithPreset:nil session:nil];
    device = [[CAMHardwareDevice alloc] initWithSession:session];
    videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
    videoDevice.focusModeSupported = YES;
    videoDevice.focusPointOfInterestSupported = YES;
    videoDevice.exposureModeSupported = YES;
    videoDevice.exposurePointOfInterestSupported = YES;
    session.videoDevice = videoDevice;
  });

  it(@"should run multiple setters successfully", ^{
    RACSignal *setFocus = [device setContinuousFocusPoint:CGPointMake(0.3, 0.6)];
    RACSignal *setExposure = [device setSingleExposurePoint:CGPointMake(0.5, 0.5)];
    RACSignal *setBoth = [RACSignal zip:@[setFocus, setExposure]];

    expect(setBoth).will.complete();
    expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeContinuousAutoFocus);
    expect(videoDevice.focusPointOfInterest).to.equal(CGPointMake(0.3, 0.6));
    expect(videoDevice.exposureMode).to.equal(AVCaptureExposureModeAutoExpose);
    expect(videoDevice.exposurePointOfInterest).to.equal(CGPointMake(0.5, 0.5));
  });
});

SpecEnd
