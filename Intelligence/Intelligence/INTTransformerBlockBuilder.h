// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlock.h"
#import "INTTransformerBlockBuilderStructures.h"

NS_ASSUME_NONNULL_BEGIN

/// Builder of \c INTTransformerBlock blocks. The resulting \c INTTransformerBlock aggregates event
/// data with supplied aggregation blocks and completes the transformation with supplied transform
/// completion blocks. The resulting block aggregates and transforms data in the following fashion:
///
/// A. Resolve event type from the given \c eventIdentifier.
/// B. Update given aggregated data with results of all \c INTAggregationBlock blocks for the event
///    type.
/// C. Collect resulting high level events from transformer completion blocks for the event type.
/// D. Return aggregated data and collected events.
///
/// @attention transformation stages A-D are done in the sequence above, but there is no guarantee
/// for the order of invocation of blocks in each stage.
///
/// Examples:
///
/// Event mapping:
/// @code
/// NSString * _Nullable(^stringEventIdentifier)(id) = ^NSString * _Nullable(NSString *event) {
///   if (![event isKindOfClass:NSString.class]) {
///     return nil;
///   }
///
///   return event;
/// };
///
/// INTTransformerBlock *block = INTTransformerBuilder(stringEventIdentifier)
///     .transform(@"foo", ^(NSDictionary<NSString *, id> *, NSString *event,
///                          INTEventMetadata *metadata, INTAppContext *context) {
///       return @[
///         @{
///           @"event": event
///           @"foregroundTime": @(metadata.foregroundTime)
///           @"baz": appContext[@"baz"]
///         }
///       ];
///     })
///     .build();
///
/// auto metadata = [[INTEventMetadata alloc]
///                  initWithTotalRunTime:21 foregroundRunTime:13 deviceTimestamp:[NSDate date]
///                  eventID:[NSUUID UUID]];
///
/// auto result = block(@{}, @"foo", metadata, @{"@baz": @55});
/// NSLog(@"%@", result.highLevelEvents); // prints "[{event: foo, foregroundTime: 13, baz: 55}]".
/// @endcode
///
/// Event aggregation:
/// @code
/// INTTransformerBlock *block = INTTransformerBuilder(stringEventIdentifier)
///     .aggregate(@"foo", ^(NSDictionary<NSString *, id> *aggregatedData, NSString *) {
///       NSUInteger counter = [aggregatedData[@"counter"] unsignedIntegerValue];
///       return @{@"counter": @(counter + 1)};
///     })
///     .aggregate(@"bar", ^(NSDictionary<NSString *, id> *, NSString *, INTEventMetadata *,
///                          INTAppContext *context) {
///       return @{
///         @"baz": appContext[@"baz"] ?: [NSNull null]
///       };
///     })
///     .transform(@"bar", ^(NSDictionary<NSString *, id> *aggregationData) {
///       return @[
///         @{
///           @"counter": aggregation[@"counter"] :? @0;
///           @"baz": appContext[@"baz"]
///         }
///        ];
///     })
///     .build()
///
/// auto result = block(@{}, @"foo", metadata, @{});
/// NSLog(@"%@", result.highLevelEvents); // prints "[]".
/// result = block(result.aggregationData, @"bar", metadata, @{@"baz": @35});
/// NSLog(@"%@", result.highLevelEvents); // prints "[{counter:1, baz:35}]".
///
/// result = block(result.aggregationData, @{}, metadata, @"foo");
/// result = block(result.aggregationData, @{}, metadata, @"bar");
/// NSLog(@"%@", result.highLevelEvents); // prints "[{counter:2, baz:null}]".
/// @endcode
///
/// Event type as class name:
/// @code
/// /// Represents an event where the user logged into his/her account.
/// @interface INTUserLoggedInEvent : NSObject
/// @end
///
/// @implementation INTUserLoggedInEvent
/// @end
///
/// /// Represents an event where the user logged into his/her account, indicating the amount of
/// /// login actions the user had made, including the current, during the application run.
/// @interface INTUserLoggedHighLevelEvent : NSObject
/// @property (nonatomic) NSUInteger loginsCount;
/// @end
///
/// @implementation INTUserLoggedHighLevelEvent
///
/// - (NSString *)description {
///   return [NSString stringWithFormat:@"user logged %lu time(s)", self.loginsCount];
/// }
///
/// @end
///
/// INTTransformerBlock *block = INTTransformerBuilder()
///     .aggregate(NSStringFromClass(INTUserLoggedEvent.class),
///                ^(NSDictionary<NSString *, id> *, INTFakeClass *) {
///       auto loginsCount = [aggregatedData[@"loginsCount"] unsignedIntegerValue];
///       return @{@"loginsCount": @(loginsCount + 1)};
///     })
///     .transform(NSStringFromClass(INTUserLoggedEvent.class),
///                ^(NSDictionary<NSString *, id> *aggregatedData) {
///       auto event = [[INTUserLoggedHighLevelEvent alloc] init];
///       event.loginsCount = [aggregatedData[@"fooSum"] unsignedIntegerValue];
///
///       return @[event];
///     })
///     .build();
///
/// auto result = block(@{}, [[INTUserLoggedInEvent alloc] init], metadata, @{});
/// NSLog(@"%@", result.highLevelEvents.firstObject); // prints "user logged 1 time(s)".
/// result = block(result.aggregationData, [[INTUserLoggedInEvent alloc] init], metadata, @{});
/// NSLog(@"%@", result.highLevelEvents.firstObject); // prints "user logged 2 time(s)".
/// @endcode
@interface INTTransformerBlockBuilder : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new builder with \c eventIdentifier. \c eventIdentifier is used for identifying
/// input events. If \c eventIdentifier returns \c nil for an input event, this event is ignored.
/// \c eventIdentifier must be a pure function. Raises an \c NSInvalidArgumentException if
/// \c eventIdentifier is \c nil.
///
/// @note if \c eventIdentifier always returns the class name of its input event, then
/// <tt>+[INTTransformerBuilder defaultBuilder]</tt> can be used.
+ (instancetype)builderWithEventIdentifier:(INTEventIdentifierBlock)eventIdentifier;

