// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventViewTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

UITouch *LTTouchEventViewCreateTouch(NSTimeInterval timestamp) {
  id touchMock = OCMClassMock([UITouch class]);
  OCMStub([touchMock timestamp]).andReturn(timestamp);
  return touchMock;
}

NSArray<UITouch *> *LTTouchEventViewCreateTouches(std::vector<NSTimeInterval> timestamps) {
  NSMutableArray<UITouch *> *touchMocks = [NSMutableArray arrayWithCapacity:timestamps.size()];
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
