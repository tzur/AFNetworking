// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSamplerTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSamplerTestParameterizedObject

@synthesize parameterizationKeys = _parameterizationKeys;

- (LTParameterizationKeyToValue *)mappingForParametricValue:(__unused CGFloat)value {
  return nil;
}

- (LTParameterizationKeyToValues *)
    mappingForParametricValues:(const std::vector<CGFloat> __unused &)values {
  return self.returnedMapping;
}

- (CGFloat)floatForParametricValue:(__unused CGFloat)value key:(NSString __unused *)key {
  return 0;
}

- (std::vector<CGFloat>)floatsForParametricValues:(const std::vector<CGFloat> __unused &)values
                                              key:(NSString __unused *)key {
  return {};
}

@end

NS_ASSUME_NONNULL_END
