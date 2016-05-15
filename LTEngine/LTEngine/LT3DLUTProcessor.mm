// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUTProcessor.h"

#import "LT3DLUT.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LT3DLUTFsh.h"
#import "LTShaderStorage+LTPassThroughShaderVsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LT3DLUTProcessor ()

/// Texture that holds a representation of the 3D LUT.
@property (strong, nonatomic) LTTexture *lutTexture;

@end

#pragma mark -
#pragma mark Initialization
#pragma mark -

@implementation LT3DLUTProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LT3DLUTFsh source] input:input andOutput:output]) {
    self.lookupTable = [LT3DLUT identity];
  }
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setLookupTable:(LT3DLUT *)lookupTable {
  _lookupTable = lookupTable;
  
  self.lutTexture = [LTTexture textureWithImage:lookupTable.packedMat];
  self[[LT3DLUTFsh rgbDimensionSizes]] = $(LTVector3(lookupTable.latticeSize.rDimensionSize,
                                                     lookupTable.latticeSize.gDimensionSize,
                                                     lookupTable.latticeSize.bDimensionSize));
}

- (void)setLutTexture:(LTTexture *)lutTexture {
  LTParameterAssert(lutTexture.size.width > 0 && lutTexture.size.height > 0, @"lutTexture must "
                    "have positive dimensions");
  _lutTexture = lutTexture;
  [self setAuxiliaryTexture:lutTexture withName:[LT3DLUTFsh lutTexture]];
}

@end

NS_ASSUME_NONNULL_END
