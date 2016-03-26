// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTEasyBoxing.h>

#import "NSValue+GLKitExtensions.h"
#import "NSValue+LTVector.h"
#import "NSValue+LTRect.h"

#ifdef __cplusplus

/// NSValue+GLKitExtensions.
LTMakeEasyBoxing(GLKVector2);
LTMakeEasyBoxing(GLKVector3);
LTMakeEasyBoxing(GLKVector4);
LTMakeEasyBoxing(GLKMatrix2);
LTMakeEasyBoxing(GLKMatrix3);
LTMakeEasyBoxing(GLKMatrix4);

/// NSValue+LTVector.
LTMakeEasyBoxing(LTVector2);
LTMakeEasyBoxing(LTVector3);
LTMakeEasyBoxing(LTVector4);

/// NSValue+LTRect.
LTMakeEasyBoxing(LTRect);

#endif
