// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Processor for packing several single channel textures into a single RGBA texture.
/// If there are less than 4 input textures, the processor fills the rest of the channels in the
/// output texture with zeros.
@interface LTChannelsPackingProcessor : LTOneShotImageProcessor

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer
                      strategy:(id<LTProcessingStrategy>)strategy
          andAuxiliaryTextures:(NSDictionary *)auxiliaryTextures NS_UNAVAILABLE;

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                           andOutput:(LTTexture *)output NS_UNAVAILABLE;

- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer
                 sourceTexture:(LTTexture *)sourceTexture
             auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                     andOutput:(LTTexture *)output NS_UNAVAILABLE;

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output NS_UNAVAILABLE;

/// Initializes the processor with given \c inputs textures and an \c output texture. \c inputs must
/// contain between 1 to 4 single channel textures of the same size and the same pixel format. \c
/// output texture must be an RGBA texture with equal size and \c dataType to the input textures
/// ones.
- (instancetype)initWithInputs:(NSArray<LTTexture *> *)inputs output:(LTTexture *)output
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
