// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessenger.h"

#import <LTKit/NSFileManager+LTKit.h>
#import <LTKit/NSURL+Query.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSErrorCodes+TinCan.h"
#import "NSFileManager+TinCan.h"
#import "TINMessage+UserInfo.h"
#import "TINMessageFactory.h"

// Returns TINMessenger's URL from the given messageID.
NSURL *TINMessengerURLFromMessageID(NSUUID *messageID) {
  auto components = [[NSURLComponents alloc] init];
  components.scheme = @"target";
  components.host = @"message";
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:@"app_group_id" value:kTINTestHostAppGroupID],
    [NSURLQueryItem queryItemWithName:@"message_id" value:messageID.UUIDString]
  ];
  return components.URL;
}

SpecBegin(TINMessenger)

__block UIApplication *applicationMock;
__block TINMessenger *messenger;
__block TINMessage *message;
__block NSFileManager *fileManager;

beforeEach(^{
  applicationMock = OCMClassMock(UIApplication.class);
  fileManager = [NSFileManager defaultManager];
  messenger = [TINMessenger messengerWithApplication:applicationMock fileManager:fileManager
                                          appGroupID:kTINTestHostAppGroupID
                                              bundle:[NSBundle mainBundle]];
  message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                 targetScheme:@"target" type:$(TINMessageTypeRequest) action:@"foo"
                                   identifier:[NSUUID UUID] userInfo:@{}];
});

afterEach(^{
  TINCleanupTestHostAppGroupDirectory();
});

context(@"message send", ^{
  it(@"should open app with the correct URL", ^{
    OCMStub([applicationMock canOpenURL:OCMOCK_ANY]).andReturn(YES);
    auto expectedQueryDictionary = @{
      @"app_group_id": message.appGroupID,
      @"message_id": message.identifier.UUIDString
    };
    BOOL (^urlCheckBlock)(NSURL *) = ^BOOL(NSURL *url) {
      BOOL schemeMatch = [url.scheme isEqualToString:@"target"];
      BOOL hostMatch = [url.host isEqualToString:@"message"];
      BOOL itemsMatch = [url.lt_queryDictionary isEqualToDictionary:expectedQueryDictionary];
      return schemeMatch && hostMatch && itemsMatch;
    };
    OCMStub([applicationMock openURL:[OCMArg checkWithBlock:urlCheckBlock] options:OCMOCK_ANY
                   completionHandler:OCMOCK_ANY]);
    [messenger sendMessage:message completion:^(BOOL, NSError *) {}];
    OCMVerifyAll((id)applicationMock);
  });

  it(@"should invoke the completion block when open URL succeeds", ^{
    OCMStub([applicationMock canOpenURL:OCMOCK_ANY]).andReturn(YES);
    OCMStub([applicationMock openURL:OCMOCK_ANY options:OCMOCK_ANY
                   completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]);

    __block BOOL blockHasRun = NO;
    [messenger sendMessage:message completion:^(BOOL success, NSError *error) {
      blockHasRun = YES;
      expect(error).to.beNil();
      expect(success).to.beTruthy();
    }];
    expect(blockHasRun).to.beTruthy();
  });

  it(@"should set an error when failed to open the URL", ^{
    OCMStub([applicationMock canOpenURL:OCMOCK_ANY]).andReturn(YES);
    OCMStub([applicationMock openURL:OCMOCK_ANY options:OCMOCK_ANY
                   completionHandler:([OCMArg invokeBlockWithArgs:@NO, nil])]);
    __block BOOL blockHasRun = NO;
    [messenger sendMessage:message completion:^(BOOL success, NSError *error) {
      expect(error.code).to.equal(TINErrorCodeMessageSendFailed);
      expect(success).to.beFalsy();
      blockHasRun = YES;
    }];
    expect(blockHasRun).to.beTruthy();
  });

  it(@"should set an error when can't open the URL", ^{
    OCMStub([applicationMock canOpenURL:OCMOCK_ANY]).andReturn(NO);
    __block BOOL blockHasRun = NO;
    [messenger sendMessage:message completion:^(BOOL success, NSError *error) {
      expect(error.code).to.equal(TINErrorCodeMessageTargetNotFound);
      expect(success).to.beFalsy();
      blockHasRun = YES;
    }];
    expect(blockHasRun).to.beTruthy();
  });

  it(@"should error when message can't be archived", ^{
    NSFileManager *fileManagerMock = OCMClassMock(NSFileManager.class);
    auto messenger = [TINMessenger messengerWithApplication:applicationMock
                                                fileManager:fileManagerMock
                                                 appGroupID:kTINTestHostAppGroupID
                                                     bundle:[NSBundle mainBundle]];
    auto message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                        targetScheme:@"target" type:$(TINMessageTypeRequest)
                                              action:@"foo" identifier:[NSUUID UUID] userInfo:@{}];
    OCMStub([fileManagerMock tin_writeMessage:OCMOCK_ANY toURL:OCMOCK_ANY
                                        error:[OCMArg anyObjectRef]]).andReturn(NO);
    __block BOOL blockHasRun = NO;
    [messenger sendMessage:message completion:^(BOOL success, NSError *error) {
      expect(error.code).to.equal(LTErrorCodeFileWriteFailed);
      expect(success).to.beFalsy();
      blockHasRun = YES;
    }];
    expect(blockHasRun).to.beTruthy();
  });
});

