// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTMeanShaderGenerator.h"

SpecBegin(LTMeanShaderGenerator)

context(@"initialization", ^{
  it(@"should not initialize with texture count == 1", ^{
    expect(^{
      __unused LTMeanShaderGenerator *generator =
          [[LTMeanShaderGenerator alloc] initWithNumberOfTextures:1];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with texture count > 1", ^{
    expect(^{
      __unused LTMeanShaderGenerator *generator =
          [[LTMeanShaderGenerator alloc] initWithNumberOfTextures:3];
    }).toNot.raiseAny();
  });
});

context(@"generation", ^{
  static NSString * const kSampleShaderString = @"uniform lowp sampler2D sourceTexture;\n"
      "uniform lowp sampler2D texture1;\n"
      "uniform lowp sampler2D texture2;\n"
      "varying highp vec2 vTexcoord;\n"
      "void main() {\n"
      "lowp vec4 sourceTextureSample = texture2D(sourceTexture, vTexcoord);\n"
      "lowp vec4 texture1Sample = texture2D(texture1, vTexcoord);\n"
      "lowp vec4 texture2Sample = texture2D(texture2, vTexcoord);\n"
      "highp vec3 colorSum = sourceTextureSample.rgb * sourceTextureSample.a + "
      "texture1Sample.rgb * texture1Sample.a + texture2Sample.rgb * texture2Sample.a;\n"
      "highp float alphaSum = sourceTextureSample.a + texture1Sample.a + texture2Sample.a;\n"
      "gl_FragColor = vec4(colorSum / alphaSum, 1.0);\n"
      "}\n";

  it(@"should create correct shader string", ^{
    LTMeanShaderGenerator *generator =
        [[LTMeanShaderGenerator alloc] initWithNumberOfTextures:3];
    expect(generator.fragmentShaderSource).to.equal(kSampleShaderString);
  });

  it(@"should create correct uniform names array for 3 input textures ", ^{
    LTMeanShaderGenerator *generator =
        [[LTMeanShaderGenerator alloc] initWithNumberOfTextures:3];
    NSArray<NSString *> *uniformNames = generator.texturesUniformNames;
    expect(uniformNames).to.equal(@[@"sourceTexture", @"texture1", @"texture2"]);
  });
});

SpecEnd
