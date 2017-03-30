// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestModule.h"

#import <LTEngine/LTTextureArchiverNonPersistentStorage.h>
#import <LTEngine/LTTextureRepository.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTRandom.h>

@implementation LTTestModule

static const NSUInteger kTestingSeed = 1234;

- (void)configure {
  [super configure];

  [self bind:[UIApplication sharedApplication] toClass:[UIApplication class]];
  [self bind:[UIDevice currentDevice] toClass:[UIDevice class]];
  [self bind:[UIScreen mainScreen] toClass:[UIScreen class]];
  [self bind:[NSLocale currentLocale] toClass:[NSLocale class]];

  [self bind:nil toClass:[NSFileManager class]];
  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    return [[LTRandom alloc] initWithSeed:kTestingSeed];
  } toClass:[LTRandom class]];

  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    id<LTTextureArchiverStorage> storage = [[LTTextureArchiverNonPersistentStorage alloc] init];
    LTTextureRepository *textureRepository = [[LTTextureRepository alloc] init];
    return [[LTTextureArchiver alloc] initWithStorage:storage textureRepository:textureRepository];
  } toClass:[LTTextureArchiver class]];
}

@end
