// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "PTNImageMetadata.h"

#import <CoreLocation/CoreLocation.h>
#import <ImageIO/ImageIO.h>
#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTCFExtensions.h>
#import <LTKit/LTCGExtensions.h>
#import <LTKit/NSNumber+CGFloat.h>
#import <LTKit/NSObject+AddToContainer.h>

#import "NSError+Photons.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, PTNImageOrientation,
  PTNImageOrientationUp,
  PTNImageOrientationDown,
  PTNImageOrientationLeft,
  PTNImageOrientationRight,
  PTNImageOrientationUpMirrored,
  PTNImageOrientationDownMirrored,
  PTNImageOrientationLeftMirrored,
  PTNImageOrientationRightMirrored
);

@implementation PTNImageOrientation (EXIF)

+ (LTBidirectionalMap *)exifToImageOrientationMap {
  static LTBidirectionalMap *map;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = [LTBidirectionalMap mapWithDictionary:@{
      @1: $(PTNImageOrientationUp),
      @2: $(PTNImageOrientationUpMirrored),
      @3: $(PTNImageOrientationDown),
      @4: $(PTNImageOrientationDownMirrored),
      @5: $(PTNImageOrientationLeftMirrored),
      @6: $(PTNImageOrientationRight),
      @7: $(PTNImageOrientationRightMirrored),
      @8: $(PTNImageOrientationLeft)
    }];
  });

  return map;
}

+ (PTNImageOrientation *)orientationWithExifOrientation:(int)exifOrientation {
  return self.exifToImageOrientationMap[@(exifOrientation)] ?: $(PTNImageOrientationUp);
}

- (int)exifOrientation {
  LTBidirectionalMap *map = [PTNImageOrientation exifToImageOrientationMap];
  return [[map keyForObject:self] intValue];
}

@end

static NSDictionary * _Nullable PTNGetMetadata(CGImageSourceRef _Nullable sourceRef,
                                               NSURL * _Nullable url,
                                               NSError *__autoreleasing *error);

static void PTNSetError(NSError *__autoreleasing *error, NSInteger errorCode, NSURL * _Nullable url,
                        NSString * _Nullable description);

static NSDictionary * _Nullable PTNGetMetadataFromURL(NSURL *url, NSError *__autoreleasing *error) {
  __block CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
  @onExit {
    LTCFSafeRelease(sourceRef);
  };
  return PTNGetMetadata(sourceRef, url, error);
}

static NSDictionary * _Nullable PTNGetMetadataFromData(NSData *data,
                                                       NSError *__autoreleasing *error) {
  __block CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
  @onExit {
    LTCFSafeRelease(sourceRef);
  };
  return PTNGetMetadata(sourceRef, nil, error);
}

static NSDictionary * _Nullable PTNGetMetadata(CGImageSourceRef _Nullable sourceRef,
                                               NSURL * _Nullable url,
                                               NSError *__autoreleasing *error) {
  if (!sourceRef) {
    PTNSetError(error, PTNErrorCodeDescriptorCreationFailed, url, @"Failed creating CGImageSource");
    return nil;
  }

  CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
  if (!properties) {
    PTNSetError(error, PTNErrorCodeDescriptorCreationFailed, url,
                @"Failed retrieving image properties");
    return nil;
  }
  return CFBridgingRelease(properties);
}

static void PTNSetError(NSError *__autoreleasing *error, NSInteger errorCode, NSURL * _Nullable url,
                        NSString * _Nullable description) {
  if (!error) {
    return;
  }

  NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
  [url setInDictionary:errorInfo forKey:NSURLErrorKey];
  [description setInDictionary:errorInfo forKey:kLTErrorDescriptionKey];
  *error = [NSError lt_errorWithCode:errorCode userInfo:[errorInfo copy]];
}

/// Toll-free bridge a \c CFStringRef into a \c NSString.
#define BRIDGE(STRING) ((__bridge NSString *)STRING)

@interface PTNImageMetadata ()

