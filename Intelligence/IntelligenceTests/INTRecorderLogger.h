// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import <Intelligence/INTEventLogger.h>

NS_ASSUME_NONNULL_BEGIN

/// Block for registering for updates on \c eventsLogged of INTRecorderLogger. The array passed to
/// this block is all the events logged.
typedef void (^INTRecorderLoggerEventBlock)(NSArray *);

/// Block returning \c YES if an event should be logged.
typedef BOOL(^INTEventFilterBlock)(id);

/// Event logger that records the events that are logged to it.
@interface INTRecorderLogger : NSObject <INTEventLogger>

/// Initializes with a filter that always returns \c YES.
- (instancetype)init;

/// Initializes with a filter that always returns \c YES.
- (instancetype)initWithEventFilter:(INTEventFilterBlock)eventFilter;

/// Initializes with a filter that always returns \c YES and \c eventBlock.
- (instancetype)initWithNewEventBlock:(INTRecorderLoggerEventBlock)eventBlock;

/// Initializes with an \c eventFilter and \c eventBlock. \c eventFilter returns \c NO if a given
/// event should not be logged.
- (instancetype)initWithEventFilter:(INTEventFilterBlock)eventFilter
                      newEventBlock:(INTRecorderLoggerEventBlock)eventBlock
    NS_DESIGNATED_INITIALIZER;

/// Holds all the events that were logged by this logger, in the order they were received.
@property (readonly, nonatomic) NSArray *eventsLogged;

/// Logs \c event only if it's supported by the receiver. If \c event is not supported by the
/// receiver, raises an \c NSInvalidArgumentException. This call is thread safe.
- (void)logEvent:(id)event;

@end

NS_ASSUME_NONNULL_END
