// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPeriodicFloatSet.h"

#import "LTFloatSetExamples.h"

SpecBegin(LTPeriodicFloatSet)

__block LTPeriodicFloatSet *set;

beforeEach(^{
  set = [[LTPeriodicFloatSet alloc] initWithPivotValue:1 numberOfValuesPerSequence:3 valueDistance:5
                                      sequenceDistance:10];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(set).toNot.beNil;
    expect(set.pivotValue).to.equal(1);
    expect(set.numberOfValuesPerSequence).to.equal(3);
    expect(set.valueDistance).to.equal(5);
    expect(set.sequenceDistance).to.equal(10);
  });

  it(@"should raise when attempting to initialize with non-positive number of values", ^{
    expect(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:1 numberOfValuesPerSequence:0
                                             valueDistance:5 sequenceDistance:10];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to initialize with non-positive value distance", ^{
    expect(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:1 numberOfValuesPerSequence:3
                                             valueDistance:0 sequenceDistance:10];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to initialize with non-positive gap distance", ^{
    expect(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:1 numberOfValuesPerSequence:3
                                             valueDistance:5 sequenceDistance:0];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"LTFloatSet protocol", ^{
  __block NSValue *boxedInterval;
  
  beforeEach(^{
    lt::Interval<CGFloat> interval({0, 10}, lt::Interval<CGFloat>::Closed);
    boxedInterval = [NSValue valueWithBytes:&interval objCType:@encode(lt::Interval<CGFloat>)];
  });

  context(@"set with equidistant values and pivot value equaling minimum value of interval", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:0 numberOfValuesPerSequence:1
                                             valueDistance:1 sequenceDistance:1];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues: @[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9, @10]
      };
    });
  });

  context(@"set with sequence of size 2 and pivot value equaling minimum value of interval", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:0 numberOfValuesPerSequence:2
                                             valueDistance:1 sequenceDistance:3];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues: @[@0, @1, @4, @5, @8, @9]
      };
    });
  });

  context(@"set with sequence of size 3 and pivot value equaling minimum value of interval", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:0 numberOfValuesPerSequence:3
                                             valueDistance:1 sequenceDistance:2];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues: @[@0, @1, @2, @4, @5, @6, @8, @9, @10]
      };
    });
  });

  context(@"set with sequence of size 5 and pivot value not equaling minimum value of interval", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:-0.5 numberOfValuesPerSequence:5
                                             valueDistance:0.5 sequenceDistance:2.5];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues:
            @[@0, @0.5, @1, @1.5, @4, @4.5, @5, @5.5, @6, @8.5, @9, @9.5, @10]
      };
    });
  });

  context(@"set with sequence of size 4 and pivot value not equaling minimum value of interval", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:-8 numberOfValuesPerSequence:4
                                             valueDistance:2.5 sequenceDistance:0.5];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues: @[@0, @2.5, @5, @7.5, @8]
      };
    });
  });

  context(@"set with sequence of size 4 and larger sequence distance", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:-8 numberOfValuesPerSequence:4
                                             valueDistance:2.5 sequenceDistance:1];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues: @[@0.5, @3, @5.5, @8, @9]
      };
    });
  });

  context(@"set with sequence of size 2 and non-integer pivot value", ^{
    beforeEach(^{
      set = [[LTPeriodicFloatSet alloc] initWithPivotValue:2.8 numberOfValuesPerSequence:2
                                             valueDistance:2.2 sequenceDistance:1];
    });

    itShouldBehaveLike(kLTFloatSetExamples, ^{
      return @{
        kLTFloatSetObject: set,
        kLTFloatSetInterval: boxedInterval,
        kLTFloatSetExpectedValues: @[@1.8, @2.8, @5, @6, @8.2, @9.2]
      };
    });
  });
});

SpecEnd
