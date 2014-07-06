// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestModule.h"

#import "LTDevice.h"
#import "LTFileManager.h"
#import "LTRandom.h"

@interface LTTestObserver : XCTestObserver
@end

@implementation LTTestObserver

- (void)startObserving {
  JSObjectionModule *module = [[LTTestModule alloc] init];
  JSObjectionInjector *injector = [JSObjection createInjector:module];
  [JSObjection setDefaultInjector:injector];
}

@end

@implementation LTTestModule

static const NSUInteger kTestingSeed = 1234;

+ (void)load {
  [[NSUserDefaults standardUserDefaults] setValue:@"XCTestLog,LTTestObserver"
                                           forKey:@"XCTestObserverClass"];
}

- (id)init {
  if (self = [super init]) {
    self.uiScreen = [OCMockObject partialMockForObject:[UIScreen mainScreen]];
    self.uiDevice = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
    self.ltDevice = [OCMockObject partialMockForObject:[LTDevice currentDevice]];
    self.uiApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
    self.nsFileManager = [OCMockObject partialMockForObject:[NSFileManager defaultManager]];
    self.ltFileManager = [OCMockObject partialMockForObject:[LTFileManager sharedManager]];
  }
  return self;
}

- (void)configure {
  [self bind:self.uiScreen toClass:[UIScreen class]];
  [self bind:self.uiDevice toClass:[UIDevice class]];
  [self bind:self.ltDevice toClass:[LTDevice class]];
  [self bind:self.uiApplication toClass:[UIApplication class]];
  [self bind:self.nsFileManager toClass:[NSFileManager class]];
  [self bind:self.ltFileManager toClass:[LTFileManager class]];
  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    return [[LTRandom alloc] initWithSeed:kTestingSeed];
  } toClass:[LTRandom class]];
}

@end
