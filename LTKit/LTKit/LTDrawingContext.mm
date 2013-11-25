// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDrawingContext.h"

#import "LTArrayBuffer.h"
#import "LTGPUStruct.h"
#import "LTProgram.h"
#import "LTTexture.h"
#import "LTVertexArray.h"

@interface LTDrawingContext ()

@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTVertexArray *vertexArray;
@property (strong, nonatomic) NSDictionary *uniformToTexture;

@end

@implementation LTDrawingContext

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithProgram:(LTProgram *)program vertexArray:(LTVertexArray *)vertexArray
     uniformToTexture:(NSDictionary *)uniformToTexture {
  if (self = [super init]) {
    NSParameterAssert(program);
    NSParameterAssert(vertexArray);
    LTAssert(!uniformToTexture ||
             [[NSSet setWithArray:uniformToTexture.allKeys] isSubsetOfSet:program.uniforms],
             @"At least one uniform does not exist in the given program (given uniforms: %@, "
             "uniforms in program: %@)", uniformToTexture.allKeys, program.uniforms);

    [self attachProgram:program toVertexArray:vertexArray];

    self.program = program;
    self.vertexArray = vertexArray;
    self.uniformToTexture = uniformToTexture;
  }
  return self;
}

#pragma mark -
#pragma mark Instance methods
#pragma mark -

- (void)drawWithMode:(LTDrawingContextDrawMode)mode {
  [self.program bindAndExecute:^{
    NSMutableArray *textureStack = [NSMutableArray array];

    GLenum index = 0;
    for (NSString *uniform in self.uniformToTexture) {
      LTTexture *texture = self.uniformToTexture[uniform];

      // Switch to the proper texture unit and bind the texture there.
      glActiveTexture(GL_TEXTURE0 + index);
      [texture bind];

      // Map sampler to the texture unit.
      self.program[uniform] = @(index);

      [textureStack addObject:texture];
    }

    [self.vertexArray bindAndExecute:^{
      glDrawArrays(mode, 0, self.vertexArray.count);
    }];

    // Unbind in reverse order.
    for (NSInteger i = textureStack.count - 1; i >= 0; --i) {
      [textureStack[i] unbind];
    }
  }];

  LTGLCheckDbg(@"Error while drawing with mode %d", mode);
}

- (void)attachProgram:(LTProgram *)program toVertexArray:(LTVertexArray *)vertexArray {
  NSMutableDictionary *attributeToIndex = [NSMutableDictionary dictionary];
  for (NSString *attribute in program.attributes) {
    attributeToIndex[attribute] = @([program attributeForName:attribute]);
  }
  [vertexArray attachAttributesToIndices:attributeToIndex];
}

@end
