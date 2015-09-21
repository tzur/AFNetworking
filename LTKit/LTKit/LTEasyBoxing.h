// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Shorthand for boxing common structs with \c NSValue. To use, wrap the struct variable with \c
/// $(), instead of calling:
///
/// @code
/// NSValue *myValue = [NSValue valueWithStructName:value];
/// @endcode

#ifdef __cplusplus

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

#endif
