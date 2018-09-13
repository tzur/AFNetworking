// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareDevice.h"

#import <LTEngine/LTMMTexture.h>

#import "CAMAudioFrame.h"
#import "CAMDevicePreset.h"
#import "CAMFakeAVCaptureDevice.h"
#import "CAMFakeAVCaptureDeviceFormat.h"
#import "CAMHardwareSession.h"
#import "CAMTestUtils.h"
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
@property (readwrite, nonatomic, nullable) AVCapturePhotoOutput *photoOutput;
@property (readwrite, nonatomic, nullable) CAMPixelFormat *pixelFormat;
@property (readwrite, nonatomic, nullable) AVCaptureConnection *photoConnection;
@property (readwrite, nonatomic, nullable) AVCaptureDevice *audioDevice;
@property (readwrite, nonatomic, nullable) AVCaptureDeviceInput *audioInput;
@property (readwrite, nonatomic, nullable) AVCaptureAudioDataOutput *audioOutput;
@property (readwrite, nonatomic, nullable) AVCaptureConnection *audioConnection;
@end

/// Protocol for faking the \c AVCapturePhotoOutput class.
@protocol AVCapturePhotoOutput
@property (nonatomic, readonly) BOOL isFlashScene;
@end

/// Make the \c AVCapturePhotoOutput conform to the protocol with the same name.
@interface AVCapturePhotoOutput (Protocol) <AVCapturePhotoOutput>
@end

/// Fake output object to test the effects of different properites.
@interface CAMFakeAVCapturePhotoOutput : NSObject <AVCapturePhotoOutput>
@property (nonatomic, readwrite) BOOL isFlashScene;
@property (nonatomic, readwrite) NSArray<NSNumber *> *supportedFlashModes;
@end

@implementation CAMFakeAVCapturePhotoOutput
@end

SpecBegin(CAMHardwareDevice)

static NSError * const kError = [NSError lt_errorWithCode:123];

