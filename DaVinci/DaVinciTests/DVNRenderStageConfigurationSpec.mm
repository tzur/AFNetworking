// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNRenderStageConfiguration.h"

#import <LTEngine/LTTexture+Factory.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

SpecBegin(DVNRenderStageConfiguration)

static NSString * const kVertexSource = @"vertex source";
static NSString * const kFragmentSource = @"fragment source";
static NSDictionary<NSString *, NSValue *> * const kUniforms = @{@"uniform": @1};

__block NSDictionary<NSString *, LTTexture *> *auxiliaryTextures;
__block LTTexture *textureMock;

beforeEach(^{
  textureMock = OCMClassMock([LTTexture class]);
  auxiliaryTextures = @{@"texture": textureMock};
});

context(@"initialization", ^{
  it(@"should initialize correctly without auxiliary textures and uniforms", ^{
    DVNRenderStageConfiguration *configuration =
        [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                                   fragmentSource:kFragmentSource];
    expect(configuration.vertexSource).to.equal(kVertexSource);
    expect(configuration.fragmentSource).to.equal(kFragmentSource);
    expect(configuration.auxiliaryTextures).to.beEmpty();
    expect(configuration.uniforms).to.beEmpty();
  });

  it(@"should initialize correctly without auxiliary textures and uniforms", ^{
    DVNRenderStageConfiguration *configuration =
        [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                                   fragmentSource:kFragmentSource
                                                auxiliaryTextures:auxiliaryTextures
                                                         uniforms:kUniforms];

    expect(configuration.vertexSource).to.equal(kVertexSource);
    expect(configuration.fragmentSource).to.equal(kFragmentSource);
    expect(configuration.auxiliaryTextures).to.equal(auxiliaryTextures);
    expect(configuration.uniforms).to.equal(kUniforms);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNRenderStageConfiguration *configuration =
      [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                                 fragmentSource:kFragmentSource
                                              auxiliaryTextures:auxiliaryTextures
                                                       uniforms:kUniforms];
  DVNRenderStageConfiguration *equalConfiguration =
      [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                                 fragmentSource:kFragmentSource
                                              auxiliaryTextures:auxiliaryTextures
                                                       uniforms:kUniforms];
  DVNRenderStageConfiguration *differentConfiguration =
    [[DVNRenderStageConfiguration alloc] initWithVertexSource:kFragmentSource
                                               fragmentSource:kVertexSource
                                            auxiliaryTextures:auxiliaryTextures
                                                     uniforms:kUniforms];
  DVNRenderStageConfiguration *otherDifferentConfiguration =
  [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                             fragmentSource:kFragmentSource
                                          auxiliaryTextures:@{}
                                                   uniforms:kUniforms];
  DVNRenderStageConfiguration *yetAnotherDifferentConfiguration =
      [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                                 fragmentSource:kFragmentSource
                                              auxiliaryTextures:auxiliaryTextures
                                                       uniforms:@{}];
  return @{
    kLTEqualityExamplesObject: configuration,
    kLTEqualityExamplesEqualObject: equalConfiguration,
    kLTEqualityExamplesDifferentObjects: @[differentConfiguration, otherDifferentConfiguration,
                                           yetAnotherDifferentConfiguration]
  };
});

context(@"instance creation with updated properties", ^{
  __block DVNRenderStageConfiguration *configuration;

  beforeEach(^{
    configuration = [[DVNRenderStageConfiguration alloc] initWithVertexSource:kVertexSource
                                                               fragmentSource:kFragmentSource
                                                            auxiliaryTextures:auxiliaryTextures
                                                                     uniforms:kUniforms];
  });

  it(@"should create a new instance with given auxiliary textures and uniform values", ^{
    LTTexture *otherTextureMock = OCMClassMock([LTTexture class]);
    NSDictionary<NSString *, LTTexture *> *otherAuxiliaryTextures = @{@"texture": otherTextureMock};
    NSDictionary<NSString *, NSValue *> *otherUniforms = @{@"uniform": @7};

    DVNRenderStageConfiguration *otherConfiguration =
        [configuration copyWithAuxiliaryTextures:otherAuxiliaryTextures uniforms:otherUniforms];

    expect(otherConfiguration.vertexSource).to.equal(configuration.vertexSource);
    expect(otherConfiguration.fragmentSource).to.equal(configuration.fragmentSource);
    expect(otherConfiguration.auxiliaryTextures).toNot.equal(configuration.auxiliaryTextures);
    expect(otherConfiguration.auxiliaryTextures).to.equal(otherAuxiliaryTextures);
    expect(otherConfiguration.uniforms).toNot.equal(configuration.uniforms);
    expect(otherConfiguration.uniforms).to.equal(otherUniforms);
  });
});

SpecEnd
