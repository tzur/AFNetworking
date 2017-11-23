// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage+UserInfo.h"

#import "NSURL+TinCan.h"

SpecBegin(TINMessage_UserInfo)

__block NSUUID *uuid;

beforeEach(^{
  uuid = [NSUUID UUID];
});

it(@"should initialize with all supported userInfo keys", ^{
  auto message = [TINMessage messageWithAppGroupID:@"foo" sourceScheme:@"bar" targetScheme:@"baz"
                                        identifier:uuid userInfo:@{
    kTINMessageFileNamesKey: @[@"file1", @"file2"]
  }];
  expect(message.fileNames).to.equal(@[@"file1", @"file2"]);
});

it(@"should return correct file URLs", ^{
  auto message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                      targetScheme:@"target" identifier:uuid userInfo:@{
    kTINMessageFileNamesKey: @[@"foo"]
  }];
  auto fooURL = nn([message.directoryURL URLByAppendingPathComponent:@"foo"]);
  expect(message.fileURLs).notTo.beNil();
  expect(message.directoryURL).notTo.beNil();
  expect(message.fileURLs).to.equal(@[fooURL]);
});

it(@"should return nil if fileNames is nil", ^{
  auto message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                      targetScheme:@"target" identifier:uuid userInfo:@{}];
  expect(message.directoryURL).notTo.beNil();
  expect(message.fileURLs).to.beNil();
});

it(@"should return nil if any file name has a relative path", ^{
  auto message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                      targetScheme:@"target" identifier:uuid userInfo:@{
    kTINMessageFileNamesKey: @[@"/foo", @"bar"]
  }];
  expect(message.fileURLs).to.beNil();
});

it(@"should return nil if any file name resolves outside of a message directory", ^{
  auto message = [TINMessage messageWithAppGroupID:kTINTestHostAppGroupID sourceScheme:@"source"
                                      targetScheme:@"target" identifier:uuid userInfo:@{
    kTINMessageFileNamesKey: @[@"../foo", @"bar"]
  }];
  expect(message.fileURLs).to.beNil();
});

SpecEnd
