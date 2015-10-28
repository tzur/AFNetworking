// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Supporting Files.
#import <LTEngine/LTDefaultModule.h>
#import <LTEngine/LTGLCheck.h>
#import <LTEngine/LTGLKitExtensions.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTEngine/LTOpenCVHalfFloat.h>
#import <LTEngine/LTRotatedRect.h>
#import <LTEngine/LTTypedefs+LTEngine.h>
#import <LTEngine/NSValue+GLKitExtensions.h>
#import <LTEngine/UIColor+Vector.h>

// Base.
#import <LTEngine/LTShaderStorage.h>

// Data Structures.
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTRect.h>
#import <LTEngine/LTVector.h>

// Image Processing/Base.
#import <LTEngine/LTImageProcessor.h>
#import <LTEngine/LTIterativeImageProcessor.h>
#import <LTEngine/LTOneShotImageProcessor.h>
#import <LTEngine/LTPainterImageProcessor.h>
#import <LTEngine/LTPartialProcessing.h>
#import <LTEngine/LTProgressiveImageProcessor.h>
#import <LTEngine/LTScreenProcessing.h>

// Image Processing/Blocks.
#import <LTEngine/LTAdjustProcessor.h>
#import <LTEngine/LTAnalogFilmProcessor.h>
#import <LTEngine/LTArithmeticProcessor.h>
#import <LTEngine/LTAspectFillResizeProcessor.h>
#import <LTEngine/LTBicubicResizeProcessor.h>
#import <LTEngine/LTBilateralFilterProcessor.h>
#import <LTEngine/LTBoxFilterProcessor.h>
#import <LTEngine/LTBWProcessor.h>
#import <LTEngine/LTCircularPatchProcessor.h>
#import <LTEngine/LTClarityProcessor.h>
#import <LTEngine/LTColorConversionProcessor.h>
#import <LTEngine/LTColorGradient.h>
#import <LTEngine/LTCropProcessor.h>
#import <LTEngine/LTDuoProcessor.h>
#import <LTEngine/LTEAWProcessor.h>
#import <LTEngine/LTEdgesMaskProcessor.h>
#import <LTEngine/LTFFTConvolutionProcessor.h>
#import <LTEngine/LTFFTProcessor.h>
#import <LTEngine/LTImageBorderProcessor.h>
#import <LTEngine/LTMaskOverlayProcessor.h>
#import <LTEngine/LTMaskedArithmeticProcessor.h>
#import <LTEngine/LTMixerProcessor.h>
#import <LTEngine/LTPatchProcessor.h>
#import <LTEngine/LTPassthroughProcessor.h>
#import <LTEngine/LTPerspectiveProcessor.h>
#import <LTEngine/LTRectCopyProcessor.h>
#import <LTEngine/LTRecomposeProcessor.h>
#import <LTEngine/LTReshapeProcessor.h>
#import <LTEngine/LTSelectiveAdjustProcessor.h>
#import <LTEngine/LTSplitComplexMat.h>
#import <LTEngine/LTTiltShiftProcessor.h>

// Image Processing/Utils.
#import <LTEngine/LTBoundaryCondition.h>

// Images.
#import <LTEngine/LTImage.h>
#import <LTEngine/LTImage+Texture.h>

// GPU/Base.
#import <LTEngine/LTArrayBuffer.h>
#import <LTEngine/LTDrawingContext.h>
#import <LTEngine/LTFbo.h>
#import <LTEngine/LTGLContext.h>
#import <LTEngine/LTGLException.h>
#import <LTEngine/LTGLTexture.h>
#import <LTEngine/LTGPUResource.h>
#import <LTEngine/LTGPUStruct.h>
#import <LTEngine/LTGPUStructsMacros.h>
#import <LTEngine/LTGPUQueue.h>
#import <LTEngine/LTMMTexture.h>
#import <LTEngine/LTProgram.h>
#import <LTEngine/LTProgramFactory.h>
#import <LTEngine/LTShader.h>
#import <LTEngine/LTTexture.h>
#import <LTEngine/LTTexture+Factory.h>
#import <LTEngine/LTVertexArray.h>

// GPU/Drawers.
#import <LTEngine/LTRectDrawer+PassthroughShader.h>

// GPU/Drawers/Shape Drawer.
#import <LTEngine/LTShapeDrawer.h>

// GPU/Painting.
#import <LTEngine/LTPainter+LTView.h>
#import <LTEngine/LTPainterStroke.h>
#import <LTEngine/LTSingleAirbrushPaintingStrategy.h>
#import <LTEngine/LTSingleBrushPaintingStrategy.h>

// GPU/Painting/Brushes.
#import <LTEngine/LTBristleBrush.h>
#import <LTEngine/LTBrush.h>
#import <LTEngine/LTEdgeAvoidingBrush.h>
#import <LTEngine/LTEdgeAvoidingMultiTextureBrush.h>
#import <LTEngine/LTMultiTextureBrush.h>
#import <LTEngine/LTRoundBrush.h>
#import <LTEngine/LTSingleTextureBrush.h>
#import <LTEngine/LTTextureBrush.h>

// GPU/Painting/Brush Effects.
#import <LTEngine/LTBrushColorDynamicsEffect.h>
#import <LTEngine/LTBrushScatterEffect.h>
#import <LTEngine/LTBrushShapeDynamicsEffect.h>

// GPU/Painting/Interpolants.
#import <LTEngine/LTCatmullRomInterpolant.h>
#import <LTEngine/LTLinearInterpolationRoutine.h>

// UI.
#import <LTEngine/LTView.h>

// LTEngineBundle.
#import <LTEngine/NSBundle+LTEngineBundle.h>
