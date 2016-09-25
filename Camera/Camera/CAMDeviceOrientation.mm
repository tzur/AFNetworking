// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMDeviceOrientation.h"

#import <CoreMotion/CoreMotion.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAMDeviceOrientation ()

/// \c CoreMotion manager used by this class.
@property (readonly, nonatomic) CMMotionManager *manager;

@end

@implementation CAMDeviceOrientation

- (instancetype)init {
  return [self initWithMotionManager:[[CMMotionManager alloc] init]];
}

- (instancetype)initWithMotionManager:(CMMotionManager *)motionManager {
  if (self = [super init]) {
    _manager = motionManager;
  }
  return self;
}

- (RACSignal *)deviceOrientationWithRefreshInterval:(NSTimeInterval)refreshInterval {
  CMMotionManager *manager = self.manager;
  return [[[[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if (!manager.deviceMotionAvailable) {
          [subscriber sendError:[NSError lt_errorWithCode:CAMErrorCodeDeviceMotionUnavailable]];
          return nil;
        }
        manager.deviceMotionUpdateInterval = refreshInterval;
        [manager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                     withHandler:^(CMDeviceMotion *motion, NSError *error) {
          if (!error) {
            [subscriber sendNext:@([CAMDeviceOrientation deviceOrientationFromMotion:motion])];
          } else {
            [manager stopDeviceMotionUpdates];
            [subscriber sendError:[NSError lt_errorWithCode:CAMErrorCodeDeviceMotionUpdateError
                                            underlyingError:error]];
          }
        }];

        return [RACDisposable disposableWithBlock:^{
          [manager stopDeviceMotionUpdates];
        }];
      }]
      takeUntil:[self rac_willDeallocSignal]]
      distinctUntilChanged]
      ignore:@(UIInterfaceOrientationUnknown)]
      setNameWithFormat:@"-deviceOrientationWithRefreshInterval: %f", refreshInterval];
}

+ (UIInterfaceOrientation)deviceOrientationFromMotion:(CMDeviceMotion *)motion {
  CMAcceleration gravity = motion.gravity;

  // Check if the device is lying flat, face up/down.
  if (std::abs(gravity.x) + std::abs(gravity.y) < 0.1 * std::abs(gravity.z)) {
    return UIInterfaceOrientationUnknown;
  }

  double angle = atan2(gravity.x, gravity.y);
  UIInterfaceOrientation orientation;
  if (angle < -3 * M_PI_4) {
    orientation = UIInterfaceOrientationPortrait;
  } else if (angle < -1 * M_PI_4) {
    orientation = UIInterfaceOrientationLandscapeRight;
  } else if (angle < 1 * M_PI_4) {
    orientation = UIInterfaceOrientationPortraitUpsideDown;
  } else if (angle < 3 * M_PI_4) {
    orientation = UIInterfaceOrientationLandscapeLeft;
  } else {
    orientation = UIInterfaceOrientationPortrait;
  }
  return orientation;
}

@end

NS_ASSUME_NONNULL_END
