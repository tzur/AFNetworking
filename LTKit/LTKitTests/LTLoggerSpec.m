// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

SpecBegin(LTLogger)

__block LTLogger *logger = nil;
__block id<LTLoggerTarget> mockTarget = nil;

beforeEach(^{
  logger = [[LTLogger alloc] init];
  mockTarget = mockProtocol(@protocol(LTLoggerTarget));
  
  [logger registerTarget:mockTarget];
});

context(@"log contents", ^{
  it(@"should contain log data", ^{
    logger.minimalLogLevel = LTLogLevelDebug;
    
    NSString *message = @"Hey!";
    const char *file = "myFile.mm";
    int line = 1337;
    
    [logger logWithFormat:message file:file line:line logLevel:LTLogLevelDebug];
    
    MKTArgumentCaptor *logged = [[MKTArgumentCaptor alloc] init];
    [verifyCount(mockTarget, times(1)) outputString:[logged capture]];
    
    expect(logged.value).to.contain(message);
    expect(logged.value).to.contain([NSString stringWithUTF8String:file]);
    expect(logged.value).to.contain(([NSString stringWithFormat:@"%d", line]));
  });
});

context(@"log levels", ^{
  it(@"should log minimal log level", ^{
    logger.minimalLogLevel = LTLogLevelDebug;

    NSString *message = @"Hey!";
    [logger logWithFormat:message file:__FILE__ line:__LINE__ logLevel:LTLogLevelDebug];

    [verifyCount(mockTarget, times(1)) outputString:anything()];
  });

  it(@"should not log below minimal log level", ^{
    logger.minimalLogLevel = LTLogLevelInfo;

    NSString *message = @"Hey!";
    [logger logWithFormat:message file:__FILE__ line:__LINE__ logLevel:LTLogLevelDebug];
    
    [verifyCount(mockTarget, never()) outputString:nil];
  });
});

SpecEnd
