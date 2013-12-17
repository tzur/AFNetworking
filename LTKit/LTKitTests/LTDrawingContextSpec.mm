// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDrawingContext.h"

#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTVertexArray.h"

SpecBegin(LTDrawingContext)

context(@"binding program and vertex array", ^{
  it(@"should provide correct attribute to index mapping", ^{
    LTProgram *program = mock([LTProgram class]);
    LTVertexArray *vertexArray = mock([LTVertexArray class]);

    [given([program attributes]) willReturn:[NSSet setWithArray:@[@"a", @"b"]]];
    [given([program attributeForName:@"a"]) willReturn:@0];
    [given([program attributeForName:@"b"]) willReturn:@1];

    __unused LTDrawingContext *drawingContext =
        [[LTDrawingContext alloc] initWithProgram:program vertexArray:vertexArray
                                 uniformToTexture:nil];

    [verify(vertexArray) attachAttributesToIndices:@{@"a": @0, @"b": @1}];
  });

  context(@"uniform to texture mapping", ^{
    __block LTProgram *program;
    __block LTVertexArray *vertexArray;

    beforeEach(^{
      program = mock([LTProgram class]);
      vertexArray = mock([LTVertexArray class]);

      [given([program uniforms]) willReturn:[NSSet setWithArray:@[@"a", @"b"]]];
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
        LTGLTexture *texture = mock([LTGLTexture class]);
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
  });
});

SpecEnd