/// Dictionary to hold actual metadata tags. The internal structure of this dictionary is carefully
/// handled to match EXIF, TIFF and other metadata tags formats, as well as iOS's treatment of such
/// tags.
///
/// Implementation references, used to determine the exact structure:
/// http://stackoverflow.com/questions/3884060/saving-geotag-info-with-photo-on-ios4-1
/// http://stackoverflow.com/questions/12869706/modified-exif-data-doesnt-save-properly
/// https://github.com/gpambrozio/GusUtils
/// http://www.exiv2.org/tags.html
/// https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGImageProperties_Reference/index.html
@property (strong, nonatomic) NSMutableDictionary *data;

@end

@implementation PTNImageMetadata

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self setupMetadataDictionary:nil];
  }
  return self;
}

- (instancetype)initWithImageURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  if (self = [self init]) {
    [self setupMetadataDictionary:PTNGetMetadataFromURL(url, error)];
  }
  return self;
}

- (instancetype)initWithImageData:(NSData *)data error:(NSError *__autoreleasing *)error {
  if (self = [self init]) {
    [self setupMetadataDictionary:PTNGetMetadataFromData(data, error)];
  }
  return self;
}

- (instancetype)initWithMetadata:(PTNImageMetadata *)metadata {
  if (self = [self init]) {
    [self setupMetadataDictionary:metadata.metadataDictionary];
  }
  return self;
}

- (instancetype)initWithMetadataDictionary:(NSDictionary *)dictionary {
  if (self = [self init]) {
    [self setupMetadataDictionary:dictionary];
  }
  return self;
}

+ (NSArray *)metadataDictionaryKeys {
  static NSArray *keys;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    keys = @[
      BRIDGE(kCGImagePropertyGPSDictionary),
      BRIDGE(kCGImagePropertyTIFFDictionary),
      BRIDGE(kCGImagePropertyExifDictionary)
    ];
  });

  return keys;
}

- (void)setupMetadataDictionary:(nullable NSDictionary *)dictionary {
  self.data = [NSMutableDictionary dictionary];
  for (id key in dictionary) {
    if ([self.class.metadataDictionaryKeys containsObject:key]) {
      // This key must contain a dictionary.
      if ([dictionary[key] isKindOfClass:[NSDictionary class]]) {
        self.data[key] = [dictionary[key] mutableCopy];
      } else {
        self.data[key] = [NSMutableDictionary dictionary];
      }
    } else {
      // This is a plain key - just copy as-is.
      self.data[key] = dictionary[key];
    }
  }

  for (id key in self.class.metadataDictionaryKeys) {
    if (!self.data[key]) {
      self.data[key] = [NSMutableDictionary dictionary];
    }
  }
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

- (instancetype)mutableCopyWithZone:(nullable NSZone *)zone {
  return [[PTNMutableImageMetadata allocWithZone:zone] initWithMetadata:self];
}

- (NSUInteger)hash {
  return self.data.hash;
}

- (BOOL)isEqual:(PTNImageMetadata *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.data isEqual:object.data];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, %@>", [self class], self, self.data];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (nullable NSString *)make {
  return self.data[BRIDGE(kCGImagePropertyTIFFDictionary)][BRIDGE(kCGImagePropertyTIFFMake)];
}

- (nullable NSString *)model {
  return self.data[BRIDGE(kCGImagePropertyTIFFDictionary)][BRIDGE(kCGImagePropertyTIFFModel)];
}

- (nullable NSString *)software {
  return self.data[BRIDGE(kCGImagePropertyTIFFDictionary)][BRIDGE(kCGImagePropertyTIFFSoftware)];
}

- (nullable NSDate *)originalTime {
  return [self exifDateFrom:self.data[BRIDGE(kCGImagePropertyExifDictionary)]
                                     [BRIDGE(kCGImagePropertyExifDateTimeOriginal)]
                     subsec:self.data[BRIDGE(kCGImagePropertyExifDictionary)]
                                     [BRIDGE(kCGImagePropertyExifSubsecTimeOriginal)]];
}

