// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, BZREventType,
  BZREventTypeNonCriticalError,
  BZREventTypeCriticalError,
  BZREventTypeInformational,
  BZREventTypeReceiptValidationStatusReceived,
  BZREventTypePromotedIAPInitiated
);

@implementation BZREvent

- (instancetype)initWithType:(BZREventType *)eventType eventError:(NSError *)eventError {
  LTAssert([eventType isEqual:$(BZREventTypeNonCriticalError)] ||
           [eventType isEqual:$(BZREventTypeCriticalError)], @"An error event cannot have the "
           "event type %@.", eventType);
  if (self = [super init]) {
    _eventType = eventType;
    _eventError = eventError;
  }
  return self;
}

- (instancetype)initWithType:(BZREventType *)eventType eventInfo:(NSDictionary *)eventInfo {
  LTAssert(![eventType isEqual:$(BZREventTypeNonCriticalError)] &&
           ![eventType isEqual:$(BZREventTypeCriticalError)], @"A non-error event cannot have the "
           "event type %@.", eventType);
  if (self = [super init]) {
    _eventType = eventType;
    _eventInfo = eventInfo;
  }
  return self;
}

- (instancetype)initWithType:(BZREventType *)eventType eventSubtype:(NSString *)eventSubtype
                   eventInfo:(NSDictionary *)eventInfo {
  LTAssert(![eventType isEqual:$(BZREventTypeNonCriticalError)] &&
           ![eventType isEqual:$(BZREventTypeCriticalError)], @"A non-error event cannot have the "
           "event type %@.", eventType);
  if (self = [super init]) {
    _eventType = eventType;
    _eventInfo = eventInfo;
    _eventSubtype = eventSubtype;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
