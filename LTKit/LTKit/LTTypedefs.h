// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>

#ifdef __cplusplus

#import <array>
#import <vector>

#pragma mark -
#pragma mark CoreGraphics
#pragma mark -

/// A collection oc \c CGFloat.
typedef std::vector<CGFloat> CGFloats;

/// A collection of \c CGPoint.
typedef std::vector<CGPoint> CGPoints;

/// A collection of \c CGSize.
typedef std::vector<CGSize> CGSizes;

/// A collection of \c CGRect.
typedef std::vector<CGRect> CGRects;

#pragma mark -
#pragma mark Scalar
#pragma mark -

/// A collection of \c GLuint.
typedef std::vector<GLuint> GLuints;

#endif

NS_ASSUME_NONNULL_BEGIN

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
typedef void (^LTFailureBlock)(NSError * _Nonnull error);

/// Block to indicate success or failure. If success is \c YES, error is \c nil. If success is \c
/// NO, error will contain an appropriate error description.
typedef void (^LTSuccessOrErrorBlock)(BOOL success, NSError * _Nullable error);

NS_ASSUME_NONNULL_END
