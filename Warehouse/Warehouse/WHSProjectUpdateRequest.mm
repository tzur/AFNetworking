// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectUpdateRequest.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WHSStepContent

- (instancetype)init {
  if (self = [super init]) {
    self.userData = [NSData data];
  }
  return self;
}

+ (instancetype)stepContentWithUserData:(NSData *)userData {
  auto stepContent = [[WHSStepContent alloc] init];
  stepContent.userData = userData;
  return stepContent;
}

+ (instancetype)stepContentWithUserData:(NSData *)userData
                        assetsSourceURL:(nullable NSURL *)assetsSourceURL {
  auto stepContent = [WHSStepContent stepContentWithUserData:userData];
  stepContent.assetsSourceURL = assetsSourceURL;
  return stepContent;
}

@end

@implementation WHSProjectUpdateRequest

- (instancetype)initWithProjectID:(NSUUID *)projectID {
  if (self = [super init]) {
    _projectID = projectID;
    self.stepIDsToDelete = @[];
    self.stepsContentToAdd = @[];
  }
  return self;
}

+ (nullable WHSProjectUpdateRequest *)requestForUndo:(WHSProjectSnapshot *)projectSnapshot {
  if (![projectSnapshot canUndo]) {
    return nil;
  }
  auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectSnapshot.ID];
  request.stepCursor = @(projectSnapshot.stepCursor - 1);
  return request;
}

+ (nullable WHSProjectUpdateRequest *)requestForRedo:(WHSProjectSnapshot *)projectSnapshot {
  if (!projectSnapshot.stepsIDs || ![projectSnapshot canRedo]) {
    return nil;
  }
  auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectSnapshot.ID];
  request.stepCursor = @(projectSnapshot.stepCursor + 1);
  return request;
}

+ (nullable WHSProjectUpdateRequest *)requestForAddStep:(WHSProjectSnapshot *)projectSnapshot
                                            stepContent:(WHSStepContent *)stepContent {
  if (!projectSnapshot.stepsIDs) {
    return nil;
  }
  auto request = [[WHSProjectUpdateRequest alloc] initWithProjectID:projectSnapshot.ID];
  request.stepsContentToAdd = @[stepContent];
  auto currentStepCursor = projectSnapshot.stepCursor;
  request.stepCursor = @(currentStepCursor + 1);
  auto currentStepsCount = projectSnapshot.stepsIDs.count;
  auto rangeToDelete = NSMakeRange(currentStepCursor, currentStepsCount - currentStepCursor);
  request.stepIDsToDelete = nn([projectSnapshot.stepsIDs subarrayWithRange:rangeToDelete]);
  return request;
}

@end

NS_ASSUME_NONNULL_END
