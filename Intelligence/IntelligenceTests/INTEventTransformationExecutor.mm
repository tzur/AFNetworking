// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventTransformationExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTEventTransformerArguments

- (instancetype)initWithEvent:(id)event metadata:(INTEventMetadata *)metadata
                      context:(INTAppContext *)context {
  if (self = [super init]) {
    _event = event;
    _metadata = metadata;
    _context = context;
  }
  return self;
}

@end

INTEventTransformerArguments *INTEventTransformerArgs(id event, INTEventMetadata *metadata,
                                                      INTAppContext * _Nullable context) {
  return [[INTEventTransformerArguments alloc] initWithEvent:event metadata:metadata
                                                     context:context ?: @{}];
}

@interface INTEventTransformationExecutor ()

/// Transformer block used for event transformation.
@property (readonly, nonatomic) INTTransformerBlock transformerBlock;

@end

@implementation INTEventTransformationExecutor

- (instancetype)initWithTransformerBlock:(INTTransformerBlock)transformerBlock {
  if (self = [super init]) {
    _transformerBlock = transformerBlock;
  }
  return self;
}

- (NSArray *)transformEventSequence:(NSArray<INTEventTransformerArguments *> *)eventSequence {
  auto eventTransformer =
      [[INTEventTransformer alloc] initWithTransformerBlocks:{self.transformerBlock}];

  auto transformedEvents = [NSMutableArray array];
  for (INTEventTransformerArguments *arguments in eventSequence) {
    auto events = [eventTransformer processEvent:arguments.event metadata:arguments.metadata
                                      appContext:arguments.context];
    [transformedEvents addObjectsFromArray:events];
  }

  return [transformedEvents copy];
}

@end

NS_ASSUME_NONNULL_END
