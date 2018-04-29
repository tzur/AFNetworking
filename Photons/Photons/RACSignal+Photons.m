// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+Photons.h"

#import <LTKit/NSError+LTKit.h>

#import "PTNImageAsset.h"
#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Photons)

- (RACSignal *)ptn_replayLastLazily {
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

- (RACSignal *)ptn_wrapErrorWithError:(NSError *)error {
  return [[self
      catch:^RACSignal *(NSError *underlyingError) {
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        return [RACSignal error:[NSError lt_errorWithCode:error.code userInfo:[userInfo copy]]];
      }]
      setNameWithFormat:@"[%@] -ptn_wrapErrorWithError: %@", self.name, error];
}

+ (RACSignal *)ptn_combineLatestWithIndex:(id<NSFastEnumeration>)signals {
  NSMutableArray *taggedSignals = [NSMutableArray array];

  for (RACSignal *signal in signals) {
    [taggedSignals addObject:[signal
        scanWithStart:nil reduceWithIndex:^id(id __unused running, id next, NSUInteger index) {
          return RACTuplePack(next, @(index));
        }]];
  }

  return [[[RACSignal
      zip:@[[RACSignal combineLatest:taggedSignals], [RACSignal combineLatest:signals]]]
      combinePreviousWithStart:nil reduce:^id(RACTuple * _Nullable previous, RACTuple *current) {
        if (!previous) {
          return RACTuplePack(current.second, nil);
        }

        RACTuple *previousCombineTagged = previous.first;
        RACTuple *currentCombineTagged = current.first;
        for (unsigned int i = 0; i < currentCombineTagged.count; ++i) {
          RACTuple *previousTaggedValue = previousCombineTagged[i];
          RACTuple *taggedValue = currentCombineTagged[i];

          if (![previousTaggedValue.second isEqualToNumber:taggedValue.second]) {
            return RACTuplePack(current.second, @(i));
          }
        }

        LTAssert(NO, @"Expected latest value tags to differ from the previous latest value tags "
                 "in at least one signal. Latest values with tags: %@, previous latest values with "
                 "tags: %@", currentCombineTagged, previousCombineTagged);
      }]
      setNameWithFormat:@"+ptn_combineLatestWithIndex: %@", signals];
}

- (RACSignal *)ptn_imageAndMetadata {
  return [[[self
      ptn_skipProgress]
      flattenMap:^(id<PTNImageAsset> asset) {
        return [RACSignal combineLatest:@[[asset fetchImage], [asset fetchImageMetadata]]];
      }]
      setNameWithFormat:@"[%@] -ptn_imageAndMetadata", self.name];
}

- (RACSignal *)ptn_image {
  return [[[self
      ptn_skipProgress]
      flattenMap:^(id<PTNImageAsset> asset) {
        return [asset fetchImage];
      }]
      setNameWithFormat:@"[%@] -ptn_image", self.name];
}

- (RACSignal *)ptn_skipProgress {
  return [[[self
      filter:^BOOL(PTNProgress *progress) {
        LTAssert([progress isKindOfClass:[PTNProgress class]], @"Expected PTNProgress object, got: "
                 "%@", NSStringFromClass([progress class]));
        return progress.result != nil;
      }]
      map:^id(PTNProgress *progress) {
        return progress.result;
      }]
      setNameWithFormat:@"[%@] -ptn_skipProgress", self.name];;
}

@end

NS_ASSUME_NONNULL_END
