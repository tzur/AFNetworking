// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTTexture.h"

@interface LTGPUImageProcessor ()

/// Drawer to use while processing.
@property (strong, nonatomic) id<LTProcessingDrawer> drawer;

/// Strategy which manages the processing execution.
@property (strong, nonatomic) id<LTProcessingStrategy> strategy;

@end

@implementation LTGPUImageProcessor

- (instancetype)initWithDrawer:(id<LTProcessingDrawer>)drawer
                      strategy:(id<LTProcessingStrategy>)strategy
          andAuxiliaryTextures:(NSDictionary *)auxiliaryTextures {
  if (self = [super init]) {
    self.drawer = drawer;
    self.strategy = strategy;
    self.auxiliaryTextures = auxiliaryTextures;
  }
  return self;
}

- (void)process {
  [self processWithPlacement:^(LTNextIterationPlacement *placement) {
    [self.drawer setSourceTexture:placement.sourceTexture];
    [self drawWithPlacement:placement];
  }];
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  CGRect sourceRect = CGRectFromSize(placement.sourceTexture.size);
  CGRect targetRect = CGRectFromSize(placement.targetFbo.size);
  [self.drawer drawRect:targetRect inFramebuffer:placement.targetFbo fromRect:sourceRect];
}

@end
