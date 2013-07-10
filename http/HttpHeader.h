//
//  HttpHeader.h
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpStatusCodes.h"

/*typedef enum {
    HttpMethodGet,
    HttpMethodPost,
    HttpMethodHead,
    HttpMethodPut,
    HttpMethodDelete,
    HttpMethodTrace,
    HttpMethodOptions,
    HttpMethodConnect,
    HttpMethodPath
} HttpMethod;*/

@interface HttpHeader : NSObject 
-(id) initWithString:(NSString*)headers error:(NSError**)error;

-(NSString*) fieldByName:(NSString*)name;
-(void) setField:(NSString*)name byName:(NSString*)value;
-(void) removeFieldByName:(NSString*)name;
-(NSString*) toString;
@end

@interface HttpRequestHeader : HttpHeader
@property (retain, nonatomic) NSString *method;
@property (retain, nonatomic) NSString *url;
@property (retain, nonatomic) NSString *httpVersion;

@property (assign, nonatomic) NSInteger contentLength;

-(BOOL) hasBody;
@end

@interface HttpResponseHeader : HttpHeader
@property (retain, nonatomic) NSString *httpVersion;
@property (nonatomic) HttpStatusCode statusCode;
@property (retain, nonatomic) NSString *reasonPhrase;
@end
