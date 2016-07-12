// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "CALayer+Enumeration.h"

SpecBegin(CALayer_Enumeration)

it(@"should correctly execute the given block for each layer", ^{
  CALayer *layer = [CALayer layer];
  CALayer *leaf0 = [CALayer layer];
  CALayer *leaf1 = [CALayer layer];
  CALayer *leaf2 = [CALayer layer];
  CALayer *leaf3 = [CALayer layer];
  CALayer *leaf4 = [CALayer layer];
  [layer addSublayer:leaf1];
  [layer addSublayer:leaf0];
  [leaf0 addSublayer:leaf2];
  [leaf0 addSublayer:leaf3];
  [leaf2 addSublayer:leaf4];
  
  NSArray<CALayer *> *layers = @[layer, leaf0, leaf1, leaf2, leaf3, leaf4];
  __block NSMutableArray<CALayer *> *touchedLayers = [[NSMutableArray alloc] init];
  [layer wf_enumerateLayersUsingBlock:^(CALayer *layer){
    [touchedLayers addObject:layer];
  }];
  expect(layers.count).to.equal(touchedLayers.count);
  expect([NSSet setWithArray:touchedLayers]).to.equal([NSSet setWithArray:layers]);
});

it(@"should correctly execute the given block on a single layer", ^{
  CALayer *layer = [CALayer layer];
  __block NSMutableArray<CALayer *> *touchedLayers = [[NSMutableArray alloc] init];
  [layer wf_enumerateLayersUsingBlock:^(CALayer *layer){
    [touchedLayers addObject:layer];
  }];
  expect(touchedLayers).to.equal(@[layer]);
});

SpecEnd