- (nullable NSDate *)digitizedTime {
  return [self exifDateFrom:self.data[BRIDGE(kCGImagePropertyExifDictionary)]
                                     [BRIDGE(kCGImagePropertyExifDateTimeDigitized)]
                     subsec:self.data[BRIDGE(kCGImagePropertyExifDictionary)]
                                     [BRIDGE(kCGImagePropertyExifSubsecTimeDigitized)]];
}

- (nullable CLLocation *)location {
  NSDictionary *gps = self.data[BRIDGE(kCGImagePropertyGPSDictionary)];

  CLLocationDegrees latitude = [gps[BRIDGE(kCGImagePropertyGPSLatitude)] doubleValue];
  CLLocationDegrees longitude = [gps[BRIDGE(kCGImagePropertyGPSLongitude)] doubleValue];
  if ([gps[BRIDGE(kCGImagePropertyGPSLatitudeRef)] isEqualToString:@"S"]) {
    latitude *= -1;
  }
  if ([gps[BRIDGE(kCGImagePropertyGPSLongitudeRef)] isEqualToString:@"W"]) {
    longitude *= -1;
  }
  CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);

  CLLocationDistance altitude = -1;
  if (gps[BRIDGE(kCGImagePropertyGPSAltitude)]) {
    altitude = [gps[BRIDGE(kCGImagePropertyGPSAltitude)] doubleValue];
    if ([gps[BRIDGE(kCGImagePropertyGPSAltitudeRef)] isEqualToNumber:@1]) {
      altitude *= -1;
    }
  }

  CLLocationAccuracy accuracy = -1;
  if (gps[BRIDGE(kCGImagePropertyGPSDOP)]) {
    accuracy = [gps[BRIDGE(kCGImagePropertyGPSDOP)] doubleValue];
  }

  CLLocationDirection course = -1;
  if (gps[BRIDGE(kCGImagePropertyGPSTrack)]) {
    course = [gps[BRIDGE(kCGImagePropertyGPSTrack)] doubleValue];
  }

  CLLocationSpeed speed = -1;
  if (gps[BRIDGE(kCGImagePropertyGPSSpeed)]) {
    // Convert from km/h to m/s.
    speed = [gps[BRIDGE(kCGImagePropertyGPSSpeed)] doubleValue] / 3.6;
  }

  NSDate *time = [self gpsDateFrom:gps[BRIDGE(kCGImagePropertyGPSDateStamp)]
                              time:gps[BRIDGE(kCGImagePropertyGPSTimeStamp)]];

  return [[CLLocation alloc] initWithCoordinate:coordinate altitude:altitude
                             horizontalAccuracy:accuracy verticalAccuracy:-1 course:course
                                          speed:speed timestamp:time];
}

- (nullable NSString *)headingReference {
  return self.data[BRIDGE(kCGImagePropertyGPSDictionary)]
                  [BRIDGE(kCGImagePropertyGPSImgDirectionRef)];
}

- (CLLocationDirection)headingDirection {
  CLLocationDirection headingDir = -1;
  if (self.data[BRIDGE(kCGImagePropertyGPSDictionary)][BRIDGE(kCGImagePropertyGPSImgDirection)]) {
    headingDir = [self.data[BRIDGE(kCGImagePropertyGPSDictionary)]
                           [BRIDGE(kCGImagePropertyGPSImgDirection)] doubleValue];
  }
  return headingDir;
}

- (CGSize)size {
  NSNumber *width = self.data[BRIDGE(kCGImagePropertyPixelWidth)];
  NSNumber *height = self.data[BRIDGE(kCGImagePropertyPixelHeight)];
  int orientation = [self.data[BRIDGE(kCGImagePropertyOrientation)] intValue];

  CGSize size = CGSizeNull;

  if (width) {
    size.width = [width CGFloatValue];
  }
  if (height) {
    size.height = [height CGFloatValue];
  }

  // Flip size for rotated images.
  if (orientation >= 5) {
    size = CGSizeMake(size.height, size.width);
  }

  return size;
}

- (PTNImageOrientation *)orientation {
  int exifOrientation = [self exifOrientation];
  return [PTNImageOrientation orientationWithExifOrientation:exifOrientation];
}

