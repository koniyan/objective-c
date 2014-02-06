//
//  PNResponseDeserializeTest.m
//  pubnub
//
//  Created by Valentin Tuller on 1/30/14.
//  Copyright (c) 2014 PubNub Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "PNPushNotificationsEnabledChannelsParser.h"
#import "PNResponse.h"
#import "PNOperationStatusResponseParser.h"
#import "PNOperationStatus.h"
#import "PNError.h"
#import "PNResponseDeserialize.h"

@interface PNError (test)
@property (nonatomic, copy) NSString *errorMessage;
@end

@interface PNResponse (test)

@property (nonatomic, strong) id response;
@property (nonatomic, assign) NSInteger statusCode;

@end


@interface PNResponseDeserialize (test)
- (id)initWithResponse:(PNResponse *)response;
- (BOOL)isChunkedTransfer:(NSDictionary *)httpResponseHeaders;
- (BOOL)isKeepAliveConnectionType:(NSDictionary *)httpResponseHeaders;
- (BOOL)isDeflateCompressedTransfer:(NSDictionary *)httpResponseHeaders;
- (BOOL)isGZIPCompressedTransfer:(NSDictionary *)httpResponseHeaders;
- (BOOL)isCompressedTransfer:(NSDictionary *)httpResponseHeaders;
- (NSUInteger)contentLength:(NSDictionary *)httpResponseHeaders;
- (PNResponse *)responseInRange:(NSRange)responseRange ofData:(NSData *)data incompleteResponse:(BOOL *)isIncompleteResponse;
- (NSData *)joinedDataFromChunkedDataUsingOctets:(NSData *)chunkedData;
- (NSUInteger)nextResponseStartIndexForData:(NSData *)data inRange:(NSRange)responseRange;
- (NSRange)nextResponseStartSearchRangeInRange:(NSRange)responseRange;

@end


@interface PNResponseDeserializeTest : SenTestCase

@end

@implementation PNResponseDeserializeTest

-(void)tearDown {
    [super tearDown];
	[NSThread sleepForTimeInterval:1.0];
}


-(NSData*)dataFromHex:(NSString*)command {
	command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSMutableData *commandToSend= [[NSMutableData alloc] init];
	unsigned char whole_byte;
	char byte_chars[3] = {'\0','\0','\0'};
	for (int i = 0; i < ([command length] / 2); i++) {
		byte_chars[0] = [command characterAtIndex:i*2];
		byte_chars[1] = [command characterAtIndex:i*2+1];
		whole_byte = strtol(byte_chars, NULL, 16);
		[commandToSend appendBytes:&whole_byte length:1];
	}
	NSLog(@"%@", commandToSend);
	return commandToSend;
}

-(void)testParseResponseData {
	NSArray *commands = @[@"48545450 2f312e31 20323030 204f4b0d 0a446174 653a2046 72692c20 3331204a 616e2032 30313420 31303a33 393a3437 20474d54 0d0a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0d0a436f 6e74656e 742d4c65 6e677468 3a203333 0d0a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0d0a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0d0a504e 2d546872 6f74746c 65643a20 300d0a0d 0a735f34 30653138 285b5b5d 2c223133 39313136 34373837 34363238 33303922 5d29",
						  @[@"\nHTTP STATUS CODE: 200\nCONNECTION WILL BE CLOSE? NO\nRESPONSE SIZE: 33\nRESPONSE CONTENT SIZE: 290\nIS JSONP: YES\nCALLBACK METHOD: s\nREQUEST IDENTIFIER: 40e18\nRESPONSE: (\n        (\n    ),\n    13911647874628309\n)\n"],
						  @"48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62",
						  @[],
						  @"48545450 2f312e31 20323030 204f4b0d 0a446174 653a2046 72692c20 3331204a 616e2032 30313420 31303a34 333a3233 20474d54 0d0a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0d0a436f 6e74656e 742d4c65 6e677468 3a203238 0d0a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0d0a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0d0a0d0a 745f6431 32613228 5b313339 31313635 30303335 30393535 38335d29",
						  @[@"\nHTTP STATUS CODE: 200\nCONNECTION WILL BE CLOSE? NO\nRESPONSE SIZE: 28\nRESPONSE CONTENT SIZE: 268\nIS JSONP: YES\nCALLBACK METHOD: t\nREQUEST IDENTIFIER: d12a2\nRESPONSE: (\n    13911650035095583\n)\n"]
						  ];

	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	for( int i=0; i<commands.count; i+=2 ) {
		NSString *command = commands[i];
		NSArray *arrResult = commands[i+1];
		NSArray *arr = [des parseResponseData: [[self dataFromHex: command] mutableCopy]];
		STAssertTrue( arrResult.count == arr.count, @"");
		for( int j=0; j<arrResult.count; j++ ) {
			NSString *str1 = arrResult[j];
			NSString *str2 = [(PNResponse*)arr[j] description];
			STAssertTrue( [str1 isEqualToString: str2] == YES, @"");
		}
	}
}

