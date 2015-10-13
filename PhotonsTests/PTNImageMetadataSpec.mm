// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "PTNImageMetadata.h"

#import <CoreLocation/CoreLocation.h>
#import <LTKit/LTCGExtensions.h>

SpecBegin(PTNImageMetadata)

static NSDictionary * const kGarbageMetadata = @{@"foo": @"bar"};

context(@"setting values", ^{
  __block PTNMutableImageMetadata *metadata;

  beforeEach(^{
    metadata = [[PTNMutableImageMetadata alloc] init];
  });

  it(@"should read back set value", ^{
    NSString *make = @"abc";
    metadata.make = make;
    expect(metadata.make).to.equal(make);

    NSString *model = @"def";
    metadata.model = model;
    expect(metadata.model).to.equal(model);

    NSString *software = @"ghi";
    metadata.software = software;
    expect(metadata.software).to.equal(software);

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:12345678.901];
    metadata.originalTime = date;
    expect(metadata.originalTime).to.equal(date);

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:345678.9];
    metadata.digitizedTime = date2;
    expect(metadata.digitizedTime).to.equal(date2);
  });

  it(@"should set size and orientation correctly", ^{
    PTNImageOrientation orientation = PTNImageOrientationDownMirrored;
    metadata.orientation = orientation;
    expect(metadata.orientation).to.equal(orientation);

    CGSize size = CGSizeMake(10, 12);
    metadata.size = size;
    expect(metadata.size).to.equal(size);

    metadata.orientation = PTNImageOrientationLeft;
    metadata.size = size;
    expect(metadata.size).to.equal(size);

    // Changing orientation can affect size.
    metadata.orientation = PTNImageOrientationUp;
    expect(metadata.size).to.equal(CGSizeMake(size.height, size.width));
  });

  it(@"should set location correctly", ^{
    CLLocation *location =
        [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(67, -120) altitude:-140
                            horizontalAccuracy:50 verticalAccuracy:-1 course:230 speed:51
                                     timestamp:[NSDate dateWithTimeIntervalSince1970:345678.9]];
    metadata.location = location;

    expect(metadata.location.coordinate).to.equal(location.coordinate);
    expect(metadata.location.altitude).to.equal(location.altitude);
    expect(metadata.location.horizontalAccuracy).to.equal(location.horizontalAccuracy);
    expect(metadata.location.verticalAccuracy).to.equal(location.verticalAccuracy);
    expect(metadata.location.course).to.equal(location.course);
    expect(metadata.location.speed).to.equal(location.speed);
    expect(metadata.location.timestamp).to.equal(location.timestamp);
  });

  it(@"should set heading correctly", ^{
    CLHeading *heading = OCMClassMock([CLHeading class]);
    OCMStub([heading trueHeading]).andReturn(13);

    metadata.heading = heading;
    expect(metadata.headingReference).to.equal(@"T");
    expect(metadata.headingDirection).to.equal(heading.trueHeading);
  });

  it(@"should clear value when setting nil", ^{
    NSString *string = @"abc";
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:345678.9];
    CLLocation *location =
        [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(67, -120) altitude:-140
                            horizontalAccuracy:50 verticalAccuracy:-1 course:230 speed:51
                                     timestamp:[NSDate dateWithTimeIntervalSince1970:345678.9]];
    CLHeading *heading = OCMClassMock([CLHeading class]);
    OCMStub([heading trueHeading]).andReturn(13);

    metadata.make = string;
    metadata.model = string;
    metadata.software = string;
    metadata.originalTime = date;
    metadata.digitizedTime = date;
    metadata.location = location;
    metadata.heading = heading;
    metadata.size = CGSizeMake(20, 30);
    metadata.orientation = PTNImageOrientationDownMirrored;

    metadata.make = nil;
    metadata.model = nil;
    metadata.software = nil;
    metadata.originalTime = nil;
    metadata.digitizedTime = nil;
    metadata.location = nil;
    metadata.heading = nil;
    metadata.size = CGSizeNull;
    metadata.orientation = PTNImageOrientationUp;

    PTNMutableImageMetadata *expected = [[PTNMutableImageMetadata alloc] init];
    expect(metadata).to.equal(expected);
  });
});

