// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSString+UTI.h"

#import <LTKit/LTUTICache.h>
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (UTI)

- (BOOL)ptn_isRawImageUTI {
  return [LTUTICache.sharedCache isUTI:self conformsTo:(NSString *)kUTTypeRawImage];
}

- (BOOL)ptn_isGIFUTI {
  return [LTUTICache.sharedCache isUTI:self conformsTo:(NSString *)kUTTypeGIF];
}

@end

NS_ASSUME_NONNULL_END
