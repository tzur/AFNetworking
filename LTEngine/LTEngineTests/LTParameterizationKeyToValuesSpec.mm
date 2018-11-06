// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizationKeyToValues.h"

#import "LTEasyVectorBoxing.h"

SpecBegin(LTParameterizationKeyToValues)

static NSString * const kFirstKey = @"a";
static NSString * const kSecondKey = @"b";

__block NSOrderedSet<NSString *> *keys;
__block cv::Mat1g values;

beforeEach(^{
  keys = [NSOrderedSet orderedSetWithArray:@[kFirstKey, kSecondKey]];
  values = (cv::Mat1g(2, 3) << (CGFloat)1.0, (CGFloat)2.0, (CGFloat)3.0,
                               (CGFloat)4.0, (CGFloat)5.0, (CGFloat)6.0);
});

afterEach(^{
  keys = nil;
  values = {};
});

context(@"initialization", ^{
  it(@"should initialize with the given keys and the given values", ^{
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:values];
    expect(mapping.keys).to.equal(keys);
    expect(mapping.numberOfValuesPerKey).to.equal(3);
  });

  it(@"should raise when attempting to initialize without keys", ^{
    expect(^{
      LTParameterizationKeyToValues __unused *mapping =
          [[LTParameterizationKeyToValues alloc] initWithKeys:[NSOrderedSet orderedSet]
                                                 valuesPerKey:values];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to initialize with incorrect matrix", ^{
    expect(^{
      values = (cv::Mat1g(1, 3) << 1, 2, 3);
      LTParameterizationKeyToValues __unused *mapping =
          [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:values];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"value retrieval", ^{
  __block LTParameterizationKeyToValues *mapping;

  beforeEach(^{
    mapping = [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:values];
  });

  it(@"should retrieve the correct values for a given key", ^{
    cv::Mat1g expectedValues = values.row(0);

    std::vector<CGFloat> retrievedValues = [mapping valuesForKey:kFirstKey];

    expect(retrievedValues.size()).to.equal(3);
    expect(retrievedValues[0]).to.equal(expectedValues(0, 0));
    expect(retrievedValues[1]).to.equal(expectedValues(0, 1));
    expect(retrievedValues[2]).to.equal(expectedValues(0, 2));
  });

  it(@"should retrieve the correct values for a given key, at given indices", ^{
    std::vector<CGFloat> expectedValues = {1, 3};
    NSArray<NSNumber *> *boxedExpectedValues = $(expectedValues);

    std::vector<CGFloat> retrievedValues = [mapping valuesForKey:kFirstKey atIndices:{0, 2}];

    NSArray<NSNumber *> *boxedRetrievedValues = $(retrievedValues);
    expect(boxedRetrievedValues).to.equal(boxedExpectedValues);
  });
});

SpecEnd
