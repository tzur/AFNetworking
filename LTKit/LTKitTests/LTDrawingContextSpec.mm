// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDrawingContext.h"

#import "LTArrayBuffer.h"
#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+TwoInputTexturesFsh.h"
#import "LTVertexArray.h"

LTSpecBegin(LTDrawingContext)

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

context(@"texture binding while drawing", ^{
  __block id vertexArray;
  __block id textureA;
  __block id textureB;

  __block LTProgram *program;
  __block id programMock;

  __block LTDrawingContext *drawingContext;

  __block LTFbo *fbo;

  beforeEach(^{
    LTTexture *output = [[LTGLTexture alloc] initByteRGBAWithSize:CGSizeMake(1, 1)];
    fbo = [[LTFbo alloc] initWithTexture:output];

    vertexArray = [OCMockObject niceMockForClass:[LTVertexArray class]];
    textureA = [OCMockObject niceMockForClass:[LTTexture class]];
    textureB = [OCMockObject niceMockForClass:[LTTexture class]];

    program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                       fragmentSource:[TwoInputTexturesFsh source]];
    programMock = [OCMockObject partialMockForObject:program];

    NSDictionary *uniformMap = @{[TwoInputTexturesFsh textureA]: textureA,
                                 [TwoInputTexturesFsh textureB]: textureB};
    drawingContext = [[LTDrawingContext alloc] initWithProgram:program
                                            vertexArray:vertexArray
                                       uniformToTexture:uniformMap];
  });

  afterEach(^{
    fbo = nil;
    drawingContext = nil;
    program = nil;
    programMock = nil;
  });

  context(@"draw with mode", ^{
    it(@"should set unique texture unit values as shader uniforms", ^{
      // Record used indices when setting sampler index.
      __block NSMutableArray *usedIndices = [NSMutableArray array];
      id valueCheck = [OCMArg checkWithBlock:^BOOL(NSNumber *number) {
        [usedIndices addObject:number];
        return YES;
      }];
      
      [[programMock expect] setObject:valueCheck forKeyedSubscript:[OCMArg any]];
      [[programMock expect] setObject:valueCheck forKeyedSubscript:[OCMArg any]];
      
      [fbo bindAndDraw:^{
        [drawingContext drawWithMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [programMock verify];
      
      // Verify given indices are unique.
      expect(usedIndices.count).to.equal([NSSet setWithArray:usedIndices].count);
    });
    
    it(@"should bind to textures", ^{
      [[textureA expect] bind];
      [[textureB expect] bind];
      
      [fbo bindAndDraw:^{
        [drawingContext drawWithMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
    
    it(@"should unbind from textures", ^{
      [[textureA expect] unbind];
      [[textureB expect] unbind];
      
      [fbo bindAndDraw:^{
        [drawingContext drawWithMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
    
    it(@"should mark begin read from texture", ^{
      [[textureA expect] beginReadFromTexture];
      [[textureB expect] beginReadFromTexture];
      
      [fbo bindAndDraw:^{
        [drawingContext drawWithMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
    
    it(@"should mark end read from texture", ^{
      [[textureA expect] endReadFromTexture];
      [[textureB expect] endReadFromTexture];
      
      [fbo bindAndDraw:^{
        [drawingContext drawWithMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
  });
  
  context(@"draw elements with mode", ^{
    __block id elementsBuffer;
    
    beforeEach(^{
      elementsBuffer = [OCMockObject mockForClass:[LTArrayBuffer class]];
      [(LTArrayBuffer *)[[elementsBuffer stub] andReturnValue:@(LTArrayBufferTypeElement)] type];
    });
    
    it(@"should set unique texture unit values as shader uniforms", ^{
      // Record used indices when setting sampler index.
      __block NSMutableArray *usedIndices = [NSMutableArray array];
      id valueCheck = [OCMArg checkWithBlock:^BOOL(NSNumber *number) {
        [usedIndices addObject:number];
        return YES;
      }];
      
      [[programMock expect] setObject:valueCheck forKeyedSubscript:[OCMArg any]];
      [[programMock expect] setObject:valueCheck forKeyedSubscript:[OCMArg any]];
      
      [fbo bindAndDraw:^{
        [drawingContext drawElements:elementsBuffer withMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [programMock verify];
      
      // Verify given indices are unique.
      expect(usedIndices.count).to.equal([NSSet setWithArray:usedIndices].count);
    });
    
    it(@"should bind to textures", ^{
      [[textureA expect] bind];
      [[textureB expect] bind];
      
      [fbo bindAndDraw:^{
        [drawingContext drawElements:elementsBuffer withMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
    
    it(@"should unbind from textures", ^{
      [[textureA expect] unbind];
      [[textureB expect] unbind];
      
      [fbo bindAndDraw:^{
        [drawingContext drawElements:elementsBuffer withMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
    
    it(@"should mark begin read from texture", ^{
      [[textureA expect] beginReadFromTexture];
      [[textureB expect] beginReadFromTexture];
      
      [fbo bindAndDraw:^{
        [drawingContext drawElements:elementsBuffer withMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
    
    it(@"should mark end read from texture", ^{
      [[textureA expect] endReadFromTexture];
      [[textureB expect] endReadFromTexture];
      
      [fbo bindAndDraw:^{
        [drawingContext drawElements:elementsBuffer withMode:LTDrawingContextDrawModeTriangles];
      }];
      
      [textureA verify];
      [textureB verify];
    });
  });
});

LTSpecEnd
