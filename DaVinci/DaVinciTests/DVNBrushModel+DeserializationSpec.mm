// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel+Deserialization.h"

#import "DVNBrushModelErrorCode.h"
#import "DVNBrushModelV1.h"

SpecBegin(DVNBrushModelVersion_Deserialization)

__block NSDictionary *jsonDictionary;

beforeEach(^{
  NSString *filePath = [[NSBundle bundleForClass:[self class]]
                        pathForResource:@"DVNTestBrushModelV1" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0
                                                     error:nil];
});

context(@"model creation from JSON dictionary", ^{
  it(@"should correctly construct brush model of version 1 without error", ^{
    NSError * _Nullable error;
    DVNBrushModel * _Nullable model = [DVNBrushModel modelFromJSONDictionary:jsonDictionary
                                                                       error:&error];
    expect(model).toNot.beNil();
    expect(model).to.beMemberOf([DVNBrushModelV1 class]);
    expect(error).to.beNil();
  });

  it(@"should return nil and populate given error if dictionary does not specify version", ^{
    NSError * _Nullable error;
    DVNBrushModel * _Nullable model = [DVNBrushModel modelFromJSONDictionary:@{} error:&error];
    expect(model).to.beNil();
    expect(error).toNot.beNil();
    expect(error.code).to.equal($(DVNBrushModelErrorCodeNoSerializedVersion).value);
  });

  it(@"should return nil and populate given error if dictionary does not specify valid version", ^{
    NSError * _Nullable error;
    DVNBrushModel * _Nullable model =
        [DVNBrushModel modelFromJSONDictionary:@{@"version": @"invalidVersion"}
                                         error:&error];
    expect(model).to.beNil();
    expect(error).toNot.beNil();
    expect(error.code).to.equal($(DVNBrushModelErrorCodeNoValidVersion).value);
  });
});

SpecEnd
