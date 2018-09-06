// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Class for fusing the displacement maps of individual layers into a composite displacements map.
/// Also creates the modified segmentation map as it will look like after applying the relevant
/// displacements.
API_AVAILABLE(ios(10.0))
@interface PNKImageMotionLayerFusion : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c device used to run this operation.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Uses the original segmentation map and displacement maps of individual layers to produce an
/// updated segmentation map and a composite displacements map.
///
/// @param commandBuffer command buffer to encode the operation.
///
/// @param inputSegmentationImage segmentation map of the original image. Must have 1 channel. Each
/// pixel must contain the index of the pixel's layer as defined by \c pnk::ImageMotionLayerType
/// enumeration.
///
/// @param inputDisplacementImages array of displacement maps of individual layers. The displacement
/// maps must be ordered as in the \c pnk::ImageMotionLayerType enumeration: the first map is for
/// water layer, the second for grass etc. There should be exactly
/// <tt>pnk::ImageMotionLayerTypeMax - 1</tt>displacement maps. Each map in the array must have 2
/// channels (for X and Y displacements) and width and height matching \c inputSegmentationImage.
///
/// @param outputSegmentationImage the new segmentation map obtained after applying the
/// displacements described by \c inputDisplacementImages to the \c inputSegmentationImage. Must
/// have 1 channel and width and height matching \c inputSegmentationImage.
///
/// @param outputDisplacementImage the fused displacement map. Must have 2 channels (for X and Y
/// displacements) and width and height matching \c inputSegmentationImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
       inputSegmentationImage:(MPSImage *)inputSegmentationImage
      inputDisplacementImages:(NSArray<MPSImage *> *)inputDisplacementImages
      outputSegmentationImage:(MPSImage *)outputSegmentationImage
      outputDisplacementImage:(MPSImage *)outputDisplacementImage;

@end

NS_ASSUME_NONNULL_END
