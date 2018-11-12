// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectStack.h"

#import "LTEasyVectorBoxing.h"
#import "LTParameterizationKeyToValues.h"

static id<LTParameterizedValueObject>
    LTParameterizedValueObjectMock(BOOL strictMock, CGFloat minParametricValue,
                                   CGFloat maxParametricValue,
                                   NSOrderedSet<NSString *> *parameterizationKeys) {
  id<LTParameterizedValueObject> mock = strictMock ?
      OCMStrictProtocolMock(@protocol(LTParameterizedValueObject)) :
      OCMProtocolMock(@protocol(LTParameterizedValueObject));
  OCMStub([mock minParametricValue]).andReturn(minParametricValue);
  OCMStub([mock maxParametricValue]).andReturn(maxParametricValue);
  OCMStub([mock parameterizationKeys]).andReturn(parameterizationKeys);
  return mock;
}

SpecBegin(LTParameterizedObjectStack)

__block LTParameterizedObjectStack *object;
__block id parameterizedObjectMock;
__block NSOrderedSet<NSString *> *parameterizationKeys;

beforeEach(^{
  parameterizationKeys = [NSOrderedSet orderedSetWithArray:@[@"key0", @"key1"]];
  parameterizedObjectMock = LTParameterizedValueObjectMock(NO, 3, 4, parameterizationKeys);
  object = [[LTParameterizedObjectStack alloc] initWithParameterizedObject:parameterizedObjectMock];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(object.parameterizedObjects).to.equal(@[parameterizedObjectMock]);
  });
});

