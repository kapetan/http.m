//
//  HttpHeader.h
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpStatusCodes.h"
#import "HttpHeaderConstants.h"
#import "HttpUrl.h"

@interface HttpHeader : NSObject
@property (assign, nonatomic) NSInteger contentLength;
@property (assign, nonatomic) NSDate *date;

-(id) initWithString:(NSString*)headers error:(NSError**)error;

-(NSString*) fieldValue:(NSString*)name;
-(void) setValue:(NSString*)value forField:(NSString*)name;
-(void) removeField:(NSString*)name;

-(NSString*) toString;
-(NSString*) lineToString;
@end

@interface HttpRequestHeader : HttpHeader
@property (nonatomic) HttpMethod method;
@property (retain, nonatomic) HttpUrl *url;
@property (retain, nonatomic) NSString *httpVersion;

-(BOOL) hasBody;
@end

@interface HttpResponseHeader : HttpHeader
@property (retain, nonatomic) NSString *httpVersion;
@property (nonatomic) HttpStatusCode statusCode;
@property (retain, nonatomic) NSString *reasonPhrase;
@end
