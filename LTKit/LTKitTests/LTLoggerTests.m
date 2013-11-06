// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import "LTLogger.h"

#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <XCTest/XCTest.h>

@interface LTLoggerTests : XCTestCase
@property (strong, nonatomic) LTLogger *logger;
@property (strong, nonatomic) id<LTLoggerTarget> mockTarget;
@end

@implementation LTLoggerTests

- (void)setUp {
  self.logger = [[LTLogger alloc] init];

  self.mockTarget = mockProtocol(@protocol(LTLoggerTarget));
  [self.logger registerTarget:self.mockTarget];
}

- (void)testLoggerShouldLogMinimalLogLevel {
  self.logger.minimalLogLevel = LTLogLevelDebug;
  
  NSString *message = @"Hey!";
  [self.logger logWithFormat:message file:__FILE__ line:__LINE__ logLevel:LTLogLevelDebug];
  
  [verifyCount(self.mockTarget, times(1)) outputString:anything()];
}

- (void)testLoggerShouldNotLogBelowMinimalLogLevel {
  self.logger.minimalLogLevel = LTLogLevelInfo;
  
  NSString *message = @"Hey!";
  [self.logger logWithFormat:message file:__FILE__ line:__LINE__ logLevel:LTLogLevelDebug];
  
  [verifyCount(self.mockTarget, never()) outputString:nil];
}

- (void)testLoggerShouldLogGivenData {
  self.logger.minimalLogLevel = LTLogLevelDebug;
  
  NSString *message = @"Hey!";
  const char *file = "myFile.mm";
  int line = 1337;
  
  [self.logger logWithFormat:message file:file line:line logLevel:LTLogLevelDebug];
  
  MKTArgumentCaptor *logged = [[MKTArgumentCaptor alloc] init];
  [verifyCount(self.mockTarget, times(1)) outputString:[logged capture]];
  
  assertThat(logged.value, containsString(message));
  assertThat(logged.value, containsString([NSString stringWithUTF8String:file]));
  assertThat(logged.value, containsString([NSString stringWithFormat:@"%d", line]));
}

@end
