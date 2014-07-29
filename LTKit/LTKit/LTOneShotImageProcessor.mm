// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTFbo.h"
#import "LTOneShotProcessingStrategy.h"
#import "LTRectDrawer.h"

@interface LTOneShotImageProcessor ()

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

@end

@implementation LTOneShotImageProcessor

- (instancetype)initWithProgram:(LTProgram *)program input:(LTTexture *)input
                      andOutput:(LTTexture *)output {
  return [self initWithProgram:program sourceTexture:input auxiliaryTextures:nil andOutput:output];
}

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
              auxiliaryTextures:(NSDictionary *)auxiliaryTextures andOutput:(LTTexture *)output {
  self.inputTexture = sourceTexture;
  self.outputTexture = output;

  LTOneShotProcessingStrategy *strategy = [[LTOneShotProcessingStrategy alloc]
                                           initWithInput:sourceTexture andOutput:output];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                                     sourceTexture:sourceTexture];
  return [super initWithDrawer:rectDrawer strategy:strategy andAuxiliaryTextures:auxiliaryTextures];
}

- (CGSize)inputSize {
  return self.inputTexture.size;
}

- (CGSize)outputSize {
  return self.outputTexture.size;
}

@end
