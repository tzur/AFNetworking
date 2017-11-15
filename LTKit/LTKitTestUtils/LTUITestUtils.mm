// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTUITestUtils.h"

#import <Specta/SpectaUtility.h>

NS_ASSUME_NONNULL_BEGIN

void LTAddInterruptionMonitor(LTUIInterruptionHandler *UIInterruptionHandler) {
  [SPTCurrentSpec addUIInterruptionMonitorWithDescription:UIInterruptionHandler.descriptionText
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
