// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Processor for calculating a displacement map which animates a scene given its segmentation to
/// different types of objects. The processor also calculates the segmentation of the animated scene
/// as it changes due to motion added to the scene.
@interface PNKImageMotionDisplacementProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with the \c segmentation of the scene. Returns \c nil when initialized
/// on a simulator or an unsupported GPU; in this case \c error will contain the description of the
/// issue.
- (nullable instancetype)initWithSegmentation:(lt::Ref<CVPixelBufferRef>)segmentation
                                        error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

/// Calculates a \c displacements map and an updated segmentation map \c newSegmentation for
/// \c time. The displacements are normalized (divided by the image size). The displacements are
/// backward: the displacement of a pixel points to the position of the original pixel in the
/// initial image. \c displacements pixel buffer must have 2 channels of half-float type (x and y
/// components). \c newSegmentation pixel buffer must have 1 channel of uchar type. \c displacements
/// and \c newSegmentation must have the same size as the \c segmentation map.
- (void)displacements:(CVPixelBufferRef)displacements
   andNewSegmentation:(CVPixelBufferRef)newSegmentation
              forTime:(NSTimeInterval)time;

/// Segmentation map of the initial image. Must have 1 channel of uchar type. Can have width and
/// height different from that of the current \c segmentation.
@property (nonatomic) lt::Ref<CVPixelBufferRef> segmentation;

@end

NS_ASSUME_NONNULL_END
