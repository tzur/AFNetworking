// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

@interface LTMMTexture : LTTexture

typedef void (^LTTextureUpdateBlock)(cv::Mat texture);

- (void)updateTexture:(LTTextureUpdateBlock)block;

@end
