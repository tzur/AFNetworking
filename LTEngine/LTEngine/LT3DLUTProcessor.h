// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LT3DLUT;

/// Processor for applying a 3D LUT tonal transformation.
@interface LT3DLUTProcessor : LTOneShotImageProcessor

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer sourceTexture:(LTTexture *)sourceTexture
             auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                     andOutput:(LTTexture *)output NS_UNAVAILABLE;

- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer
                      strategy:(id<LTProcessingStrategy>)strategy
          andAuxiliaryTextures:(NSDictionary *)auxiliaryTextures NS_UNAVAILABLE;

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                           andOutput:(LTTexture *)output NS_UNAVAILABLE;

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output NS_UNAVAILABLE;

/// Initializes the processor with the given \c input and \c output textures.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output
    NS_DESIGNATED_INITIALIZER;

/// 3D lookup table, to be applied onto the input texture and rendered into the output texture.
/// Identity by default.
@property (nonatomic) LT3DLUT *lookupTable;

@end

NS_ASSUME_NONNULL_END