context(@"", ^{
  __block CAMHardwareSession *session;
  __block CAMHardwareDevice *device;

  beforeEach(^{
    session = [[CAMHardwareSession alloc] initWithPreset:nil session:nil];
    device = [[CAMHardwareDevice alloc] initWithSession:session
                                           sessionQueue:dispatch_get_main_queue()];
  });

  context(@"video", ^{
    static const CGSize kSize = CGSizeMake(3, 6);

    it(@"should set pixel format for photo output", ^{
      id videoOutput = OCMClassMock([AVCaptureVideoDataOutput class]);
      session.videoOutput = videoOutput;
      id photoOutput = OCMClassMock([AVCapturePhotoOutput class]);
      session.photoOutput = photoOutput;

      CAMPixelFormat *pixelFormat = $(CAMPixelFormat420f);
      OCMExpect([videoOutput setVideoSettings:pixelFormat.videoSettings]);

      LLSignalTestRecorder *recorder = [[device setPixelFormat:pixelFormat] testRecorder];
      OCMVerifyAllWithDelay(videoOutput, 1);
      expect(session.pixelFormat).to.equal(pixelFormat);
      expect(recorder).to.sendValues(@[pixelFormat]);
      expect(recorder).to.complete();
    });

    it(@"should not set pixel format for photo output without subscribing", ^{
      id videoOutput = OCMClassMock([AVCaptureVideoDataOutput class]);
      session.videoOutput = videoOutput;
      id photoOutput = OCMClassMock([AVCapturePhotoOutput class]);
      session.photoOutput = photoOutput;

      OCMReject([videoOutput setVideoSettings:OCMOCK_ANY]);
      OCMReject([session setPixelFormat:OCMOCK_ANY]);
      [device setPixelFormat:$(CAMPixelFormat420f)];
    });

    context(@"video frames", ^{
      static const CFStringRef kOrientationKey = (__bridge CFStringRef)@"Orientation";

      __block lt::Ref<CMSampleBufferRef> sampleBuffer;
      __block lt::Ref<CMSampleBufferRef> sampleBuffer2;
      __block id output;
      __block id connection;
      __block LLSignalTestRecorder *recorder;

      beforeEach(^{
        sampleBuffer = lt::Ref<CMSampleBufferRef>(CAMCreateImageSampleBuffer($(CAMPixelFormatBGRA),
                                                                             kSize));
        sampleBuffer2 = lt::Ref<CMSampleBufferRef>(CAMCreateImageSampleBuffer($(CAMPixelFormatBGRA),
                                                                              kSize));

        output = OCMClassMock([AVCaptureVideoDataOutput class]);
        connection = OCMClassMock([AVCaptureConnection class]);
        recorder = [[device videoFrames] testRecorder];
      });

      it(@"should send video frames", ^{
        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect(recorder).to.sendValuesWithCount(1);
        expect(recorder).to.matchValue(0, ^BOOL(id<CAMVideoFrame> frame) {
          return [frame sampleBuffer].get() == sampleBuffer.get();
        });

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer2.get()
               fromConnection:connection];
        expect(recorder).to.sendValuesWithCount(2);
        expect(recorder).to.matchValue(1, ^BOOL(id<CAMVideoFrame> frame) {
          return [frame sampleBuffer].get() == sampleBuffer2.get();
        });

        expect(recorder).toNot.complete();
      });

      it(@"should send video frames errors", ^{
        CMSetAttachment(sampleBuffer.get(), kCMSampleBufferAttachmentKey_DroppedFrameReason,
                        (__bridge CFStringRef)@"A", kCMAttachmentMode_ShouldPropagate);
        CMSetAttachment(sampleBuffer2.get(), kCMSampleBufferAttachmentKey_DroppedFrameReason,
                        (__bridge CFStringRef)@"B", kCMAttachmentMode_ShouldPropagate);

        LLSignalTestRecorder *errorsRecorder = [[device videoFramesErrors] testRecorder];

        [device captureOutput:output didDropSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect(errorsRecorder).to.sendValuesWithCount(1);
        expect(errorsRecorder).to.sendValue(0, [NSError lt_errorWithCode:CAMErrorCodeDroppedFrame
                                                             description:@"A"]);

        [device captureOutput:output didDropSampleBuffer:sampleBuffer2.get()
               fromConnection:connection];
        expect(errorsRecorder).to.sendValuesWithCount(2);
        expect(errorsRecorder).to.sendValue(1, [NSError lt_errorWithCode:CAMErrorCodeDroppedFrame
                                                             description:@"B"]);

        expect(errorsRecorder).toNot.complete();
      });

      it(@"should send video frames and errors without completing either signal", ^{
        CMSetAttachment(sampleBuffer2.get(), kCMSampleBufferAttachmentKey_DroppedFrameReason,
                        (__bridge CFStringRef)@"B", kCMAttachmentMode_ShouldPropagate);

        LLSignalTestRecorder *errorsRecorder = [[device videoFramesErrors] testRecorder];

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect(recorder).to.sendValuesWithCount(1);
        expect(recorder).to.matchValue(0, ^BOOL(id<CAMVideoFrame> frame) {
          return [frame sampleBuffer].get() == sampleBuffer.get();
        });

        [device captureOutput:output didDropSampleBuffer:sampleBuffer2.get()
               fromConnection:connection];
        expect(errorsRecorder).to.sendValuesWithCount(1);
        expect(errorsRecorder).to.sendValue(0, [NSError lt_errorWithCode:CAMErrorCodeDroppedFrame
                                                             description:@"B"]);

        expect(recorder).toNot.complete();
        expect(errorsRecorder).toNot.complete();
      });

      it(@"should not change orientation when orientations are equal and not mirrored", ^{
        CMSetAttachment(sampleBuffer.get(), kOrientationKey, (__bridge CFNumberRef)@3,
                        kCMAttachmentMode_ShouldPropagate);

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect([recorder.values[0] exifOrientation]).to.equal(3);
      });

      it(@"should rotate orientation when orientations are not equal", ^{
        CMSetAttachment(sampleBuffer.get(), kOrientationKey, (__bridge CFNumberRef)@3,
                        kCMAttachmentMode_ShouldPropagate);
        device.interfaceOrientation = UIInterfaceOrientationPortrait;
        device.gravityOrientation = UIInterfaceOrientationLandscapeLeft;

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect([recorder.values[0] exifOrientation]).to.equal(8);
      });

      it(@"should mirror orientation when connection is mirrored", ^{
        CMSetAttachment(sampleBuffer.get(), kOrientationKey, (__bridge CFNumberRef)@3,
                        kCMAttachmentMode_ShouldPropagate);
        id videoConnection = OCMClassMock([AVCaptureConnection class]);
        OCMStub([videoConnection isVideoMirrored]).andReturn(YES);
        session.videoConnection = videoConnection;

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect([recorder.values[0] exifOrientation]).to.equal(4);
      });

      it(@"should rotate and mirror orientation when orientations are not equal and connection is "
          "mirrored", ^{
        CMSetAttachment(sampleBuffer.get(), kOrientationKey, (__bridge CFNumberRef)@3,
                        kCMAttachmentMode_ShouldPropagate);
        device.interfaceOrientation = UIInterfaceOrientationPortrait;
        device.gravityOrientation = UIInterfaceOrientationLandscapeLeft;
        id videoConnection = OCMClassMock([AVCaptureConnection class]);
        OCMStub([videoConnection isVideoMirrored]).andReturn(YES);
        session.videoConnection = videoConnection;

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect([recorder.values[0] exifOrientation]).to.equal(7);
      });

      it(@"should not change orientation when it doesn't exist", ^{
        device.interfaceOrientation = UIInterfaceOrientationPortrait;
        device.gravityOrientation = UIInterfaceOrientationLandscapeLeft;

        [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
               fromConnection:connection];
        expect([recorder.values[0] propagatableMetadata][@"Orientation"]).to.beNil();
      });
    });

    it(@"should update interface orientation correctly", ^{
      id previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      id previewConnection = OCMClassMock([AVCaptureConnection class]);
      OCMStub([previewLayer connection]).andReturn(previewConnection);
      id videoConnection = OCMClassMock([AVCaptureConnection class]);
      id photoConnection = OCMClassMock([AVCaptureConnection class]);
      session.previewLayer = previewLayer;
      session.videoConnection = videoConnection;
      session.photoConnection = photoConnection;

      UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationLandscapeRight;
      AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)interfaceOrientation;

      [[[photoConnection reject] ignoringNonObjectArgs] setVideoOrientation:videoOrientation];

      device.interfaceOrientation = interfaceOrientation;

      expect(device.interfaceOrientation).to.equal(interfaceOrientation);
      OCMVerify([previewConnection setVideoOrientation:videoOrientation]);
      OCMVerify([videoConnection setVideoOrientation:videoOrientation]);
    });

    it(@"should update gravity orientation correctly", ^{
      id previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      id previewConnection = OCMClassMock([AVCaptureConnection class]);
      OCMStub([previewLayer connection]).andReturn(previewConnection);
      id videoConnection = OCMClassMock([AVCaptureConnection class]);
      id photoConnection = OCMClassMock([AVCaptureConnection class]);
      session.previewLayer = previewLayer;
      session.videoConnection = videoConnection;
      session.photoConnection = photoConnection;

      UIInterfaceOrientation gravityOrientation = UIInterfaceOrientationLandscapeLeft;
      AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)gravityOrientation;

      [[[previewConnection reject] ignoringNonObjectArgs] setVideoOrientation:videoOrientation];
      [[[videoConnection reject] ignoringNonObjectArgs] setVideoOrientation:videoOrientation];

      device.gravityOrientation = gravityOrientation;

      expect(device.gravityOrientation).to.equal(gravityOrientation);
      OCMVerify([photoConnection setVideoOrientation:videoOrientation]);
    });

    it(@"should not update video orientation to Unknown", ^{
      id previewLayer = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      id previewConnection = OCMClassMock([AVCaptureConnection class]);
      OCMStub([previewLayer connection]).andReturn(previewConnection);
      id videoConnection = OCMClassMock([AVCaptureConnection class]);
      id photoConnection = OCMClassMock([AVCaptureConnection class]);
      session.previewLayer = previewLayer;
      session.videoConnection = videoConnection;
      session.photoConnection = photoConnection;

      device.interfaceOrientation = UIInterfaceOrientationLandscapeRight;

      [[[photoConnection reject] ignoringNonObjectArgs]
          setVideoOrientation:(AVCaptureVideoOrientation)0];
      [[[previewConnection reject] ignoringNonObjectArgs]
          setVideoOrientation:(AVCaptureVideoOrientation)0];
      [[[videoConnection reject] ignoringNonObjectArgs]
          setVideoOrientation:(AVCaptureVideoOrientation)0];

      device.interfaceOrientation = UIInterfaceOrientationUnknown;
      expect(device.interfaceOrientation).to.equal(UIInterfaceOrientationUnknown);

      device.gravityOrientation = UIInterfaceOrientationUnknown;
      expect(device.gravityOrientation).to.equal(UIInterfaceOrientationUnknown);
    });

    it(@"should send subject changed updates", ^{
      LLSignalTestRecorder *recorder = [device.subjectAreaChanged testRecorder];
      [[NSNotificationCenter defaultCenter]
          postNotificationName:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
      expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
      expect(recorder).toNot.complete();
    });
  });

  context(@"audio", ^{
    it(@"should send audio frame", ^{
      lt::Ref<CMSampleBufferRef> sampleBuffer = CAMCreateEmptySampleBuffer();
      lt::Ref<CMSampleBufferRef> otherSampleBuffer = CAMCreateEmptySampleBuffer();

      id output = OCMClassMock([AVCaptureAudioDataOutput class]);
      id connection = OCMClassMock([AVCaptureConnection class]);

      LLSignalTestRecorder *recorder = [[device audioFrames] testRecorder];
      [device captureOutput:output didOutputSampleBuffer:sampleBuffer.get()
             fromConnection:connection];
      expect(recorder).to.matchValue(0, ^BOOL(id<CAMAudioFrame> frame) {
        return [frame sampleBuffer].get() == sampleBuffer.get();
      });
      [device captureOutput:output didOutputSampleBuffer:otherSampleBuffer.get()
             fromConnection:connection];
      expect(recorder).to.matchValue(1, ^BOOL(id<CAMAudioFrame> frame) {
        return [frame sampleBuffer].get() == otherSampleBuffer.get();
      });
      expect(recorder).toNot.complete();
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
  });

  context(@"focus", ^{
    static const CGPoint kPoint = CGPointMake(0.2, 0.3);

    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = (id)videoDevice;
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
        expect(videoDevice.focusPointOfInterestDuringModeSet).to.equal(kPoint);
      });

      it(@"should set continuous focus", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousFocusPoint:kPoint] testRecorder];
        expect(recorder).will.sendValues(@[$(kPoint)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeContinuousAutoFocus);
        expect(videoDevice.focusPointOfInterest).to.equal(kPoint);
        expect(videoDevice.focusPointOfInterestDuringModeSet).to.equal(kPoint);
      });

      it(@"should lock focus", ^{
        LLSignalTestRecorder *recorder = [[device setLockedFocus] testRecorder];
        expect(recorder).will.sendValues(@[$(CGPointNull)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeLocked);
        expect(videoDevice.focusPointOfInterest).toNot.equal(CGPointNull);
      });

      it(@"should set manual focus", ^{
        LLSignalTestRecorder *recorder = [[device setLockedFocusPosition:0.25] testRecorder];
        expect(recorder).will.sendValues(@[@(0.25)]);
        expect(recorder).to.complete();
        expect(videoDevice.focusMode).to.equal(AVCaptureFocusModeLocked);
        expect(videoDevice.lensPosition).to.equal(0.25);
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
        [device setLockedFocusPosition:0.25];
        expect(videoDevice.focusMode).toNot.equal(AVCaptureFocusModeLocked);
        expect(videoDevice.lensPosition).toNot.equal(0.25);
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
        LLSignalTestRecorder *recorder = [[device setLockedFocusPosition:0.25] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.lensPosition).toNot.equal(0.25);
      });

      it(@"should return error when lens position is invalid", ^{
        videoDevice.focusModeSupported = YES;

        LLSignalTestRecorder *highRecorder = [[device setLockedFocusPosition:2] testRecorder];
        expect(highRecorder).will.error();
        expect(highRecorder.error.code).to.equal(CAMErrorCodeFocusSettingUnsupported);

        LLSignalTestRecorder *lowRecorder = [[device setLockedFocusPosition:-0.5] testRecorder];
        expect(lowRecorder).will.error();
        expect(lowRecorder.error.code).to.equal(CAMErrorCodeFocusSettingUnsupported);

        LLSignalTestRecorder *nanRecorder = [[device setLockedFocusPosition:NAN] testRecorder];
        expect(nanRecorder).will.error();
        expect(nanRecorder.error.code).to.equal(CAMErrorCodeFocusSettingUnsupported);
      });
    });
  });

  context(@"exposure", ^{
    static const CGPoint kPoint = CGPointMake(0.2, 0.3);

    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      CAMFakeAVCaptureDeviceFormat *deviceFormat = [[CAMFakeAVCaptureDeviceFormat alloc] init];
      deviceFormat.minISOToReturn = 10;
      deviceFormat.maxISOToReturn = 100;
      deviceFormat.minExposureDurationToReturn = CMTimeMakeWithSeconds(0.001, 1000000);
      deviceFormat.maxExposureDurationToReturn = CMTimeMakeWithSeconds(0.1, 1000000);

      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      videoDevice.activeFormat = (id)deviceFormat;

      session.videoDevice = (id)videoDevice;
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
        expect(videoDevice.exposurePointOfInterestDuringModeSet).to.equal(kPoint);
      });

      it(@"should set continuous exposure", ^{
        LLSignalTestRecorder *recorder = [[device setContinuousExposurePoint:kPoint] testRecorder];
        expect(recorder).will.sendValues(@[$(kPoint)]);
        expect(recorder).to.complete();
        expect(videoDevice.exposureMode).to.equal(AVCaptureExposureModeContinuousAutoExposure);
        expect(videoDevice.exposurePointOfInterest).to.equal(kPoint);
        expect(videoDevice.exposurePointOfInterestDuringModeSet).to.equal(kPoint);
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
        LLSignalTestRecorder *recorder = [[device setExposureCompensation:0.25] testRecorder];
        expect(recorder).will.sendValues(@[@0.25]);
        expect(recorder).to.complete();
        expect(videoDevice.exposureTargetBias).to.equal(0.25);
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

      it(@"should return correct min exposure duration", ^{
        expect(device.minExposureDuration).will.equal(0.001);
      });

      it(@"should return correct max exposure duration", ^{
        expect(device.maxExposureDuration).will.equal(0.1);
      });

      it(@"should return correct min ISO", ^{
        expect(device.minISO).will.equal(10.0);
      });

      it(@"should return correct max ISO", ^{
        expect(device.maxISO).will.equal(100.0);
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
        [device setExposureCompensation:0.25];
        expect(videoDevice.exposureTargetBias).toNot.equal(0.25);
      });

      it(@"should update exposure offset", ^{
        videoDevice.exposureTargetOffset = 3;
        expect(device.exposureOffset).will.equal(3);
        videoDevice.exposureTargetOffset = -1;
        expect(device.exposureOffset).will.equal(-1);
      });

      it(@"should get correct exposure duration", ^{
        waitUntilTimeout(3, ^(DoneCallback done) {
          [videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(0.01, 1000000)
                                                     ISO:AVCaptureISOCurrent
                                       completionHandler:^(CMTime __unused syncTime) {
                                         done();
                                       }];
        });
        expect(device.exposureDuration).to.equal(0.01);

        waitUntilTimeout(3, ^(DoneCallback done) {
          [videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(0.02, 1000000)
                                                     ISO:AVCaptureISOCurrent
                                       completionHandler:^(CMTime __unused syncTime) {
                                         done();
                                       }];
        });
        expect(device.exposureDuration).to.equal(0.02);
      });

      it(@"should set correct exposure duration", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithDuration:0.01] testRecorder];
        expect(recorder).will.sendValues(@[@0.01]);
        expect(recorder).to.complete();
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).to.equal(0.01);
      });

      it(@"should get correct ISO", ^{
        waitUntilTimeout(3, ^(DoneCallback done) {
          [videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent
                                                     ISO:70
                                       completionHandler:^(CMTime __unused syncTime) {
                                         done();
                                       }];
        });
        expect(device.ISO).to.equal(70);

        waitUntilTimeout(3, ^(DoneCallback done) {
          [videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent
                                                     ISO:80
                                       completionHandler:^(CMTime __unused syncTime) {
                                         done();
                                       }];
        });
        expect(device.ISO).to.equal(80);
      });

      it(@"should set correct ISO", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithISO:80] testRecorder];
        expect(recorder).will.sendValues(@[@80]);
        expect(recorder).to.complete();
        expect(videoDevice.ISO).to.equal(80);
      });

      it(@"should set correct exposure duration and ISO", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithDuration:0.03 andISO:90]
                                          testRecorder];
        expect(recorder).will.sendValues(@[RACTuplePack(@0.03, @90)]);
        expect(recorder).to.complete();
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).to.equal(0.03);
        expect(videoDevice.ISO).to.equal(90);
      });
    });

    context(@"require subscription", ^{
      it(@"should not set correct exposure duration", ^{
        [device setManualExposureWithDuration:0.01];
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).toNot.equal(0.01);
      });

      it(@"should not set correct ISO", ^{
        [device setManualExposureWithISO:80];
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).toNot.equal(80);
      });

      it(@"should not set correct exposure duration and ISO", ^{
        [device setManualExposureWithDuration:0.03 andISO:90];
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).toNot.equal(0.03);
        expect(videoDevice.ISO).toNot.equal(90);
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

      it(@"should return error when exposure compensation is invalid", ^{
        videoDevice.minExposureTargetBias = 2;
        videoDevice.maxExposureTargetBias = 3;

        LLSignalTestRecorder *highRecorder = [[device setExposureCompensation:3.1] testRecorder];
        expect(highRecorder).will.error();
        expect(highRecorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);

        LLSignalTestRecorder *lowRecorder = [[device setExposureCompensation:1.9] testRecorder];
        expect(lowRecorder).will.error();
        expect(lowRecorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);

        LLSignalTestRecorder *nanRecorder = [[device setExposureCompensation:NAN] testRecorder];
        expect(nanRecorder).will.error();
        expect(nanRecorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);
      });

      it(@"should return error when attempting to set exposure duration too small", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithDuration:0.0001]
                                          testRecorder];
        expect(recorder).will.error();
        expect(recorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).toNot.equal(0.0001);
      });

      it(@"should return error when attempting to set exposure duration too large", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithDuration:10.0]
                                          testRecorder];
        expect(recorder).will.error();
        expect(recorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);
        expect(CMTimeGetSeconds(videoDevice.exposureDuration)).toNot.equal(10.0);
      });

      it(@"should return error when attempting to set ISO too small", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithISO:1.0]
                                          testRecorder];
        expect(recorder).will.error();
        expect(recorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);
        expect(videoDevice.ISO).toNot.equal(1.0);
      });

      it(@"should return error when attempting to set ISO too large", ^{
        LLSignalTestRecorder *recorder = [[device setManualExposureWithDuration:1000.0]
                                          testRecorder];
        expect(recorder).will.error();
        expect(recorder.error.code).to.equal(CAMErrorCodeExposureSettingUnsupported);
        expect(videoDevice.ISO).toNot.equal(1000.0);
      });
    });
  });

  context(@"white balance", ^{
    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = (id)videoDevice;
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
        videoDevice.maxWhiteBalanceGain = 5;
        AVCaptureWhiteBalanceGains gains({1.1, 1.2, 1.3});
        videoDevice.gainsToReturnFromConversion = gains;

        LLSignalTestRecorder *recorder =
            [[device setLockedWhiteBalanceWithTemperature:0.25 tint:0.5] testRecorder];
        expect(recorder).will.sendValues(@[RACTuplePack(@0.25, @0.5)]);
        expect(recorder).to.complete();
        expect(videoDevice.whiteBalanceMode).to.equal(AVCaptureWhiteBalanceModeLocked);
        expect(videoDevice.deviceWhiteBalanceGains).to.equal(gains);
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
        [device setLockedWhiteBalanceWithTemperature:0.25 tint:0.5];
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
            [[device setLockedWhiteBalanceWithTemperature:0.25 tint:0.5] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(videoDevice.deviceWhiteBalanceGains).toNot.equal(gains);
      });

      it(@"should return error when temperature and tint are invalid", ^{
        videoDevice.whiteBalanceModeSupported = YES;
        videoDevice.maxWhiteBalanceGain = 2;
        AVCaptureWhiteBalanceGains highGains({3.1, 1.2, 1.3});
        AVCaptureWhiteBalanceGains lowGains({1.1, 0.5, 1.3});
        AVCaptureWhiteBalanceGains nanGains({1.1, 1.2, NAN});

        videoDevice.gainsToReturnFromConversion = highGains;
        LLSignalTestRecorder *highRecorder =
            [[device setLockedWhiteBalanceWithTemperature:3000 tint:0] testRecorder];
        expect(highRecorder).will.error();
        expect(highRecorder.error.code).to.equal(CAMErrorCodeWhiteBalanceSettingUnsupported);

        videoDevice.gainsToReturnFromConversion = lowGains;
        LLSignalTestRecorder *lowRecorder =
            [[device setLockedWhiteBalanceWithTemperature:3000 tint:0] testRecorder];
        expect(lowRecorder).will.error();
        expect(lowRecorder.error.code).to.equal(CAMErrorCodeWhiteBalanceSettingUnsupported);

        videoDevice.gainsToReturnFromConversion = nanGains;
        LLSignalTestRecorder *nanRecorder =
            [[device setLockedWhiteBalanceWithTemperature:3000 tint:0] testRecorder];
        expect(nanRecorder).will.error();
        expect(nanRecorder.error.code).to.equal(CAMErrorCodeWhiteBalanceSettingUnsupported);
      });
    });
  });

  context(@"zoom", ^{
    __block CAMFakeAVCaptureDevice *videoDevice;
    __block CAMFakeAVCaptureDeviceFormat *format;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = (id)videoDevice;

      format = [[CAMFakeAVCaptureDeviceFormat alloc] init];
      format.videoMaxZoomFactorToReturn = 4;
      videoDevice.activeFormat = (id)format;
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
        videoDevice.activeFormat = (id)format;
        expect(device.maxZoomFactor).will.equal(3);
      });

      it(@"should update hasZoom", ^{
        expect(device.hasZoom).to.beTruthy();
        format.videoMaxZoomFactorToReturn = 1;
        videoDevice.activeFormat = (id)format;
        expect(device.maxZoomFactor).will.equal(1);
        expect(device.minZoomFactor).will.equal(1);
        expect(device.hasZoom).will.beFalsy();
      });
    });

    context(@"require subscription", ^{
      it(@"should not set zoom", ^{
        [device setZoom:0.25];
        expect(videoDevice.videoZoomFactor).toNot.equal(0.25);
      });

      it(@"should not set zoom ramped", ^{
        [device setZoom:0.25 rate:0.5];
        expect(videoDevice.videoZoomFactor).toNot.equal(0.25);
      });
    });

    context(@"negative", ^{
      it(@"should return error when zoom value is invalid", ^{
        LLSignalTestRecorder *highRecorder = [[device setZoom:5] testRecorder];
        expect(highRecorder).will.error();
        expect(highRecorder.error.code).to.equal(CAMErrorCodeZoomSettingUnsupported);

        LLSignalTestRecorder *lowRecorder = [[device setZoom:0.2] testRecorder];
        expect(lowRecorder).will.error();
        expect(lowRecorder.error.code).to.equal(CAMErrorCodeZoomSettingUnsupported);

        LLSignalTestRecorder *nanRecorder = [[device setZoom:NAN] testRecorder];
        expect(nanRecorder).will.error();
        expect(nanRecorder.error.code).to.equal(CAMErrorCodeZoomSettingUnsupported);
      });
    });
  });

  context(@"flash", ^{
    __block CAMFakeAVCaptureDevice *videoDevice;
    __block CAMFakeAVCapturePhotoOutput *photoOutput;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      photoOutput = [[CAMFakeAVCapturePhotoOutput alloc] init];
      session.videoDevice = (id)videoDevice;
      session.photoOutput = (id)photoOutput;
    });

    context(@"positive", ^{
      beforeEach(^{
        photoOutput.supportedFlashModes = @[@(AVCaptureFlashModeAuto)];
      });

      it(@"should set flash mode and update currentFlashMode", ^{
        LLSignalTestRecorder *recorder =
            [[device setFlashMode:AVCaptureFlashModeAuto] testRecorder];
        expect(recorder).will.sendValues(@[@(AVCaptureFlashModeAuto)]);
        expect(recorder).to.complete();
        expect(device.currentFlashMode).to.equal(AVCaptureFlashModeAuto);
      });

      it(@"should update hasFlash", ^{
        expect(device.hasFlash).to.beFalsy();
        videoDevice.hasFlash = YES;
        expect(device.hasFlash).will.beTruthy();
      });

      it(@"should update flashWillFire", ^{
        expect(device.flashWillFire).to.beFalsy();
        photoOutput.isFlashScene = YES;
        expect(device.flashWillFire).will.beTruthy();
      });
    });

    context(@"require subscription", ^{
      __block id photoOutput;

      beforeEach(^{
        photoOutput = OCMClassMock([AVCapturePhotoOutput class]);
        session.photoOutput = photoOutput;
      });

      it(@"should not set flash mode and update currentFlashMode", ^{
        [device setFlashMode:AVCaptureFlashModeAuto];
        expect(device.currentFlashMode).toNot.equal(AVCaptureFlashModeAuto);
      });
    });

    context(@"negative", ^{
      it(@"should return error from flash mode", ^{
        LLSignalTestRecorder *recorder =
            [[device setFlashMode:AVCaptureFlashModeAuto] testRecorder];
        NSError *expected = [NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported];
        expect(recorder).will.sendError(expected);
        expect(device.currentFlashMode).toNot.equal(AVCaptureFlashModeAuto);
      });
    });
  });

  context(@"torch", ^{
    static const float kTorchLevel = 0.0625;

    __block CAMFakeAVCaptureDevice *videoDevice;

    beforeEach(^{
      videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
      session.videoDevice = (id)videoDevice;
    });

    context(@"positive", ^{
      beforeEach(^{
        videoDevice.torchModeSupported = YES;
      });

      it(@"should set torch level", ^{
        LLSignalTestRecorder *recorder = [[device setTorchLevel:kTorchLevel] testRecorder];
        expect(recorder).will.sendValues(@[@(kTorchLevel)]);
        expect(recorder).to.complete();
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOn);
        expect(videoDevice.torchLevel).to.equal(kTorchLevel);
      });

      it(@"should set torch mode", ^{
        LLSignalTestRecorder *recorder = [[device setTorchMode:AVCaptureTorchModeAuto]
                                          testRecorder];
        expect(recorder).will.sendValues(@[@(AVCaptureTorchModeAuto)]);
        expect(recorder).to.complete();
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeAuto);
      });

      it(@"should set torch on and off", ^{
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOff);
        LLSignalTestRecorder *onRecorder = [[device setTorchLevel:1] testRecorder];
        expect(onRecorder).will.sendValues(@[@1]);
        expect(onRecorder).to.complete();
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOn);

        LLSignalTestRecorder *offRecorder = [[device setTorchLevel:0] testRecorder];
        expect(offRecorder).will.sendValues(@[@0]);
        expect(offRecorder).to.complete();
        expect(videoDevice.torchMode).to.equal(AVCaptureTorchModeOff);
      });

      it(@"should update hasTorch", ^{
        expect(device.hasTorch).to.beFalsy();
        videoDevice.hasTorch = YES;
        expect(device.hasTorch).to.beTruthy();
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

      it(@"should not set torch mode", ^{
        [device setTorchMode:AVCaptureTorchModeOn];
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeOn);
      });
    });

    context(@"negative", ^{
      static const auto kModeNotSupportedError =
          [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];

      beforeEach(^{
        auto defaultTorchMode = AVCaptureTorchModeOff;
        videoDevice.torchMode = defaultTorchMode;
      });

      it(@"should return error when torch level 0 is unsupported", ^{
        videoDevice.torchMode = AVCaptureTorchModeAuto;
        LLSignalTestRecorder *recorder = [[device setTorchLevel:0] testRecorder];
        expect(recorder).will.sendError(kModeNotSupportedError);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeOff);
      });

      it(@"should return error when torch mode off is unsupported", ^{
        videoDevice.torchMode = AVCaptureTorchModeAuto;
        LLSignalTestRecorder *recorder = [[device setTorchMode:AVCaptureTorchModeOff]
                                          testRecorder];
        expect(recorder).will.sendError(kModeNotSupportedError);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeOff);
      });

      it(@"should return error when torch level greater than 0 in unsupported", ^{
        LLSignalTestRecorder *recorder = [[device setTorchLevel:kTorchLevel] testRecorder];
        expect(recorder).will.sendError(kModeNotSupportedError);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeOn);
      });

      it(@"should return error when torch mode on is unsupported", ^{
        LLSignalTestRecorder *recorder = [[device setTorchMode:AVCaptureTorchModeOn]
                                          testRecorder];
        expect(recorder).will.sendError(kModeNotSupportedError);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeOn);
      });

      it(@"should return error when torch mode auto is unsupported", ^{
        LLSignalTestRecorder *recorder = [[device setTorchMode:AVCaptureTorchModeAuto]
                                          testRecorder];
        expect(recorder).will.sendError(kModeNotSupportedError);
        expect(videoDevice.torchMode).toNot.equal(AVCaptureTorchModeAuto);
      });

      it(@"should return error when torch level is invalid", ^{
        videoDevice.torchModeSupported = YES;

        LLSignalTestRecorder *highRecorder = [[device setTorchLevel:2] testRecorder];
        expect(highRecorder).will.error();
        expect(highRecorder.error.code).to.equal(CAMErrorCodeTorchModeSettingUnsupported);

        LLSignalTestRecorder *lowRecorder = [[device setTorchLevel:-0.5] testRecorder];
        expect(lowRecorder).will.error();
        expect(lowRecorder.error.code).to.equal(CAMErrorCodeTorchModeSettingUnsupported);

        LLSignalTestRecorder *nanRecorder = [[device setTorchLevel:NAN] testRecorder];
        expect(nanRecorder).will.error();
        expect(nanRecorder.error.code).to.equal(CAMErrorCodeTorchModeSettingUnsupported);
      });
    });
  });
});