context(@"isEqual", ^{
  it(@"should equal when empty", ^{
    PTNImageMetadata *metadata = [[PTNImageMetadata alloc] init];
    PTNImageMetadata *anotherMetadata = [[PTNImageMetadata alloc] init];
    expect(metadata).toNot.beIdenticalTo(anotherMetadata);
    expect(metadata).to.equal(anotherMetadata);
  });

  it(@"should equal when not empty", ^{
    PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
                                  initWithMetadataDictionary:kGarbageMetadata];
    PTNImageMetadata *anotherMetadata = [[PTNImageMetadata alloc]
                                         initWithMetadataDictionary:kGarbageMetadata];
    expect(metadata).toNot.beIdenticalTo(anotherMetadata);
    expect(metadata).to.equal(anotherMetadata);
  });

  it(@"should equal when different", ^{
    PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
                                  initWithMetadataDictionary:kGarbageMetadata];
    PTNImageMetadata *anotherMetadata = [[PTNImageMetadata alloc] init];
    expect(metadata).toNot.beIdenticalTo(anotherMetadata);
    expect(metadata).toNot.equal(anotherMetadata);
  });

  it(@"should be equal when equal", ^{
    PTNMutableImageMetadata *metadata = [[PTNMutableImageMetadata alloc] init];
    PTNMutableImageMetadata *anotherMetadata = [[PTNMutableImageMetadata alloc] init];
    expect(metadata).toNot.beIdenticalTo(anotherMetadata);
    expect(metadata).to.equal(anotherMetadata);

    metadata.make = @"abc";
    expect(metadata).toNot.equal(anotherMetadata);
    anotherMetadata.make = @"def";
    expect(metadata).toNot.equal(anotherMetadata);
    anotherMetadata.make = @"abc";
    expect(metadata).to.equal(anotherMetadata);
  });
});

context(@"NSCopying", ^{
  it(@"should produce mutable and immutable copies", ^{
    PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
                                  initWithMetadataDictionary:kGarbageMetadata];
    expect([metadata copy]).to.beIdenticalTo(metadata);
    expect([[metadata mutableCopy] isKindOfClass:[PTNMutableImageMetadata class]]).to.beTruthy();

    PTNMutableImageMetadata *mutableMetadata = [metadata mutableCopy];
    expect(mutableMetadata.metadataDictionary).to.equal(metadata.metadataDictionary);
    expect([[mutableMetadata copy] isKindOfClass:[PTNImageMetadata class]]).to.beTruthy();
    expect([[mutableMetadata mutableCopy] isKindOfClass:[PTNMutableImageMetadata class]]).to.beTruthy();

    PTNImageMetadata *immutant = [mutableMetadata copy];
    expect(immutant).to.equal(metadata);
    expect(immutant).toNot.beIdenticalTo(metadata);
    expect(immutant.metadataDictionary).to.equal(mutableMetadata.metadataDictionary);

    PTNMutableImageMetadata *mutableMetadataCopy = [mutableMetadata mutableCopy];
    expect(mutableMetadataCopy).to.equal(mutableMetadata);
    expect(mutableMetadataCopy).toNot.beIdenticalTo(mutableMetadata);
  });
});

