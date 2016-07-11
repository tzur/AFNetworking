// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareSession.h"

#import "CAMFakeAVCaptureDevice.h"
#import "CAMFormatStrategy.h"

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
- (instancetype)initWithSession:(AVCaptureSession *)session;
@end

SpecBegin(CAMHardwareSession)

static NSError * const kError = [NSError errorWithDomain:@"abc" code:123 userInfo:nil];

__block CAMHardwareSession *session;
__block id sessionMock;

beforeEach(^{
  sessionMock = OCMClassMock([AVCaptureSession class]);
  session = [[CAMHardwareSession alloc] initWithSession:sessionMock];
});

context(@"init", ^{
  it(@"should create session", ^{
    CAMHardwareSession *localSession = [[CAMHardwareSession alloc] init];
    expect(localSession.session).toNot.beNil();
  });

  it(@"should use mock session", ^{
    expect(session.session).to.beIdenticalTo(sessionMock);
  });

  it(@"should not init other properties", ^{
    expect(session.previewLayer).to.beNil();
    expect(session.videoDevice).to.beNil();
    expect(session.videoInput).to.beNil();
    expect(session.videoOutput).to.beNil();
    expect(session.videoConnection).to.beNil();
    expect(session.stillOutput).to.beNil();
    expect(session.stillConnection).to.beNil();
    expect(session.audioDevice).to.beNil();
    expect(session.audioInput).to.beNil();
    expect(session.audioOutput).to.beNil();
    expect(session.audioConnection).to.beNil();
  });
});

context(@"preview layer", ^{
  it(@"should create layer with session", ^{
    expect(session.previewLayer).to.beNil();

    [session createPreviewLayer];

    expect(session.previewLayer).toNot.beNil();
    expect(session.previewLayer.session).to.equal(sessionMock);
  });
});

context(@"video input", ^{
  __block CAMFakeAVCaptureDevice *device;
  __block CAMFakeFormatStrategy *formatStrategy;

  beforeEach(^{
    device = [[CAMFakeAVCaptureDevice alloc] init];
    device.mediaTypes = @[AVMediaTypeVideo];
    formatStrategy = [[CAMFakeFormatStrategy alloc] init];
  });

  it(@"should raise when not passing an error output", ^{
    expect(^{
      [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should keep device and input on success", ^{
    formatStrategy.format = @1;
    OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

    BOOL success;
    NSError *error;
    success = [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerify([sessionMock addInput:OCMOCK_ANY]);
    expect(session.videoDevice).to.beIdenticalTo(device);
    expect(session.videoInput).toNot.beNil();
    expect(session.videoInput.device).to.beIdenticalTo(device);
  });

  it(@"should return error when device is nil", ^{
    device = nil;
    BOOL success;
    NSError *error;
    success = [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeMissingVideoDevice);
  });

  it(@"should return error when unable to select format", ^{
    BOOL success;
    NSError *error;
    success = [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeFailedConfiguringVideoDevice);
    expect(device.didUnlock).to.beTruthy();
  });

  it(@"should return error when unable to lock device", ^{
    device.lockError = kError;

    BOOL success;
    NSError *error;
    success = [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeFailedLockingVideoDevice);
    expect(error.lt_underlyingError).to.equal(kError);
  });

  it(@"should return error when unable to create input", ^{
    formatStrategy.format = @1;
    id classMock = OCMClassMock([AVCaptureDeviceInput class]);
    OCMStub([classMock deviceInputWithDevice:device error:[OCMArg setTo:kError]]);

    BOOL success;
    NSError *error;
    success = [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeFailedCreatingVideoInput);
    expect(error.lt_underlyingError).to.equal(kError);

    [classMock stopMocking];
  });

  it(@"should return error when unable to attach input", ^{
    formatStrategy.format = @1;
    OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(NO);

    BOOL success;
    NSError *error;
    success = [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeFailedAttachingVideoInput);
  });

  it(@"should remove current input", ^{
    formatStrategy.format = @1;
    OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

    NSError *error;
    [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];
    id firstInput = session.videoInput;

    [session setupVideoInputWithDevice:device formatStrategy:formatStrategy error:&error];
    OCMVerify([sessionMock removeInput:firstInput];);
    expect(session.videoInput).toNot.beIdenticalTo(firstInput);
  });
});

context(@"video output", ^{
  it(@"should raise when not passing an error output", ^{
    expect(^{
      [session setupVideoOutputWithError:nil];
    }).to.raise(NSInvalidArgumentException);
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

context(@"still output", ^{
  it(@"should raise when not passing an error output", ^{
    expect(^{
      [session setupStillOutputWithError:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should keep output on success", ^{
    OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

    BOOL success;
    NSError *error;
    success = [session setupStillOutputWithError:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    expect(session.stillOutput).toNot.beNil();
    OCMVerify([sessionMock addOutput:(id)session.stillOutput]);
  });

  it(@"should return error when unable to attach output", ^{
    OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(NO);

    BOOL success;
    NSError *error;
    success = [session setupStillOutputWithError:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeFailedAttachingStillOutput);
  });

  it(@"should remove current output", ^{
    OCMStub([sessionMock canAddOutput:OCMOCK_ANY]).andReturn(YES);

    NSError *error;
    [session setupStillOutputWithError:&error];
    id firstOutput = session.stillOutput;

    [session setupStillOutputWithError:&error];
    OCMVerify([sessionMock removeOutput:firstOutput]);
    expect(session.stillOutput).toNot.beIdenticalTo(firstOutput);
  });
});

context(@"audio input", ^{
  __block CAMFakeAVCaptureDevice *device;

  beforeEach(^{
    device = [[CAMFakeAVCaptureDevice alloc] init];
    device.mediaTypes = @[AVMediaTypeAudio];
  });

  it(@"should raise when not passing an error output", ^{
    expect(^{
      [session setupAudioInputWithDevice:device error:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should keep device and input on success", ^{
    OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

    BOOL success;
    NSError *error;
    success = [session setupAudioInputWithDevice:device error:&error];

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
    success = [session setupAudioInputWithDevice:device error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeMissingAudioDevice);
  });

  it(@"should return error when unable to create input", ^{
    id classMock = OCMClassMock([AVCaptureDeviceInput class]);
    OCMStub([classMock deviceInputWithDevice:device error:[OCMArg setTo:kError]]);

    BOOL success;
    NSError *error;
    success = [session setupAudioInputWithDevice:device error:&error];

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
    success = [session setupAudioInputWithDevice:device error:&error];

    expect(success).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(CAMErrorCodeFailedAttachingAudioInput);
  });

  it(@"should remove current input", ^{
    OCMStub([sessionMock canAddInput:OCMOCK_ANY]).andReturn(YES);

    NSError *error;
    [session setupAudioInputWithDevice:device error:&error];
    id firstInput = session.audioInput;

    [session setupAudioInputWithDevice:device error:&error];
    OCMVerify([sessionMock removeInput:OCMOCK_ANY];);
    expect(session.audioInput).toNot.beIdenticalTo(firstInput);
  });
});

context(@"audio output", ^{
  it(@"should raise when not passing an error output", ^{
    expect(^{
      [session setupAudioOutputWithError:nil];
    }).to.raise(NSInvalidArgumentException);
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

SpecEnd
