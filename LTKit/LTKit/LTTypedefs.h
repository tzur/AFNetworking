// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>

#ifdef __cplusplus

#import <opencv2/core/core.hpp>
#import <vector>

#import "LTVector.h"

#pragma mark -
#pragma mark CoreGraphics
#pragma mark -

/// A collection oc \c CGFloat.
typedef std::vector<CGFloat> CGFloats;

/// A collection of \c CGPoint.
typedef std::vector<CGPoint> CGPoints;

/// A collection of \c CGSize.
typedef std::vector<CGSize> CGSizes;

#pragma mark -
#pragma mark GLKit
#pragma mark -

/// A collection of \c LTVector2.
typedef std::vector<LTVector2> LTVector2s;
/// A collection of \c GLKVector3.
typedef std::vector<GLKVector3> GLKVector3s;
/// A collection of \c GLKVector4.
typedef std::vector<GLKVector4> GLKVector4s;

#pragma mark -
#pragma mark LTVector
#pragma mark -

/// A collection of \c LTVector2.
typedef std::vector<LTVector2> LTVector2s;
/// A collection of \c LTVector3.
typedef std::vector<LTVector3> LTVector3s;
/// A collection of \c LTVector4.
typedef std::vector<LTVector4> LTVector4s;

#pragma mark -
#pragma mark OpenCV
#pragma mark -

/// A collection of \c cv::Mat.
typedef std::vector<cv::Mat> Matrices;

#endif

/// Various typedefs that are applicable across LTKit.

#pragma mark -
#pragma mark LTKit
#pragma mark -

/// Void block.
typedef void (^LTVoidBlock)();

/// Block used as a completion handler.
typedef LTVoidBlock LTCompletionBlock;

/// Block used as a completion handler with a boolean \c finished parameter.
typedef void (^LTBoolCompletionBlock)(BOOL finished);

/// Block used as a failure handler with an NSError describing the reason for failure.
typedef void (^LTFailureBlock)(NSError *error);

/// Block to indicate success or failure. If success is \c YES, error is \c nil. If success is \c
/// NO, error will contain an appropriate error description.
typedef void (^LTSuccessOrErrorBlock)(BOOL success, NSError *error);
