// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import <Foundation/Foundation.h>

@interface LTDevice : NSObject

// The current device the app is running on.
+ (LTDevice *)currentDevice;

// Maximal texture size that can be used on the device's GPU.
@property (readonly, nonatomic) NSUInteger maxTextureSize;

// YES if writing to textures with half-float precision is supported.
@property (readonly, nonatomic) BOOL canUseHalfFloatTextures;

// YES if writing to textures with half-float precision is supported.
@property (readonly, nonatomic) BOOL canRenderToHalfFloatTextures;

@end
