// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResourceExamples.h"

#import "LTGPUResource.h"

NSString * const kLTResourceExamples = @"LTResourceExamples";
NSString * const kLTResourceExamplesSUTValue = @"LTResourceExamplesSUTValue";
NSString * const kLTResourceExamplesOpenGLParameterName = @"LTResourceExamplesOpenGLParameterName";

SharedExampleGroupsBegin(LTResourceExamples)

sharedExamplesFor(kLTResourceExamples, ^(NSDictionary *data) {
  __block id<LTGPUResource> resource;
  __block GLenum parameter;

  beforeEach(^{
    resource = [data[kLTResourceExamplesSUTValue] nonretainedObjectValue];
    parameter = [data[kLTResourceExamplesOpenGLParameterName] unsignedIntValue];
  });

  afterEach(^{
    resource = nil;
  });

  it(@"should bind to texture", ^{
    [resource bind];

    GLint currentBoundObject;
    glGetIntegerv(parameter, &currentBoundObject);

    expect(currentBoundObject).to.equal(resource.name);
  });

  it(@"should cause no effect on second bind", ^{
    [resource bind];
    [resource bind];

    GLint currentBoundObject;
    glGetIntegerv(parameter, &currentBoundObject);

    expect(currentBoundObject).to.equal(resource.name);
  });

  it(@"should unbind from texture", ^{
    [resource bind];
    [resource unbind];

    GLint currentBoundObject;
    glGetIntegerv(parameter, &currentBoundObject);

    expect(currentBoundObject).to.equal(0);
  });

  it(@"should cause no effect on second unbind", ^{
    [resource bind];
    [resource unbind];
    [resource unbind];

    GLint currentBoundObject;
    glGetIntegerv(parameter, &currentBoundObject);

    expect(currentBoundObject).to.equal(0);
  });

  it(@"should bind and unbind", ^{
    __block GLint currentBoundObject;

    [resource bindAndExecute:^{
      glGetIntegerv(parameter, &currentBoundObject);
      expect(currentBoundObject).to.equal(resource.name);
    }];

    glGetIntegerv(parameter, &currentBoundObject);
    expect(currentBoundObject).to.equal(0);
  });

  it(@"should support recursive binding", ^{
    __block GLint currentBoundObject;

    [resource bindAndExecute:^{
      [resource bindAndExecute:^{
      }];

      glGetIntegerv(parameter, &currentBoundObject);
      expect(currentBoundObject).to.equal(resource.name);
    }];
  });
});

SharedExampleGroupsEnd