-(void)testIsChunkedTransfer {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSDictionary *header = @{@"Transfer-Encoding":@"chunked"};
	STAssertTrue( [des isChunkedTransfer: header] == YES, @"");

	header = @{@"Transfer-Encodingzv":@"chunked"};
	STAssertTrue( [des isChunkedTransfer: header] == NO, @"");
}

-(void)testIsCompressedTransfer {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSDictionary *header = @{@"Content-Encoding":@"gzip"};
	STAssertTrue( [des isCompressedTransfer: header] == YES, @"");

	header = @{@"Content-Encoding":@"deflate"};
	STAssertTrue( [des isCompressedTransfer: header] == YES, @"");

	header = @{@"Content-Encodingasdf":@"deflate"};
	STAssertTrue( [des isCompressedTransfer: header] == NO, @"");
}

-(void)testIsGZIPCompressedTransfer {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSDictionary *header = @{@"Content-Encoding":@"gzip"};
	STAssertTrue( [des isGZIPCompressedTransfer: header] == YES, @"");

	header = @{@"Content-Encoding":@"gzipqw"};
	STAssertTrue( [des isGZIPCompressedTransfer: header] == NO, @"");
}

-(void)testIsDeflateCompressedTransfer {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSDictionary *header = @{@"Content-Encoding":@"deflate"};
	STAssertTrue( [des isDeflateCompressedTransfer: header] == YES, @"");

	header = @{@"Content-Encoding":@"deflateasdf"};
	STAssertTrue( [des isDeflateCompressedTransfer: header] == NO, @"");
}

-(void)testIsKeepAliveConnectionType {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSDictionary *header = @{@"Connection":@"close"};
	STAssertTrue( [des isKeepAliveConnectionType: header] == NO, @"");

	header = @{@"Connection":@"close1"};
	STAssertTrue( [des isKeepAliveConnectionType: header] == YES, @"");
}

-(void)testContentLength {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSDictionary *header = @{@"Content-Length":@"123"};
	STAssertTrue( [des contentLength: header] == 123, @"");
}


