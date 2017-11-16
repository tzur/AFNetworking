// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@interface UIFakeTouch : UITouch
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) UITouchPhase phase;
@end

/// Creates a \c UIFakeTouch object with the given \c timestamp.
UIFakeTouch *LTTouchEventViewCreateTouch(NSTimeInterval timestamp);

/// Creates fake \c UITouch objects with the given \c timestamps.
NSArray<UIFakeTouch *> *LTTouchEventViewCreateTouches(std::vector<NSTimeInterval> timestamps);

/// Creates a fake \c UIEvent object.
UIEvent *LTTouchEventViewCreateEvent();

/// Causes the given fake \c eventMock to return the given \c coalescedTouches and the given
/// \c predictedTouches for the given \c mainTouch.
void LTTouchEventViewMakeEventReturnTouchesForTouch(id eventMock, UITouch *mainTouch,
                                                    NSArray<UITouch *> *coalescedTouches,
                                                    NSArray<UITouch *> *predictedTouches);

NS_ASSUME_NONNULL_END
