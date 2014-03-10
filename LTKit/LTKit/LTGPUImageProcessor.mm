// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTTexture.h"

@interface LTGPUImageProcessor ()

/// Drawer to use while processing.
@property (strong, nonatomic) id<LTProcessingDrawer> drawer;

/// Strategy which manages the processing execution.
@property (strong, nonatomic) id<LTProcessingStrategy> strategy;

/// Dictionary of \c NSString to \c LTTexture of axiliary textures to use to assist processing.
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;

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

- (id<LTImageProcessorOutput>)process {
  [self.strategy processingWillBegin];

  while ([self.strategy hasMoreIterations]) {
    LTNextIterationPlacement *placement = [self.strategy iterationStarted];

    [self.drawer setSourceTexture:placement.sourceTexture];
    [self drawWithPlacement:placement];
    [self.strategy iterationEnded];
  }

  return [self.strategy processedOutputs];
}

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  CGRect sourceRect = CGRectFromOriginAndSize(CGPointZero, placement.sourceTexture.size);
  CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, placement.targetFbo.size);
  [self.drawer drawRect:targetRect inFramebuffer:placement.targetFbo fromRect:sourceRect];
}

- (void)setAuxiliaryTextures:(NSDictionary *)auxiliaryTextures {
  _auxiliaryTextures = auxiliaryTextures;
  [auxiliaryTextures enumerateKeysAndObjectsUsingBlock:^(NSString *key, LTTexture *obj, BOOL *) {
    [self.drawer setAuxiliaryTexture:obj withName:key];
  }];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  [self.drawer setUniform:key withValue:obj];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self.drawer uniformForName:key];
}

@end