-(void)testResponseInRange {
	NSArray *commands = @[ @(268), @(0), @"48545450 2f312e31 20323030 204f4b0d 0a446174 653a2046 72692c20 3331204a 616e2032 30313420 31323a30 373a3030 20474d54 0d0a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0d0a436f 6e74656e 742d4c65 6e677468 3a203238 0d0a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0d0a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0d0a0d0a 745f6233 31316228 5b313339 31313730 30323030 36343634 37335d29",
						   @"\nHTTP STATUS CODE: 200\nCONNECTION WILL BE CLOSE? NO\nRESPONSE SIZE: 28\nRESPONSE CONTENT SIZE: 268\nIS JSONP: YES\nCALLBACK METHOD: t\nREQUEST IDENTIFIER: b311b\nRESPONSE: (\n    13911700200646473\n)\n", @(0),
	   @(290), @(0), @"48545450 2f312e31 20323030 204f4b0d 0a446174 653a2046 72692c20 3331204a 616e2032 30313420 31323a30 373a3030 20474d54 0d0a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0d0a436f 6e74656e 742d4c65 6e677468 3a203333 0d0a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0d0a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0d0a504e 2d546872 6f74746c 65643a20 300d0a0d 0a735f37 66313132 285b5b5d 2c223133 39313137 30303230 30303937 31313122 5d29",
						   @"\nHTTP STATUS CODE: 200\nCONNECTION WILL BE CLOSE? NO\nRESPONSE SIZE: 33\nRESPONSE CONTENT SIZE: 290\nIS JSONP: YES\nCALLBACK METHOD: s\nREQUEST IDENTIFIER: 7f112\nRESPONSE: (\n        (\n    ),\n    13911700200097111\n)\n", @(0),
	   @(605), @(0), @"48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62",
						   [NSNull null], @(1),
	   @(605), @(0), @"48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62485454 502f312e 31203530 34204761 74657761 79205469 6d656f75 740a4461 74653a20 5468752c 20303320 4f637420 32303133 2031313a 31303a31 3820474d 540a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0a436f6e 74656e74 2d4c656e 6774683a 20333732 0a436f6e 6e656374 696f6e3a 206b6565 702d616c 6976650a 43616368 652d436f 6e74726f 6c3a206e 6f2d6361 6368650a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4f7269 67696e3a 202a0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0a3c3f78 6d6c2076 65727369 6f6e3d27 312e3027 3f3e3c21 444f4354 59504520 68746d6c 20505542 4c494320 272d2f2f 5733432f 2f445444 20584854 4d4c2031 2e302053 74726963 742f2f45 4e272768 7474703a 2f2f7777 772e7733 2e6f7267 2f54522f 7868746d 6c312f44 54442f78 68746d6c 312d7374 72696374 2e647464 273e3c68 746d6c20 786d6c6e 733d2768 7474703a 2f2f7777 772e7733 2e6f7267 2f313939 392f7868 746d6c27 3e3c6865 61643e3c 7469746c 653e5468 65207265 71756573 74206661 696c6564 3c2f7469 746c653e 3c2f6865 61643e3c 626f6479 3e3c703e 3c626967 3e536572 76696365 20556e61 7661696c 61626c65 2e3c2f62 69673e3c 2f703e3c 703e3c69 3e546563 686e6963 616c2064 65736372 69707469 6f6e3a3c 2f693e3c 62722f3e 35303420 47617465 77617920 54696d65 2d6f7574 202d2054 68652077 65622073 65727665 72206973 206e6f74 20726573 706f6e64 696e673c 2f703e3c 2f624854 54502f31 2e312035 30342047 61746577 61792054 696d656f 75740a44 6174653a 20546875 2c203033 204f6374 20323031 33203131 3a31303a 31382047 4d540a43 6f6e7465 6e742d54 7970653a 20746578 742f6a61 76617363 72697074 3b206368 61727365 743d2255 54462d38 220a436f 6e74656e 742d4c65 6e677468 3a203337 320a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0a436163 68652d43 6f6e7472 6f6c3a20 6e6f2d63 61636865 0a416363 6573732d 436f6e74 726f6c2d 416c6c6f 772d4f72 6967696e 3a202a0a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4d6574 686f6473 3a204745 540a3c3f 786d6c20 76657273 696f6e3d 27312e30 273f3e3c 21444f43 54595045 2068746d 6c205055 424c4943 20272d2f 2f573343 2f2f4454 44205848 544d4c20 312e3020 53747269 63742f2f 454e2727 68747470 3a2f2f77 77772e77 332e6f72 672f5452 2f786874 6d6c312f 4454442f 7868746d 6c312d73 74726963 742e6474 64273e3c 68746d6c 20786d6c 6e733d27 68747470 3a2f2f77 77772e77 332e6f72 672f3139 39392f78 68746d6c 273e3c68 6561643e 3c746974 6c653e54 68652072 65717565 73742066 61696c65 643c2f74 69746c65 3e3c2f68 6561643e 3c626f64 793e3c70 3e3c6269 673e5365 72766963 6520556e 61766169 6c61626c 652e3c2f 6269673e 3c2f703e 3c703e3c 693e5465 63686e69 63616c20 64657363 72697074 696f6e3a 3c2f693e 3c62722f 3e353034 20476174 65776179 2054696d 652d6f75 74202d20 54686520 77656220 73657276 65722069 73206e6f 74207265 73706f6e 64696e67 3c2f703e 3c2f6248 5454502f 312e3120 35303420 47617465 77617920 54696d65 6f75740a 44617465 3a205468 752c2030 33204f63 74203230 31332031 313a3130 3a313820 474d540a 436f6e74 656e742d 54797065 3a207465 78742f6a 61766173 63726970 743b2063 68617273 65743d22 5554462d 38220a43 6f6e7465 6e742d4c 656e6774 683a2033 37320a43 6f6e6e65 6374696f 6e3a206b 6565702d 616c6976 650a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4f 72696769 6e3a202a 0a416363 6573732d 436f6e74 726f6c2d 416c6c6f 772d4d65 74686f64 733a2047 45540a3c 3f786d6c 20766572 73696f6e 3d27312e 30273f3e 3c21444f 43545950 45206874 6d6c2050 55424c49 4320272d 2f2f5733 432f2f44 54442058 48544d4c 20312e30 20537472 6963742f 2f454e27 27687474 703a2f2f 7777772e 77332e6f 72672f54 522f7868 746d6c31 2f445444 2f786874 6d6c312d 73747269 63742e64 7464273e 3c68746d 6c20786d 6c6e733d 27687474 703a2f2f 7777772e 77332e6f 72672f31 3939392f 7868746d 6c273e3c 68656164 3e3c7469 746c653e 54686520 72657175 65737420 6661696c 65643c2f 7469746c 653e3c2f 68656164 3e3c626f 64793e3c 703e3c62 69673e53 65727669 63652055 6e617661 696c6162 6c652e3c 2f626967 3e3c2f70 3e3c703e 3c693e54 6563686e 6963616c 20646573 63726970 74696f6e 3a3c2f69 3e3c6272 2f3e3530 34204761 74657761 79205469 6d652d6f 7574202d 20546865 20776562 20736572 76657220 6973206e 6f742072 6573706f 6e64696e 673c2f70 3e3c2f62 48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62485454 502f312e 31203530 34204761 74657761 79205469 6d656f75 740a4461 74653a20 5468752c 20303320 4f637420 32303133 2031313a 31303a31 3820474d 540a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0a436f6e 74656e74 2d4c656e 6774683a 20333732 0a436f6e 6e656374 696f6e3a 206b6565 702d616c 6976650a 43616368 652d436f 6e74726f 6c3a206e 6f2d6361 6368650a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4f7269 67696e3a 202a0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0a3c3f78 6d6c2076 65727369 6f6e3d27 312e3027 3f3e3c21 444f4354 59504520 68746d6c 20505542 4c494320 272d2f2f 5733432f 2f445444 20584854 4d4c2031 2e302053 74726963 742f2f45 4e272768 7474703a 2f2f7777 772e7733 2e6f7267 2f54522f 7868746d 6c312f44 54442f78 68746d6c 312d7374 72696374 2e647464 273e3c68 746d6c20 786d6c6e 733d2768 7474703a 2f2f7777 772e7733 2e6f7267 2f313939 392f7868 746d6c27 3e3c6865 61643e3c 7469746c 653e5468 65207265 71756573 74206661 696c6564 3c2f7469 746c653e 3c2f6865 61643e3c 626f6479 3e3c703e 3c626967 3e536572 76696365 20556e61 7661696c 61626c65 2e3c2f62 69673e3c 2f703e3c 703e3c69 3e546563 686e6963 616c2064 65736372 69707469 6f6e3a3c 2f693e3c 62722f3e 35303420 47617465 77617920 54696d65 2d6f7574 202d2054 68652077 65622073 65727665 72206973 206e6f74 20726573 706f6e64 696e673c 2f703e3c 2f624854 54502f31 2e312035 30342047 61746577 61792054 696d656f 75740a44 6174653a 20546875 2c203033 204f6374 20323031 33203131 3a31303a 31382047 4d540a43 6f6e7465 6e742d54 7970653a 20746578 742f6a61 76617363 72697074 3b206368 61727365 743d2255 54462d38 220a436f 6e74656e 742d4c65 6e677468 3a203337 320a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0a436163 68652d43 6f6e7472 6f6c3a20 6e6f2d63 61636865 0a416363 6573732d 436f6e74 726f6c2d 416c6c6f 772d4f72 6967696e 3a202a0a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4d6574 686f6473 3a204745 540a3c3f 786d6c20 76657273 696f6e3d 27312e30 273f3e3c 21444f43 54595045 2068746d 6c205055 424c4943 20272d2f 2f573343 2f2f4454 44205848 544d4c20 312e3020 53747269 63742f2f 454e2727 68747470 3a2f2f77 77772e77 332e6f72 672f5452 2f786874 6d6c312f 4454442f 7868746d 6c312d73 74726963 742e6474 64273e3c 68746d6c 20786d6c 6e733d27 68747470 3a2f2f77 77772e77 332e6f72 672f3139 39392f78 68746d6c 273e3c68 6561643e 3c746974 6c653e54 68652072 65717565 73742066 61696c65 643c2f74 69746c65 3e3c2f68 6561643e 3c626f64 793e3c70 3e3c6269 673e5365 72766963 6520556e 61766169 6c61626c 652e3c2f 6269673e 3c2f703e 3c703e3c 693e5465 63686e69 63616c20 64657363 72697074 696f6e3a 3c2f693e 3c62722f 3e353034 20476174 65776179 2054696d 652d6f75 74202d20 54686520 77656220 73657276 65722069 73206e6f 74207265 73706f6e 64696e67 3c2f703e 3c2f6248 5454502f 312e3120 35303420 47617465 77617920 54696d65 6f75740a 44617465 3a205468 752c2030 33204f63 74203230 31332031 313a3130 3a313820 474d540a 436f6e74 656e742d 54797065 3a207465 78742f6a 61766173 63726970 743b2063 68617273 65743d22 5554462d 38220a43 6f6e7465 6e742d4c 656e6774 683a2033 37320a43 6f6e6e65 6374696f 6e3a206b 6565702d 616c6976 650a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4f 72696769 6e3a202a 0a416363 6573732d 436f6e74 726f6c2d 416c6c6f 772d4d65 74686f64 733a2047 45540a3c 3f786d6c 20766572 73696f6e 3d27312e 30273f3e 3c21444f 43545950 45206874 6d6c2050 55424c49 4320272d 2f2f5733 432f2f44 54442058 48544d4c 20312e30 20537472 6963742f 2f454e27 27687474 703a2f2f 7777772e 77332e6f 72672f54 522f7868 746d6c31 2f445444 2f786874 6d6c312d 73747269 63742e64 7464273e 3c68746d 6c20786d 6c6e733d 27687474 703a2f2f 7777772e 77332e6f 72672f31 3939392f 7868746d 6c273e3c 68656164 3e3c7469 746c653e 54686520 72657175 65737420 6661696c 65643c2f 7469746c 653e3c2f 68656164 3e3c626f 64793e3c 703e3c62 69673e53 65727669 63652055 6e617661 696c6162 6c652e3c 2f626967 3e3c2f70 3e3c703e 3c693e54 6563686e 6963616c 20646573 63726970 74696f6e 3a3c2f69 3e3c6272 2f3e3530 34204761 74657761 79205469 6d652d6f 7574202d 20546865 20776562 20736572 76657220 6973206e 6f742072 6573706f 6e64696e 673c2f70 3e3c2f62 48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62485454 502f312e 31203530 34204761 74657761 79205469 6d656f75 740a4461 74653a20 5468752c 20303320 4f637420 32303133 2031313a 31303a31 3820474d 540a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0a436f6e 74656e74 2d4c656e 6774683a 20333732 0a436f6e 6e656374 696f6e3a 206b6565 702d616c 6976650a 43616368 652d436f 6e74726f 6c3a206e 6f2d6361 6368650a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4f7269 67696e3a 202a0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0a3c3f78 6d6c2076 65727369 6f6e3d27 312e3027 3f3e3c21 444f4354 59504520 68746d6c 20505542 4c494320 272d2f2f 5733432f 2f445444 20584854 4d4c2031 2e302053 74726963 742f2f45 4e272768 7474703a 2f2f7777 772e7733 2e6f7267 2f54522f 7868746d 6c312f44 54442f78 68746d6c 312d7374 72696374 2e647464 273e3c68 746d6c20 786d6c6e 733d2768 7474703a 2f2f7777 772e7733 2e6f7267 2f313939 392f7868 746d6c27 3e3c6865 61643e3c 7469746c 653e5468 65207265 71756573 74206661 696c6564 3c2f7469 746c653e 3c2f6865 61643e3c 626f6479 3e3c703e 3c626967 3e536572 76696365 20556e61 7661696c 61626c65 2e3c2f62 69673e3c 2f703e3c 703e3c69 3e546563 686e6963 616c2064 65736372 69707469 6f6e3a3c 2f693e3c 62722f3e 35303420 47617465 77617920 54696d65 2d6f7574 202d2054 68652077 65622073 65727665 72206973 206e6f74 20726573 706f6e64 696e673c 2f703e3c 2f62",
						   [NSNull null], @(1),
];

	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	for( int i=0; i<commands.count; i+=5 ) {
		NSRange range;
		range.length = [commands[i] intValue];
		range.location = [commands[i+1] intValue];
		NSString *command = commands[i+2];
		NSString *result = commands[i+3];
		BOOL isIncompleteResponse;
		PNResponse *response = [des responseInRange: range ofData: [self dataFromHex: command] incompleteResponse: &isIncompleteResponse];
		if( [result isKindOfClass: [NSNull class]] == YES )
			STAssertTrue( response == nil, @"");
		else {
			NSString *str2 = [response description];
			NSLog(@"result \n|%@|\n|%@|", result, str2);
			STAssertTrue( [result isEqualToString: str2] == YES, @"");
		}
		STAssertTrue( isIncompleteResponse == [commands[i+4] intValue], @"");
	}
}

