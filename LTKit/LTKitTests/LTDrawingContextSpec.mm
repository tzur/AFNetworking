// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDrawingContext.h"

#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTVertexArray.h"

SpecBegin(LTDrawingContext)

context(@"binding program and vertex array", ^{
  it(@"should provide correct attribute to index mapping", ^{
    id program = [OCMockObject mockForClass:[LTProgram class]];
    id vertexArray = [OCMockObject mockForClass:[LTVertexArray class]];

    [[[program stub] andReturn:[NSSet setWithArray:@[@"a", @"b"]]] attributes];
    [[[program stub] andReturnValue:@(0)] attributeForName:@"a"];
    [[[program stub] andReturnValue:@(1)] attributeForName:@"b"];

    [[vertexArray expect] attachAttributesToIndices:@{@"a": @0, @"b": @1}];

    __unused LTDrawingContext *drawingContext =
        [[LTDrawingContext alloc] initWithProgram:program vertexArray:vertexArray
                                 uniformToTexture:nil];

    [vertexArray verify];
  });

  context(@"uniform to texture mapping", ^{
    __block id program;
    __block id vertexArray;

    beforeEach(^{
      program = [OCMockObject niceMockForClass:[LTProgram class]];
      vertexArray = [OCMockObject niceMockForClass:[LTVertexArray class]];

      [[[program stub] andReturn:[NSSet setWithArray:@[@"a", @"b"]]] uniforms];
    });

    it(@"should raise when uniforms is not a subset of program uniforms", ^{
      NSDictionary *uniformMap = @{@"a": [NSNull null], @"c": [NSNull null]};

      expect(^{
        __unused LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:program
                                                                           vertexArray:vertexArray
                                                                      uniformToTexture:uniformMap];
      }).to.raise(NSInternalInconsistencyException);
    });

    it(@"should raise when attaching a uniform which does not exist in program", ^{
      LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:program
                                                                vertexArray:vertexArray
                                                           uniformToTexture:nil];

      expect(^{
        id texture = [OCMockObject niceMockForClass:[LTGLTexture class]];
        [context attachUniform:@"z" toTexture:texture];
      }).to.raise(NSInternalInconsistencyException);
    });

    it(@"should raise when attaching a nil texture", ^{
      LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:program
                                                                vertexArray:vertexArray
                                                           uniformToTexture:nil];

      expect(^{
        [context attachUniform:@"a" toTexture:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when detaching nil uniform", ^{
      LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:program
                                                                vertexArray:vertexArray
                                                           uniformToTexture:nil];

      expect(^{
        [context detachUniformFromTexture:nil];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

SpecEnd
