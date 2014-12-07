// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Category adding type testing to \c NSValue.
@interface NSValue (Type)

/// Returns \c YES if the type of encoded value is equal to the given Objective-C type of value, as
/// provided by the @encode() compiler directive.
- (BOOL)lt_isKindOfObjCType:(const char *)type;

@end
