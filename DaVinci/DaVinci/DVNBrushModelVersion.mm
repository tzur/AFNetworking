// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelVersion.h"

#import "DVNBrushModel.h"
#import "DVNBrushModelV1.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, DVNBrushModelVersion,
  DVNBrushModelVersionV1
);

@implementation DVNBrushModelVersion (DaVinci)

- (Class)classOfBrushModel {
  switch (self.value) {
    case DVNBrushModelVersionV1:
      return [DVNBrushModelV1 class];
  }
}

@end

NS_ASSUME_NONNULL_END