-(void)testJoinedDataFromChunkedDataUsingOctets {
	NSArray *commands = @[ @"36300d0a 6172635f 38386636 39287b22 73746174 7573223a 3430302c 226d6573 73616765 223a2249 6e76616c 69642054 696d6573 74616d70 222c2273 65727669 6365223a 22416363 65737320 4d616e61 67657222 2c226572 726f7222 3a747275 657d290a 0d0a",
	   @"6172635f 38386636 39287b22 73746174 7573223a 3430302c 226d6573 73616765 223a2249 6e76616c 69642054 696d6573 74616d70 222c2273 65727669 6365223a 22416363 65737320 4d616e61 67657222 2c226572 726f7222 3a747275 657d290a",

		@"38350d0a 735f6237 37613628 7b227374 61747573 223a3430 302c2273 65727669 6365223a 22416363 65737320 4d616e61 67657222 2c226572 726f7222 3a747275 652c226d 65737361 6765223a 22496e76 616c6964 20537562 73637269 6265204b 6579222c 22706179 6c6f6164 223a7b22 6368616e 6e656c73 223a5b22 6368616e 6e656c22 5d7d7d29 0a0d0a",
	   @"735f6237 37613628 7b227374 61747573 223a3430 302c2273 65727669 6365223a 22416363 65737320 4d616e61 67657222 2c226572 726f7222 3a747275 652c226d 65737361 6765223a 22496e76 616c6964 20537562 73637269 6265204b 6579222c 22706179 6c6f6164 223a7b22 6368616e 6e656c73 223a5b22 6368616e 6e656c22 5d7d7d29 0a",

		@"37340d0a 685f3834 63303228 7b227374 61747573 223a3430 332c2273 65727669 6365223a 22416363 65737320 4d616e61 67657222 2c226572 726f7222 3a747275 652c226d 65737361 6765223a 22466f72 62696464 656e222c 22706179 6c6f6164 223a7b22 6368616e 6e656c73 223a5b22 6368225d 7d7d290a 0d0a",
		@"685f3834 63303228 7b227374 61747573 223a3430 332c2273 65727669 6365223a 22416363 65737320 4d616e61 67657222 2c226572 726f7222 3a747275 652c226d 65737361 6765223a 22466f72 62696464 656e222c 22706179 6c6f6164 223a7b22 6368616e 6e656c73 223a5b22 6368225d 7d7d290a"];

	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	for( int i=0; i<commands.count; i+=2 ) {
		NSData *chunkedData = [self dataFromHex: commands[i]];
		NSData *result = [des joinedDataFromChunkedDataUsingOctets: chunkedData];
		NSData *expectation = [self dataFromHex: commands[i+1]];
		STAssertTrue( [result isEqualToData: expectation], @"");
	}
}


