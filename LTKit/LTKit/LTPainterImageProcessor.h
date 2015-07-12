// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTProgressiveImageProcessor.h"

@protocol LTPaintingStrategy;
@class LTTexture;

/// Concrete image processor for \c LTPainter based image processing tasks. The processor is defined
/// by a canvas texture, and an \c LTPainterStrategy that specifies how the processor will paint on
/// given canvas. This processor is built on the \c LTProgressiveProcessor interface. This allows
/// animating the output, as its being processed, as painting based processing might be time
/// consuming (due to deferred rendering in overlapping areas).
@interface LTPainterImageProcessor : LTProgressiveImageProcessor

/// Initializes the processor with the given canvas texture and painting strategy.
- (instancetype)initWithCanvasTexture:(LTTexture *)canvasTexture
                     paintingStrategy:(id<LTPaintingStrategy>)strategy;

/// Size of the canvas texture.
@property (readonly, nonatomic) CGSize canvasSize;

@end
