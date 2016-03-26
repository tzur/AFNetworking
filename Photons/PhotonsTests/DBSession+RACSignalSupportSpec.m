// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "DBSession+RACSignalSupport.h"

SpecBegin(DBSession_RACSignalSupport)

__block DBSession *session;

beforeEach(^{
  session = [[DBSession alloc] initWithAppKey:@"foo" appSecret:@"bar" root:@"/"];
});

it(@"should send the user id associated with authorization failure", ^{
  LLSignalTestRecorder *recorder = [[session ptn_authorizationFailureSignal] testRecorder];
  [session.delegate sessionDidReceiveAuthorizationFailure:session userId:@"foo"];
  expect(recorder).to.sendValues(@[@"foo"]);
});

SpecEnd
