// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>

#ifdef __cplusplus

#import <vector>

#pragma mark -
#pragma mark CoreGraphics
#pragma mark -

/// A collection of CGPoints.
typedef std::vector<CGPoint> CGPoints;

#pragma mark -
#pragma mark GLKit
#pragma mark -

/// A collection of GLKVector2.
typedef std::vector<GLKVector2> GLKVector2s;
/// A collection of GLKVector3.
typedef std::vector<GLKVector3> GLKVector3s;
/// A collection of GLKVector4.
typedef std::vector<GLKVector4> GLKVector4s;

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
