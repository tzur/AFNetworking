// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

SpecBegin(LTLogger)

static NSString * const kMessage = @"Hey!";
static const char *kFile = "myFile.mm";
static int kLine = 1337;

__block id mockTarget;
__block LTLogger *logger;

beforeEach(^{
  mockTarget = OCMProtocolMock(@protocol(LTLoggerTarget));
  logger = [[LTLogger alloc] init];
});

context(@"log contents", ^{
  it(@"should contain log data", ^{
    [logger registerTarget:mockTarget withMinimalLogLevel:LTLogLevelDebug];

    [logger logWithFormat:kMessage file:kFile line:kLine logLevel:LTLogLevelDebug];

    OCMVerify([mockTarget outputString:[OCMArg checkWithBlock:^BOOL(NSString *log) {
      return [log rangeOfString:kMessage].location != NSNotFound;
    }] file:kFile line:kLine logLevel:LTLogLevelDebug]);
  });
});

context(@"log levels", ^{
  it(@"should log minimal log level", ^{
    [logger registerTarget:mockTarget withMinimalLogLevel:LTLogLevelDebug];

    [logger logWithFormat:kMessage file:kFile line:kLine logLevel:LTLogLevelDebug];

    OCMVerify([mockTarget outputString:OCMOCK_ANY file:kFile line:kLine logLevel:LTLogLevelDebug]);
  });

  it(@"should log above minimal log level", ^{
    [logger registerTarget:mockTarget withMinimalLogLevel:LTLogLevelDebug];

    [logger logWithFormat:kMessage file:kFile line:kLine logLevel:LTLogLevelWarning];

    OCMVerify([mockTarget outputString:OCMOCK_ANY file:kFile line:kLine
                              logLevel:LTLogLevelWarning]);
  });

  it(@"should not log below minimal log level", ^{
    [logger registerTarget:mockTarget withMinimalLogLevel:LTLogLevelInfo];

    OCMReject([[mockTarget ignoringNonObjectArgs]
        outputString:OCMOCK_ANY file:kFile line:kLine logLevel:LTLogLevelDebug]);

    [logger logWithFormat:kMessage file:kFile line:kLine logLevel:LTLogLevelDebug];
  });
});

it(@"should unregister a logger target", ^{
  [logger registerTarget:mockTarget withMinimalLogLevel:LTLogLevelDebug];
  [logger unregisterTarget:mockTarget];

  OCMReject([[mockTarget ignoringNonObjectArgs]
      outputString:OCMOCK_ANY file:kFile line:kLine logLevel:LTLogLevelDebug]);

  [logger logWithFormat:kMessage file:kFile line:kLine logLevel:LTLogLevelDebug];
});

SpecEnd
