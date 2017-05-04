// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlock.h"
#import "INTTransformerBlockBuilderStructures.h"

NS_ASSUME_NONNULL_BEGIN

/// Builder of \c INTTransformerBlock blocks. The resulting \c INTTransformerBlock aggregates event
/// data in a cycle, starting and completing a transformation on a start and end event types,
/// respectively. The block may aggregate data on other event types during an active cycle, as
/// specified by the \c aggregate method. The resulting block aggregates and transforms data in the
/// following fashion:
///
/// A. Resolve event type from the given \c eventIdentifier.
/// B. Start or continue a cycle if:
///   - The event type was resolved by \c eventIdentifier.
///   - The event type is the start event or a start event was processed and an end event has yet to
///     be processed.
/// C. Update given aggregated data with results of all \c INTAggregationBlock blocks for the event
///    type.
/// D. If event type is the end event, complete the transformation and collect the resulting high
///    level events.
/// E. Return aggregated data and collected high level events.
///
/// @attention transformation stages A-E are done in the sequence above, but there is no guarantee
/// for the order of invocation of blocks in each stage.
///
/// Examples:
///
/// Aggregation of multiple events, including event types other than the start and end events:
/// @code
/// /// Represents an event where the app entered a foreground state, indicating the reason that
/// /// made it move into the foreground.
/// @interface INTAppDidEnterForeground : NSObject
/// @property (nonatomic) NSTimeInterval foregroundReason;
/// @end
///
/// @implementation INTAppDidEnterForeground
///
/// - (NSString *)description {
///   return [NSString stringWithFormat:@"foreground reason: %@ secs", self.foregroundReason];
/// }
///
/// @end
///
/// INTTransformerBlock block = INTCycleTransformerBlockBuilder(stringEventIdentifier)
///     .cycle(@"foreground", @"appBecameActive")
///     .aggregate(@"foreground", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
///       return @{@"foregroundReason": @"organic"};
///     })
///     .aggregate(@"deepLinkOpened", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
///       return @{@"foregroundReason": @"link"};
///     })
///     .aggregate(@"notificationOpened", ^(NSDictionary<NSString *, id> *aggregatedData,
///                                         NSString *) {
///       return @{@"foregroundReason": @"notification"};
///     })
///     .onCycleEnd(^(NSDictionary<NSString *, id> *aggregationData) {
///       auto event = [[INTAppDidEnterForeground alloc] init];
///       event.foregroundReason = aggregationData[@"foregroundReason"];
///       return @[event];
///     })
///     .build();
///
/// auto result = block(@{}, @"foreground", INTCreateEventMetadata(), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
/// result = block(result.aggregationData, @"appBecameActive", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents.firstObject); // prints "foreground reason: organic"
/// result = block(result.aggregationData, @"appBecameActive", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
///
/// result = block(@{}, @"foreground", INTCreateEventMetadata(), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
/// result = block(result.aggregationData, @"deepLinkOpened", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
/// result = block(result.aggregationData, @"appBecameActive", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents.firstObject); // prints "foreground reason: link"
///
/// result = block(@{}, @"foreground", INTCreateEventMetadata(), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
/// result = block(result.aggregationData, @"notificationOpened", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
/// result = block(result.aggregationData, @"appBecameActive", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents.firstObject); // prints "foreground reason: notification"
/// @endcode
///
/// Automatic duration counting
/// @code
/// /// Represents an event where the app entered a background state, indicating the amount of time
/// /// spent in foreground.
/// @interface INTAppDidEnterBackground : NSObject
/// @property (nonatomic) NSTimeInterval foregroundDuration;
/// @end
///
/// @implementation INTAppDidEnterBackground
///
/// - (NSString *)description {
///   return [NSString stringWithFormat:@"foreground duration: %lu secs", self.foregroundDuration];
/// }
///
/// @end
///
/// INTTransformerBlock block = INTCycleTransformerBlockBuilder(stringEventIdentifier)
///     .cycle(@"foreground", @"background")
///     .appendDuration(@"foregroundDuration")
///     .onCycleEnd(^(NSDictionary<NSString *, id> *aggregationData) {
///       auto event = [[INTAppDidEnterBackground alloc] init];
///       event.foregroundDuration = [aggregationData[@"foregroundDuration"] doubleValue];
///       return @[event];
///     })
///     .build();
///
/// auto result = block(@{}, @"foreground", INTCreateEventMetadata(1), @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]"
/// result = block(result.aggregationData, @"background", INTCreateEventMetadata(5), @{});
/// NSLog(@"%@", result.highLevelEvents.firstObject); // prints "foreground duration: 4 secs"
/// @endcode
@interface INTCycleTransformerBlockBuilder : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new builder with \c eventIdentifier, used for identifying input events.
+ (instancetype)builderWithEventIdentifier:(INTEventIdentifierBlock)eventIdentifier;

