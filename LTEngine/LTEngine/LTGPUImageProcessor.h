// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"
#import "LTTextureDrawer.h"
#import "LTProcessingStrategy.h"

@protocol LTProgramFactory;

/// Concrete image processor for GPU image processing tasks. The processor is defined by two
/// objects: an \c LTTextureDrawer used for drawing the area the processing is taking place
/// (such as rect, grid, an so on), and an \c LTProcessingStrategy that describes how much
/// processing is needed until a result is ready, and takes care of resource management to
/// seamlessly achieve that task. Since the strategy doesn't handle auxiliary textures, they are
/// taken care of by this class, which makes sure the drawer is aware of them prior to processing.
///
/// This class shouldn't be used directly, but sublassed to contain a specific drawer and strategy.
@interface LTGPUImageProcessor : LTImageProcessor

/// Initializes with an \c LTTextureDrawer, \c LTProcessingStrategy and auxiliary textures, which
/// can be \c nil.
///
/// @see documentation of this class for more information.
- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer
                      strategy:(id<LTProcessingStrategy>)strategy
          andAuxiliaryTextures:(NSDictionary *)auxiliaryTextures;

/// Program factory used when creating the program from the given vertex and fragment sources.
/// Subclasses can override this factory to modify program's creation. The default factory is \c
/// LTBasicProgramFactory.
+ (id<LTProgramFactory>)programFactory;

@end
