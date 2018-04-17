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

  it(@"should return correct system pixel format", ^{
    CAMPixelFormat *pixelFormat = $(CAMPixelFormat420f);
    OSType expectedFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    expect(pixelFormat.cvPixelFormat).to.equal(expectedFormat);
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

  it(@"should return values set with designated initializer", ^{
    id<CAMFormatStrategy> formatStrategy = OCMProtocolMock(@protocol(CAMFormatStrategy));
    CAMDevicePreset *preset = [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormatBGRA)
                                                                    camera:$(CAMDeviceCameraFront)
                                                               enableAudio:YES
                            automaticallyConfiguresApplicationAudioSession:NO
                                                            formatStrategy:formatStrategy
                                                               outputQueue:queue];

    expect(preset.pixelFormat).to.equal($(CAMPixelFormatBGRA));
    expect(preset.camera).to.equal($(CAMDeviceCameraFront));
    expect(preset.enableAudio).to.beTruthy();
    expect(preset.automaticallyConfiguresApplicationAudioSession).to.beFalsy();
    expect(preset.formatStrategy).to.equal(formatStrategy);
    expect(preset.outputQueue).to.equal(queue);
  });

  it(@"should return values set with convenience initializer", ^{
    id<CAMFormatStrategy> formatStrategy = OCMProtocolMock(@protocol(CAMFormatStrategy));
    CAMDevicePreset *preset = [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormat420f)
                                                                    camera:$(CAMDeviceCameraBack)
                                                               enableAudio:NO
                                                            formatStrategy:formatStrategy
                                                               outputQueue:queue];

    expect(preset.pixelFormat).to.equal($(CAMPixelFormat420f));
    expect(preset.camera).to.equal($(CAMDeviceCameraBack));
    expect(preset.enableAudio).to.beFalsy();
    expect(preset.automaticallyConfiguresApplicationAudioSession).to.beTruthy();
    expect(preset.formatStrategy).to.equal(formatStrategy);
    expect(preset.outputQueue).to.equal(queue);
  });
});

SpecEnd
