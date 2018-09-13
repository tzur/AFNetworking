// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareSession.h"

#import "CAMDevicePreset.h"
#import "CAMFakeAVCaptureDevice.h"
#import "CAMFormatStrategy.h"
#import "CAMHardwareSessionFactory.h"

/// Fake \c CAMFormatStrategy for testing.
@interface CAMFakeFormatStrategy : NSObject <CAMFormatStrategy>

/// Object to return for \c formatFrom:. Note that no validation is done that \c format is contained
/// in the array given to \c formatFrom:.
@property (strong, nonatomic) id format;

@end

@implementation CAMFakeFormatStrategy
- (AVCaptureDeviceFormat *)formatFrom:(NSArray<AVCaptureDeviceFormat *> __unused *)formats {
  return self.format;
}
@end

@interface CAMHardwareSession (ForTesting)
- (instancetype)initWithPreset:(CAMDevicePreset *)preset session:(AVCaptureSession *)session;
- (void)createPreviewLayer;
- (BOOL)setupVideoInputWithDevice:(AVCaptureDevice *)device
                   formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                            error:(NSError **)error;
- (BOOL)setupVideoOutputWithError:(NSError **)error;
- (BOOL)setupPhotoOutputWithPixelFormat:(CAMPixelFormat *)pixelFormat
                                  error:(NSError **)error;
- (BOOL)setupAudioInputWithDevice:(AVCaptureDevice *)device error:(NSError **)error;
- (BOOL)setupAudioOutputWithError:(NSError **)error;
- (void)setVideoOutput:(AVCaptureVideoDataOutput *)videoOutput;
- (void)setAudioOutput:(AVCaptureAudioDataOutput *)audioOutput;
@end

@interface CAMHardwareSessionFactory (ForTesting)
- (BOOL)configureSession:(CAMHardwareSession *)session withPreset:(CAMDevicePreset *)preset
                   error:(NSError * __autoreleasing *)error;
@end

SpecBegin(CAMHardwareSession)

static NSError * const kError = [NSError lt_errorWithCode:123];

context(@"dealloc", ^{
  it(@"should not retain itself", ^{
    __weak CAMHardwareSession *weakSession;
    @autoreleasepool {
      id sessionMock = OCMClassMock([AVCaptureSession class]);
      CAMFakeFormatStrategy *formatStrategy = [[CAMFakeFormatStrategy alloc] init];
      CAMDevicePreset *preset =
          [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormatBGRA)
                                                camera:$(CAMDeviceCameraBack)
                                           enableAudio:NO
                                        formatStrategy:formatStrategy
                                           outputQueue:dispatch_get_main_queue()];
      CAMHardwareSession *session = [[CAMHardwareSession alloc] initWithPreset:preset
                                                                       session:sessionMock];
      weakSession = session;
      expect(weakSession).notTo.beNil();
    }
    expect(weakSession).to.beNil();
  });

  it(@"should clean up session", ^{
    id sessionMock = OCMClassMock([AVCaptureSession class]);
    OCMStub([sessionMock isRunning]).andReturn(YES);
    NSArray *inputs =
        @[OCMClassMock([AVCaptureInput class]), OCMClassMock([AVCaptureInput class])];
    NSArray *outputs =
        @[OCMClassMock([AVCaptureOutput class]), OCMClassMock([AVCaptureOutput class])];
    OCMStub([sessionMock inputs]).andReturn(inputs);
    OCMStub([sessionMock outputs]).andReturn(outputs);
    id videoOutput = OCMClassMock([AVCaptureVideoDataOutput class]);
    id audioOutput = OCMClassMock([AVCaptureAudioDataOutput class]);

    @autoreleasepool {
      CAMFakeFormatStrategy *formatStrategy = [[CAMFakeFormatStrategy alloc] init];
      CAMDevicePreset *preset =
          [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormatBGRA)
                                                camera:$(CAMDeviceCameraBack)
                                           enableAudio:NO
                                        formatStrategy:formatStrategy
                                           outputQueue:dispatch_get_main_queue()];
      CAMHardwareSession *session = [[CAMHardwareSession alloc] initWithPreset:preset
                                                                       session:sessionMock];
      [session setVideoOutput:videoOutput];
      [session setAudioOutput:audioOutput];
    }

    OCMVerify([sessionMock stopRunning]);
    OCMVerify([sessionMock removeInput:inputs[0]]);
    OCMVerify([sessionMock removeInput:inputs[1]]);
    OCMVerify([sessionMock removeOutput:outputs[0]]);
    OCMVerify([sessionMock removeOutput:outputs[1]]);
    OCMVerify([videoOutput setSampleBufferDelegate:nil queue:NULL]);
    OCMVerify([audioOutput setSampleBufferDelegate:nil queue:NULL]);
  });

  it(@"should not stop session if it's not running", ^{
    id sessionMock = OCMClassMock([AVCaptureSession class]);
    OCMReject([sessionMock stopRunning]);

    @autoreleasepool {
      CAMFakeFormatStrategy *formatStrategy = [[CAMFakeFormatStrategy alloc] init];
      CAMDevicePreset *preset =
          [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormatBGRA)
                                                camera:$(CAMDeviceCameraBack)
                                           enableAudio:NO
                                        formatStrategy:formatStrategy
                                           outputQueue:dispatch_get_main_queue()];
      CAMHardwareSession * __unused session =
          [[CAMHardwareSession alloc] initWithPreset:preset session:sessionMock];
    }
  });
});

