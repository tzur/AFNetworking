// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentProviderParameters.h"

NS_ASSUME_NONNULL_BEGIN

/// Parameters for \c BZRProductContentMultiProvider containing information information of which
/// underlying content provider to use and its parameters.
@interface BZRProductContentMultiProviderParameters : BZRContentProviderParameters

/// Key to an entry of a content provider in the collection of content providers of
/// \c BZRProductContentMultiProvider class.
@property (readonly, nonatomic) NSString *contentProviderName;

/// Parameters needed for the contentProvider specified by \c contentProviderName. Must be of the
/// correct type as expected by the provider specified by \c contentProviderName.
@property (readonly, nonatomic, nullable) BZRContentProviderParameters *
    parametersForContentProvider;

@end

NS_ASSUME_NONNULL_END
