// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsArchiver.h"

NSSet *LTTextureContentsArchivers() {
  __block NSSet *classSet;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableSet *mutableClassSet = [NSMutableSet set];

    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
      Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
      numClasses = objc_getClassList(classes, numClasses);
      for (int i = 0; i < numClasses; ++i) {
        Class nextClass = classes[i];
        if (class_conformsToProtocol(nextClass, @protocol(LTTextureContentsArchiver))) {
          [mutableClassSet addObject:NSClassFromString(NSStringFromClass(classes[i]))];
        }
      }
      free(classes);
    }

    classSet = [mutableClassSet copy];
  });

  return classSet;
}
