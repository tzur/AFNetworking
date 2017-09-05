// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Marks a method or function as one that returns a localized string. This will suppress the
/// "Missing Localizability" static analyzer issue.
#ifndef LT_RETURNS_LOCALIZED_STRING
  #define LT_RETURNS_LOCALIZED_STRING __attribute__((annotate("returns_localized_nsstring")))
#endif

/// Wrapper for a string resource file used for localizing apps. A string resource file is a table
/// mapping between string keys to localized strings. The keys are usually strings in the default
/// locale, like English.
///
/// To use this class, create a .strings file in a bundle, then initialize this class with the
/// bundle and the .string file name to access the file's content.
///
/// @see \c NSBundle for more information about localization. In particular see
/// <tt>-localizedStringForKey:value:table:</tt>.
/// @see Chapter Strings Resources in Apple's Resource Programming Guide.
@interface LTLocalizationTable : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c bundle and \c tableName which contains the relevant localized strings.
- (instancetype)initWithBundle:(NSBundle *)bundle tableName:(NSString *)tableName
    NS_DESIGNATED_INITIALIZER;

/// Returns a localized string for \c key string. \c key is returned if no matching localized string
/// could be found, either because there is no table with \c tableName in the bundle, or such table
/// does not have a matching localized string for the required locale.
- (NSString *)objectForKeyedSubscript:(NSString *)key;

/// Name of the localized strings table.
@property (readonly, nonatomic) NSString *tableName;

@end

NS_ASSUME_NONNULL_END
