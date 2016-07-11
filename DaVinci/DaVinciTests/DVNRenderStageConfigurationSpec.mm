// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNRenderStageConfiguration.h"

#import <LTEngine/LTTexture.h>

SpecBegin(DVNRenderStageConfiguration)

static NSString * const vertexSource = @"vertex source";
static NSString * const fragmentSource = @"fragment source";

context(@"initialization", ^{
  it(@"should initialize correctly without auxiliary textures and uniforms", ^{
    DVNRenderStageConfiguration *configuration =
        [[DVNRenderStageConfiguration alloc] initWithVertexSource:vertexSource
                                                   fragmentSource:fragmentSource];
    expect(configuration.vertexSource).to.equal(vertexSource);
    expect(configuration.fragmentSource).to.equal(fragmentSource);
    expect(configuration.auxiliaryTextures).to.beEmpty();
    expect(configuration.uniforms).to.beEmpty();
  });

  it(@"should initialize correctly without auxiliary textures and uniforms", ^{
    id textureMock = OCMClassMock([LTTexture class]);
    NSDictionary<NSString *, LTTexture *> *auxiliaryTextures = @{@"texture": textureMock};
    NSDictionary<NSString *, NSValue *> *uniforms = @{@"uniform": @1};

    DVNRenderStageConfiguration *configuration =
        [[DVNRenderStageConfiguration alloc] initWithVertexSource:vertexSource
                                                   fragmentSource:fragmentSource
                                                auxiliaryTextures:auxiliaryTextures
                                                         uniforms:uniforms];

    expect(configuration.vertexSource).to.equal(vertexSource);
    expect(configuration.fragmentSource).to.equal(fragmentSource);
    expect(configuration.auxiliaryTextures).to.equal(auxiliaryTextures);
    expect(configuration.uniforms).to.equal(uniforms);
  });
});

SpecEnd
