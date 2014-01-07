// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

/// @class LTOneShotImageProcessor
///
/// Processes a single image input with a single processing iteration, and returns a single output.
@interface LTOneShotImageProcessor : LTIterativeImageProcessor

/// Generates a new output based on the current image processor inputs. This method blocks until a
/// result is available.
- (LTSingleTextureOutput *)process;

@end
