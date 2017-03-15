// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@class INTEventMetadata;

/// Context of a specific application run or part of it, defined as an application usage segment.
/// Data in the context uniquely identifies a segment. The keys in the dictionary are defined by the
/// client application and can be arbitrary, supporting the client application's specific event
/// aggregation logic.
///
/// Examples of values that may define a run segment:
///
/// - ID defining a specific instance of the app.
///
/// - Current screen name, screen usage ID or both.
///
/// - Currently open project.
typedef NSDictionary<NSString *, id> INTAppContext;

/// Block defining an aggregation over a \c context, \c eventMetadata and \c event, producing
/// an updated context. The block must be a pure function without side effects.
typedef INTAppContext * _Nonnull(^INTAppContextGeneratorBlock)
    (INTAppContext *context, INTEventMetadata *eventMetadata, id event);

/// Returns a \c INTContextGeneratorBlock which always returns the given \c context argument.
INTAppContextGeneratorBlock INTIdentityAppContextGenerator();

/// Returns a composed context generator from \c generators. The resulting context generator has a
/// return value that is a result of consecutive block invocations, where the \c context argument is
/// the returned value of the block before it in \c generators, with the first block in
/// \c generators being invoked with the original \c context argument. \c eventMetadata and \c event
/// arguments of each block are the original arguments given to the returned block. Empty
/// \c generators results in an identity context generator.
INTAppContextGeneratorBlock INTComposeAppContextGenerators(NSArray<INTAppContextGeneratorBlock>
                                                           *generators);

NS_ASSUME_NONNULL_END
