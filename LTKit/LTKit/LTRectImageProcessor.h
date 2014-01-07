// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTProgram, LTRectDrawer;

/// @class LTRectImageProcessor
///
/// Abstract class for image processor based on \c LTRectDrawer. This object is responsible for
/// transferring the model values from the processor to the drawer prior to the actual processing.
/// Subclasses should override the \c drawToOutput method and implement the actual processing code
/// there.
@interface LTRectImageProcessor : LTImageProcessor

/// Initializes with the program and arrays of input and output textures.
///
/// @param program the program used to process the input textures.
/// @param inputs array of \c LTTexture objects, which correspond to the input images to process.
/// @param output array of \c LTTexture objects, which correspond to the output images to produce.
- (instancetype)initWithProgram:(LTProgram *)program inputs:(NSArray *)inputs
                        outputs:(NSArray *)outputs;

/// Generates a new output based on the current image processor inputs. This method blocks until a
/// result is available.
///
/// @return textures returned from \c drawToOutput.
- (LTMultipleTextureOutput *)process;

/// Uses \c rectDrawer to execute processing on the input. This is done after proper configuration
/// of the \c rectDrawer to include all the processor's model values.
///
/// @return array containing the output \c LTTexture objects. Subclasses are responsible for
/// defining a concrete order for the textures inside the array.
///
/// @note this method is abstract and should be overridden by subclasses.
- (NSArray *)drawToOutput;

/// Rect drawer used to process the texture.
@property (readonly, nonatomic) LTRectDrawer *rectDrawer;

@end

@interface LTRectImageProcessor (ForTesting)

/// Initializes with the program and arrays of input and output textures.
///
/// @param rectDrawer rect drawer used for processing.
/// @param inputs array of \c LTTexture objects, which correspond to the input images to process.
/// @param output array of \c LTTexture objects, which correspond to the output images to produce.
- (instancetype)initWithRectDrawer:(LTRectDrawer *)rectDrawer inputs:(NSArray *)inputs
                           outputs:(NSArray *)outputs;

@end
