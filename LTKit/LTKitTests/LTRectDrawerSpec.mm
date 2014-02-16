// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectDrawer.h"

#import "LTMultiRectDrawerSpec.h"
#import "LTProcessingDrawerExamples.h"
#import "LTSingleRectDrawerSpec.h"

SpecBegin(LTRectDrawer)

itShouldBehaveLike(kLTProcessingDrawerExamples,
                   @{kLTProcessingDrawerClass: [LTRectDrawer class]});

itShouldBehaveLike(kLTSingleRectDrawerExamples,
                   @{kLTSingleRectDrawerClass: [LTRectDrawer class]});

itShouldBehaveLike(kLTMultiRectDrawerExamples,
                   @{kLTMultiRectDrawerClass: [LTRectDrawer class]});

SpecEnd
