// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectStack.h"

SpecBegin(LTParameterizedObjectStack)

__block LTParameterizedObjectStack *object;
__block id parameterizedObjectMock;
__block NSSet<NSString *> *parameterizationKeys;

beforeEach(^{
  parameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
  OCMStub([parameterizedObjectMock minParametricValue]).andReturn(3);
  OCMStub([parameterizedObjectMock maxParametricValue]).andReturn(4);
  parameterizationKeys = [NSSet setWithArray:@[@"key0", @"key1"]];
  OCMStub([parameterizedObjectMock parameterizationKeys]).andReturn(parameterizationKeys);
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
    anotherParameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
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
      NSSet *differentParameterizationKeys = [NSSet setWithArray:@[]];
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
      id nonExistentParameterizedObject = OCMProtocolMock(@protocol(LTParameterizedObject));
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
      NSSet *differentParameterizationKeys = [NSSet setWithArray:@[]];
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
      id<LTParameterizedObject> result = [object popParameterizedObject];
      expect(result).to.beNil();
      expect(object.parameterizedObjects).to.equal(@[parameterizedObjectMock]);
    });

    it(@"should pop the most recently pushed parameterized object", ^{
      OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(4);
      OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(7);
      OCMStub([anotherParameterizedObjectMock parameterizationKeys])
          .andReturn(parameterizationKeys);
      [object pushParameterizedObject:anotherParameterizedObjectMock];
      id yetAnotherParameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
      OCMStub([yetAnotherParameterizedObjectMock minParametricValue]).andReturn(7);
      OCMStub([yetAnotherParameterizedObjectMock maxParametricValue]).andReturn(8);
      OCMStub([yetAnotherParameterizedObjectMock parameterizationKeys])
          .andReturn(parameterizationKeys);
      [object pushParameterizedObject:yetAnotherParameterizedObjectMock];

      id<LTParameterizedObject> result = [object popParameterizedObject];
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
    anotherParameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
    OCMStub([anotherParameterizedObjectMock minParametricValue]).andReturn(4);
    OCMStub([anotherParameterizedObjectMock maxParametricValue]).andReturn(7);
    OCMStub([anotherParameterizedObjectMock parameterizationKeys]).andReturn(parameterizationKeys);
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
      __block id strictParameterizedObjectMock;
      __block id anotherStrictParameterizedObjectMock;

      beforeEach(^{
        strictParameterizedObjectMock = OCMStrictProtocolMock(@protocol(LTParameterizedObject));
        OCMStub([strictParameterizedObjectMock minParametricValue]).andReturn(3);
        OCMStub([strictParameterizedObjectMock maxParametricValue]).andReturn(4);
        OCMStub([strictParameterizedObjectMock parameterizationKeys])
            .andReturn(parameterizationKeys);

        anotherStrictParameterizedObjectMock =
            OCMStrictProtocolMock(@protocol(LTParameterizedObject));
        OCMStub([anotherStrictParameterizedObjectMock minParametricValue]).andReturn(4);
        OCMStub([anotherStrictParameterizedObjectMock maxParametricValue]).andReturn(7);
        OCMStub([anotherStrictParameterizedObjectMock parameterizationKeys])
            .andReturn(parameterizationKeys);

        object = [[LTParameterizedObjectStack alloc]
                  initWithParameterizedObject:strictParameterizedObjectMock];
        [object pushParameterizedObject:anotherStrictParameterizedObjectMock];
      });

      it(@"should delegate key to values queries to the correct parameterized object", ^{
        OCMExpect([strictParameterizedObjectMock floatForParametricValue:3.5 key:@"key0"])
            .andReturn(0);
        OCMExpect([strictParameterizedObjectMock floatForParametricValue:3.5 key:@"key1"])
            .andReturn(1);
        OCMExpect([anotherStrictParameterizedObjectMock floatForParametricValue:5.5 key:@"key0"])
            .andReturn(10);
        OCMExpect([anotherStrictParameterizedObjectMock floatForParametricValue:5.5 key:@"key1"])
            .andReturn(11);

        LTParameterizationKeyToValues *result = [object mappingForParametricValues:{3.5, 5.5}];

        expect([NSSet setWithArray:[result allKeys]]).to.equal(parameterizationKeys);
        expect(result[@"key0"]).to.equal(@[@0, @10]);
        expect(result[@"key1"]).to.equal(@[@1, @11]);
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

    it(@"should delegate values queries to the correct parameterized object", ^{
      OCMExpect([parameterizedObjectMock floatForParametricValue:3.5 key:@"key0"]).andReturn(0);
      OCMExpect([anotherParameterizedObjectMock floatForParametricValue:5.5 key:@"key0"])
          .andReturn(1);

      CGFloats values = [object floatsForParametricValues:{3.5, 5.5} key:@"key0"];

      expect(values.size()).to.equal(2);
      expect(values[0]).to.equal(0);
      expect(values[1]).to.equal(1);
      OCMVerifyAll(parameterizedObjectMock);
      OCMVerifyAll(anotherParameterizedObjectMock);
    });
  });
});

SpecEnd
