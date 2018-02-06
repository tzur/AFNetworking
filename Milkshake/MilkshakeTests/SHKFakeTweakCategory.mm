// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKFakeTweakCategory.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SHKFakeTweakCategory

@synthesize name = _name;

- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections {
  return [self initWithName:name tweakCollections:tweakCollections updateSignal:nil];
}

- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections
                updateSignal:(nullable RACSignal *)updateSignal {
  if (self = [super init]) {
    _name = name;
    _tweakCollections = tweakCollections;
    _updateSignal = updateSignal;
  }
  return self;
}

- (RACSignal *)update {
  return nn(self.updateSignal);
}

- (void)reset {
  self.resetCalled = YES;
}

@end

@implementation SHKPartialFakeTweakCategory

@synthesize name = _name;
@synthesize tweakCollections = _tweakCollections;

- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections {
  if (self = [super init]) {
    _name = name;
    _tweakCollections = tweakCollections;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
