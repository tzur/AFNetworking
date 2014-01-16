// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

#define LTNoFormatWarningBegin \
  _Pragma("clang diagnostic push") \
  _Pragma("clang diagnostic ignored \"-Wformat-security\"") \

#define LTNoFormatWarningEnd \
  _Pragma("clang diagnostic pop")

SpecBegin(LTLogger)

__block LTLogger *logger = nil;
__block id mockTarget = nil;

beforeEach(^{
  logger = [[LTLogger alloc] init];

  mockTarget = [OCMockObject mockForProtocol:@protocol(LTLoggerTarget)];
  
  [logger registerTarget:mockTarget];
});

context(@"log contents", ^{
  it(@"should contain log data", ^{
    logger.minimalLogLevel = LTLogLevelDebug;
    
    NSString *message = @"Hey!";
    const char *file = "myFile.mm";
    int line = 1337;

    [[mockTarget expect] outputString:[OCMArg checkWithBlock:^BOOL(NSString *log) {
      return [log rangeOfString:message].location != NSNotFound &&
          [log rangeOfString:[NSString stringWithUTF8String:file]].location != NSNotFound &&
          [log rangeOfString:[NSString stringWithFormat:@"%d", line]].location != NSNotFound;
    }]];

LTNoFormatWarningBegin
    [logger logWithFormat:message file:file line:line logLevel:LTLogLevelDebug];
LTNoFormatWarningEnd

    [mockTarget verify];
  });
});

context(@"log levels", ^{
  it(@"should log minimal log level", ^{
    logger.minimalLogLevel = LTLogLevelDebug;

    [[mockTarget expect] outputString:[OCMArg any]];

    NSString *message = @"Hey!";
LTNoFormatWarningBegin
    [logger logWithFormat:message file:__FILE__ line:__LINE__ logLevel:LTLogLevelDebug];
LTNoFormatWarningEnd

    [mockTarget verify];
  });

  it(@"should not log below minimal log level", ^{
    logger.minimalLogLevel = LTLogLevelInfo;

    NSString *message = @"Hey!";
LTNoFormatWarningBegin
    [logger logWithFormat:message file:__FILE__ line:__LINE__ logLevel:LTLogLevelDebug];
LTNoFormatWarningEnd

    [mockTarget verify];
  });
});

SpecEnd
