// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

@interface LTGPUImageProcessor (Protected)

/// Adds or updates a single auxiliary texture to the auxiliary textures dictionary. The texture
/// will be retained by the processor.
- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name;

/// Dictionary of \c NSString to \c LTTexture of axiliary textures to use to assist processing.
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;

@end
