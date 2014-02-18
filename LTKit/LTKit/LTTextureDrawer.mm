// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

#import "LTArrayBuffer.h"
#import "LTDrawingContext.h"
#import "LTProgram.h"

@interface LTTextureDrawer ()

/// Program to use when drawing the rect.
@property (strong, nonatomic) LTProgram *program;

/// Context holding the geometry and program.
@property (strong, nonatomic) LTDrawingContext *context;

/// Mapping between uniform name and its attached texture.
@property (strong, nonatomic) NSMutableDictionary *uniformToTexture;

@end

@implementation LTTextureDrawer

NSString * const kSourceTextureUniform = @"sourceTexture";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture {
  return [self initWithProgram:program sourceTexture:texture auxiliaryTextures:nil];
}

- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
    auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture {
  if (self = [super init]) {
    LTParameterAssert([self.mandatoryUniforms isSubsetOfSet:program.uniforms], @"At least one of "
                      "the required uniforms %@ doesn't exist in the given program",
                      self.mandatoryUniforms);
    LTParameterAssert([[NSSet setWithArray:[uniformToAuxiliaryTexture allKeys]]
                       isSubsetOfSet:program.uniforms], @"At least one of the given auxiliary "
                      "texture uniforms %@ doesn't exist in the given program",
                      [uniformToAuxiliaryTexture allKeys]);
    
    self.uniformToTexture = [NSMutableDictionary dictionary];
    [self setSourceTexture:texture];
    [self setAuxiliaryTextures:uniformToAuxiliaryTexture];
    
    self.program = program;
    self.context = [self createDrawingContext];
  }
  return self;
}

#pragma mark -
#pragma mark Abstract
#pragma mark -

- (LTDrawingContext *)createDrawingContext {
  LTMethodNotImplemented();
}

- (void)drawRect:(__unused CGRect)targetRect inFramebuffer:(LTFbo __unused *)fbo
        fromRect:(__unused CGRect)sourceRect {
  LTMethodNotImplemented();
}

- (void)drawRotatedRect:(LTRotatedRect __unused *)targetRect inFramebuffer:(LTFbo __unused *)fbo
        fromRotatedRect:(LTRotatedRect __unused *)sourceRect {
  LTMethodNotImplemented();
}

- (void)drawRotatedRects:(NSArray __unused *)targetRects inFramebuffer:(LTFbo __unused *)fbo
        fromRotatedRects:(NSArray __unused *)sourceRects {
  LTMethodNotImplemented();
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setAuxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture {
  [uniformToAuxiliaryTexture
   enumerateKeysAndObjectsUsingBlock:^(NSString *key, LTTexture *texture, BOOL *) {
     [self setTexture:texture withName:key];
   }];
}

- (void)setSourceTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  [self setTexture:texture withName:kSourceTextureUniform];
}

- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name {
  LTParameterAssert(texture);
  LTParameterAssert(name && ![name isEqualToString:kSourceTextureUniform]);
  [self setTexture:texture withName:name];
}

- (void)setTexture:(LTTexture *)texture withName:(NSString *)name {
  if ([self.uniformToTexture[name] isEqual:texture]) {
    return;
  }
  self.uniformToTexture[name] = texture;
  
  [self.context attachUniform:name toTexture:texture];
}

- (void)setUniform:(NSString *)name withValue:(id)value {
  LTAssert(![name isEqualToString:@"position"] &&
           ![name isEqualToString:@"texcoord"], @"Uniform name cannot be one of %@",
           self.mandatoryUniforms);
  
  self.program[name] = value;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  [self setUniform:key withValue:obj];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self uniformForName:key];
}

- (id)uniformForName:(NSString *)name {
  return self.program[name];
}

- (NSSet *)mandatoryUniforms {
  static NSSet *uniforms;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    uniforms = [NSSet setWithArray:@[@"projection", @"modelview", @"texture",
                                     kSourceTextureUniform]];
  });
  
  return uniforms;
}

@end