/// Returns new builder with an \c eventIdentifier that returns the class name of the input event.
///
/// @attention using class name as an event identifier means that all assigned blocks for a specific
/// class name are not invoked when an instance of a subclass is processed with the resulting
/// \c INTTransformerBlock.
+ (instancetype)defaultBuilder;

/// Returns a block that sets the events which start and end a transformation cycle. This step is
/// mandatory.
- (INTCycleTransformerBlockBuilder *(^)(NSString *startEventType, NSString *endEventType))cycle;

/// Returns a block that adds an aggregation block to invoke on events of \c eventType when invoked.
/// This method can be used for event types other than the start and end events of the cycle,
/// allowing arbitrary events within a cycle, for data aggragation. \c intl::AggregationBlock must
/// supply a pure function that returns the changes to apply to the aggregated data. Setting
/// \c NSNull to a key, results in its removal. Its possible to add multiple aggregation blocks per
/// \c eventType. This step is optional.
- (INTCycleTransformerBlockBuilder *(^)(NSString *eventType, intl::AggregationBlock))aggregate;

/// Returns a block that sets the completion block to invoke in the end of the transformation cycle
/// when invoked. Events returned from the block are be considered hight level events, as defined by
/// the \C INTTransformerBlock documentation and are returned by the resulting
/// \c INTTransformerBlock when an event of type \c eventType is processed.
/// \c intl::TransformCompletionBlock must supply a pure function. only one completion block can be
/// set for a cycle, the last set competion block will be used in the resulting
/// \c INTTransformerBlock. This step is mandatory.
- (INTCycleTransformerBlockBuilder *(^)(intl::TransformCompletionBlock))onCycleEnd;

/// Returns a block that adds a the key in which the cycle duration will be counted. The cycle
/// duration is calculated according to \c totalRuntime passed in the \c metadata parameter. This
/// step is optional.
- (INTCycleTransformerBlockBuilder *(^)(NSString *key))appendDuration;

/// Builds a transformer block with the set parameters. If
/// <tt>-[INTCycleTransformerBlockBuilder cycle]</tt> or
/// <tt>-[INTCycleTransformerBlockBuilder defaultBuilder]</tt>have not been called, an exception
/// will be raised.
- (INTTransformerBlock (^)())build;

@end

#ifdef __cplusplus
extern "C" {
#endif

/// Creates a new instance of \c INTCycleTransformerBlockBuilder. If \c eventIdentifier is nil then
/// this is a shortcut for <tt>+[INTCycleTransformerBlockBuilder defaultBuilder]</tt>, otherwise
/// this is a shortcut for <tt>+[INTCycleTransformerBlockBuilder builderWithEventIdentifier:]</tt>.
inline INTCycleTransformerBlockBuilder
      *INTCycleTransformerBuilder(INTEventIdentifierBlock _Nullable eventIdentifier = nil) {
  if (!eventIdentifier) {
    return [INTCycleTransformerBlockBuilder defaultBuilder];
  }
  return [INTCycleTransformerBlockBuilder builderWithEventIdentifier:eventIdentifier];
}

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