-(void)testNextResponseStartIndexForData {
	NSArray *commands = @[ @(268), @(0), @"48545450 2f312e31 20323030 204f4b0d 0a446174 653a2046 72692c20 3331204a 616e2032 30313420 31343a33 323a3539 20474d54 0d0a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0d0a436f 6e74656e 742d4c65 6e677468 3a203238 0d0a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0d0a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0d0a0d0a 745f6433 34656628 5b313339 31313738 37373938 35343237 33385d29", @(4294967295),

	   @(290), @(0), @"48545450 2f312e31 20323030 204f4b0d 0a446174 653a2046 72692c20 3331204a 616e2032 30313420 31343a33 323a3539 20474d54 0d0a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0d0a436f 6e74656e 742d4c65 6e677468 3a203333 0d0a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0d0a4361 6368652d 436f6e74 726f6c3a 206e6f2d 63616368 650d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0d0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0d0a504e 2d546872 6f74746c 65643a20 300d0a0d 0a735f65 62393663 285b5b5d 2c223133 39313137 38373739 38303532 33343022 5d29", @(9223372036854775807),

		@(605), @(0), @"48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62", @(9223372036854775807),

		@(1210), @(0), @"48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62485454 502f312e 31203530 34204761 74657761 79205469 6d656f75 740a4461 74653a20 5468752c 20303320 4f637420 32303133 2031313a 31303a31 3820474d 540a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0a436f6e 74656e74 2d4c656e 6774683a 20333732 0a436f6e 6e656374 696f6e3a 206b6565 702d616c 6976650a 43616368 652d436f 6e74726f 6c3a206e 6f2d6361 6368650a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4f7269 67696e3a 202a0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0a3c3f78 6d6c2076 65727369 6f6e3d27 312e3027 3f3e3c21 444f4354 59504520 68746d6c 20505542 4c494320 272d2f2f 5733432f 2f445444 20584854 4d4c2031 2e302053 74726963 742f2f45 4e272768 7474703a 2f2f7777 772e7733 2e6f7267 2f54522f 7868746d 6c312f44 54442f78 68746d6c 312d7374 72696374 2e647464 273e3c68 746d6c20 786d6c6e 733d2768 7474703a 2f2f7777 772e7733 2e6f7267 2f313939 392f7868 746d6c27 3e3c6865 61643e3c 7469746c 653e5468 65207265 71756573 74206661 696c6564 3c2f7469 746c653e 3c2f6865 61643e3c 626f6479 3e3c703e 3c626967 3e536572 76696365 20556e61 7661696c 61626c65 2e3c2f62 69673e3c 2f703e3c 703e3c69 3e546563 686e6963 616c2064 65736372 69707469 6f6e3a3c 2f693e3c 62722f3e 35303420 47617465 77617920 54696d65 2d6f7574 202d2054 68652077 65622073 65727665 72206973 206e6f74 20726573 706f6e64 696e673c 2f703e3c 2f62", @(605),

		@(1815), @(0), @"48545450 2f312e31 20353034 20476174 65776179 2054696d 656f7574 0a446174 653a2054 68752c20 3033204f 63742032 30313320 31313a31 303a3138 20474d54 0a436f6e 74656e74 2d547970 653a2074 6578742f 6a617661 73637269 70743b20 63686172 7365743d 22555446 2d38220a 436f6e74 656e742d 4c656e67 74683a20 3337320a 436f6e6e 65637469 6f6e3a20 6b656570 2d616c69 76650a43 61636865 2d436f6e 74726f6c 3a206e6f 2d636163 68650a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4f726967 696e3a20 2a0a4163 63657373 2d436f6e 74726f6c 2d416c6c 6f772d4d 6574686f 64733a20 4745540a 3c3f786d 6c207665 7273696f 6e3d2731 2e30273f 3e3c2144 4f435459 50452068 746d6c20 5055424c 49432027 2d2f2f57 33432f2f 44544420 5848544d 4c20312e 30205374 72696374 2f2f454e 27276874 74703a2f 2f777777 2e77332e 6f72672f 54522f78 68746d6c 312f4454 442f7868 746d6c31 2d737472 6963742e 64746427 3e3c6874 6d6c2078 6d6c6e73 3d276874 74703a2f 2f777777 2e77332e 6f72672f 31393939 2f786874 6d6c273e 3c686561 643e3c74 69746c65 3e546865 20726571 75657374 20666169 6c65643c 2f746974 6c653e3c 2f686561 643e3c62 6f64793e 3c703e3c 6269673e 53657276 69636520 556e6176 61696c61 626c652e 3c2f6269 673e3c2f 703e3c70 3e3c693e 54656368 6e696361 6c206465 73637269 7074696f 6e3a3c2f 693e3c62 722f3e35 30342047 61746577 61792054 696d652d 6f757420 2d205468 65207765 62207365 72766572 20697320 6e6f7420 72657370 6f6e6469 6e673c2f 703e3c2f 62485454 502f312e 31203530 34204761 74657761 79205469 6d656f75 740a4461 74653a20 5468752c 20303320 4f637420 32303133 2031313a 31303a31 3820474d 540a436f 6e74656e 742d5479 70653a20 74657874 2f6a6176 61736372 6970743b 20636861 72736574 3d225554 462d3822 0a436f6e 74656e74 2d4c656e 6774683a 20333732 0a436f6e 6e656374 696f6e3a 206b6565 702d616c 6976650a 43616368 652d436f 6e74726f 6c3a206e 6f2d6361 6368650a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4f7269 67696e3a 202a0a41 63636573 732d436f 6e74726f 6c2d416c 6c6f772d 4d657468 6f64733a 20474554 0a3c3f78 6d6c2076 65727369 6f6e3d27 312e3027 3f3e3c21 444f4354 59504520 68746d6c 20505542 4c494320 272d2f2f 5733432f 2f445444 20584854 4d4c2031 2e302053 74726963 742f2f45 4e272768 7474703a 2f2f7777 772e7733 2e6f7267 2f54522f 7868746d 6c312f44 54442f78 68746d6c 312d7374 72696374 2e647464 273e3c68 746d6c20 786d6c6e 733d2768 7474703a 2f2f7777 772e7733 2e6f7267 2f313939 392f7868 746d6c27 3e3c6865 61643e3c 7469746c 653e5468 65207265 71756573 74206661 696c6564 3c2f7469 746c653e 3c2f6865 61643e3c 626f6479 3e3c703e 3c626967 3e536572 76696365 20556e61 7661696c 61626c65 2e3c2f62 69673e3c 2f703e3c 703e3c69 3e546563 686e6963 616c2064 65736372 69707469 6f6e3a3c 2f693e3c 62722f3e 35303420 47617465 77617920 54696d65 2d6f7574 202d2054 68652077 65622073 65727665 72206973 206e6f74 20726573 706f6e64 696e673c 2f703e3c 2f624854 54502f31 2e312035 30342047 61746577 61792054 696d656f 75740a44 6174653a 20546875 2c203033 204f6374 20323031 33203131 3a31303a 31382047 4d540a43 6f6e7465 6e742d54 7970653a 20746578 742f6a61 76617363 72697074 3b206368 61727365 743d2255 54462d38 220a436f 6e74656e 742d4c65 6e677468 3a203337 320a436f 6e6e6563 74696f6e 3a206b65 65702d61 6c697665 0a436163 68652d43 6f6e7472 6f6c3a20 6e6f2d63 61636865 0a416363 6573732d 436f6e74 726f6c2d 416c6c6f 772d4f72 6967696e 3a202a0a 41636365 73732d43 6f6e7472 6f6c2d41 6c6c6f77 2d4d6574 686f6473 3a204745 540a3c3f 786d6c20 76657273 696f6e3d 27312e30 273f3e3c 21444f43 54595045 2068746d 6c205055 424c4943 20272d2f 2f573343 2f2f4454 44205848 544d4c20 312e3020 53747269 63742f2f 454e2727 68747470 3a2f2f77 77772e77 332e6f72 672f5452 2f786874 6d6c312f 4454442f 7868746d 6c312d73 74726963 742e6474 64273e3c 68746d6c 20786d6c 6e733d27 68747470 3a2f2f77 77772e77 332e6f72 672f3139 39392f78 68746d6c 273e3c68 6561643e 3c746974 6c653e54 68652072 65717565 73742066 61696c65 643c2f74 69746c65 3e3c2f68 6561643e 3c626f64 793e3c70 3e3c6269 673e5365 72766963 6520556e 61766169 6c61626c 652e3c2f 6269673e 3c2f703e 3c703e3c 693e5465 63686e69 63616c20 64657363 72697074 696f6e3a 3c2f693e 3c62722f 3e353034 20476174 65776179 2054696d 652d6f75 74202d20 54686520 77656220 73657276 65722069 73206e6f 74207265 73706f6e 64696e67 3c2f703e 3c2f62", @(605)
						   ];

	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	for( int i=0; i<commands.count; i+=4 ) {
		NSRange range;
		range.length = [commands[i] intValue];
		range.location = [commands[i+1] intValue];
		NSUInteger index = [des nextResponseStartIndexForData: [self dataFromHex: commands[i+2]] inRange: range];
		NSLog(@"i = %d, index / expect %lu / %lu", i, (unsigned long)index, (unsigned long)[commands[i+3] unsignedIntValue]);
		STAssertTrue( index == [commands[i+3] unsignedIntValue], @"");
	}
}

-(void)testNextResponseStartSearchRangeInRange {
	PNResponseDeserialize *des = [[PNResponseDeserialize alloc] init];
	NSRange range = [des nextResponseStartSearchRangeInRange: NSMakeRange( 1, 1)];
	STAssertTrue( range.length == 0, @"");
	STAssertTrue( range.location == 2, @"");
}

@end


