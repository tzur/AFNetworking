// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectSnapshot+Tests.h"

NS_ASSUME_NONNULL_BEGIN

static const auto kWHSStepsIDs = @[
  nn([[NSUUID alloc] initWithUUIDString:@"C5DC25F9-8EA3-41CC-9BF6-C098F0BE28F2"]),
  nn([[NSUUID alloc] initWithUUIDString:@"DCC53438-B81E-4FB9-8640-DC5769557CCE"]),
  nn([[NSUUID alloc] initWithUUIDString:@"C4BD3739-242A-47E8-B9BA-13CF9EF91249"]),
  nn([[NSUUID alloc] initWithUUIDString:@"9E9AB27F-6CF8-433F-914B-DBF7FCEE9AC2"]),
  nn([[NSUUID alloc] initWithUUIDString:@"06A39F09-3906-4FA9-B8EC-013ABBAB26FC"])
];

@implementation WHSProjectSnapshot (TestUtils)

+ (instancetype)dummyProject {
  return [WHSProjectSnapshot dummyProjectWithStepsIDs:kWHSStepsIDs
                                           stepCursor:kWHSStepsIDs.count - 1];
}

+ (instancetype)dummyProjectWithNilStepsIDs {
  return [WHSProjectSnapshot dummyProjectWithStepsIDs:nil stepCursor:kWHSStepsIDs.count - 1];
}

+ (instancetype)dummyProjectWithNoStepsAfterCursor {
  return [WHSProjectSnapshot dummyProjectWithStepsIDs:kWHSStepsIDs stepCursor:kWHSStepsIDs.count];
}

+ (instancetype)dummyProjectWithZeroStepCursor {
  return [WHSProjectSnapshot dummyProjectWithStepsIDs:kWHSStepsIDs stepCursor:0];
}

+ (instancetype)dummyProjectWithStepsIDs:(nullable NSArray<NSUUID *> *)stepsIDs
                              stepCursor:(NSUInteger)stepCursor {
  auto projectID = [[NSUUID alloc] initWithUUIDString:@"8352CC13-CF1D-4DA7-BDBE-B805E79C2207"];
  return [[WHSProjectSnapshot alloc] initWithID:projectID bundleID:@"dummyBundle"
                                   creationDate:[NSDate date] modificationDate:[NSDate date]
                                       stepsIDs:stepsIDs stepCursor:stepCursor userData:nil
                                      assetsURL:[NSBundle mainBundle].bundleURL];
}

- (nullable NSArray<NSUUID *> *)stepsIDsAfterCursor {
  if (!self.stepsIDs) {
    return nil;
  }
  auto rangeAfterCursor = NSMakeRange(self.stepCursor, self.stepsIDs.count - self.stepCursor);
  return [nn(self.stepsIDs) subarrayWithRange:rangeAfterCursor];
}

@end

NS_ASSUME_NONNULL_END
