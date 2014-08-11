// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTProgram, LTTexture;

/// Uniform name of the source texture, which must be contained in each texture drawer program.
extern NSString * const kLTSourceTextureUniform;

/// Protocol which accompanies the abstract class \c LTTextureDrawer. This protocol can be used by
/// classes that wrap other drawers and don't want the additional functionality that is gained by
/// subclassing from the \c LTTextureDrawer abstract class.
@protocol LTTextureDrawer <NSObject>

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

/// Sets the source texture to the given \c texture. If the texture is equal to the current
/// configured texture, no action will be done. The given texture cannot be \c nil.
- (void)setSourceTexture:(LTTexture *)texture;

/// Sets auxiliary \c texture with the given sampler \c name as an input source to the drawer.
/// Both \c texture and \c name cannot be \c nil, and \c name cannot be \c sourceTexture.
- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name;

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c -[LTProgram setUniform:withValue:].
- (void)setUniform:(NSString *)name withValue:(id)value;

/// Returns the underlying program's uniform value for the given \c name, or throws an exception if
/// the \c name is not a valid one.
- (id)uniformForName:(NSString *)name;

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c setUniform:withValue:.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Returns the underlying program's uniform value, or throws an exception if the given \c key is
/// not a valid one.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Set of mandatory uniforms that must exist in the given program.
@property (readonly, nonatomic) NSSet *mandatoryUniforms;

@end

/// Abstract class for drawer objects. The abstract drawer is capable of initializing from a
/// program and a set of textures and verifying their correctness. It enforces mandatory uniforms
/// that must exist in the given program. Additionally, it allows to modify the underlying program's
/// uniforms.
///
/// @note subclasses must implement the abstract \c createDrawingContext method, which creates a
/// context for drawing, and supply an appropriate drawing methods based on the drawer's intents.
@interface LTTextureDrawer : NSObject <LTTextureDrawer>
@end
