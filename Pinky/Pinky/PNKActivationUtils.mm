// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKActivationUtils.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

std::pair<BOOL, BOOL> PNKActivationNeedsAlphaBetaParameters(pnk::ActivationType activationType) {
  switch (activationType) {
    case pnk::ActivationTypeIdentity:
    case pnk::ActivationTypeAbsolute:
    case pnk::ActivationTypeReLU:
    case pnk::ActivationTypeTanh:
    case pnk::ActivationTypeSigmoid:
    case pnk::ActivationTypeSoftsign:
    case pnk::ActivationTypeSoftplus:
      return {NO, NO};
    case pnk::ActivationTypeLeakyReLU:
    case pnk::ActivationTypePReLU:
    case pnk::ActivationTypeELU:
      return {YES, NO};
    case pnk::ActivationTypeScaledTanh:
    case pnk::ActivationTypeSigmoidHard:
    case pnk::ActivationTypeLinear:
    case pnk::ActivationTypeParametricSoftplus:
      return {YES, YES};
  }
}

#endif

NS_ASSUME_NONNULL_END
