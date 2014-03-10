// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <opencv2/core/core.hpp>

@class LTSplitComplexMat, LTTexture;

/// Protocol for tagging classes which contain output of \c LTImageProcessor classes.
@protocol LTImageProcessorOutput <NSObject>
@end

/// DTO for output containing a single texture.
@interface LTSingleTextureOutput : NSObject <LTImageProcessorOutput>

/// Initializes with a single texture.
- (instancetype)initWithTexture:(LTTexture *)texture;

/// Output texture.
@property (readonly, nonatomic) LTTexture *texture;

@end

/// DTO for output containing multiple textures.
@interface LTMultipleTextureOutput : NSObject <LTImageProcessorOutput>

/// Initializes with an array of textures.
- (instancetype)initWithTextures:(NSArray *)textures;

/// Output textures.
@property (readonly, nonatomic) NSArray *textures;

@end

/// DTO for output containing a single cv::Mat.
@interface LTSingleMatOutput : NSObject <LTImageProcessorOutput>

/// Initializes with a mat.
- (instancetype)initWithMat:(const cv::Mat &)mat;

/// Output mat.
@property (readonly, nonatomic) const cv::Mat &mat;

@end

/// DTO for holding a split complex mat output.
@interface LTSplitComplexMatOutput : NSObject <LTImageProcessorOutput>

/// Initializes with a split complex mat.
- (instancetype)initWithSplitComplexMat:(LTSplitComplexMat *)splitComplexMat;

/// Output texture.
@property (readonly, nonatomic) LTSplitComplexMat *splitComplexMat;

@end
