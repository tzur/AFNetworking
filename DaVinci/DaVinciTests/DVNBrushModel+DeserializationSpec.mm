// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel+Deserialization.h"

#import "DVNBrushModelErrorCode.h"
#import "DVNBrushModelVersion+TestBrushModel.h"

static NSString * const kDVNBrushModelVersionDeserializationExamples =
    @"DVNBrushModelVersionDeserializationExamples";
static NSString * const kDVNBrushModelVersionDeserializationExamplesJSONDictionary =
    @"DVNBrushRenderConfigurationProviderExamplesModel";
static NSString * const kDVNBrushModelVersionDeserializationExamplesClass =
    @"DVNBrushModelVersionDeserializationExamplesClass";

SharedExamplesBegin(DVNBrushModelVersionDeserializationExamples)

sharedExamplesFor(kDVNBrushModelVersionDeserializationExamples, ^(NSDictionary *data) {
  __block NSDictionary *jsonDictionary;
  __block Class expectedClass;

  beforeEach(^{
    jsonDictionary = data[kDVNBrushModelVersionDeserializationExamplesJSONDictionary];
    expectedClass = data[kDVNBrushModelVersionDeserializationExamplesClass];
  });

  context(@"model creation from JSON dictionary", ^{
    it(@"should correctly construct brush model without error", ^{
      NSError * _Nullable error;
      DVNBrushModel * _Nullable model = [DVNBrushModel modelFromJSONDictionary:jsonDictionary
                                                                         error:&error];
      expect(model).toNot.beNil();
      expect(model).to.beMemberOf(expectedClass);
      expect(error).to.beNil();
    });

    it(@"should return nil and populate given error if dictionary does not specify version", ^{
      NSError * _Nullable error;
      DVNBrushModel * _Nullable model = [DVNBrushModel modelFromJSONDictionary:@{} error:&error];
      expect(model).to.beNil();
      expect(error).toNot.beNil();
      expect(error.code).to.equal($(DVNBrushModelErrorCodeNoSerializedVersion).value);
    });

    it(@"should return nil and populate given error if dictionary specifies invalid version", ^{
      NSError * _Nullable error;
      DVNBrushModel * _Nullable model =
          [DVNBrushModel modelFromJSONDictionary:@{@"version": @"invalidVersion"}
                                           error:&error];
      expect(model).to.beNil();
      expect(error).toNot.beNil();
      expect(error.code).to.equal($(DVNBrushModelErrorCodeNoValidVersion).value);
    });
  });
});

SharedExamplesEnd

SpecBegin(DVNBrushModelVersion_Deserialization)

context(@"deserialization", ^{
  for (DVNBrushModelVersion *version in [DVNBrushModelVersion fields]) {
    itShouldBehaveLike(kDVNBrushModelVersionDeserializationExamples, ^{
      return @{
        kDVNBrushModelVersionDeserializationExamplesJSONDictionary:
            [version JSONDictionaryOfTestBrushModel],
        kDVNBrushModelVersionDeserializationExamplesClass: [version classOfBrushModel]
      };
    });
  }
});

SpecEnd