context(@"session", ^{
  __block CAMHardwareSession *session;
  __block id sessionMock;
  __block CAMDevicePreset *preset;
  __block CAMFakeFormatStrategy *formatStrategy;

  beforeEach(^{
    sessionMock = OCMClassMock([AVCaptureSession class]);
    formatStrategy = [[CAMFakeFormatStrategy alloc] init];
    preset = [[CAMDevicePreset alloc] initWithPixelFormat:$(CAMPixelFormatBGRA)
                                                   camera:$(CAMDeviceCameraBack)
                                              enableAudio:NO
                                           formatStrategy:formatStrategy
                                              outputQueue:dispatch_get_main_queue()];
    session = [[CAMHardwareSession alloc] initWithPreset:preset session:sessionMock];
  });

  context(@"preview layer", ^{
    it(@"should create layer with session", ^{
      id classMock = OCMClassMock([AVCaptureVideoPreviewLayer class]);
      OCMStub([classMock layerWithSession:sessionMock]).andReturn(classMock);

      expect(session.previewLayer).to.beNil();

      [session createPreviewLayer];

      expect(session.previewLayer).to.beIdenticalTo(classMock);

      [classMock stopMocking];
    });
  });

  context(@"video input", ^{
    __block CAMFakeAVCaptureDevice *device;

    beforeEach(^{
      device = [[CAMFakeAVCaptureDevice alloc] init];
      device.mediaTypes = @[AVMediaTypeVideo];
    });

    it(@"should not raise when not passing an error output", ^{
      expect(^{
        [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy error:nil];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should keep device and input on success", ^{
      formatStrategy.format = @1;
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);
      id deviceInput = OCMClassMock([AVCaptureDeviceInput class]);
      OCMStub([deviceInput deviceInputWithDevice:(id)device error:[OCMArg anyObjectRef]])
          .andReturn(deviceInput);

      BOOL success;
      NSError *error;
      success = [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy
                                             error:&error];

      expect(success).to.beTruthy();
      expect(error).to.beNil();
      OCMVerify([sessionMock addInput:OCMOCK_ANY]);
      expect(session.videoDevice).to.beIdenticalTo(device);
      expect(session.videoInput).to.beIdenticalTo(deviceInput);

      [deviceInput stopMocking];
    });

    it(@"should return error when device is nil", ^{
      device = nil;
      BOOL success;
      NSError *error;
      success = [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy
                                             error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeMissingVideoDevice);
    });

    it(@"should return error when unable to select format", ^{
      BOOL success;
      NSError *error;
      success = [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy
                                             error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedConfiguringVideoDevice);
      expect(device.didUnlock).to.beTruthy();
    });

    it(@"should return error when unable to lock device", ^{
      device.lockError = kError;

      BOOL success;
      NSError *error;
      success = [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy
                                             error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedLockingVideoDevice);
      expect(error.lt_underlyingError).to.equal(kError);
    });

    it(@"should return error when unable to create input", ^{
      formatStrategy.format = @1;
      id classMock = OCMClassMock([AVCaptureDeviceInput class]);
      OCMStub([classMock deviceInputWithDevice:(id)device error:[OCMArg setTo:kError]]);

      BOOL success;
      NSError *error;
      success = [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy
                                             error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedCreatingVideoInput);
      expect(error.lt_underlyingError).to.equal(kError);

      [classMock stopMocking];
    });

    it(@"should return error when unable to attach input", ^{
      formatStrategy.format = @1;
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(NO);
      id deviceInput = OCMClassMock([AVCaptureDeviceInput class]);
      OCMStub([deviceInput deviceInputWithDevice:(id)device error:[OCMArg anyObjectRef]])
          .andReturn(deviceInput);

      BOOL success;
      NSError *error;
      success = [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy
                                             error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedAttachingVideoInput);

      [deviceInput stopMocking];
    });

    it(@"should remove current input", ^{
      formatStrategy.format = @1;
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);
      id deviceInput = OCMClassMock([AVCaptureDeviceInput class]);
      OCMStub([deviceInput deviceInputWithDevice:(id)device error:[OCMArg anyObjectRef]])
          .andReturn(deviceInput);

      NSError *error;
      [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy error:&error];
      id firstInput = session.videoInput;

      [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy error:&error];
      OCMVerify([sessionMock removeInput:firstInput];);

      [deviceInput stopMocking];
    });
  });

  context(@"set camera", ^{
    __block CAMFakeAVCaptureDevice *device;
    __block id camera;
    __block id deviceInput;

    beforeEach(^{
      device = [[CAMFakeAVCaptureDevice alloc] init];
      device.mediaTypes = @[AVMediaTypeVideo];

      camera = OCMClassMock([CAMDeviceCamera class]);
      OCMStub([camera device]).andReturn(device);

      formatStrategy.format = @1;
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

      deviceInput = OCMClassMock([AVCaptureDeviceInput class]);
      OCMStub([deviceInput deviceInputWithDevice:(id)device error:[OCMArg anyObjectRef]])
          .andReturn(deviceInput);
    });

    afterEach(^{
      [deviceInput stopMocking];
    });

    it(@"should not raise when not passing an error output", ^{
      expect(^{
        [session setCamera:camera error:nil];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should keep device and input on success", ^{
      BOOL success;
      NSError *error;
      success = [session setCamera:camera error:&error];

      expect(success).to.beTruthy();
      expect(error).to.beNil();
      OCMVerify([sessionMock addInput:OCMOCK_ANY]);
      expect(session.videoDevice).to.beIdenticalTo(device);
      expect(session.videoInput).to.beIdenticalTo(deviceInput);
    });

    it(@"should remove current input", ^{
      NSError *error;
      [session setupVideoInputWithDevice:(id)device formatStrategy:formatStrategy error:&error];
      id firstInput = session.videoInput;

      [session setCamera:camera error:&error];
      OCMVerify([sessionMock removeInput:firstInput];);
    });

    it(@"should begin and commit configuration", ^{
      [sessionMock setExpectationOrderMatters:YES];
      OCMExpect([sessionMock beginConfiguration]);
      OCMExpect([sessionMock commitConfiguration]);

      NSError *error;
      [session setCamera:camera error:&error];

      OCMVerifyAll(sessionMock);
    });
  });

  context(@"video output", ^{
    it(@"should not raise when not passing an error output", ^{
      expect(^{
        [session setupVideoOutputWithError:nil];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should keep output on success", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

      BOOL success;
      NSError *error;
      success = [session setupVideoOutputWithError:&error];

      expect(success).to.beTruthy();
      expect(error).to.beNil();
      expect(session.videoOutput).toNot.beNil();
      OCMVerify([sessionMock addOutput:(id)session.videoOutput]);
    });

    it(@"should return error when unable to attach output", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(NO);

      BOOL success;
      NSError *error;
      success = [session setupVideoOutputWithError:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedAttachingVideoOutput);
    });

    it(@"should remove current output", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

      NSError *error;
      [session setupVideoOutputWithError:&error];
      id firstOutput = session.videoOutput;

      [session setupVideoOutputWithError:&error];
      OCMVerify([sessionMock removeOutput:firstOutput]);
      expect(session.videoOutput).toNot.beIdenticalTo(firstOutput);
    });
  });

  context(@"photo output", ^{
    it(@"should not raise when not passing an error output", ^{
      expect(^{
        [session setupPhotoOutputWithPixelFormat:$(CAMPixelFormat420f) error:nil];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should keep output on success", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

      BOOL success;
      NSError *error;
      success = [session setupPhotoOutputWithPixelFormat:$(CAMPixelFormat420f) error:&error];

      expect(success).to.beTruthy();
      expect(error).to.beNil();

      OCMVerify([sessionMock addOutput:(id)session.photoOutput]);
    });

    it(@"should return error when unable to attach output", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(NO);

      BOOL success;
      NSError *error;
      success = [session setupPhotoOutputWithPixelFormat:$(CAMPixelFormat420f) error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedAttachingPhotoOutput);
    });

    it(@"should remove current output", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

      NSError *error;
      [session setupPhotoOutputWithPixelFormat:$(CAMPixelFormat420f) error:&error];

      id firstOutput = session.photoOutput;

      [session setupPhotoOutputWithPixelFormat:$(CAMPixelFormat420f) error:&error];
      OCMVerify([sessionMock removeOutput:firstOutput]);
      expect(session.photoOutput).toNot.beIdenticalTo(firstOutput);
    });
  });

  context(@"audio input", ^{
    __block CAMFakeAVCaptureDevice *device;

    beforeEach(^{
      device = [[CAMFakeAVCaptureDevice alloc] init];
      device.mediaTypes = @[AVMediaTypeAudio];
    });

    it(@"should not raise when not passing an error output", ^{
      expect(^{
        [session setupAudioInputWithDevice:(id)device error:nil];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should keep device and input on success", ^{
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

      BOOL success;
      NSError *error;
      success = [session setupAudioInputWithDevice:(id)device error:&error];

      expect(success).to.beTruthy();
      expect(error).to.beNil();
      OCMVerify([sessionMock addInput:OCMOCK_ANY]);
      expect(session.audioDevice).to.beIdenticalTo(device);
      expect(session.audioInput).toNot.beNil();
      expect(session.audioInput.device).to.beIdenticalTo(device);
    });

    it(@"should return error when device is nil", ^{
      device = nil;
      BOOL success;
      NSError *error;
      success = [session setupAudioInputWithDevice:(id)device error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeMissingAudioDevice);
    });

    it(@"should return error when unable to create input", ^{
      id classMock = OCMClassMock([AVCaptureDeviceInput class]);
      OCMStub([classMock deviceInputWithDevice:(id)device error:[OCMArg setTo:kError]]);

      BOOL success;
      NSError *error;
      success = [session setupAudioInputWithDevice:(id)device error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedCreatingAudioInput);
      expect(error.lt_underlyingError).to.equal(kError);

      [classMock stopMocking];
    });

    it(@"should return error when unable to attach input", ^{
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(NO);

      BOOL success;
      NSError *error;
      success = [session setupAudioInputWithDevice:(id)device error:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedAttachingAudioInput);
    });

    it(@"should remove current input", ^{
      OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

      NSError *error;
      [session setupAudioInputWithDevice:(id)device error:&error];
      id firstInput = session.audioInput;

      [session setupAudioInputWithDevice:(id)device error:&error];
      OCMVerify([sessionMock removeInput:OCMOCK_ANY];);
      expect(session.audioInput).toNot.beIdenticalTo(firstInput);
    });
  });

  context(@"audio output", ^{
    it(@"should not raise when not passing an error output", ^{
      expect(^{
        [session setupAudioOutputWithError:nil];
      }).toNot.raise(NSInvalidArgumentException);
    });

    it(@"should keep output on success", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

      BOOL success;
      NSError *error;
      success = [session setupAudioOutputWithError:&error];

      expect(success).to.beTruthy();
      expect(error).to.beNil();
      expect(session.audioOutput).toNot.beNil();
      OCMVerify([sessionMock addOutput:(id)session.audioOutput]);
    });

    it(@"should return error when unable to attach output", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(NO);

      BOOL success;
      NSError *error;
      success = [session setupAudioOutputWithError:&error];

      expect(success).to.beFalsy();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(CAMErrorCodeFailedAttachingAudioOutput);
    });

    it(@"should remove current output", ^{
      OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

      NSError *error;
      [session setupAudioOutputWithError:&error];
      id firstOutput = session.audioOutput;

      [session setupAudioOutputWithError:&error];
      OCMVerify([sessionMock removeOutput:firstOutput]);
      expect(session.audioOutput).toNot.beIdenticalTo(firstOutput);
    });
  });
});

context(@"factory", ^{
  __block id session;
  __block id preset;
  __block NSError *error;
  __block CAMHardwareSessionFactory *factory;

  beforeEach(^{
    session = OCMClassMock([CAMHardwareSession class]);
    preset = OCMClassMock([CAMDevicePreset class]);
    error = nil;
    factory = [[CAMHardwareSessionFactory alloc] init];
  });

  it(@"should create preview layer", ^{
    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([session createPreviewLayer]);
  });

  it(@"should create video input", ^{
    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                           error:[OCMArg anyObjectRef]]);
  });

  it(@"should create video output", ^{
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);

    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([session setupVideoOutputWithError:[OCMArg anyObjectRef]]);
  });

  it(@"should configure video output", ^{
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    id videoOutput = OCMClassMock([AVCaptureVideoDataOutput class]);
    OCMStub([session videoOutput]).andReturn(videoOutput);

    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([videoOutput setVideoSettings:OCMOCK_ANY]);
  });

  it(@"should create photo output", ^{
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);

    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
  });

  it(@"should create audio input", ^{
    OCMStub([preset enableAudio]).andReturn(YES);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:nil]]).andReturn(YES);

    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([session setupAudioInputWithDevice:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
  });

  it(@"should create audio output", ^{
    OCMStub([preset enableAudio]).andReturn(YES);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioInputWithDevice:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);

    [factory configureSession:session withPreset:preset error:&error];
    OCMVerify([session setupAudioOutputWithError:[OCMArg anyObjectRef]]);
  });

  it(@"should not create audio input when audio not enabled", ^{
    OCMStub([preset enableAudio]).andReturn(NO);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:$(CAMPixelFormat420f)
                                               error:[OCMArg setTo:nil]]).andReturn(YES);

    [[[session reject] ignoringNonObjectArgs] setupAudioInputWithDevice:OCMOCK_ANY error:NULL];
    [factory configureSession:session withPreset:preset error:&error];
  });

  it(@"should not create audio output when audio not enabled", ^{
    OCMStub([preset enableAudio]).andReturn(NO);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioInputWithDevice:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);

    [[[session reject] ignoringNonObjectArgs] setupAudioOutputWithError:NULL];
    [factory configureSession:session withPreset:preset error:&error];
  });

  it(@"should successfully configure session", ^{
    OCMStub([preset enableAudio]).andReturn(YES);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioInputWithDevice:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);

    BOOL success = [factory configureSession:session withPreset:preset error:&error];
    expect(success).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should return error when video input setup failed", ^{
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:kError]]).andReturn(NO);
    BOOL success = [factory configureSession:session withPreset:preset error:&error];
    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
  });

  it(@"should return error when video output setup failed", ^{
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:kError]]).andReturn(NO);
    BOOL success = [factory configureSession:session withPreset:preset error:&error];
    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
  });

  it(@"should return error when photo output setup failed", ^{
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:kError]]).andReturn(NO);
    BOOL success = [factory configureSession:session withPreset:preset error:&error];
    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
  });

  it(@"should return error when audio input setup failed", ^{
    OCMStub([preset enableAudio]).andReturn(YES);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioInputWithDevice:OCMOCK_ANY
                                         error:[OCMArg setTo:kError]]).andReturn(NO);
    BOOL success = [factory configureSession:session withPreset:preset error:&error];
    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
  });

  it(@"should return error when audio output setup failed", ^{
    OCMStub([preset enableAudio]).andReturn(YES);
    OCMStub([session setupVideoInputWithDevice:OCMOCK_ANY formatStrategy:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupVideoOutputWithError:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupPhotoOutputWithPixelFormat:OCMOCK_ANY
                                               error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioInputWithDevice:OCMOCK_ANY
                                         error:[OCMArg setTo:nil]]).andReturn(YES);
    OCMStub([session setupAudioOutputWithError:[OCMArg setTo:kError]]).andReturn(NO);
    BOOL success = [factory configureSession:session withPreset:preset error:&error];
    expect(success).to.beFalsy();
    expect(error).to.equal(kError);
  });
});

SpecEnd
