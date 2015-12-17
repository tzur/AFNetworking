// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterization.h"

SpecBegin(LTReparameterization)

__block LTReparameterization *reparameterization;

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 1}];
    expect(reparameterization).toNot.beNil();

    reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 1, 2, 3}];
    expect(reparameterization).toNot.beNil();
  });

  it(@"should raise when attempting to initialize with mapping of size smaller than 2", ^{
    expect(^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{0}];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to initialize with not monotonically increasing mapping", ^{
    expect(^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 0, 1}];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{0, -1, -2}];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{0, -1, 1}];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"NSCopying protocol", ^{
  __block LTReparameterization *copyOfReparameterization;

  beforeEach(^{
    reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 1, 2}];
    copyOfReparameterization = [reparameterization copy];
  });

  it(@"should return a copy that is identical to itself", ^{
    expect(copyOfReparameterization).to.beIdenticalTo(reparameterization);
  });

  it(@"should return a copy with correct mapping", ^{
    expect([copyOfReparameterization floatForParametricValue:0])
        .to.equal([reparameterization floatForParametricValue:0]);
    expect([copyOfReparameterization floatForParametricValue:0.5])
        .to.equal([reparameterization floatForParametricValue:0.5]);
    expect([copyOfReparameterization floatForParametricValue:1])
        .to.equal([reparameterization floatForParametricValue:1]);
  });

  it(@"should return a copy with correct minimum parametric value", ^{
    expect(copyOfReparameterization.minParametricValue)
        .to.equal(reparameterization.minParametricValue);
  });

  it(@"should return a copy with correct maximum parametric value", ^{
    expect(copyOfReparameterization.maxParametricValue)
        .to.equal(reparameterization.maxParametricValue);
  });
});

context(@"LTPrimitiveParameterizedObject", ^{
  it(@"should have the correct minParametricValue and maxParametricValue", ^{
    reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 1}];
    expect(reparameterization.minParametricValue).to.equal(0);
    expect(reparameterization.maxParametricValue).to.equal(1);

    reparameterization = [[LTReparameterization alloc] initWithMapping:{0.5, 2, 3}];
    expect(reparameterization.minParametricValue).to.equal(0.5);
    expect(reparameterization.maxParametricValue).to.equal(3);

    reparameterization = [[LTReparameterization alloc] initWithMapping:{7, 8, 9, 10}];
    expect(reparameterization.minParametricValue).to.equal(7);
    expect(reparameterization.maxParametricValue).to.equal(10);
  });

  context(@"key to value mapping", ^{
    static const CGFloat kEpsilon = 1e-6;

    it(@"should return correct reparameterized values for a trivial mapping", ^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 1}];
      expect([reparameterization floatForParametricValue:-1]).to.beCloseToWithin(-1, kEpsilon);
      expect([reparameterization floatForParametricValue:-0.5]).to.beCloseToWithin(-0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:0]).to.beCloseToWithin(0, kEpsilon);
      expect([reparameterization floatForParametricValue:0.25]).to.beCloseToWithin(0.25, kEpsilon);
      expect([reparameterization floatForParametricValue:0.5]).to.beCloseToWithin(0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:0.75]).to.beCloseToWithin(0.75, kEpsilon);
      expect([reparameterization floatForParametricValue:1]).to.beCloseToWithin(1, kEpsilon);
      expect([reparameterization floatForParametricValue:1.5]).to.beCloseToWithin(1.5, kEpsilon);
      expect([reparameterization floatForParametricValue:2]).to.beCloseToWithin(2, kEpsilon);
    });

    it(@"should return correct reparameterized values for a linear mapping", ^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{2, 5}];
      expect([reparameterization floatForParametricValue:-1]).to.beCloseToWithin(-1, kEpsilon);
      expect([reparameterization floatForParametricValue:0.5]).to.beCloseToWithin(-0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:2]).to.beCloseToWithin(0, kEpsilon);
      expect([reparameterization floatForParametricValue:3]).to.beCloseToWithin(1.0 / 3, kEpsilon);
      expect([reparameterization floatForParametricValue:3.5]).to.beCloseToWithin(0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:4]).to.beCloseToWithin(2.0 / 3, kEpsilon);
      expect([reparameterization floatForParametricValue:5]).to.beCloseToWithin(1, kEpsilon);
      expect([reparameterization floatForParametricValue:6.5]).to.beCloseToWithin(1.5, kEpsilon);
      expect([reparameterization floatForParametricValue:8]).to.beCloseToWithin(2, kEpsilon);
    });

    it(@"should return correct reparameterized values for non-linear mapping with two intervals", ^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{1, 2, 7}];
      expect([reparameterization floatForParametricValue:0]).to.beCloseToWithin(-0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:0.5]).to.beCloseToWithin(-0.25, kEpsilon);
      expect([reparameterization floatForParametricValue:1]).to.beCloseToWithin(0, kEpsilon);
      expect([reparameterization floatForParametricValue:1.5]).to.beCloseToWithin(0.25, kEpsilon);
      expect([reparameterization floatForParametricValue:2]).to.beCloseToWithin(0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:4.5]).to.beCloseToWithin(0.75, kEpsilon);
      expect([reparameterization floatForParametricValue:7]).to.beCloseToWithin(1, kEpsilon);
      expect([reparameterization floatForParametricValue:9.5]).to.beCloseToWithin(1.25, kEpsilon);
      expect([reparameterization floatForParametricValue:12]).to.beCloseToWithin(1.5, kEpsilon);
    });

    it(@"should return correct reparameterized values for non-linear mapping", ^{
      reparameterization = [[LTReparameterization alloc] initWithMapping:{0, 1, 10, 100, 1000}];
      expect([reparameterization floatForParametricValue:-1]).to.beCloseToWithin(-0.25, kEpsilon);
      expect([reparameterization floatForParametricValue:-0.5]).to.beCloseToWithin(-0.125, kEpsilon);
      expect([reparameterization floatForParametricValue:0]).to.beCloseToWithin(0, kEpsilon);
      expect([reparameterization floatForParametricValue:0.5]).to.beCloseToWithin(0.125, kEpsilon);
      expect([reparameterization floatForParametricValue:1]).to.beCloseToWithin(0.25, kEpsilon);
      expect([reparameterization floatForParametricValue:5.5]).to.beCloseToWithin(0.375, kEpsilon);
      expect([reparameterization floatForParametricValue:10]).to.beCloseToWithin(0.5, kEpsilon);
      expect([reparameterization floatForParametricValue:55]).to.beCloseToWithin(0.625, kEpsilon);
      expect([reparameterization floatForParametricValue:100]).to.beCloseToWithin(0.75, kEpsilon);
      expect([reparameterization floatForParametricValue:550]).to.beCloseToWithin(0.875, kEpsilon);
      expect([reparameterization floatForParametricValue:1000]).to.beCloseToWithin(1, kEpsilon);
      expect([reparameterization floatForParametricValue:1450]).to.beCloseToWithin(1.125, kEpsilon);
      expect([reparameterization floatForParametricValue:1900]).to.beCloseToWithin(1.25, kEpsilon);
    });
  });
});

SpecEnd