- (int)exifOrientation {
  return [self.data[BRIDGE(kCGImagePropertyOrientation)] intValue];
}

- (NSDictionary *)metadataDictionary {
  return [self.data copy];
}

#pragma mark -
#pragma mark Date formatting
#pragma mark -

- (NSDate *)exifDateFrom:(NSString *)dateTime subsec:(NSString *)subsec {
  NSString *fullDate = [NSString stringWithFormat:@"%@.%@", dateTime, subsec];
  return [[self dateFormatterWithFormat:@"yyyy:MM:dd HH:mm:ss.SSS"] dateFromString:fullDate];
}

- (NSDate *)gpsDateFrom:(NSString *)date time:(NSString *)time {
  NSString *fullDate = [NSString stringWithFormat:@"%@ %@", date, time];
  NSDate *gpsDate =
      [[self utcDateFormatterWithFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"] dateFromString:fullDate];
  if (!gpsDate) {
    // Try another format if the first one failed.
    gpsDate = [[self utcDateFormatterWithFormat:@"yyyy:MM:dd HH:mm:ss"] dateFromString:fullDate];
  }
  return gpsDate;
}

- (NSDateFormatter *)dateFormatterWithFormat:(NSString *)formatString {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  dateFormatter.dateFormat = formatString;
  return dateFormatter;
}

- (NSDateFormatter *)utcDateFormatterWithFormat:(NSString *)formatString {
  NSDateFormatter *dateFormatter = [self dateFormatterWithFormat:formatString];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
  return dateFormatter;
}

@end

@implementation PTNMutableImageMetadata

@dynamic make, model, software, originalTime, digitizedTime, location, size, orientation;

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (id)copyWithZone:(nullable NSZone *)zone {
  return [[PTNImageMetadata allocWithZone:zone] initWithMetadata:self];
}

- (instancetype)mutableCopyWithZone:(nullable NSZone *)zone {
  return [[PTNMutableImageMetadata allocWithZone:zone] initWithMetadata:self];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setMake:(nullable NSString *)make {
  [self.data[BRIDGE(kCGImagePropertyTIFFDictionary)] setValue:make
                                                       forKey:BRIDGE(kCGImagePropertyTIFFMake)];
}

- (void)setModel:(nullable NSString *)model {
  [self.data[BRIDGE(kCGImagePropertyTIFFDictionary)] setValue:model
                                                       forKey:BRIDGE(kCGImagePropertyTIFFModel)];
}

- (void)setSoftware:(nullable NSString *)software {
  [self.data[BRIDGE(kCGImagePropertyTIFFDictionary)] setValue:software
                                                       forKey:BRIDGE(kCGImagePropertyTIFFSoftware)];
}

- (void)setOriginalTime:(nullable NSDate *)originalTime {
  NSString * _Nullable dateTime = originalTime ? [self exifDateTimeFor:originalTime] : nil;
  NSString * _Nullable subsecTime = originalTime ? [self exifSubsecTimeFor:originalTime] : nil;
  [self.data[BRIDGE(kCGImagePropertyExifDictionary)]
      setValue:dateTime forKey:BRIDGE(kCGImagePropertyExifDateTimeOriginal)];
  [self.data[BRIDGE(kCGImagePropertyTIFFDictionary)]
      setValue:dateTime forKey:BRIDGE(kCGImagePropertyTIFFDateTime)];
  [self.data[BRIDGE(kCGImagePropertyExifDictionary)]
      setValue:subsecTime forKey:BRIDGE(kCGImagePropertyExifSubsecTimeOriginal)];
  [self.data[BRIDGE(kCGImagePropertyExifDictionary)]
      setValue:subsecTime forKey:BRIDGE(kCGImagePropertyExifSubsecTime)];
}

- (void)setDigitizedTime:(nullable NSDate *)digitizedTime {
  [self.data[BRIDGE(kCGImagePropertyExifDictionary)]
   setValue:digitizedTime ? [self exifDateTimeFor:digitizedTime] : nil
        forKey:BRIDGE(kCGImagePropertyExifDateTimeDigitized)];
  [self.data[BRIDGE(kCGImagePropertyExifDictionary)]
   setValue:digitizedTime ? [self exifSubsecTimeFor:digitizedTime] : nil
        forKey:BRIDGE(kCGImagePropertyExifSubsecTimeDigitized)];
}

- (void)setLocation:(nullable CLLocation *)location {
  NSMutableDictionary *gps = self.data[BRIDGE(kCGImagePropertyGPSDictionary)];

  [gps removeObjectsForKeys:@[
    BRIDGE(kCGImagePropertyGPSVersion),
    BRIDGE(kCGImagePropertyGPSTimeStamp),
    BRIDGE(kCGImagePropertyGPSDateStamp),
    BRIDGE(kCGImagePropertyGPSLatitudeRef),
    BRIDGE(kCGImagePropertyGPSLatitude),
    BRIDGE(kCGImagePropertyGPSLongitudeRef),
    BRIDGE(kCGImagePropertyGPSLongitude),
    BRIDGE(kCGImagePropertyGPSDOP),
    BRIDGE(kCGImagePropertyGPSAltitudeRef),
    BRIDGE(kCGImagePropertyGPSAltitude),
    BRIDGE(kCGImagePropertyGPSSpeedRef),
    BRIDGE(kCGImagePropertyGPSSpeed),
    BRIDGE(kCGImagePropertyGPSTrackRef),
    BRIDGE(kCGImagePropertyGPSTrack),
    BRIDGE(kCGImagePropertyGPSImgDirectionRef),
    BRIDGE(kCGImagePropertyGPSImgDirection)
  ]];

  if (!location) {
    return;
  }

  // The exact format used to write the tags here is determined by both the EXIF standard and iOS's
  // handling of the metadata NSDictionary (since eventually, it's iOS that reads the dictionary
  // and writes the actual image file).
  // See \c data above for links and more info.

  gps[BRIDGE(kCGImagePropertyGPSTimeStamp)] = [self gpsTimeFor:location.timestamp];
  gps[BRIDGE(kCGImagePropertyGPSDateStamp)] = [self gpsDateFor:location.timestamp];

  CLLocationDegrees latitude = location.coordinate.latitude;
  // "N"/"S" stand for North/South. The Numerical value should be non-negative.
  gps[BRIDGE(kCGImagePropertyGPSLatitudeRef)] = latitude >= 0 ? @"N" : @"S";
  gps[BRIDGE(kCGImagePropertyGPSLatitude)] = @(ABS(latitude));

  CLLocationDegrees longitude = location.coordinate.longitude;
  // "E"/"W" stand for East/West. The Numerical value should be non-negative.
  gps[BRIDGE(kCGImagePropertyGPSLongitudeRef)] = longitude >= 0 ? @"E" : @"W";
  gps[BRIDGE(kCGImagePropertyGPSLongitude)] = @(ABS(longitude));

  CLLocationAccuracy accuracy = location.horizontalAccuracy;
  // Negative values are invalid.
  if (accuracy >= 0) {
    gps[BRIDGE(kCGImagePropertyGPSDOP)] = @(accuracy);
  }

  CLLocationDistance altitude = location.altitude;
  if (!isnan(altitude)) {
    // 0/1 stand for above/below sea level. The Numerical value should be non-negative.
    gps[BRIDGE(kCGImagePropertyGPSAltitudeRef)] = altitude >= 0 ? @0 : @1;
    gps[BRIDGE(kCGImagePropertyGPSAltitude)] = @(ABS(altitude));
  }

  CLLocationSpeed speed = location.speed;
  // Negative values are invalid.
  if (speed >= 0) {
    // "K" stands for km/h.
    gps[BRIDGE(kCGImagePropertyGPSSpeedRef)] = @"K";
    // Convert from m/s (CLLocationSpeed) to km/h.
    gps[BRIDGE(kCGImagePropertyGPSSpeed)] = @(speed * 3.6);
  }

  CLLocationDirection course = location.course;
  // Negative values are invalid.
  if (course >= 0) {
    // "T" stands for True heading (as opposed to Magnetic heading). CLLocationDirections are all
    // true heading.
    gps[BRIDGE(kCGImagePropertyGPSTrackRef)] = @"T";
    gps[BRIDGE(kCGImagePropertyGPSTrack)] = @(course);
  }
}

- (void)setHeading:(nullable CLHeading *)heading {
  NSMutableDictionary *gps = self.data[BRIDGE(kCGImagePropertyGPSDictionary)];

  [gps removeObjectsForKeys:@[
    BRIDGE(kCGImagePropertyGPSImgDirectionRef),
    BRIDGE(kCGImagePropertyGPSImgDirection)]
  ];

  if (!heading) {
    return;
  }

  // Prefer True heading if available (Magnetic heading is always available).
  if (heading.trueHeading >= 0) {
    gps[BRIDGE(kCGImagePropertyGPSImgDirectionRef)] = @"T";
    gps[BRIDGE(kCGImagePropertyGPSImgDirection)] = @(heading.trueHeading);
  } else {
    gps[BRIDGE(kCGImagePropertyGPSImgDirectionRef)] = @"M";
    gps[BRIDGE(kCGImagePropertyGPSImgDirection)] = @(heading.magneticHeading);
  }
}

- (void)setSize:(CGSize)size {
  [self.data removeObjectsForKeys:@[
    BRIDGE(kCGImagePropertyPixelWidth),
    BRIDGE(kCGImagePropertyPixelHeight)]
  ];

  CGSize exifSize = size;
  if ([self.data[BRIDGE(kCGImagePropertyOrientation)] intValue] >= 5) {
    exifSize = CGSizeMake(exifSize.height, exifSize.width);
  }

  if (!isnan(exifSize.width)) {
    self.data[BRIDGE(kCGImagePropertyPixelWidth)] = @(exifSize.width);
  }
  if (!isnan(exifSize.height)) {
    self.data[BRIDGE(kCGImagePropertyPixelHeight)] = @(exifSize.height);
  }
}

- (void)setOrientation:(PTNImageOrientation *)orientation {
  [self.data removeObjectForKey:BRIDGE(kCGImagePropertyOrientation)];
  [self.data[BRIDGE(kCGImagePropertyTIFFDictionary)]
      removeObjectForKey:BRIDGE(kCGImagePropertyTIFFOrientation)];

  if (![orientation isEqual:$(PTNImageOrientationUp)]) {
    int exifOrientation = orientation.exifOrientation;
    self.data[BRIDGE(kCGImagePropertyOrientation)] = @(exifOrientation);
    self.data[BRIDGE(kCGImagePropertyTIFFDictionary)][BRIDGE(kCGImagePropertyTIFFOrientation)] =
        @(exifOrientation);
  }
}

#pragma mark -
#pragma mark Date formatting
#pragma mark -

- (NSString *)exifDateTimeFor:(NSDate *)date {
  // The EXIF standard doesn't specify exactly what timezone this should be in. Apple's Camera app
  // uses local timezone, so we do the same here. There exists a tag specifically for this
  // ('Exif.Image.TimeZoneOffset') but it is rarely used. See http://www.exiv2.org/tags.html
  return [[self dateFormatterWithFormat:@"yyyy:MM:dd HH:mm:ss"] stringFromDate:date];
}

- (NSString *)exifSubsecTimeFor:(NSDate *)date {
  return [[self dateFormatterWithFormat:@"SSS"] stringFromDate:date];
}

- (NSString *)gpsTimeFor:(NSDate *)date {
  // GPS timestamp is in UTC timezone by definition. See 'Exif.GPSInfo.GPSTimeStamp' in
  // http://www.exiv2.org/tags.html
  return [[self utcDateFormatterWithFormat:@"HH:mm:ss.SSSSSS"] stringFromDate:date];
}

- (NSString *)gpsDateFor:(NSDate *)date {
  return [[self utcDateFormatterWithFormat:@"yyyy:MM:dd"] stringFromDate:date];
}

@end

NS_ASSUME_NONNULL_END