/// Returns new builder with an \c eventIdentifier that returns the class name of the input event.
///
/// @attention using class name as an event identifier means that all assigned blocks for a specific
/// class name are not invoked when an instance of a subclass is processed with the resulting
/// \c INTTransformerBlock.
+ (instancetype)defaultBuilder;

/// Returns a block that adds an aggregation block to invoke on events of \c eventType when invoked.
/// \c intl::AggregationBlock must supply a pure function that returns the changes to apply to the
/// aggregated data. Setting \c NSNull to a key, results in it's removal. Its possible to add
/// multiple aggregation blocks per \c eventType. This step is optional.
- (INTTransformerBlockBuilder *(^)(NSString *eventType, intl::AggregationBlock))aggregate;

/// Returns a block that adds transform completion block to invoke on events of \c eventType when
/// invoked. Events returned from the block are be considered hight level events, as defined by
/// the \C INTTransformerBlock documentation and are returned by the resulting
/// \c INTTransformerBlock when an event of type \c eventType is processed.
/// \c INTTransformCompletionBlock must be a pure function. It's possible to add multiple completion
/// blocks per \c eventType. This step is optional.
- (INTTransformerBlockBuilder *(^)(NSString *eventType, intl::TransformCompletionBlock))transform;

/// Builds a transformer block with an event identifier and supplied blocks per event type. This
/// method must be called to conclude the transformer block creation.
- (INTTransformerBlock(^)())build;

@end

#ifdef __cplusplus
extern "C" {
#endif

/// Creates a new instance of \c INTTransformerBlockBuilder. If \c eventIdentifier is nil then this
/// is a shortcut for <tt>+[INTTransformerBlockBuilder defaultBuilder]</tt>, otherwise this is a
/// shortcut for <tt>+[INTTransformerBlockBuilder builderWithEventIdentifier:]</tt>.
inline INTTransformerBlockBuilder *INTTransformerBuilder
    (INTEventIdentifierBlock _Nullable eventIdentifier = nil) {
  if (!eventIdentifier) {
    return [INTTransformerBlockBuilder defaultBuilder];
  }
  return [INTTransformerBlockBuilder builderWithEventIdentifier:eventIdentifier];
}

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
