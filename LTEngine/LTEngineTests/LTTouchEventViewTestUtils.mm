// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventViewTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIFakeTouch
@synthesize timestamp = _timestamp;
@synthesize phase = _phase;
@end

UIFakeTouch *LTTouchEventViewCreateTouch(NSTimeInterval timestamp) {
  UIFakeTouch *touch = [[UIFakeTouch alloc] init];
  touch.timestamp = timestamp;
  return touch;
}

NSArray<UIFakeTouch *> *LTTouchEventViewCreateTouches(std::vector<NSTimeInterval> timestamps) {
  NSMutableArray<UIFakeTouch *> *touchMocks = [NSMutableArray arrayWithCapacity:timestamps.size()];
  for (NSTimeInterval timestamp : timestamps) {
    [touchMocks addObject:LTTouchEventViewCreateTouch(timestamp)];
  }
  return [touchMocks copy];
}

UIEvent *LTTouchEventViewCreateEvent() {
  return OCMClassMock([UIEvent class]);
}

void LTTouchEventViewMakeEventReturnTouchesForTouch(id eventMock, UITouch *mainTouch,
                                                    NSArray<UITouch *> *coalescedTouches,
                                                    NSArray<UITouch *> *predictedTouches) {
  OCMStub([eventMock coalescedTouchesForTouch:mainTouch]).andReturn(coalescedTouches);
  OCMStub([eventMock predictedTouchesForTouch:mainTouch]).andReturn(predictedTouches);
}

NS_ASSUME_NONNULL_END
