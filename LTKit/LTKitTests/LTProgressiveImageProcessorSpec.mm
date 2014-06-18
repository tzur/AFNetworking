// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTProgressiveImageProcessor+Protected.h"

SpecBegin(LTProgressiveImageProcessor)

__block LTProgressiveImageProcessor *processor;

afterEach(^{
  processor = nil;
});

context(@"initialization", ^{
  it(@"should initialize with no arguments", ^{
    expect(^{
      processor = [[LTProgressiveImageProcessor alloc] init];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  beforeEach(^{
    processor = [[LTProgressiveImageProcessor alloc] init];
  });
  
  it(@"should have default properties", ^{
    expect(processor.processedProgress).to.equal(0);
    expect(processor.targetProgress).to.equal(0);
  });
  
  it(@"should set targetProgress", ^{
    processor.targetProgress = 0.5;
    expect(processor.targetProgress).to.equal(0.5);
    
    expect(^{
      processor.targetProgress = -FLT_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      processor.targetProgress = 1 + FLT_EPSILON;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should reset progress", ^{
    processor.targetProgress = 0.5;
    processor.processedProgress = 0.5;
    expect(processor.targetProgress).notTo.equal(0);
    expect(processor.processedProgress).notTo.equal(0);
    [processor resetProgress];
    expect(processor.targetProgress).to.equal(0);
    expect(processor.processedProgress).to.equal(0);
  });
});

SpecEnd
