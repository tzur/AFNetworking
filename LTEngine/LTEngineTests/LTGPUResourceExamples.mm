// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResourceExamples.h"

#import "LTGLContext+Internal.h"
#import "LTGPUResource.h"
#import "LTGPUResourceProxy.h"

NSString * const kLTResourceExamples = @"LTResourceExamples";
NSString * const kLTResourceExamplesSUTValue = @"LTResourceExamplesSUTValue";
NSString * const kLTResourceExamplesOpenGLParameterName = @"LTResourceExamplesOpenGLParameterName";
NSString * const kLTResourceExamplesIsResourceFunction = @"LTResourceExamplesIsResourceFunction";

SharedExampleGroupsBegin(LTResourceExamples)

sharedExamplesFor(kLTResourceExamples, ^(NSDictionary *data) {
  __block id<LTGPUResource> resource;
  __block GLenum parameter;
  __block LTGLIsResource isResource;

  beforeEach(^{
    resource = [data[kLTResourceExamplesSUTValue] nonretainedObjectValue];
    parameter = [data[kLTResourceExamplesOpenGLParameterName] unsignedIntValue];
    isResource = (LTGLIsResource)[data[kLTResourceExamplesIsResourceFunction] pointerValue];
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

  it(@"should execute a block", ^{
    __block BOOL didExecute = NO;
    [resource bindAndExecute:^{
      didExecute = YES;
    }];
    expect(didExecute).to.beTruthy();
  });

  it(@"should raise exception when trying to execute a nil block", ^{
    expect(^{
      [resource bindAndExecute:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception when trying to execute a nil block when already bound", ^{
    expect(^{
      [resource bind];
      [resource bindAndExecute:nil];
      [resource unbind];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should appear in the current context resources", ^{
    auto resources = [[LTGLContext currentContext] resources];
    expect(resources).to.contain(resource);
  });

  it(@"should not appear in its context after disposal", ^{
    [resource dispose];
    auto resources = [[LTGLContext currentContext] resources];
    expect(resources).notTo.contain(resource);
  });

  it(@"should have context set to the current context", ^{
    expect(resource.context).to.equal([LTGLContext currentContext]);
  });

  it(@"should set name to 0 upon disposal", ^{
    [resource dispose];
    expect(resource.name).to.equal(0);
  });

  it(@"should not be bound after disposal", ^{
    [resource bind];
    [resource dispose];

    GLint currentBoundObject;
    glGetIntegerv(parameter, &currentBoundObject);
    expect(currentBoundObject).to.equal(0);
  });

  it(@"should not cause GL errors if unbinding after disposal", ^{
    [resource dispose];
    [resource unbind];
    LTGLCheck(@"GL errors caused while disposing");
  });

  it(@"should invalidate name after disposal", ^{
    // Some resources do not invalidate their names since it goes back to a pool. Therefore, this
    // test is optional.
    if (!isResource) {
      return;
    }

    GLuint name = resource.name;
    [resource dispose];
    expect(isResource(name)).to.beFalsy();
  });
});

SharedExampleGroupsEnd
