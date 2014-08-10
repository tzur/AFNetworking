// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

@protocol LTProcessingDrawer, LTProcessingStrategy;

@class LTNextIterationPlacement;

/// Block for processing a source texture to a target framebuffer defined in the given \c placement.
typedef void (^LTProcessWithPlacementBlock)(LTNextIterationPlacement *placement);

@interface LTGPUImageProcessor (Protected)

/// Sets a processor's program's uniform \c key to the given \c value.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Returns the value of the processor's program's uniform with the name given by \c key.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Adds or updates a single auxiliary texture to the auxiliary textures dictionary. The texture
/// will be retained by the processor.
- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name;

/// Executes the processor's strategy and calls the given \c block with a placement configuration.
/// The block should process the source texture to the target framebuffer. For multi-pass
/// strategies, the block may be called multiple times with different placements.
- (void)processWithPlacement:(LTProcessWithPlacementBlock)block;

/// Dictionary of \c NSString to \c LTTexture of axiliary textures to use to assist processing.
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;

@end
