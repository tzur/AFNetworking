// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTMeanProcessor.h"

#import "LTGLContext.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMeanShaderGenerator.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTMeanProcessor

static const NSUInteger kMinimalSupportedTextures = 2;

- (instancetype)initWithInputTextures:(NSArray<LTTexture *> *)input output:(LTTexture *)output {
  LTParameterAssert(input.count >= kMinimalSupportedTextures,
                    @"Input array cannot have less than %lu textures",
                    (unsigned long)kMinimalSupportedTextures);

  LTParameterAssert(input.count <=
                    (unsigned long)[LTGLContext currentContext].maxFragmentTextureUnits,
                    @"Maximal number of device texutres is %d and less than required %lu",
                    [LTGLContext currentContext].maxFragmentTextureUnits,
                    (unsigned long)input.count);

  LTMeanShaderGenerator *generator =
      [[LTMeanShaderGenerator alloc] initWithNumberOfTextures:input.count];
  NSMutableDictionary *auxiliaryTextures =
      [NSMutableDictionary dictionaryWithCapacity:input.count - 1];
  for (NSUInteger i = 1; i < input.count; ++i) {
    auxiliaryTextures[generator.texturesUniformNames[i]] = input[i];
  }

  return self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                             fragmentSource:generator.fragmentShaderSource
                              sourceTexture:input.firstObject
                          auxiliaryTextures:auxiliaryTextures
                                  andOutput:output];
}

- (instancetype)initWithInputTextures:(NSArray<LTTexture *> *)input {
  LTTexture *output = [LTTexture textureWithSize:input.firstObject.size
                                     pixelFormat:input.firstObject.pixelFormat
                                  allocateMemory:YES];
  return [self initWithInputTextures:input output:output];
}

@end
