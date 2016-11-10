// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSObject+NSSet.h"

SpecBegin(NSObject_NSSet)

context(@"objects other than arrays", ^{
  it(@"should return a set containing the receiver", ^{
    NSObject *object = [[NSObject alloc] init];
    expect([object lt_set]).to.equal([NSSet setWithObject:object]);
    expect([@1 lt_set]).to.equal([NSSet setWithObject:@1]);
    expect([[NSSet setWithObject:@1] lt_set])
        .to.equal([NSSet setWithObject:[NSSet setWithObject:@1]]);
  });
});

context(@"arrays", ^{
  it(@"should return an empty set for a receiving empty array", ^{
    expect([@[] lt_set]).to.equal([NSSet set]);
  });

  it(@"should return a set with the contents of the receiving array", ^{
    expect([@[@1, @2, @3] lt_set]).to.equal([NSSet setWithArray:@[@1, @2, @3]]);
  });

  it(@"should return a set with the contents of the receiving array, without repetitions", ^{
    expect([@[@1, @2, @3, @3] lt_set]).to.equal([NSSet setWithArray:@[@1, @2, @3]]);
  });
});

SpecEnd
