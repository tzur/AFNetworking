// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDrawingContext.h"

#import "LTArrayBuffer.h"
#import "LTGPUStruct.h"
#import "LTIndicesArray.h"
#import "LTProgram.h"
#import "LTTexture.h"
#import "LTVertexArray.h"

@interface LTDrawingContext ()

@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTVertexArray *vertexArray;
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;

@end

@implementation LTDrawingContext

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProgram:(LTProgram *)program vertexArray:(LTVertexArray *)vertexArray
               uniformToTexture:(NSDictionary *)uniformToTexture {
  if (self = [super init]) {
    LTParameterAssert(program);
    LTParameterAssert(vertexArray);
    LTAssert(!uniformToTexture ||
             [[NSSet setWithArray:uniformToTexture.allKeys] isSubsetOfSet:program.uniforms],
             @"At least one uniform does not exist in the given program (given uniforms: %@, "
             "uniforms in program: %@)", uniformToTexture.allKeys, program.uniforms);

    [self attachProgram:program toVertexArray:vertexArray];

    self.program = program;
    self.vertexArray = vertexArray;
    self.uniformToTexture = [[NSMutableDictionary alloc] initWithDictionary:uniformToTexture];
  }
  return self;
}

#pragma mark -
#pragma mark Instance methods
#pragma mark -

- (void)drawWithMode:(LTDrawingContextDrawMode)mode {
  [self drawUsingBlock:^{
    glDrawArrays(mode, 0, self.vertexArray.count);
  }];
}

- (void)drawElements:(LTIndicesArray *)indices withMode:(LTDrawingContextDrawMode)mode {
  LTParameterAssert(indices);
  [self drawUsingBlock:^{
    [indices.arrayBuffer bindAndExecute:^{
      glDrawElements(mode, (GLsizei)indices.count, indices.type, 0);
    }];
  }];
}

- (void)drawUsingBlock:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self.program bindAndExecute:^{
    NSMutableArray *textureStack = [NSMutableArray array];

    GLenum index = 0;
    for (NSString *uniform in self.uniformToTexture) {
      LTTexture *texture = self.uniformToTexture[uniform];

      // Switch to the proper texture unit and bind the texture there.
      glActiveTexture(GL_TEXTURE0 + index);
      [texture bind];
      [texture beginReadFromTexture];

      // Map sampler to the texture unit.
      self.program[uniform] = @(index);
      
      [textureStack addObject:texture];
      ++index;
    }

    /// Bind the vertex array, and use the block to draw.
    [self.vertexArray bindAndExecute:block];
    
    // Unbind in reverse order.
    for (NSInteger i = textureStack.count - 1; i >= 0; --i) {
      [textureStack[i] endReadFromTexture];
      [textureStack[i] unbind];
    }
  }];

  LTGLCheckDbg(@"Error while drawing");
}

- (void)attachUniform:(NSString *)uniform toTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  LTAssert([self.program.uniforms containsObject:uniform], @"Given uniform '%@' is not one of the "
           "program's uniforms: %@", uniform, self.program.uniforms);

  self.uniformToTexture[uniform] = texture;
}

- (void)detachUniformFromTexture:(NSString *)uniform {
  LTParameterAssert(uniform);
  [self.uniformToTexture removeObjectForKey:uniform];
}

- (void)attachProgram:(LTProgram *)program toVertexArray:(LTVertexArray *)vertexArray {
  NSMutableDictionary *attributeToIndex = [NSMutableDictionary dictionary];
  for (NSString *attribute in program.attributes) {
    attributeToIndex[attribute] = @([program attributeForName:attribute]);
  }
  [vertexArray attachAttributesToIndices:attributeToIndex];
}

@end
