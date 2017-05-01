// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDataStructures.h"
#import "INTEventMetadata.h"
#import "INTEventTransformer.h"

NS_ASSUME_NONNULL_BEGIN

/// Parameters for a single invocation of
/// <tt>-[INTEventTransformer processEvent:withMetadata:context:completion]</tt>.
@interface INTEventTransformerArguments : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given parameters.
- (instancetype)initWithEvent:(id)event metadata:(INTEventMetadata *)metadata
                      context:(INTAppContext *)context NS_DESIGNATED_INITIALIZER;

/// Event.
@property (readonly, nonatomic) id event;

/// Metadata
@property (readonly, nonatomic) INTEventMetadata *metadata;

/// App context.
@property (readonly, nonatomic) INTAppContext *context;

@end

/// Returns an \c INTEventTransformerArguments with \c event, \c metadata, \c context. if \c context
/// is \c nil, and empty dictionary is used.
INTEventTransformerArguments *INTEventTransformerArgs(id event, INTEventMetadata *metadata,
                                                      INTAppContext * _Nullable context = nil);

/// Executor of an \c INTTransformerBlock over a sequence of inputs.
@interface INTEventTransformationExecutor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c transformerBlock.
- (instancetype)initWithTransformerBlock:(INTTransformerBlock)transformerBlock
    NS_DESIGNATED_INITIALIZER;

/// Transforms the \c eventSequence, starting with a clean transformation state. Returns the
/// resulting events.
- (NSArray *)transformEventSequence:(NSArray<INTEventTransformerArguments *> *)eventSequence;

@end

NS_ASSUME_NONNULL_END
