// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Photons)

- (instancetype)ptn_replayLastLazily {
  RACMulticastConnection *connection = [self multicast:[RACReplaySubject
                                                        replaySubjectWithCapacity:1]];
  // A new signal is created here instead of defer since under specific race conditions a value
  // can be missed and lost entirely when using defer.
  //
  // The defer operator creates and returns a signal that subscribes to the original signal in its
  // subscribe block.
  // \c RACReplaySubject holds an internal intermmediate subject used to pass values after
  // subscription and to replay values upon late subscription. All the while itself being subscribed
  // to the original signal.
  //
  // Since \c RACReplaySubject first connects (subscribes up to the original signal) and only
  // afterwards subscribes subscribers to itself, quick on-subscription operation related values can
  // be received by it before it adds subscribers to itself.
  // In such a case the values won't be sent directly to its subscribers. Luckily the recording of
  // values does occur, so subscribers receive the values by replay upon their subscription.
  //
  // The \c replayLazily operator has an infinite replay capacity, thus this phenomena has no vital
  // effect - the subscribers receive the values, not knowing that they're actually echoes of the
  // past.
  //
  // This operator on the other hand is vulnerable to such an effect. Receiving the replayed values
  // instead of passed-through originals has no immediate consequences, but rather its limited
  // capacity is the true culprit. If multiple values are passed in during that crucial purgatory
  // time, when the \c replaySignal is subscribed above but yet to have subscribers of its own, it
  // records only the last value received, discarding earlier values completely.
  //
  // To overcome this we create a new signal that first subscribes its own subscribers to itself and
  // only afterwards subscribes itself the the underlying signal.
  // Defer with \c RACMulticastConnection can actually achieve this with \c autoconnect but it
  // permanently stops subscribing when it reaches 0 subscribers.
  //
  // @note Unlike \c replayLazily but rather like \c replayLast this operator doesn't naturally
  // dispose of its internal subscribtion and it can be disposed only if the source signal completes
  // or errs.
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACDisposable *disposable = [connection.signal subscribe:subscriber];
    [connection connect];
    return disposable;
  }] setNameWithFormat:@"[%@] -ptn_replayLastLazily", self.name];
}

@end

NS_ASSUME_NONNULL_END
