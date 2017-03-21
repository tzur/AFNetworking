// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUArrayChangesetProvider.h"

#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUArrayChangesetProvider ()

/// Array of \c PTNDescriptor objects used to create the changeset returned by \c fetchChangest.
@property (readonly, nonatomic) NSArray<id<PTNDescriptor>> *descriptors;

/// Title for the changeset metadata returned by this provider.
@property (readonly, nonatomic, nullable) NSString *changesetTitle;

@end

@implementation PTUArrayChangesetProvider

- (instancetype)initWithDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                     changesetTitle:(nullable NSString *)changesetTitle {
  LTParameterAssert(descriptors, @"Descriptor array cannot be nil");
  if (self = [super init]) {
    _descriptors = descriptors;
    _changesetTitle = changesetTitle;
  }
  return self;
}

- (RACSignal *)fetchChangeset {
  return [RACSignal return:[[PTUChangeset alloc] initWithAfterDataModel:@[self.descriptors]]];
}

- (RACSignal *)fetchChangesetMetadata {
  return [RACSignal return:[[PTUChangesetMetadata alloc] initWithTitle:self.changesetTitle
                                                         sectionTitles:@{}]];
}

@end

NS_ASSUME_NONNULL_END
