// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectImageProcessor.h"

#import "LTFbo.h"
#import "LTRectDrawer.h"

@interface LTImageProcessor ()
@property (strong, nonatomic) NSMutableDictionary *inputModel;
@end

@interface LTRectImageProcessor ()
/// Rect drawer used to process the texture.
@property (readwrite, nonatomic) LTRectDrawer *rectDrawer;
@end

@implementation LTRectImageProcessor

- (instancetype)initWithProgram:(LTProgram *)program inputs:(NSArray *)inputs
                        outputs:(NSArray *)outputs {
  self.rectDrawer = [self createRectDrawerWithProgram:program];
  return [super initWithInputs:inputs outputs:outputs];
}

- (LTRectDrawer *)createRectDrawerWithProgram:(LTProgram *)program {
  return [[LTRectDrawer alloc] initWithProgram:program];
}

- (LTMultipleTextureOutput *)process {
  [self updateRectDrawerWithModel];
  NSArray *outputs = [self drawToOutput];
  return [[LTMultipleTextureOutput alloc] initWithTextures:outputs];
}

- (void)updateRectDrawerWithModel {
  LTTexture *input = [self.inputs firstObject];
  [self.rectDrawer setSourceTexture:input];

  for (NSString *key in self.inputModel) {
    self.rectDrawer[key] = self.inputModel[key];
  }
}

- (NSArray *)drawToOutput {
  LTAssert(NO, @"-[LTRectImageProcessor drawToOutput:] is an abstract method that should be "
           "overridden by subclasses");
}

@end

@implementation LTRectImageProcessor (ForTesting)

- (instancetype)initWithRectDrawer:(LTRectDrawer *)rectDrawer inputs:(NSArray *)inputs
                           outputs:(NSArray *)outputs {
  self.rectDrawer = rectDrawer;
  return [super initWithInputs:inputs outputs:outputs];
}

@end
