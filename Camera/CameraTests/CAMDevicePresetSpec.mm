// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMDevicePreset.h"

#import "CAMFormatStrategy.h"

SpecBegin(CAMDevicePreset)

context(@"pixel format", ^{
  it(@"should return correct video settings dictionary", ^{
    CAMPixelFormat *pixelFormat = $(CAMPixelFormat420f);
    NSDictionary *videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:
                                    @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    expect(pixelFormat.videoSettings).to.equal(videoSettings);
  });
});

context(@"physical device", ^{
  __block id classMock;
  __block AVCaptureDevice *frontCamera;
  __block AVCaptureDevice *backCamera;
  __block AVCaptureDevice *otherCamera;
  __block AVCaptureDevice *notCamera;

  beforeEach(^{
    frontCamera = OCMClassMock([AVCaptureDevice class]);
    OCMStub([(AVCaptureDevice *)frontCamera position]).andReturn(AVCaptureDevicePositionFront);
    backCamera = OCMClassMock([AVCaptureDevice class]);
    OCMStub([(AVCaptureDevice *)backCamera position]).andReturn(AVCaptureDevicePositionBack);
    otherCamera = OCMClassMock([AVCaptureDevice class]);
    OCMStub([(AVCaptureDevice *)otherCamera position])
        .andReturn(AVCaptureDevicePositionUnspecified);
    notCamera = OCMClassMock([AVCaptureDevice class]);

    classMock = OCMClassMock([AVCaptureDevice class]);

    NSArray *notCameras = @[notCamera];
    OCMStub([classMock devicesWithMediaType:AVMediaTypeAudio]).andReturn(notCameras);
  });

  afterEach(^{
    [classMock stopMocking];
  });

  context(@"positive flows", ^{
    beforeEach(^{
      NSArray *cameras = @[frontCamera, backCamera, otherCamera];
      OCMStub([classMock devicesWithMediaType:AVMediaTypeVideo]).andReturn(cameras);
    });

    it(@"should return correct physical device", ^{
      expect($(CAMDeviceCameraBack).device).to.equal(backCamera);
      expect($(CAMDeviceCameraFront).device).to.equal(frontCamera);
    });

    it(@"should return correct position", ^{
      expect($(CAMDeviceCameraBack).position).to.equal(AVCaptureDevicePositionBack);
      expect($(CAMDeviceCameraFront).position).to.equal(AVCaptureDevicePositionFront);
    });
  });

  context(@"negative flows", ^{
    beforeEach(^{
      NSArray *cameras = @[frontCamera, otherCamera];
      OCMStub([classMock devicesWithMediaType:AVMediaTypeVideo]).andReturn(cameras);
    });

    it(@"should return nil device for non-existing camera", ^{
      expect($(CAMDeviceCameraBack).device).to.beNil();
    });
  });
});

context(@"preset object", ^{
  __block dispatch_queue_t queue;

  beforeEach(^{
    queue = dispatch_queue_create("test queue", DISPATCH_QUEUE_SERIAL);
  });

  it(@"should return set values", ^{
    id<CAMFormatStrategy> formatStrategy = OCMProtocolMock(@protocol(CAMFormatStrategy));
    CAMDevicePreset *preset = [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormatBGRA)
                                                                    camera:$(CAMDeviceCameraFront)
                                                               enableAudio:YES
                                                            formatStrategy:formatStrategy
                                                               outputQueue:queue];

    expect(preset.pixelFormat).to.equal($(CAMPixelFormatBGRA));
    expect(preset.camera).to.equal($(CAMDeviceCameraFront));
    expect(preset.enableAudio).to.beTruthy();
    expect(preset.formatStrategy).to.equal(formatStrategy);
    expect(preset.outputQueue).to.equal(queue);
  });

  it(@"should return presets with given queue", ^{
    CAMDevicePreset *stillPreset = [CAMDevicePreset stillCameraWithQueue:queue];
    expect(stillPreset).toNot.beNil();
    expect(stillPreset.outputQueue).to.equal(queue);

    CAMDevicePreset *selfiePreset = [CAMDevicePreset selfieCameraWithQueue:queue];
    expect(selfiePreset).toNot.beNil();
    expect(selfiePreset.outputQueue).to.equal(queue);

    CAMDevicePreset *videoPreset = [CAMDevicePreset videoCameraWithQueue:queue];
    expect(videoPreset).toNot.beNil();
    expect(videoPreset.outputQueue).to.equal(queue);
  });

  it(@"should return presets with main queue", ^{
    CAMDevicePreset *stillPreset = [CAMDevicePreset stillCamera];
    expect(stillPreset).toNot.beNil();
    expect(stillPreset.outputQueue).to.equal(dispatch_get_main_queue());

    CAMDevicePreset *selfiePreset = [CAMDevicePreset selfieCamera];
    expect(selfiePreset).toNot.beNil();
    expect(selfiePreset.outputQueue).to.equal(dispatch_get_main_queue());

    CAMDevicePreset *videoPreset = [CAMDevicePreset videoCamera];
    expect(videoPreset).toNot.beNil();
    expect(videoPreset.outputQueue).to.equal(dispatch_get_main_queue());
  });
});

SpecEnd