context(@"message from URL", ^{
  __block NSURL *url;
  __block NSUUID *messageID;

  beforeEach(^{
    messageID = message.identifier;
    url = TINMessengerURLFromMessageID(messageID);
    NSError *error;
    [fileManager tin_writeMessage:message toURL:nn(message.url) error:&error];
  });

  it(@"should return message from valid URL", ^{
    __block NSError *error;
    auto _Nullable message = [messenger messageFromURL:url error:&error];
    expect(error).to.beNil();
    expect(message.identifier).to.equal(messageID);
    expect(message.sourceScheme).to.equal(@"source");
    expect(message.targetScheme).to.equal(@"target");
    expect(message.appGroupID).to.equal(kTINTestHostAppGroupID);
  });

  it(@"should fail if the message isn't stored persistently", ^{
    NSError *error;
    auto url = TINMessengerURLFromMessageID([NSUUID UUID]);
    auto _Nullable message = [messenger messageFromURL:url error:&error];
    expect(message).to.beNil();
    expect(error).notTo.beNil();
  });

  it(@"should fail returning a message from invalid URL", ^{
    auto components = [[NSURLComponents alloc] init];
    components.scheme = @"target";
    components.host = @"query";
    components.queryItems = @[
      [NSURLQueryItem queryItemWithName:@"foo" value:kTINAppGroupID],
      [NSURLQueryItem queryItemWithName:@"bar" value:messageID.UUIDString]
    ];
    auto url = components.URL;
    NSError *error;
    auto _Nullable message = [messenger messageFromURL:url error:&error];
    expect(message).to.beNil();
    expect(error).notTo.beNil();
  });
});

it(@"should return YES for valid URL", ^{
  auto url = TINMessengerURLFromMessageID([NSUUID UUID]);
  expect([TINMessenger isTinCanURL:url]).to.beTruthy();
});

it(@"should return NO for invalid URL", ^{
  auto url = [NSURL URLWithString:@"foo"];
  expect([TINMessenger isTinCanURL:url]).to.beFalsy();
});

it(@"should return NO when query canSendMessageToTargetScheme: with an invalid scheme", ^{
  expect([messenger canSendMessageToTargetScheme:message.targetScheme]).to.beFalsy();
});

it(@"should return YES when canSendMessageToTargetScheme: with a valid scheme", ^{
  TINMessage *messageMock = OCMClassMock([TINMessage class]);
  OCMStub(messageMock.url).andReturn([NSURL URLWithString:@"foo"]);
  OCMStub([applicationMock canOpenURL:OCMOCK_ANY]).andReturn(YES);
  expect([messenger canSendMessageToTargetScheme:@"foo"]).to.beTruthy();
});

context(@"message remove", ^{
  __block TINMessageFactory *messageFactory;
  __block NSBundle *bundleMock;

  beforeEach(^{
    bundleMock = OCMClassMock([NSBundle class]);
    messageFactory = [TINMessageFactory messageFactoryWithSourceScheme:@"source"
                                                           fileManager:fileManager
                                                            appGroupID:kTINTestHostAppGroupID];
    messenger = [TINMessenger messengerWithApplication:applicationMock
                                           fileManager:[NSFileManager defaultManager]
                                            appGroupID:kTINTestHostAppGroupID bundle:bundleMock];
  });

  it(@"should remove all messages", ^{
    auto messenger = [TINMessenger messengerWithApplication:applicationMock
                                                fileManager:[NSFileManager defaultManager]
                                                 appGroupID:kTINTestHostAppGroupID
                                                     bundle:[NSBundle mainBundle]];
    auto data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
    auto message = [messageFactory messageWithTargetScheme:@"testhost" type:$(TINMessageTypeRequest)
                                                    action:@"foo" userInfo:@{} data:data
                                                       uti:(__bridge NSString *)kUTTypePNG
                                                     error:nil];
    __block NSError *error;
    expect([messenger removeAllMessagesForScheme:@"testhost" error:&error]).to.beTruthy();
    expect(error).to.beNil();
    expect([fileManager lt_fileExistsAtPath:nn(message.directoryURL.path)]);
  });

  it(@"should report error when failed removing messages directory", ^{
    NSFileManager *fileManagerMock = OCMClassMock(NSFileManager.class);
    auto messenger = [TINMessenger messengerWithApplication:applicationMock
                                                fileManager:fileManagerMock
                                                 appGroupID:kTINTestHostAppGroupID
                                                     bundle:[NSBundle mainBundle]];
    OCMStub([fileManagerMock tin_removeAllMessagesWithAppGroupID:OCMOCK_ANY scheme:OCMOCK_ANY
             error:[OCMArg setTo:[NSError lt_errorWithCode:123]]]).andReturn(NO);
    __block NSError *error;
    expect([messenger removeAllMessagesForScheme:@"testhost" error:&error]).to.beFalsy();
    expect(error.code).to.equal(123);
  });

  it(@"should report error when scheme isn't registered in application's Info.plist", ^{
    __block NSError *error;
    expect([messenger removeAllMessagesForScheme:@"foo" error:&error]).to.beFalsy();
    expect(error.code).to.equal(TINErrorCodeNoValidSchemeFound);
  });

  it(@"should report error when failed getting CFBundleURLTypes", ^{
    OCMStub(bundleMock.infoDictionary).andReturn(@{});
    __block NSError *error;
    expect([messenger removeAllMessagesForScheme:@"testhost" error:&error]).to.beFalsy();
    expect(error.code).to.equal(TINErrorCodeNoValidSchemeFound);
  });

  it(@"should report error when failed getting CFBundleURLSchemes", ^{
    OCMStub(bundleMock.infoDictionary).andReturn(@{@"CFBundleURLTypes": @[]});
    __block NSError *error;
    expect([messenger removeAllMessagesForScheme:@"testhost" error:&error]).to.beFalsy();
    expect(error.code).to.equal(TINErrorCodeNoValidSchemeFound);
  });
});

SpecEnd
