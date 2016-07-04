// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@protocol LTContentTouchEvent;

/// Protocol to be implemented by objects deciding whether a given \c id<LTContentTouchEvent> object
/// is considered valid, given another \c id<LTContentTouchEvent> object.
@protocol LTContentTouchEventPredicate <NSObject>

/// Returns \c YES if the provided \c event is valid, given the \c baseEvent.
- (BOOL)isValidEvent:(id<LTContentTouchEvent>)event
          givenEvent:(id<LTContentTouchEvent>)baseEvent;

@end

/// Protocol to be implemented by objects that constitute a composite of
/// \c id<LTContentTouchEventPredicate> objects. The specific way the predicates are combined
/// depends on the implementation of the object conforming to this protocol.
@protocol LTContentTouchEventMultiPredicate <LTContentTouchEventPredicate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the predicate composed with the given \c predicates.
- (instancetype)initWithPredicates:(NSArray<id<LTContentTouchEventPredicate>> *)predicates;

/// Returns a new predicate composed with the given \c predicates.
+ (instancetype)predicateWithPredicates:(NSArray<id<LTContentTouchEventPredicate>> *)predicates;

/// Predicates composing this instance.
@property (readonly, nonatomic) NSArray<id<LTContentTouchEventPredicate>> *predicates;

@end
