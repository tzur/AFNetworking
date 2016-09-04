// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentFetcherParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRContentFetcherParameters

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
  LTParameterAssert(JSONDictionary[@"type"], @"The JSON field named 'type' is missing, so the class"
                    " of the content fetcher couldn't be determined.");
  Class contentFetcherParametersClass = NSClassFromString(JSONDictionary[@"type"]);
  LTParameterAssert([contentFetcherParametersClass isSubclassOfClass:self], @"The JSON field named"
                    " 'type' must specify a name of a subclass of %@, got: %@", self,
                    JSONDictionary[@"type"]);

  return contentFetcherParametersClass;
}

@end

NS_ASSUME_NONNULL_END
