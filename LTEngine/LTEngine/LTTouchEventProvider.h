// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTContentTouchEvent, LTTouchEvent;

/// Protocol to be implemented by objects providing information about currently occurring touch
/// event sequences.
@protocol LTTouchEventProvider <NSObject>

/// Returns all touch events belonging to currently existing touch event sequences with phase
/// \c UITouchPhaseStationary.
- (NSSet<id<LTTouchEvent>> *)stationaryTouchEvents;

@end

/// Protocol to be implemented by objects providing information about currently occurring content
/// touch event sequences.
@protocol LTContentTouchEventProvider <NSObject>

/// Returns all content touch events belonging to currently existing content touch event sequences
/// with phase \c UITouchPhaseStationary.
- (NSSet<id<LTContentTouchEvent>> *)stationaryContentTouchEvents;

@end

NS_ASSUME_NONNULL_END
