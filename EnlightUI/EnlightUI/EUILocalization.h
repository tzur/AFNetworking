// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/LTLocalizationTable.h>

NS_ASSUME_NONNULL_BEGIN

/// Name of the default localization table.
extern NSString * const kEUIDefaultLocalizationTableName;

/// Class that provides localization services.
@interface EUILocalization : NSObject

/// Mapping between localization table name and the table for accessing the localized strings.
+ (NSDictionary<NSString *, LTLocalizationTable *> *)tablesMap;

@end

/// Returns localized \c key string from the table with the given \c tableName. \c key is returned
/// if no such key exists in \c tableName or if \c tableName does not exist.
static inline NSString *EUILocalizeWithTable(NSString *tableName, NSString *key)
LT_RETURNS_LOCALIZED_STRING {
  LTLocalizationTable * _Nullable table = [EUILocalization tablesMap][tableName];
  return table ? table[key] : key;
}

namespace eui {
  /// Returns localized \c key string from the default table. \c key is returned if no such key
  /// exists in the default table or if the default table does not exist. \c comment is used only by
  /// external tools that extract the strings needed to be localized.
  ///
  /// @important \c key must be a literal string and not \c NSString object.
  ///
  /// @code
  /// _LDefault(@"String to localize", @"some context to help localize this string");
  /// @endcode
  static inline NSString *_LDefault(NSString *key, NSString __unused *comment) {
    return EUILocalizeWithTable(kEUIDefaultLocalizationTableName, key);
  }

  /// Returns localized \c key for strings containing plurals, like "%d persons" from the default
  /// table. \c key is returned if no such key exists in the default table or if the default table
  /// does not exist. \c comment is used only by external tools that extract the strings needed to
  /// be localized.
  ///
  /// @important \c key must be a literal string and not \c NSString object.
  ///
  /// @code
  /// [NSString stringWithFormat:_LPlural(@"%lu photos", @"context string"), photos.count];
  /// @endcode
  static inline NSString *_LPlural(NSString *key, NSString *comment) {
    return _LDefault(key, comment);
  }

  /// Returns the same \c key that was provided to this method without localization. This is used to
  /// silence the static analyzer when the string that is displayed doesn't require any
  /// localization.
  static inline NSString *_LIgnore(NSString *key) LT_RETURNS_LOCALIZED_STRING {
    return key;
  }
}

NS_ASSUME_NONNULL_END
