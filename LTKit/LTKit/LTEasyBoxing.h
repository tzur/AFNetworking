// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValue+GLKitExtensions.h"

/// Shorthand for boxing common structs with \c NSValue. To use, wrap the struct variable with \c
/// $(), instead of calling:
///
/// @code
/// NSValue *myValue = [NSValue valueWithStructName:value];
/// @endcode

#define LTMakeEasyBoxing(STRUCT_NAME) \
  NS_INLINE NSValue *$(const STRUCT_NAME &value) { \
    return [NSValue valueWith##STRUCT_NAME:value]; \
  }

/// NSValue+NSValueUIGeometryExtensions.
LTMakeEasyBoxing(CGAffineTransform);
LTMakeEasyBoxing(CGPoint);
LTMakeEasyBoxing(CGRect);
LTMakeEasyBoxing(CGSize);
LTMakeEasyBoxing(UIOffset);
LTMakeEasyBoxing(UIEdgeInsets);

/// NSValue+CAAdditions.
LTMakeEasyBoxing(CATransform3D);

/// NSValue+GLKitExtensions.
LTMakeEasyBoxing(GLKVector2);
LTMakeEasyBoxing(GLKVector3);
LTMakeEasyBoxing(GLKVector4);
LTMakeEasyBoxing(GLKMatrix2);
LTMakeEasyBoxing(GLKMatrix3);
LTMakeEasyBoxing(GLKMatrix4);

#undef LTMakeEasyBoxing
