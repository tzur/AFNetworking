// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKCollectionUtils.h"

NS_ASSUME_NONNULL_BEGIN

void PNKValidateCollection(NSDictionary *collection, NSArray<NSString *> *names,
                           NSString *designation) {
  LTParameterAssert(collection.count == names.count, @"%@ collection must have size of %lu, got "
                    "%lu", designation, (unsigned long)names.count,
                    (unsigned long)collection.count);
  for (NSString *name in names) {
    LTParameterAssert([collection objectForKey:name], @"entry with name %@ not found in %@ "
                      "collection", name, designation);
  }
}

NS_ASSUME_NONNULL_END
