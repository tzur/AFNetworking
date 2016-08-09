// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentProviderParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRContentProviderParameters

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
  LTParameterAssert(JSONDictionary[@"type"], @"The JSON field named 'type' is missing, so the class"
                    " of the content provider couldn't be determined.");
  Class contentProviderParametersClass = NSClassFromString(JSONDictionary[@"type"]);
  LTParameterAssert([contentProviderParametersClass isSubclassOfClass:self], @"The JSON field named"
                    " 'type' must specify a name of a subclass of %@, got: %@", self,
                    JSONDictionary[@"type"]);

  return contentProviderParametersClass;
}

@end

NS_ASSUME_NONNULL_END
