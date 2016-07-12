// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTEqualityExamples.h"

NSString * const kLTEqualityExamples = @"NSObjectExamples";
NSString * const kLTEqualityExamplesObject = @"NSObjectExamplesObject";
NSString * const kLTEqualityExamplesEqualObject = @"NSObjectExamplesEqualObject";
NSString * const kLTEqualityExamplesDifferentObjects = @"NSObjectExamplesDifferentObjects";

SharedExamplesBegin(NSObjectExamples)

sharedExamplesFor(kLTEqualityExamples, ^(NSDictionary *data) {
  context(@"NSObject protocol", ^{
    __block id<NSObject> object;
    __block id<NSObject> equalObject;

    beforeEach(^{
      object = data[kLTEqualityExamplesObject];
      equalObject = data[kLTEqualityExamplesEqualObject];
    });

    afterEach(^{
      object = nil;
      equalObject = nil;
    });

    context(@"equality", ^{
      it(@"should return YES when comparing to itself", ^{
        expect([object isEqual:object]).to.beTruthy();
      });

      it(@"should return YES when comparing to equal but not identical object", ^{
        expect(object).toNot.beIdenticalTo(equalObject);
        expect([object isEqual:equalObject]).to.beTruthy();
      });

      it(@"should return NO when comparing to nil", ^{
        expect([object isEqual:nil]).to.beFalsy();
      });

      it(@"should return NO when comparing to an object of a different class", ^{
        expect([object isEqual:[[NSObject alloc] init]]).to.beFalsy();
      });

      it(@"should return NO when comparing to different objects", ^{
        for (id<NSObject> differentObject in data[kLTEqualityExamplesDifferentObjects]) {
          expect([differentObject isKindOfClass:[object class]]);
          expect([object isEqual:differentObject]).to.beFalsy();
        }
      });
    });

    context(@"hash", ^{
      it(@"should return the same hash value for equal but not identical objects", ^{
        expect(object).toNot.beIdenticalTo(equalObject);
        expect(object.hash).to.equal(equalObject.hash);
      });
    });
  });
});

SharedExamplesEnd
