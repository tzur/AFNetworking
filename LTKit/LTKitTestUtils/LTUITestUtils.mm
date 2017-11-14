// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTUITestUtils.h"

#import <Specta/Specta.h>

NS_ASSUME_NONNULL_BEGIN

static inline SPTSpec * _Nullable SPTCurrentSpec() {
  return [[NSThread mainThread] threadDictionary][@"SPTCurrentSpec"];
}

void LTAddInterruptionMonitor(LTUIInterruptionHandler *UIInterruptionHandler) {
  SPTSpec *spec = SPTCurrentSpec();
  [spec addUIInterruptionMonitorWithDescription:UIInterruptionHandler.descriptionText
                                        handler:UIInterruptionHandler.block];
}

LTUIInterruptionHandler *LTGetAllowAllAlertsBlock() {
  return [[LTUIInterruptionHandler alloc] initWithDescription:@"Allow all alerts"
                                                    withBlock:^BOOL(XCUIElement *alert) {
    if (alert.buttons[@"Allow"].exists) {
      [alert.buttons[@"Allow"] tap];
      return YES;
    }
    else if (alert.buttons[@"OK"].exists) {
      [alert.buttons[@"OK"] tap];
      return YES;
    }
    return NO;
  }];
}

NS_ASSUME_NONNULL_END
