// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

NS_ASSUME_NONNULL_BEGIN

@class LTEventBus;

@protocol LTMessageContainer;

/// Object that observes an event bus and saves all the events to a messageContainer container.
///
/// Each received event will be converted to message in the format
/// <tt><date> [<eventClass>] <eventDescription></tt>.
@interface LTEventBusObserver : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this logger that listens to events sent on \c eventBus and saves them to
/// \c messageContainer. All entries will be logged, except those of a class listed in
/// \c ignoredEventsClasses.
- (instancetype)initWithMessageContainer:(id<LTMessageContainer>)messageContainer
                                eventBus:(LTEventBus *)eventBus
                    ignoredEventsClasses:(NSArray<Class> *)ignoredEventsClasses
    NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
