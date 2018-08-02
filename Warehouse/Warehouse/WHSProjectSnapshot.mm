// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WHSProjectSnapshot

- (instancetype)initWithID:(NSUUID *)ID bundleID:(NSString *)bundleID
              creationDate:(NSDate *)creationDate modificationDate:(NSDate *)modificationDate
                  stepsIDs:(nullable NSArray<NSUUID *> *)stepsIDs stepCursor:(NSUInteger)stepCursor
                  userData:(nullable NSData *)userData assetsURL:(NSURL *)assetsURL {
  if (self = [super init]) {
    _ID = ID;
    _bundleID = bundleID;
    _creationDate = creationDate;
    _modificationDate = modificationDate;
    _stepsIDs = stepsIDs;
    _stepCursor = stepCursor;
    _userData = userData;
    _assetsURL = assetsURL;
  }
  return self;
}

@end

@implementation WHSProjectSnapshot (AvailableOperations)

- (BOOL)canUndo {
  return self.stepCursor;
}

- (BOOL)canRedo {
  return self.stepCursor < self.stepsIDs.count;
}

@end

@implementation WHSStep

- (instancetype)initWithID:(NSUUID *)ID projectID:(NSUUID *)projectID userData:(NSData *)userData
                 assetsURL:(NSURL *)assetsURL {
  if (self = [super init]) {
    _ID = ID;
    _projectID = projectID;
    _userData = userData;
    _assetsURL = assetsURL;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
