// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectImageProcessor.h"

#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"

@interface LTTestRectImageProcessor : LTRectImageProcessor
@end

@implementation LTTestRectImageProcessor

- (NSArray *)drawToOutput {
  return self.outputs;
}

@end

SpecBegin(LTRectImageProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTTexture *input;
__block LTTexture *output;

beforeEach(^{
  input = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                  precision:LTTexturePrecisionByte
                                   channels:LTTextureChannelsRGBA
                             allocateMemory:YES];

  output = [[LTGLTexture alloc] initWithSize:input.size
                                   precision:input.precision
                                    channels:input.channels
                              allocateMemory:YES];
});

afterEach(^{
  input = nil;
  output = nil;
});

it(@"should initialize with a valid program", ^{
  LTProgram *program = [[LTProgram alloc]
                        initWithVertexSource:[LTShaderStorage passthroughVsh]
                        fragmentSource:[LTShaderStorage passthroughFsh]];

  expect(^{
    __unused LTRectImageProcessor *processor = [[LTRectImageProcessor alloc]
                                                initWithProgram:program
                                                inputs:@[input]
                                                outputs:@[output]];
  }).toNot.raiseAny();
});

it(@"should configure rect drawer with model", ^{
  id drawerMock = [OCMockObject mockForClass:[LTRectDrawer class]];

  static NSString * const kFirstKey = @"MyFirstKey";
  static NSString * const kFirstValue = @"MyFirstValue";
  static NSString * const kSecondKey = @"MySecondKey";
  static NSString * const kSecondValue = @"MySecondValue";

  [[drawerMock expect] setSourceTexture:input];
  [[drawerMock expect] setObject:kFirstValue forKeyedSubscript:kFirstKey];
  [[drawerMock expect] setObject:kSecondValue forKeyedSubscript:kSecondKey];

  LTRectImageProcessor *processor = [[LTTestRectImageProcessor alloc]
                                     initWithRectDrawer:drawerMock
                                     inputs:@[input]
                                     outputs:@[output]];

  processor[kFirstKey] = kFirstValue;
  processor[kSecondKey] = kSecondValue;

  LTMultipleTextureOutput *result = [processor process];

  expect(result.textures.count).to.equal(1);

  [drawerMock verify];
});

SpecEnd
