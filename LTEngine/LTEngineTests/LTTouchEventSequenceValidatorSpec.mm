// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventSequenceValidator.h"

#import "LTTouchEventSequenceValidatorExamples.h"

SpecBegin(LTTouchEventSequenceValidator)

context(@"initialization", ^{
  it(@"should initialize without an delegate", ^{
    LTTouchEventSequenceValidator *validator = [[LTTouchEventSequenceValidator alloc] init];
    expect(validator).toNot.beNil();
    expect(validator.delegate).to.beNil();
  });

  it(@"should initialize with a strongly held delegate", ^{
    id __weak weakDelegateMock;
    LTTouchEventSequenceValidator *validator;

    @autoreleasepool {
      id delegateMock = OCMProtocolMock(@protocol(LTTouchEventDelegate));
      validator = [[LTTouchEventSequenceValidator alloc] initWithDelegate:delegateMock
                                                             heldStrongly:YES];
      weakDelegateMock = delegateMock;
    }

    expect(validator).toNot.beNil();
    expect(validator.delegate).toNot.beNil();
    expect(validator.delegate).to.beIdenticalTo(weakDelegateMock);
  });

  it(@"should initialize with a weakly held delegate", ^{
    id __weak weakDelegateMock;
    LTTouchEventSequenceValidator *validator;

    @autoreleasepool {
      id delegateMock = OCMProtocolMock(@protocol(LTTouchEventDelegate));
      validator = [[LTTouchEventSequenceValidator alloc] initWithDelegate:delegateMock
                                                             heldStrongly:NO];
      weakDelegateMock = delegateMock;
    }

    expect(validator).toNot.beNil();
    expect(validator.delegate).to.beNil();
    expect(weakDelegateMock).to.beNil();
  });
});

itShouldBehaveLike(kLTTouchEventSequenceValidatorExamples, ^{
    return @{kLTTouchEventSequenceValidatorExamplesDelegate:
               [[LTTouchEventSequenceValidator alloc] init]};
});

context(@"forwarding of method calls", ^{
  __block id<LTTouchEventDelegate> delegateMock;
  __block LTTouchEventSequenceValidator *validator;
  __block id<LTTouchEvent> touchEvent0;
  __block id<LTTouchEvent> touchEvent1;
  __block NSArray<id<LTTouchEvent>> *touchEvents;
  __block NSArray<id<LTTouchEvent>> *predictedEvents;

  beforeEach(^{
    delegateMock = OCMProtocolMock(@protocol(LTTouchEventDelegate));
    validator = [[LTTouchEventSequenceValidator alloc] initWithDelegate:delegateMock
                                                           heldStrongly:YES];
    touchEvent0 = OCMProtocolMock(@protocol(LTTouchEvent));
    touchEvent1 = OCMProtocolMock(@protocol(LTTouchEvent));
    touchEvents = @[touchEvent0];
    predictedEvents = @[touchEvent1];
  });

  afterEach(^{
    predictedEvents = nil;
    touchEvents = nil;
    touchEvent1 = nil;
    touchEvent0 = nil;
    validator = nil;
    delegateMock = nil;
  });

  it(@"should forward starting touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];
    OCMVerify([delegateMock receivedTouchEvents:touchEvents predictedEvents:predictedEvents
                        touchEventSequenceState:LTTouchEventSequenceStateStart]);
  });

  it(@"should forward continuing touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateContinuation];
    OCMVerify([delegateMock receivedTouchEvents:touchEvents predictedEvents:predictedEvents
                        touchEventSequenceState:LTTouchEventSequenceStateContinuation]);
  });

  it(@"should forward stationary touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
    OCMVerify([delegateMock receivedTouchEvents:touchEvents predictedEvents:predictedEvents
                        touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary]);
  });

  it(@"should forward ending touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateEnd];
    OCMVerify([delegateMock receivedTouchEvents:touchEvents predictedEvents:predictedEvents
                        touchEventSequenceState:LTTouchEventSequenceStateEnd]);
  });

  it(@"should forward cancelled touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateCancellation];
    OCMVerify([delegateMock receivedTouchEvents:touchEvents predictedEvents:predictedEvents
                        touchEventSequenceState:LTTouchEventSequenceStateCancellation]);
  });

  it(@"should forward updates of touch events", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];
    [validator receivedUpdatesOfTouchEvents:touchEvents];
    OCMVerify([delegateMock receivedUpdatesOfTouchEvents:touchEvents]);
  });

  it(@"should forward termination information about ending touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];

    NSSet<NSNumber *> *sequenceIDs = [NSSet setWithObject:@0];
    [validator touchEventSequencesWithIDs:sequenceIDs
                      terminatedWithState:LTTouchEventSequenceStateEnd];
    OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                   terminatedWithState:LTTouchEventSequenceStateEnd]);
  });

  it(@"should forward termination information about cancelled touch event sequences", ^{
    [validator receivedTouchEvents:touchEvents predictedEvents:predictedEvents
           touchEventSequenceState:LTTouchEventSequenceStateStart];

    NSSet<NSNumber *> *sequenceIDs = [NSSet setWithObject:@0];
    [validator touchEventSequencesWithIDs:sequenceIDs
                      terminatedWithState:LTTouchEventSequenceStateCancellation];
    OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                   terminatedWithState:LTTouchEventSequenceStateCancellation]);
  });
});

SpecEnd
