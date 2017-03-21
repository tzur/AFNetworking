// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValueTransformer+LTEngine.h"

#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/LTPath.h>
#import <LTKit/UIColor+Utilities.h>

#import "LTTestMTLModel.h"

@interface LTTestNonJSONMTLModel : MTLModel
@end

@implementation LTTestNonJSONMTLModel
@end

LTEnumMake(NSUInteger, LTTestEnum,
  LTTestEnumFoo,
  LTTestEnumBar
);

SpecBegin(NSValueTransformer_LTEngine)

context(@"class value transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer valueTransformerForName:kLTClassValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:@"NSValueTransformer"]).to
        .equal([NSValueTransformer class]);
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:NSValueTransformer.class]).to
        .equal(@"NSValueTransformer");
  });

  it(@"should raise if class name is invalid", ^{
    expect(^{
      [transformer transformedValue:@"_NonExistingClass"];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"model value transformer", ^{
  __block LTTestMTLModel *model;
  __block NSValueTransformer *transformer;

  beforeEach(^{
    model = [[LTTestMTLModel alloc] initWithDictionary:@{
      @instanceKeypath(LTTestMTLModel, name): @"foo",
      @instanceKeypath(LTTestMTLModel, value): @42
    } error:nil];

    transformer = [NSValueTransformer valueTransformerForName:kLTModelValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform for strings", ^{
    expect([transformer transformedValue:@"foo"]).to.equal(@"foo");
  });

  it(@"should perform forward transform for numbers", ^{
    expect([transformer transformedValue:@42]).to.equal(@42);
  });

  it(@"should perform forward transform for enums", ^{
    expect([transformer transformedValue:@{
      @"_class": NSStringFromClass(LTTestEnum.class),
      @"name": $(LTTestEnumFoo).name
    }]).to.equal($(LTTestEnumFoo));
  });

  it(@"should perform forward transform for model", ^{
    expect([transformer transformedValue:@{
      @instanceKeypath(LTTestMTLModel, name): @"foo",
      @instanceKeypath(LTTestMTLModel, value): @42,
      @"_class": @"LTTestMTLModel"
    }]).to.equal(model);
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:model]).to.equal(@{
      @"name": @"foo",
      @"value": @42,
      @"_class": @"LTTestMTLModel"
    });
  });

  it(@"should perform reverse transform for enums", ^{
    expect([transformer reverseTransformedValue:$(LTTestEnumFoo)]).to.equal(@{
      @"_class": NSStringFromClass(LTTestEnum.class),
      @"name": $(LTTestEnumFoo).name
    });
  });

  it(@"should raise if model class name key doesn't exist", ^{
    expect(^{
      [transformer transformedValue:@{
        @instanceKeypath(LTTestMTLModel, name): @"foo",
        @instanceKeypath(LTTestMTLModel, value): @42
      }];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if model class name doesn't exist", ^{
    expect(^{
      [transformer transformedValue:@{
        @instanceKeypath(LTTestMTLModel, name): @"foo",
        @instanceKeypath(LTTestMTLModel, value): @42,
        @"_class": @"_NonExistingClass"
      }];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if model class name is not a subclass of MTLModel", ^{
    expect(^{
      [transformer transformedValue:@{
        @instanceKeypath(LTTestMTLModel, name): @"foo",
        @instanceKeypath(LTTestMTLModel, value): @42,
        @"_class": @"NSObject"
      }];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if invalid object is given", ^{
    expect(^{
      [transformer transformedValue:[NSDate date]];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [transformer reverseTransformedValue:[NSDate date]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if given model doesn't conform to MTLJSONSerializing", ^{
    expect(^{
      [transformer reverseTransformedValue:[[LTTestNonJSONMTLModel alloc] init]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"enum transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer lt_enumNameTransformerForClass:LTTestEnum.class];
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:$(LTTestEnumFoo).name]).to.equal($(LTTestEnumFoo));
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:$(LTTestEnumFoo)]).to.equal($(LTTestEnumFoo).name);
  });

  it(@"should raise if given enum class is not an enum", ^{
    expect(^{
      [NSValueTransformer lt_enumNameTransformerForClass:NSString.class];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when transforming an invalid enum field name", ^{
    expect(^{
      [transformer transformedValue:@"foo"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when transforming a nil value", ^{
    expect(^{
      [transformer transformedValue:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when reverse transforming a nil value", ^{
    expect(^{
      [transformer reverseTransformedValue:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"dictionary with value model class", ^{
  __block NSDictionary<NSString *, NSDictionary<NSString *, id> *> *json;
  __block NSDictionary<NSString *, NSDictionary<NSString *, id> *> *models;
  __block NSValueTransformer *transformer;

  beforeEach(^{
    json = @{
      @"foo": @{
        @instanceKeypath(LTTestMTLModel, name): @"first",
        @instanceKeypath(LTTestMTLModel, value): @42
      },
      @"bar": @{
        @instanceKeypath(LTTestMTLModel, name): @"second",
        @instanceKeypath(LTTestMTLModel, value): @35
      }
    };

    models = @{
      @"foo": [[LTTestMTLModel alloc] initWithDictionary:@{
        @instanceKeypath(LTTestMTLModel, name): @"first",
        @instanceKeypath(LTTestMTLModel, value): @42
      } error:nil],
      @"bar": [[LTTestMTLModel alloc] initWithDictionary:@{
        @instanceKeypath(LTTestMTLModel, name): @"second",
        @instanceKeypath(LTTestMTLModel, value): @35
      } error:nil]
    };

    transformer = [NSValueTransformer
                   lt_JSONDictionaryTransformerWithValuesOfModelClass:LTTestMTLModel.class];
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:json]).to.equal(models);
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:models]).to.equal(json);
  });

  it(@"should raise if non-dictionary is given", ^{
    expect(^{
      [transformer transformedValue:@"foo"];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [transformer reverseTransformedValue:@"foo"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if non-string keys are given", ^{
    expect(^{
      [transformer transformedValue:@{@42: json[@"foo"]}];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      [transformer reverseTransformedValue:@{@42: models[@"foo"]}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if serialization fails", ^{
    expect(^{
      [transformer transformedValue:@{
        @"foo": @{
          @instanceKeypath(LTTestMTLModel, name): @"first"
        }
      }];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"transformer composition", ^{
  __block NSValueTransformer *valueTransformer;

  beforeEach(^{
    valueTransformer =
        [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSString *(NSString *value) {
      LTParameterAssert([value isKindOfClass:NSString.class] && value.length);
      return [value stringByAppendingString:@"_transformed"];
    } reverseBlock:^NSString *(NSString *transformedValue) {
      LTParameterAssert(!NSEqualRanges([transformedValue rangeOfString:@"_transformed"],
                                       NSMakeRange(NSNotFound, 0)));
      return [transformedValue stringByReplacingOccurrencesOfString:@"_transformed"
                                                         withString:@""];
    }];
  });

  context(@"dictionary transformer", ^{
    __block NSDictionary<NSString *, NSString *> *json;
    __block NSDictionary<NSString *, NSString *> *values;

    __block NSValueTransformer *transformer;

    beforeEach(^{
      json = @{
        @"foo": @"bar",
        @"bar": @"baz"
      };

      values = @{
        @"foo": @"bar_transformed",
        @"bar": @"baz_transformed"
      };

      transformer = [NSValueTransformer
                     lt_JSONDictionaryTransformerWithTransformer:valueTransformer];
    });

    it(@"should perform forward transform", ^{
      expect([transformer transformedValue:json]).to.equal(values);
    });

    it(@"should perform reverse transform", ^{
      expect([transformer reverseTransformedValue:values]).to.equal(json);
    });

    it(@"should raise if non-dictionary is given", ^{
      expect(^{
        [transformer transformedValue:@"foo"];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [transformer reverseTransformedValue:@"foo"];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if non-string keys are given", ^{
      expect(^{
        [transformer transformedValue:@{@42: json[@"foo"]}];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [transformer reverseTransformedValue:@{@42: values[@"foo"]}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if transformation of dictionary value fails", ^{
      expect(^{
        [transformer reverseTransformedValue:@{
          @"": @"bar"
        }];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if reverese transformation of dictionary value fails", ^{
      expect(^{
        [transformer reverseTransformedValue:@{
          @"foo": @"bar_serialized"
        }];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"array transformer", ^{
    __block NSArray<NSString *> *json;
    __block NSArray<NSString *> *values;

    __block NSValueTransformer *transformer;

    beforeEach(^{
      json = @[@"foo", @"bar"];
      values = @[@"foo_transformed", @"bar_transformed"];

      transformer = [NSValueTransformer lt_JSONArrayTransformerWithTransformer:valueTransformer];
    });

    it(@"should perform forward transform", ^{
      expect([transformer transformedValue:json]).to.equal(values);
    });

    it(@"should perform reverse transform", ^{
      expect([transformer reverseTransformedValue:values]).to.equal(json);
    });

    it(@"should raise if non-array is given", ^{
      expect(^{
        [transformer transformedValue:@"foo"];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [transformer reverseTransformedValue:@"foo"];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if non-string values are given", ^{
      expect(^{
        [transformer transformedValue:@[@42]];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if transformation of array object fails", ^{
      expect(^{
        [transformer reverseTransformedValue:@[@""]];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if reverese transfrrmation of array object fails", ^{
      expect(^{
        [transformer reverseTransformedValue:@[@"bar_serialized"]];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"color value transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer valueTransformerForName:kLTColorValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:@"#FFFF0000"]).to.equal([UIColor redColor]);
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:[UIColor blackColor]]).to.equal(@"#FF000000");
  });

  it(@"should raise if received object for forward transform isn't a string", ^{
    expect(^{
      [transformer transformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received string for forward transform isn't formatted correctly", ^{
    expect(^{
      [transformer transformedValue:@"00000"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received object for reverse transform isn't a color", ^{
    expect(^{
      [transformer reverseTransformedValue:@"#000000"];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"uuid value transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer valueTransformerForName:kLTUUIDValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:@"123e4567-e89b-12d3-a456-426655440000"]).
        to.equal([[NSUUID alloc] initWithUUIDString:@"123e4567-e89b-12d3-a456-426655440000"]);
    expect([transformer transformedValue:nil]).to.beNil();
  });

  it(@"should perform reverse transform", ^{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"123e4567-e89b-12d3-a456-426655440000"];
    expect([transformer reverseTransformedValue:uuid]).
                to.equal(@"123E4567-E89B-12D3-A456-426655440000");
    expect([transformer reverseTransformedValue:nil]).to.beNil();
  });

  it(@"should raise if received object for forward transform isn't a string", ^{
    expect(^{
      [transformer transformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received string for forward transform isn't formatted correctly", ^{
    expect(^{
      [transformer transformedValue:@"00000-weew3434-sdwe-34-3333333"];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      [transformer transformedValue:@"123e4567-e89b-12d3-a456-4266554400009"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received object for reverse transform isn't a uuid", ^{
    expect(^{
      [transformer reverseTransformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"standard date value transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer valueTransformerForName:kLTUTCDateValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:@"1970-01-01T00:00:30.000Z"]).
        to.equal([NSDate dateWithTimeIntervalSince1970:30]);
  });

  it(@"should perform reverse transform", ^{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:30];
    expect([transformer reverseTransformedValue:date]).to.equal(@"1970-01-01T00:00:30.000Z");
  });

  it(@"should raise if received object for forward transform isn't a string", ^{
    expect(^{
      [transformer transformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received string for forward transform isn't formatted correctly", ^{
    expect(^{
      [transformer transformedValue:@"19700101 00:00:30.00043"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received object for reverse transform isn't a date", ^{
    expect(^{
      [transformer reverseTransformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"time zone value transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer valueTransformerForName:kLTTimeZoneValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    NSString *timeZoneName = [NSTimeZone knownTimeZoneNames][0];
    expect([transformer transformedValue:timeZoneName]).
        to.equal([[NSTimeZone alloc] initWithName:timeZoneName]);
  });

  it(@"should perform reverse transform", ^{
    NSString *timeZoneName = [NSTimeZone knownTimeZoneNames][0];
    NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:timeZoneName];
    expect([transformer reverseTransformedValue:timeZone]).to.equal(timeZoneName);
  });

  it(@"should raise if received object for forward transform isn't a string", ^{
    expect(^{
      [transformer transformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received string for forward transform isn't formatted correctly", ^{
    expect(^{
      [transformer transformedValue:@"ABC"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received object for reverse transform isn't a time zone", ^{
    expect(^{
      [transformer reverseTransformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"LTPath value transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer valueTransformerForName:kLTLTPathValueTransformer];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                 andRelativePath:@"foo/bar"];
    expect([transformer transformedValue:path.relativeURL.absoluteString]).to.equal(path);
  });

  it(@"should perform reverse transform", ^{
    LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                 andRelativePath:@"foo/bar"];
    expect([transformer reverseTransformedValue:path]).to.equal(path.relativeURL.absoluteString);
  });

  it(@"should raise if received object for forward transform isn't a string", ^{
    expect(^{
      [transformer transformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received string for forward transform isn't formatted correctly", ^{
    expect(^{
      [transformer transformedValue:@"ABC"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received object for reverse transform isn't an LTPath", ^{
    expect(^{
      [transformer reverseTransformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"URL value transformer", ^{
  __block NSValueTransformer *transformer;
  __block NSURLComponents *components;

  beforeEach(^{
    transformer = [NSValueTransformer
                   valueTransformerForName:kLTURLValueTransformer];
    components = [[NSURLComponents alloc] init];
    components.scheme = @"http";
    components.host = @"hostus mostus";
    components.path = @"/cool path";
    components.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"q" value:@"7日間無料"]];
  });

  it(@"should have a valid transformer", ^{
    expect(transformer).notTo.beNil();
  });

  it(@"should perform forward transform", ^{
    NSString *urlString = @"http://hostus mostus/cool path?q=7日間無料";
    expect([transformer transformedValue:urlString]).to.equal(components.URL);
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:components.URL])
        .to.equal(@"http://hostus%20mostus/cool%20path?q=7%E6%97%A5%E9%96%93%E7%84%A1%E6%96%99");
  });

  it(@"should raise if received object for transform isn't a NSString", ^{
    expect(^{
      [transformer transformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if received object for reverse transform isn't a NSURL", ^{
    expect(^{
      [transformer reverseTransformedValue:[UIColor blackColor]];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
