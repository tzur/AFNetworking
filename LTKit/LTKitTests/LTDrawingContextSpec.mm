// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDrawingContext.h"

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

  it(@"should raise when uniforms is not a subset of program uniforms", ^{
    LTProgram *program = mock([LTProgram class]);
    LTVertexArray *vertexArray = mock([LTVertexArray class]);

    [given([program uniforms]) willReturn:[NSSet setWithArray:@[@"a", @"b"]]];

    NSDictionary *uniformMap = @{@"a": [NSNull null], @"c": [NSNull null]};

    expect(^{
      __unused LTDrawingContext *context = [[LTDrawingContext alloc] initWithProgram:program
                                                                         vertexArray:vertexArray
                                                                    uniformToTexture:uniformMap];
    }).to.raise(NSInternalInconsistencyException);
  });
});

SpecEnd
