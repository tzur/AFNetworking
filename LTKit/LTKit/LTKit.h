// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTAssert.h>

// Supporting Files.
#import <LTKit/LTCGExtensions.h>
#import <LTKit/LTDefaultModule.h>
#import <LTKit/LTEasyBoxing.h>
#import <LTKit/LTGLKitExtensions.h>
#import <LTKit/LTGLUtils.h>
#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/LTLogger.h>
#import <LTKit/LTLoggerMacrosImpl.h>
#import <LTKit/LTOpenCVExtensions.h>
#import <LTKit/LTOpenCVHalfFloat.h>
#import <LTKit/LTRandom.h>
#import <LTKit/LTRotatedRect.h>
#import <LTKit/LTTimer.h>
#import <LTKit/LTTypedefs.h>
#import <LTKit/NSNumber+CGFloat.h>
#import <LTKit/NSString+Hashing.h>
#import <LTKit/NSValue+GLKitExtensions.h>
#import <LTKit/UIColor+Vector.h>

// Base.
#import <LTKit/LTDevice.h>
#import <LTKit/LTEnum.h>
#import <LTKit/LTEnumRegistry.h>
#import <LTKit/LTShaderStorage.h>

// Data Structures.
#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTRect.h>
#import <LTKit/LTVector.h>

// Image Processing/Base.
#import <LTKit/LTImageProcessor.h>
#import <LTKit/LTIterativeImageProcessor.h>
#import <LTKit/LTOneShotImageProcessor.h>
#import <LTKit/LTPainterImageProcessor.h>
#import <LTKit/LTPartialProcessing.h>
#import <LTKit/LTProgressiveImageProcessor.h>
#import <LTKit/LTScreenProcessing.h>

// Image Processing/Blocks.
#import <LTKit/LTAdjustProcessor.h>
#import <LTKit/LTAnalogFilmProcessor.h>
#import <LTKit/LTArithmeticProcessor.h>
#import <LTKit/LTBilateralFilterProcessor.h>
#import <LTKit/LTBoxFilterProcessor.h>
#import <LTKit/LTBWProcessor.h>
#import <LTKit/LTClarityProcessor.h>
#import <LTKit/LTColorConversionProcessor.h>
#import <LTKit/LTColorGradient.h>
#import <LTKit/LTCropProcessor.h>
#import <LTKit/LTDuoProcessor.h>
#import <LTKit/LTEAWProcessor.h>
#import <LTKit/LTEdgesMaskProcessor.h>
#import <LTKit/LTFFTConvolutionProcessor.h>
#import <LTKit/LTFFTProcessor.h>
#import <LTKit/LTImageBorderProcessor.h>
#import <LTKit/LTImageFrameProcessor.h>
#import <LTKit/LTMaskOverlayProcessor.h>
#import <LTKit/LTMaskedArithmeticProcessor.h>
#import <LTKit/LTMixerProcessor.h>
#import <LTKit/LTPatchProcessor.h>
#import <LTKit/LTPassthroughProcessor.h>
#import <LTKit/LTPerspectiveProcessor.h>
#import <LTKit/LTRectCopyProcessor.h>
#import <LTKit/LTRecomposeProcessor.h>
#import <LTKit/LTReshapeProcessor.h>
#import <LTKit/LTSelectiveAdjustProcessor.h>
#import <LTKit/LTSplitComplexMat.h>
#import <LTKit/LTTiltShiftProcessor.h>

// Image Processing/Utils.
#import <LTKit/LTBoundaryCondition.h>

// Images.
#import <LTKit/LTImage.h>
#import <LTKit/LTImage+Texture.h>

// IO.
#import <LTKit/LTFileManager.h>
#import <LTKit/LTImageLoader.h>

// GPU/Base.
#import <LTKit/LTArrayBuffer.h>
#import <LTKit/LTDrawingContext.h>
#import <LTKit/LTFbo.h>
#import <LTKit/LTGLContext.h>
#import <LTKit/LTGLException.h>
#import <LTKit/LTGLTexture.h>
#import <LTKit/LTGPUResource.h>
#import <LTKit/LTGPUStruct.h>
#import <LTKit/LTGPUStructsMacros.h>
#import <LTKit/LTGPUQueue.h>
#import <LTKit/LTMMTexture.h>
#import <LTKit/LTProgram.h>
#import <LTKit/LTProgramFactory.h>
#import <LTKit/LTShader.h>
#import <LTKit/LTTexture.h>
#import <LTKit/LTTexture+Factory.h>
#import <LTKit/LTVertexArray.h>

// GPU/Drawers.
#import <LTKit/LTRectDrawer+PassthroughShader.h>

// GPU/Drawers/Shape Drawer.
#import <LTKit/LTShapeDrawer.h>

// GPU/Painting.
#import <LTKit/LTPainter+LTView.h>
#import <LTKit/LTPainterStroke.h>
#import <LTKit/LTSingleAirbrushPaintingStrategy.h>
#import <LTKit/LTSingleBrushPaintingStrategy.h>

// GPU/Painting/Brushes.
#import <LTKit/LTBristleBrush.h>
#import <LTKit/LTBrush.h>
#import <LTKit/LTEdgeAvoidingBrush.h>
#import <LTKit/LTEdgeAvoidingMultiTextureBrush.h>
#import <LTKit/LTMultiTextureBrush.h>
#import <LTKit/LTRoundBrush.h>
#import <LTKit/LTSingleTextureBrush.h>
#import <LTKit/LTTextureBrush.h>

// GPU/Painting/Brush Effects.
#import <LTKit/LTBrushColorDynamicsEffect.h>
#import <LTKit/LTBrushScatterEffect.h>
#import <LTkit/LTBrushShapeDynamicsEffect.h>

// GPU/Painting/Interpolation Routines.
#import <LTKit/LTCatmullRomInterpolationRoutine.h>
#import <LTKit/LTLinearInterpolationRoutine.h>

// UI.
#import <LTkit/LTAnimation.h>
#import <LTKit/LTView.h>

// LTKitBundle.
#import <LTKitBundle/NSBundle+LTKitBundle.h>
