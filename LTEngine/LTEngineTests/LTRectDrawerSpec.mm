// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectDrawer.h"

#import "LTMultiRectDrawerSpec.h"
#import "LTSingleRectDrawerSpec.h"
#import "LTTextureDrawerExamples.h"

SpecBegin(LTRectDrawer)

itShouldBehaveLike(kLTTextureDrawerExamples,
                   @{kLTTextureDrawerClass: [LTRectDrawer class]});

itShouldBehaveLike(kLTSingleRectDrawerExamples,
                   @{kLTSingleRectDrawerClass: [LTRectDrawer class]});

itShouldBehaveLike(kLTMultiRectDrawerExamples,
                   @{kLTMultiRectDrawerClass: [LTRectDrawer class]});

SpecEnd
