// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "WFVolumeButtonEvents.h"

#import "WFVolumeButtonEvent+NotificationName.h"

@interface UIApplication ()
- (void)setWantsVolumeButtonEvents:(BOOL)enable;
@end

/// Posts a notification which corresponds to the given \c event using the default notification
/// center.
static void WFPostNotification(WFVolumeButtonEvent *event) {
  [[NSNotificationCenter defaultCenter] postNotificationName:event.notificationName object:nil];
}

SpecBegin(WFVolumeButtonEvents)

it(@"should return a signal which fires volume button events", ^{
  auto recorder = [WFVolumeButtonEvents() testRecorder];
  WFPostNotification($(WFVolumeButtonEventVolumeUpPress));
  expect(recorder).will.sendValuesWithCount(1);
  expect(recorder.values[0]).to.equal($(WFVolumeButtonEventVolumeUpPress));

  WFPostNotification($(WFVolumeButtonEventVolumeUpRelease));
  expect(recorder).will.sendValuesWithCount(2);
  expect(recorder.values[1]).to.equal($(WFVolumeButtonEventVolumeUpRelease));

  WFPostNotification($(WFVolumeButtonEventVolumeDownPress));
  expect(recorder).will.sendValuesWithCount(3);
  expect(recorder.values[2]).to.equal($(WFVolumeButtonEventVolumeDownPress));

  WFPostNotification($(WFVolumeButtonEventVolumeDownRelease));
  expect(recorder).will.sendValuesWithCount(4);
  expect(recorder.values[3]).to.equal($(WFVolumeButtonEventVolumeDownRelease));
});

it(@"should fire the same event in multiple signals", ^{
  auto recorder = [WFVolumeButtonEvents() testRecorder];
  auto recorder2 = [WFVolumeButtonEvents() testRecorder];
  WFPostNotification($(WFVolumeButtonEventVolumeUpPress));

  expect(recorder).will.sendValues(@[$(WFVolumeButtonEventVolumeUpPress)]);
  expect(recorder2).will.sendValues(@[$(WFVolumeButtonEventVolumeUpPress)]);
});

it(@"should disable events generation when no active subscription", ^{
  UIApplication *applicationMock = OCMStrictClassMock([UIApplication class]);
  OCMExpect([applicationMock setWantsVolumeButtonEvents:YES]);
  OCMExpect([applicationMock setWantsVolumeButtonEvents:NO]);
  auto events = WFVolumeButtonEvents(applicationMock);
  auto events1 = WFVolumeButtonEvents(applicationMock);
  auto disposable = [events subscribeNext:^(WFVolumeButtonEvent * _Nullable) {}];
  auto disposable1 = [events1 subscribeNext:^(WFVolumeButtonEvent * _Nullable) {}];
  [disposable dispose];
  [disposable1 dispose];
  OCMVerifyAll(applicationMock);
});

SpecEnd
