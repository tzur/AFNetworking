// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSamplerTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSamplerTestParameterizedObject

@synthesize parameterizationKeys = _parameterizationKeys;

- (LTParameterizationKeyToValue *)mappingForParametricValue:(__unused CGFloat)value {
  return nil;
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values {
#pragma push_macro("equal")
#undef equal
  if (std::equal(values.begin(), values.end(), _expectedParametricValues.begin(),
                 _expectedParametricValues.end())) {
    return self.returnedMapping;
  }
  return nil;
#pragma pop_macro("equal")
}

- (CGFloat)floatForParametricValue:(__unused CGFloat)value key:(NSString __unused *)key {
  return 0;
}

- (CGFloats)floatsForParametricValues:(const CGFloats __unused &)values
                                  key:(NSString __unused *)key {
  return {};
}

@end

NS_ASSUME_NONNULL_END
