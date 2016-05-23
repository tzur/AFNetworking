// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTHashExtensions.h"

#ifdef __cplusplus

// Adds \c lt::unordered_map, which backs \c std::unordered_map but supports Objective-C objects as
// keys. To use an \c unordered_map, one must first create an \c std::hash specialization for that
// specific class using \c LTObjectiveCHashMake.

namespace lt {
  /// Equality functor for Objective-C objects.
  struct objc_equal_to {
    inline bool operator()(id lhs, id rhs) const {
      return lhs == rhs || [lhs isEqual:rhs];
    }
  };
  
  template<typename Key, typename T>
  using unordered_map = std::unordered_map<Key, T, std::hash<Key>, lt::objc_equal_to>;
}

#endif
