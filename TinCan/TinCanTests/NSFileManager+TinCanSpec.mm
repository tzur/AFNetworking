// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSFileManager+TinCan.h"

#import <LTKit/NSFileManager+LTKit.h>
#import <LTKitTestUtils/LTTestUtils.h>

#import "TINMessage+UserInfo.h"
#import "TINMessageFactory.h"

SpecBegin(NSFileManager_TinCan)

__block NSFileManager *fileManager;
__block TINMessageFactory *messageFactory;
__block TINMessage *message;

beforeEach(^{
  fileManager = [NSFileManager defaultManager];
  messageFactory = [TINMessageFactory messageFactoryWithSourceScheme:@"source"
                                                         fileManager:fileManager
                                                          appGroupID:kTINTestHostAppGroupID];
  message = [messageFactory messageWithTargetScheme:@"target"
                                              block:^NSDictionary *(NSURL *, NSError **) {
    return @{@"foo": @"bar"};
  } error:NULL];
});

afterEach(^{
  TINCleanupTestHostAppGroupDirectory();
});

context(@"unit tests", ^{
  it(@"should report error when failed accessing the file system", ^{
    NSFileManager *fileManagerMock = OCMPartialMock(fileManager);
    OCMStub([fileManagerMock createDirectoryAtURL:OCMOCK_ANY withIntermediateDirectories:YES
                                       attributes:OCMOCK_ANY
                                            error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([fileManagerMock lt_writeData:OCMOCK_ANY toFile:OCMOCK_ANY options:NSDataWritingAtomic
        error:[OCMArg setTo:[NSError lt_errorWithCode:123]]]).andReturn(NO);
    auto messageFactory = [TINMessageFactory messageFactoryWithSourceScheme:@"source"
                                                                fileManager:fileManagerMock
                                                                 appGroupID:kTINTestHostAppGroupID];
    __block NSError *error;
    auto message = [messageFactory messageWithTargetScheme:@"target"
                                                     block:^NSDictionary *(NSURL *, NSError **) {
      return @{@"foo": @"bar"};
    } error:&error];
    auto success = [fileManagerMock tin_writeMessage:message toURL:nn(message.url) error:&error];
    expect(success).to.beFalsy();
    expect(error.code).to.equal(123);
  });

  it(@"should report error when failed creating intermidiate direct", ^{
    NSFileManager *fileManagerMock = OCMPartialMock(fileManager);
    OCMStub([fileManagerMock createDirectoryAtURL:OCMOCK_ANY withIntermediateDirectories:YES
        attributes:OCMOCK_ANY error:[OCMArg setTo:[NSError lt_errorWithCode:123]]]).andReturn(NO);

    auto messageFactory = [TINMessageFactory messageFactoryWithSourceScheme:@"source"
        fileManager:fileManagerMock appGroupID:kTINTestHostAppGroupID];
    __block NSError *error;
    auto message = [messageFactory messageWithTargetScheme:@"target"
                                                     block:^NSDictionary *(NSURL *, NSError **) {
      return @{@"foo": @"bar"};
    } error:&error];
    auto success = [fileManagerMock tin_writeMessage:message toURL:nn(message.url) error:&error];
    expect(success).to.beFalsy();
    expect(error.code).to.equal(123);
  });

  it(@"should report error when file doesn't exist", ^{
    NSFileManager *fileManagerMock = OCMPartialMock(fileManager);
    OCMStub([fileManagerMock lt_dataWithContentsOfFile:OCMOCK_ANY options:0
        error:[OCMArg setTo:[NSError lt_errorWithCode:123]]]);
    auto url = [NSURL fileURLWithPath:@"/tmp/foo"];
    __block NSError *error;
    auto _Nullable message = [fileManager tin_readMessageFromURL:url error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(123);
  });
});

context(@"integration tests", ^{
  it(@"should write the message to url", ^{
    auto url = [NSURL fileURLWithPath:LTTemporaryPath(@"message")];
    expect([fileManager tin_writeMessage:message toURL:url error:NULL]).to.beTruthy();
    expect([fileManager fileExistsAtPath:nn(url.path)]).to.beTruthy();
  });

  it(@"should report error for non file url", ^{
    auto url = [NSURL URLWithString:@"foo"];
    __block NSError *error;
    expect([fileManager tin_writeMessage:message toURL:url error:&error]).to.beFalsy();
    expect(error.code).to.equal(LTErrorCodeInvalidArgument);
  });

  it(@"should report error for url which resolves to a directory", ^{
    auto url = [NSURL fileURLWithPath:LTTemporaryPath()];
    __block NSError *error;
    expect([fileManager tin_writeMessage:message toURL:url error:&error]).to.beFalsy();
    expect(error).notTo.beNil();
  });

  it(@"should read the message from url", ^{
    __block NSError *error;
    [fileManager tin_writeMessage:message toURL:nn(message.url) error:&error];
    auto _Nullable restoredMessage = [fileManager tin_readMessageFromURL:nn(message.url)
                                                                   error:&error];
    expect(restoredMessage).notTo.beNil();
    expect(error).to.beNil();
    expect(message).to.equal(restoredMessage);
  });

  it(@"should report error for non file url", ^{
    auto url = [NSURL URLWithString:@"foo"];
    __block NSError *error;
    auto _Nullable message = [fileManager tin_readMessageFromURL:url error:&error];
    expect(message).to.beNil();
    expect(error.code).to.equal(LTErrorCodeInvalidArgument);
  });
});

SpecEnd
