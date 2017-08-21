#import <Foundation/Foundation.h>

#define EXP_SHORTHAND

#import <Expecta/Expecta.h>
#import <XCTest/XCTest.h>

#import "FakeTestCase.h"
#import "EXPExpect+Test.h"

#define assertPass(expr) \
    XCTAssertNoThrow((expr))

#define assertFail(expr, message...) \
    XCTAssertThrowsSpecificNamed(expr, NSException, ## message)

#define assertEquals(a, b) XCTAssertEqual((a), (b))
#define assertEqualObjects(a, b) XCTAssertEqualObjects((a), (b))
#define assertTrue(a) XCTAssertTrue((a))
#define assertFalse(a) XCTAssertFalse((a))
#define assertNil(a) XCTAssertNil((a))

#define test_expect(a) [expect(a) test]
