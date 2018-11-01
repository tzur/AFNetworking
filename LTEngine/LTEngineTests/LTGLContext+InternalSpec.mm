// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTGLContext+Internal.h"

#import "LTGPUResource.h"

/// Object implementing \c LTGPUResource protocol, used for testing purpose.
@interface LTGPUTestResource : NSObject <LTGPUResource>
@property (readonly, nonatomic) GLuint name;
@property (readonly, nonatomic, nullable) LTGLContext *context;
@end

@implementation LTGPUTestResource

- (instancetype)initWithName:(GLuint)name {
  if (self = [super init]) {
    _name = name;
    _context = nil;
  }
  return self;
}

+ (instancetype)resourceWithName:(GLuint)name {
  return [[LTGPUTestResource alloc] initWithName:name];
}

- (void)bind {
  LTMethodNotImplemented();
}

- (void)unbind {
  LTMethodNotImplemented();
}

- (void)bindAndExecute:(__unused NS_NOESCAPE LTVoidBlock)block {
  LTMethodNotImplemented();
}

- (void)dispose {
  LTMethodNotImplemented();
}

@end

SpecBegin(LTGLContext_Internal)

__block LTGLContext * _Nullable glContext;

beforeEach(^{
  glContext = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:glContext];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
  glContext = nil;
});

it(@"should add multiple resources", ^{
  auto resource1 = [LTGPUTestResource resourceWithName:1];
  auto resource2 = [LTGPUTestResource resourceWithName:2];
  auto resource3 = [LTGPUTestResource resourceWithName:3];

  [glContext addResource:resource1];
  [glContext addResource:resource2];
  [glContext addResource:resource3];

  auto resources = glContext.resources;

  expect(resources).to.haveCountOf(3);
  expect(resources).to.contain(resource1);
  expect(resources).to.contain(resource2);
  expect(resources).to.contain(resource3);
});

it(@"should override when adding existing resource", ^{
  auto resource1 = [LTGPUTestResource resourceWithName:3];
  auto resource2 = [LTGPUTestResource resourceWithName:3];

  [glContext addResource:resource1];
  [glContext addResource:resource2];

  expect(glContext.resources.count).to.equal(1);
  expect([glContext.resources containsObject:resource2]).to.beTruthy();
});

it(@"should remove existing resources", ^{
  auto resource1 = [LTGPUTestResource resourceWithName:10];
  auto resource2 = [LTGPUTestResource resourceWithName:11];
  auto resource3 = [LTGPUTestResource resourceWithName:12];

  [glContext addResource:resource1];
  [glContext addResource:resource2];
  [glContext addResource:resource3];

  [glContext removeResource:resource1];
  [glContext removeResource:resource2];
  [glContext removeResource:resource3];

  expect(glContext.resources.count).to.equal(0);
});

it(@"should do nothing when trying to remove non existing resource", ^{
  auto resource1 = [LTGPUTestResource resourceWithName:5];
  auto resource2 = [LTGPUTestResource resourceWithName:6];
  auto resource3 = [LTGPUTestResource resourceWithName:7];

  [glContext addResource:resource1];
  [glContext addResource:resource2];
  [glContext removeResource:resource3];

  expect(glContext.resources).to.haveCountOf(2);
  expect(glContext.resources).to.contain(resource1);
  expect(glContext.resources).to.contain(resource2);
});

SpecEnd
