// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSArray+SelectorName.h"

SpecBegin(NSArray_SelectorName)

context(@"lt_selectorNameFromComponents", ^{
  it(@"should strip spaces from the prefix", ^{
    NSString *name = [@[@"pre fix ", @"Suffix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefixSuffix");
  });

  it(@"should replace the first letter of the prefix with lower case", ^{
    NSString *name = [@[@"Prefix", @"Suffix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefixSuffix");
  });

  it(@"should strip spaces and lower case the first letter of the prefix", ^{
    NSString *name = [@[@" Pre fix", @"Suffix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefixSuffix");
  });

  it(@"should strip spaces and upper case the first letter of the suffix", ^{
    NSString *name = [@[@"Prefix", @" suf fix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefixSuffix");
  });

  it(@"should combine more than two elements", ^{
    NSString *name = [@[@"Prefix", @"middle", @" suf fix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefixMiddleSuffix");
  });

  it(@"should combine empty element with non-empty elements", ^{
    NSString *name = [@[@"Prefix", @" ", @"suffix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefixSuffix");
  });

  it(@"should combine single item", ^{
    NSString *name = [@[@"Prefix"] lt_selectorNameFromComponents];
    expect(name).to.equal(@"prefix");
  });

  it(@"should combine zero elements", ^{
    NSString *name = [@[@""] lt_selectorNameFromComponents];
    expect(name).to.equal(@"");
  });

  it(@"should return empty selector for no elements", ^{
    NSString *name = [@[] lt_selectorNameFromComponents];
    expect(name).to.equal(@"");
  });
});

context(@"lt_selectorFromComponents", ^{
  it(@"should create selector with proper name", ^{
    SEL selector = [@[@"Prefix", @"middle", @" suf fix"] lt_selectorFromComponents];
    expect(NSStringFromSelector(selector)).to.equal(@"prefixMiddleSuffix");
  });
});

SpecEnd
