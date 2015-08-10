// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Photons)

- (instancetype)ptn_replayLastLazily {
  RACMulticastConnection *connection = [self multicast:[RACReplaySubject
                                                        replaySubjectWithCapacity:1]];
  return [[RACSignal
      defer:^{
        [connection connect];
        return connection.signal;
      }]
      setNameWithFormat:@"[%@] -ptn_replayLastLazily", self.name];
}

@end

NS_ASSUME_NONNULL_END