context(@"initialization", ^{
  __block PTNImageMetadata *metadata;

  beforeEach(^{
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"PTNImageMetadataImage" ofType:@"jpg"];
    expect(path).toNot.beNil();
    NSError *error;
    metadata = [[PTNImageMetadata alloc] initWithImageURL:[NSURL fileURLWithPath:path]
                                                    error:&error];
    expect(error).to.beNil();
    expect(metadata).notTo.beNil();
  });

  it(@"should initialize with expected test data", ^{
    expect(metadata.make).to.equal(@"Apple");
    expect(metadata.model).to.equal(@"iPhone 6");
    expect(metadata.software).to.equal(@"8.1.3");

    NSDate *originalTime = [NSDate dateWithTimeIntervalSince1970:1423410852.489];
    expect(metadata.originalTime).to.equal(originalTime);
    expect(metadata.digitizedTime).to.equal(originalTime);

    expect(metadata.location.coordinate.latitude).to.beCloseToWithin(31.767272, 0.000001);
    expect(metadata.location.coordinate.longitude).to.beCloseToWithin(35.19585, 0.000001);
    expect(metadata.location.altitude).to.beCloseToWithin(730, 0.1);
    expect(metadata.location.horizontalAccuracy).to.beLessThan(0);
    expect(metadata.location.verticalAccuracy).to.beLessThan(0);
    expect(metadata.location.speed).to.beCloseToWithin(1.831 / 3.6, 0.001);
    expect(metadata.location.course).to.beLessThan(0);
    NSDate *gpsTime = [NSDate dateWithTimeIntervalSince1970:1423410851];
    expect(metadata.location.timestamp).to.equal(gpsTime);
    expect(metadata.headingReference).to.beNil();
    expect(metadata.headingDirection).to.beLessThan(0);

    expect(metadata.size).to.equal(CGSizeMake(44, 44));
    expect(metadata.orientation).to.equal(PTNImageOrientationUp);
  });

  it(@"should copy metadata", ^{
    PTNImageMetadata *copy = [[PTNImageMetadata alloc] initWithMetadata:metadata];
    expect(copy).to.equal(metadata);
    expect(copy).toNot.beIdenticalTo(metadata);
  });

  it(@"should copy metadata dictionary", ^{
    PTNImageMetadata *copy =
        [[PTNImageMetadata alloc] initWithMetadataDictionary:metadata.metadataDictionary];
    expect(copy).to.equal(metadata);
    expect(copy).toNot.beIdenticalTo(metadata);
  });

  it(@"should be empty when image path is invalid", ^{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:@"/foo/bar/baz"];

    NSError *error;
    metadata = [[PTNImageMetadata alloc] initWithImageURL:url error:&error];

    expect(metadata).to.equal([[PTNImageMetadata alloc] init]);
    expect(error).notTo.beNil();
  });
});

context(@"orientations", ^{
  sharedExamplesFor(@"reading orientation", ^(NSDictionary *data) {
    it(@"should read correct orientation", ^{
      NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:data[@"name"]
                                                                        ofType:@"jpg"];
      PTNImageMetadata *metadata = [[PTNImageMetadata alloc]
          initWithImageURL:[NSURL fileURLWithPath:path] error:nil];
      expect(metadata.orientation).to.equal(data[@"orientation"]);
    });
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataUp",
    @"orientation": @(PTNImageOrientationUp)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataDown",
    @"orientation": @(PTNImageOrientationDown)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataLeft",
    @"orientation": @(PTNImageOrientationLeft)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataRight",
    @"orientation": @(PTNImageOrientationRight)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataUpMirrored",
    @"orientation": @(PTNImageOrientationUpMirrored)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataDownMirrored",
    @"orientation": @(PTNImageOrientationDownMirrored)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataLeftMirrored",
    @"orientation": @(PTNImageOrientationLeftMirrored)
  });

  itShouldBehaveLike(@"reading orientation", @{
    @"name": @"PTNImageMetadataRightMirrored",
    @"orientation": @(PTNImageOrientationRightMirrored)
  });
});