context(@"modifying extensible parameterized object", ^{
  __block id anotherParameterizedObjectMock;

  beforeEach(^{
    anotherParameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedValueObject));
  });

  context(@"pushing parameterized object", ^{
    it(@"should raise when pushing parameterized object with invalid intrinsic parametric range", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(7);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(4);
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(parameterizationKeys);

      expect(^{
        [object pushParameterizedObject:anotherParameterizedObjectMock];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when pushing parameterized object with invalid minParametricValue", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(5);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(7);
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(parameterizationKeys);

      expect(^{
        [object pushParameterizedObject:anotherParameterizedObjectMock];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when pushing parameterized object with invalid parameterizationKeys", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(4);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(7);
      NSOrderedSet *differentParameterizationKeys = [NSOrderedSet orderedSetWithArray:@[]];
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(differentParameterizationKeys);

      expect(^{
        [object pushParameterizedObject:anotherParameterizedObjectMock];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should push parameterized object", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(4);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(7);
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(parameterizationKeys);

      [object pushParameterizedObject:anotherParameterizedObjectMock];
      expect(object.parameterizedObjects).to.equal(@[parameterizedObjectMock,
                                                     anotherParameterizedObjectMock]);
    });
  });

  context(@"replacing parameterized object", ^{
    it(@"should raise when replacing non-existent parameterized object", ^{
      id nonExistentParameterizedObject = OCMProtocolMock(@protocol(LTParameterizedValueObject));
      expect(^{
        [object replaceParameterizedObject:nonExistentParameterizedObject
                                  byObject:anotherParameterizedObjectMock];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when replacing by parameterized object with different parametric range", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(3);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(3.8);
      expect(^{
        [object replaceParameterizedObject:parameterizedObjectMock
                                  byObject:anotherParameterizedObjectMock];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when replacing by parameterized object with invalid parameterization keys", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(3);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(4);
      NSOrderedSet *differentParameterizationKeys = [NSOrderedSet orderedSetWithArray:@[]];
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(differentParameterizationKeys);
      expect(^{
        [object replaceParameterizedObject:parameterizedObjectMock
                                  byObject:anotherParameterizedObjectMock];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should replace parameterized object by another parameterized object", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(3);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(4);
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(parameterizationKeys);

      [object replaceParameterizedObject:parameterizedObjectMock
                                byObject:anotherParameterizedObjectMock];

      expect(object.parameterizedObjects).to.equal(@[anotherParameterizedObjectMock]);
    });
  });

  context(@"popping last parameterized object", ^{
    it(@"should do nothing if only one parameterized object exists", ^{
      id<LTParameterizedValueObject> result = [object popParameterizedObject];
      expect(result).to.beNil();
      expect(object.parameterizedObjects).to.equal(@[parameterizedObjectMock]);
    });

    it(@"should pop the most recently pushed parameterized object", ^{
      anotherParameterizedObjectMock =
          LTParameterizedValueObjectMock(NO, 4, 7, parameterizationKeys);
      [object pushParameterizedObject:anotherParameterizedObjectMock];
      id<LTParameterizedValueObject> yetAnotherParameterizedObjectMock =
          LTParameterizedValueObjectMock(NO, 7, 8, parameterizationKeys);
      [object pushParameterizedObject:yetAnotherParameterizedObjectMock];

      id<LTParameterizedValueObject> result = [object popParameterizedObject];
      expect(result).to.beIdenticalTo(yetAnotherParameterizedObjectMock);
      expect(object.parameterizedObjects)
          .to.equal(@[parameterizedObjectMock, anotherParameterizedObjectMock]);

      result = [object popParameterizedObject];
      expect(result).to.beIdenticalTo(anotherParameterizedObjectMock);
      expect(object.parameterizedObjects).to.equal(@[parameterizedObjectMock]);
    });
  });
});

context(@"LTParameterizedObject protocol", ^{
  __block id anotherParameterizedObjectMock;

  beforeEach(^{
    anotherParameterizedObjectMock = LTParameterizedValueObjectMock(NO, 4, 7, parameterizationKeys);
  });

  it(@"should have the minParametricValue of its first object", ^{
    expect(object.minParametricValue).to.equal(3);
    [object pushParameterizedObject:anotherParameterizedObjectMock];
    expect(object.minParametricValue).to.equal(3);
    [object popParameterizedObject];
    expect(object.minParametricValue).to.equal(3);
  });

  it(@"should have the maxParametricValue of its last object", ^{
    expect(object.maxParametricValue).to.equal(4);
    [object pushParameterizedObject:anotherParameterizedObjectMock];
    expect(object.maxParametricValue).to.equal(7);
    [object popParameterizedObject];
    expect(object.maxParametricValue).to.equal(4);
  });

  it(@"should have the parameterization keys of any of its object", ^{
    expect(object.parameterizationKeys).to.equal(parameterizationKeys);
  });

  context(@"queries", ^{
    beforeEach(^{
      [object pushParameterizedObject:anotherParameterizedObjectMock];
    });

    it(@"should delegate key to value queries to the correct parameterized object", ^{
      id mappingKeyToValueMock = OCMClassMock([LTParameterizationKeyToValue class]);
      OCMExpect([parameterizedObjectMock mappingForParametricValue:3.5])
          .andReturn(mappingKeyToValueMock);

      LTParameterizationKeyToValue *mapping = [object mappingForParametricValue:3.5];

      expect(mapping).to.beIdenticalTo(mappingKeyToValueMock);
      OCMVerifyAll(parameterizedObjectMock);

      id anotherMappingKeyToValueMock = OCMClassMock([LTParameterizationKeyToValue class]);
      OCMExpect([anotherParameterizedObjectMock mappingForParametricValue:5.5])
          .andReturn(anotherMappingKeyToValueMock);

      mapping = [object mappingForParametricValue:5.5];

      expect(mapping).to.beIdenticalTo(anotherMappingKeyToValueMock);
      OCMVerifyAll(anotherParameterizedObjectMock);
    });

    context(@"key to values queries", ^{
      __block id<LTParameterizedValueObject> strictParameterizedObjectMock;
      __block id<LTParameterizedValueObject> anotherStrictParameterizedObjectMock;

      beforeEach(^{
        strictParameterizedObjectMock =
            LTParameterizedValueObjectMock(YES, 3, 4, parameterizationKeys);
        anotherStrictParameterizedObjectMock =
            LTParameterizedValueObjectMock(YES, 4, 7, parameterizationKeys);

        object = [[LTParameterizedObjectStack alloc]
                  initWithParameterizedObject:strictParameterizedObjectMock];
        [object pushParameterizedObject:anotherStrictParameterizedObjectMock];
      });

      it(@"should delegate key to values queries to the correct parameterized object", ^{
        cv::Mat1g values = (cv::Mat1g(2, 1) << 0, 1);
        LTParameterizationKeyToValues *keyToValues =
            [[LTParameterizationKeyToValues alloc] initWithKeys:parameterizationKeys
                                                   valuesPerKey:values];
        OCMExpect([[(id)strictParameterizedObjectMock ignoringNonObjectArgs]
                   mappingForParametricValues:{3.5}]).andReturn(keyToValues);

        values = (cv::Mat1g(2, 1) << 10, 11);
        keyToValues = [[LTParameterizationKeyToValues alloc] initWithKeys:parameterizationKeys
                                                             valuesPerKey:values];
        OCMExpect([[(id)anotherStrictParameterizedObjectMock ignoringNonObjectArgs]
                   mappingForParametricValues:{5.5}]).andReturn(keyToValues);

        LTParameterizationKeyToValues *result = [object mappingForParametricValues:{3.5, 5.5}];

        std::vector<CGFloat> values0 = [result valuesForKey:@"key0"];
        std::vector<CGFloat> values1 = [result valuesForKey:@"key1"];

        expect(result.keys).to.equal(parameterizationKeys);
        expect(values0.size()).to.equal(2);
        expect(values0[0]).to.equal(0);
        expect(values0[1]).to.equal(10);
        expect(values1.size()).to.equal(2);
        expect(values1[0]).to.equal(1);
        expect(values1[1]).to.equal(11);
        OCMVerifyAll(strictParameterizedObjectMock);
        OCMVerifyAll(anotherStrictParameterizedObjectMock);
      });
    });

    it(@"should delegate value queries to the correct parameterized object", ^{
      OCMExpect([parameterizedObjectMock floatForParametricValue:3.5 key:@"key0"]).andReturn(0);
      CGFloat value = [object floatForParametricValue:3.5 key:@"key0"];
      expect(value).to.equal(0);
      OCMVerifyAll(parameterizedObjectMock);

      OCMExpect([anotherParameterizedObjectMock floatForParametricValue:5.5 key:@"key0"])
          .andReturn(1);
      value = [object floatForParametricValue:5.5 key:@"key0"];
      expect(value).to.equal(1);
      OCMVerifyAll(anotherParameterizedObjectMock);
    });

    it(@"should delegate value queries with parametric values outside range to correct object", ^{
      OCMExpect([parameterizedObjectMock floatForParametricValue:2 key:@"key0"]).andReturn(0);
      CGFloat value = [object floatForParametricValue:2 key:@"key0"];
      expect(value).to.equal(0);
      OCMVerifyAll(parameterizedObjectMock);

      OCMExpect([anotherParameterizedObjectMock floatForParametricValue:10 key:@"key0"])
          .andReturn(8);
      value = [object floatForParametricValue:10 key:@"key0"];
      expect(value).to.equal(8);
      OCMVerifyAll(parameterizedObjectMock);
    });

    it(@"should delegate values queries to the correct parameterized object", ^{
      OCMExpect([parameterizedObjectMock floatForParametricValue:3.5 key:@"key0"]).andReturn(0);
      OCMExpect([anotherParameterizedObjectMock floatForParametricValue:5.5 key:@"key0"])
          .andReturn(1);

      std::vector<CGFloat> values = [object floatsForParametricValues:{3.5, 5.5} key:@"key0"];

      expect(values.size()).to.equal(2);
      expect(values[0]).to.equal(0);
      expect(values[1]).to.equal(1);
      OCMVerifyAll(parameterizedObjectMock);
      OCMVerifyAll(anotherParameterizedObjectMock);
    });
  });
});

context(@"count property", ^{
  __block id anotherParameterizedObjectMock;
  __block id yetAnotherParameterizedObjectMock;

  beforeEach(^{
    anotherParameterizedObjectMock = LTParameterizedValueObjectMock(NO, 4, 5, parameterizationKeys);

    yetAnotherParameterizedObjectMock =
        LTParameterizedValueObjectMock(NO, 4, 5, parameterizationKeys);
  });

  it(@"should return the correct count", ^{
    expect(object.count).to.equal(1);

    [object pushParameterizedObject:anotherParameterizedObjectMock];
    expect(object.count).to.equal(2);

    [object replaceParameterizedObject:anotherParameterizedObjectMock
                              byObject:yetAnotherParameterizedObjectMock];
    expect(object.count).to.equal(2);

    [object popParameterizedObject];
    expect(object.count).to.equal(1);
  });
});

context(@"top and bottom properties", ^{
  __block id<LTParameterizedValueObject> anotherParameterizedObjectMock;
  __block id<LTParameterizedValueObject> yetAnotherParameterizedObjectMock;

  beforeEach(^{
    anotherParameterizedObjectMock = LTParameterizedValueObjectMock(NO, 4, 7, parameterizationKeys);
    yetAnotherParameterizedObjectMock =
        LTParameterizedValueObjectMock(NO, 7, 8, parameterizationKeys);
    [object pushParameterizedObject:anotherParameterizedObjectMock];
    [object pushParameterizedObject:yetAnotherParameterizedObjectMock];
  });

  it(@"should return its top element", ^{
    expect(object.top).to.equal(yetAnotherParameterizedObjectMock);
  });

  it(@"should return its bottom element", ^{
    expect(object.bottom).to.equal(parameterizedObjectMock);
  });
});

SpecEnd
