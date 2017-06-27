// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Represents a Taplytics configuration.
///
/// Impersonates the undocumented \c TLProperties class. The implementation for this object is in
/// the Taplytics SDK framework. No \c @implementation block should be created to this class.
@interface TLProperties : NSObject

/// Name of the application in Taplytics' system.
@property (readonly, nonatomic) NSString *appName;

/// Maps dynamic variable keys to information about the value.
@property (readonly, nonatomic, nullable)
    NSDictionary<NSString *, NSDictionary *> *dynamicVariables;

/// Contains information about all the experiments and their possible variations.
@property (readonly, nonatomic) NSArray<NSDictionary *> *experiments;

/// Contains information on the active experiments and their selected variations.
@property (readonly, nonatomic) NSArray<NSDictionary *> *experimentAndVariationNames;

/// Current session ID.
@property (readonly, nonatomic, nullable) NSString *sessionID;

@end

NS_ASSUME_NONNULL_END
