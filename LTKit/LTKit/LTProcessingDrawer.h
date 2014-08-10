// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMultiRectDrawer.h"
#import "LTSingleRectDrawer.h"

@class LTProgram, LTTexture;

/// Protocol for drawers that can be used to process an image using the GPU.
@protocol LTProcessingDrawer <LTTextureDrawer, LTSingleRectDrawer, LTMultiRectDrawer>

/// Initializes with the given program and source texture, with no auxiliary textures. The program
/// must include the uniforms \c projection (projection matrix), \c modelview (modelview matrix) \c
/// texture (texture matrix) and \c sourceTexture (the master source texture).
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture;

/// Designated initializer: initializes with the given program, source texture and auxiliary
/// textures. The source coordinate system of the drawer is defined by the source texture (when used
/// in the \c drawRect:inFramebuffer:fromRect: and \c drawRect:inFramebufferWithSize:fromRect:
/// methods).
///
/// @param program program used while drawing. Must include the uniforms \c projection (projection
/// matrix), \c modelview (modelview matrix) and \c texture (texture matrix).
/// @param uniformToauxiliaryTexture mapping between uniform name (\c NSString) and its
/// corresponding \c LTTexture object.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
              auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture;

@end
