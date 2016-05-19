// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTMeanShaderGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTMeanShaderGenerator

- (instancetype)initWithNumberOfTextures:(NSUInteger)textureCount {
  LTParameterAssert(textureCount > 1, @"MeanShaderGenerator only works with more than 1 texture");

  if (self = [super init]) {
    NSMutableArray *uniformNames = [NSMutableArray arrayWithCapacity:textureCount];
    for (NSUInteger i = 0; i < textureCount; ++i) {
      [uniformNames addObject:[self textureUniformNameForIndex:i]];
    }
    _texturesUniformNames = [uniformNames copy];
    _fragmentShaderSource = [self meanFragmentSourceForTextureCount:textureCount];
  }
  return self;
}

#pragma mark -
#pragma mark Shader Generation
#pragma mark -

static NSString * const kFragmentSourceBase = @"varying highp vec2 vTexcoord;\n"
    "void main() {\n";

static NSString * const kFragmentSourceSuffix = @"}\n";

- (NSString *)meanFragmentSourceForTextureCount:(NSUInteger)count {
  NSMutableString *resultFragment = [NSMutableString string];
  for (NSUInteger i = 0; i < count; ++i) {
    [resultFragment appendString:[self samplerLineForUniformName:self.texturesUniformNames[i]]];
  }
  [resultFragment appendString:kFragmentSourceBase];
  [resultFragment appendString:[self samplingSegmentForTextureCount:count]];
  [resultFragment appendString:[self calculationSegmentForTextureCount:count]];
  [resultFragment appendString:kFragmentSourceSuffix];
  return [resultFragment copy];
}

- (NSString *)samplingSegmentForTextureCount:(NSUInteger)count {
  NSMutableString *segment = [NSMutableString string];
  for (NSUInteger i = 0; i < count; ++i) {
    [segment
     appendString:[NSString stringWithFormat:@"lowp vec4 %@ = texture2D(%@, vTexcoord);\n",
                   [self sampleVariableForUniformName:self.texturesUniformNames[i]],
                   self.texturesUniformNames[i]]];
  }
  return [segment copy];
}

- (NSString *)calculationSegmentForTextureCount:(NSUInteger)count {
  NSMutableString *segment = [NSMutableString string];
  NSMutableString *colorSum = [@"highp vec3 colorSum = " mutableCopy];
  NSMutableString *alphaSum = [@"highp float alphaSum = " mutableCopy];

  [colorSum appendString:[NSString stringWithFormat:@"%@.rgb * %@.a",
                          [self sampleVariableForUniformName:self.texturesUniformNames[0]],
                          [self sampleVariableForUniformName:self.texturesUniformNames[0]]]];
  [alphaSum appendString:[NSString stringWithFormat:@"%@.a",
                          [self sampleVariableForUniformName:self.texturesUniformNames[0]]]];

  for (NSUInteger i = 1; i < count; ++i) {
    [colorSum appendString:[NSString stringWithFormat:@" + %@.rgb * %@.a",
                            [self sampleVariableForUniformName:self.texturesUniformNames[i]],
                            [self sampleVariableForUniformName:self.texturesUniformNames[i]]]];
    [alphaSum appendString:[NSString stringWithFormat:@" + %@.a",
                            [self sampleVariableForUniformName:self.texturesUniformNames[i]]]];
  }

  [colorSum appendString:@";\n"];
  [alphaSum appendString:@";\n"];
  NSString *result = @"gl_FragColor = vec4(colorSum / alphaSum, 1.0);\n";
  [segment appendString:[@[colorSum, alphaSum, result] componentsJoinedByString:@""]];
  return [segment copy];
}

#pragma mark -
#pragma mark Name Generators
#pragma mark -

- (NSString *)textureUniformNameForIndex:(NSUInteger)index {
  if (index == 0) {
    return @"sourceTexture";
  }
  return [NSString stringWithFormat:@"texture%lu", (unsigned long)index];
}

- (NSString *)samplerLineForUniformName:(NSString *)name {
  return [NSString stringWithFormat:@"uniform lowp sampler2D %@;\n", name];
}

- (NSString *)sampleVariableForUniformName:(NSString *)name {
  return [NSString stringWithFormat:@"%@Sample", name];
}

@end

NS_ASSUME_NONNULL_END
