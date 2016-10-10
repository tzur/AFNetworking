// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"
#import "LTValueObject.h"

NS_ASSUME_NONNULL_BEGIN

@class LTEventBus;

/// Event that is sent when a log message is created.
@interface LTLoggerEvent : LTValueObject

/// Initializes with the log \c message.
- (instancetype)initWithMessage:(NSString *)message NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Log message included in the event.
@property (readonly, nonatomic) NSString *message;

@end

/// Logger target that sends events to the given event bus on \c outputString:.
@interface LTEventBusLoggerTarget : NSObject <LTLoggerTarget>

/// Initializes with the event bus to send the events to.
- (instancetype)initWithEventBus:(LTEventBus *)eventBus NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
