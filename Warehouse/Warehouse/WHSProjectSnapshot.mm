// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WHSProjectSnapshot

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                  bundleIdentifier:(NSString *)bundleIdentifier creationDate:(NSDate *)creationDate
                  modificationDate:(NSDate *)modificationDate size:(uint64_t)size
                             steps:(nullable NSArray<NSUUID *> *)steps
                        stepCursor:(NSUInteger)stepCursor
                          userData:(nullable NSDictionary<NSString *, id> *)userData
                         assetsURL:(NSURL *)assetsURL {
  if (self = [super init]) {
    _identifier = identifier;
    _bundleIdentifier = bundleIdentifier;
    _creationDate = creationDate;
    _modificationDate = modificationDate;
    _size = size;
    _steps = steps;
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
  return self.stepCursor < self.steps.count;
}

@end

@implementation WHSStep

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                 projectIdentifier:(NSUUID *)projectIdentifier
                          userData:(NSDictionary<NSString *, id> *)userData
                         assetsURL:(NSURL *)assetsURL {
  if (self = [super init]) {
    _identifier = identifier;
    _projectIdentifier = projectIdentifier;
    _userData = userData;
    _assetsURL = assetsURL;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