context(@"compliance", ^{
  __block PTNImageMetadata *metadata;
  __block PTNMutableImageMetadata *expected;

  beforeEach(^{
    // Read an image created with Apple's Camera.
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"PTNImageMetadataImage" ofType:@"jpg"];
    expect(path).toNot.beNil();
    NSError *error;
    metadata = [[PTNImageMetadata alloc] initWithImageURL:[NSURL fileURLWithPath:path] error:&error];
    expect(error).to.beNil();
    expect(metadata).notTo.beNil();

    // Prepare a PTNImageMetadata with the expected metadata from the same image.
    expected = [[PTNMutableImageMetadata alloc] init];

    expected.make = @"Apple";
    expected.model = @"iPhone 6";
    expected.software = @"8.1.3";

    NSDate *originalTime = [NSDate dateWithTimeIntervalSince1970:1423410852.489];
    expected.originalTime = originalTime;
    expected.digitizedTime = originalTime;

    CLLocation *location =
        [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(31.767272, 35.19585)
                                      altitude:730.0530973451328 horizontalAccuracy:-1
                              verticalAccuracy:-1 course:-1 speed:(1.831628303495311 / 3.6)
                                     timestamp:[NSDate dateWithTimeIntervalSince1970:1423410851]];
    expected.location = location;

    expected.size = CGSizeMake(44, 44);
  });

  // We compare the underlying NSDictionary, because eventually this is what's passed along to the
  // methods that write the image file.

  it(@"should contain expected keys", ^{
    NSSet *keys =
        [NSSet setWithArray:@[@"PixelWidth", @"PixelHeight", @"{Exif}", @"{TIFF}", @"{GPS}"]];
    expect([NSSet setWithArray:expected.metadataDictionary.allKeys]).to.equal(keys);
  });

  sharedExamples(@"equal values", ^(NSDictionary *data) {
    it(@"should have equal values", ^{
      id keypath = data[@"keypath"];
      id value = [metadata.metadataDictionary valueForKeyPath:keypath];
      id expectedValue = [expected.metadataDictionary valueForKeyPath:keypath];
      expect(value).to.equal(expectedValue);
    });
  });

  sharedExamples(@"close values", ^(NSDictionary *data) {
    it(@"should have close values", ^{
      id keypath = data[@"keypath"];
      id value = [metadata.metadataDictionary valueForKeyPath:keypath];
      id expectedValue = [expected.metadataDictionary valueForKeyPath:keypath];
      expect(value).to.beCloseTo(expectedValue);
    });
  });

  sharedExamples(@"equal or nil values", ^(NSDictionary *data) {
    it(@"should have equal values or at lease one is nil", ^{
      id keypath = data[@"keypath"];
      id value = [metadata.metadataDictionary valueForKeyPath:keypath];
      id expectedValue = [expected.metadataDictionary valueForKeyPath:keypath];
      if (value && expected) {
        expect(value).to.equal(expectedValue);
      }
    });
  });

  itShouldBehaveLike(@"equal values", @{@"keypath": @"PixelHeight"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"PixelWidth"});

  itShouldBehaveLike(@"equal values", @{@"keypath": @"{Exif}.DateTimeDigitized"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{Exif}.DateTimeOriginal"});
  itShouldBehaveLike(@"equal or nil values", @{@"keypath": @"{Exif}.SubsecTime"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{Exif}.SubsecTimeDigitized"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{Exif}.SubsecTimeOriginal"});

  itShouldBehaveLike(@"equal values", @{@"keypath": @"{TIFF}.DateTime"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{TIFF}.Make"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{TIFF}.Model"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{TIFF}.Software"});

  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.Altitude"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.AltitudeRef"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.DateStamp"});
  itShouldBehaveLike(@"close values", @{@"keypath": @"{GPS}.Latitude"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.LatitudeRef"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.Longitude"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.LongitudeRef"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.Speed"});
  itShouldBehaveLike(@"equal values", @{@"keypath": @"{GPS}.SpeedRef"});

  it(@"should have identical timestamp up to formatting", ^{
    NSString *value = [metadata.metadataDictionary valueForKeyPath:@"{GPS}.TimeStamp"];
    NSString *expectedValue = [expected.metadataDictionary valueForKeyPath:@"{GPS}.TimeStamp"];

    if ([expectedValue hasSuffix:@".000000"]) {
      expect(value).to.equal([expectedValue substringToIndex:(expectedValue.length - 7)]);
    } else {
      expect(value).to.equal(expectedValue);
    }
  });
});

SpecEnd