context(@"flip", ^{
  __block id session;
  __block CAMHardwareDevice *device;

  beforeEach(^{
    session = OCMClassMock([CAMHardwareSession class]);
    device = [[CAMHardwareDevice alloc] initWithSession:session
                                           sessionQueue:dispatch_get_main_queue()];
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
    device = [[CAMHardwareDevice alloc] initWithSession:session
                                           sessionQueue:dispatch_get_main_queue()];
    videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
    session.videoDevice = (id)videoDevice;
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
      CAMHardwareDevice *device =
          [[CAMHardwareDevice alloc] initWithSession:session
                                        sessionQueue:dispatch_get_main_queue()];
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
        CAMHardwareDevice *device =
            [[CAMHardwareDevice alloc] initWithSession:session
                                          sessionQueue:dispatch_get_main_queue()];
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
    return [device setTorchMode:AVCaptureTorchModeOff];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setTorchLevel:0.01];
  }});

  itShouldBehaveLike(@"retaining", @{@"signalBlock": ^RACSignal *(CAMHardwareDevice *device) {
    return [device setTorchMode:AVCaptureTorchModeOn];
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
    device = [[CAMHardwareDevice alloc] initWithSession:session
                                           sessionQueue:dispatch_get_main_queue()];
    videoDevice = [[CAMFakeAVCaptureDevice alloc] init];
    videoDevice.focusModeSupported = YES;
    videoDevice.focusPointOfInterestSupported = YES;
    videoDevice.exposureModeSupported = YES;
    videoDevice.exposurePointOfInterestSupported = YES;
    session.videoDevice = (id)videoDevice;
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
