// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDataStructures.h"

NS_ASSUME_NONNULL_BEGIN

INTAppContextGeneratorBlock INTIdentityAppContextGenerator() {
  return ^INTAppContext *(INTAppContext *context, INTEventMetadata *, id) {
    return context;
  };
}

INTAppContextGeneratorBlock INTComposeAppContextGenerators(NSArray<INTAppContextGeneratorBlock>
                                                           *generators) {
  if (!generators.count) {
    return INTIdentityAppContextGenerator();
  }

  INTAppContextGeneratorBlock result = generators.firstObject;

  for (NSUInteger i = 1; i < generators.count; ++i) {
    result = ^(INTAppContext *context, INTEventMetadata *eventMetadata, id event) {
      return generators[i](result(context, eventMetadata, event), eventMetadata, event);
    };
  }

  return result;
}

NS_ASSUME_NONNULL_END
