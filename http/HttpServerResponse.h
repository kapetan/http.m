//
//  HttpServerResponse.h
//  http
//
//  Created by Mirza Kapetanovic on 7/10/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpHeader.h"
#import "TcpConnection.h"

@class HttpServerResponse;

@protocol HttpServerResponseDelegate <NSObject>
-(void) responseDidEnd:(HttpServerResponse*)response;
-(void) responseDidDrain:(HttpServerResponse*)response;
-(void) responseDidClose:(HttpServerResponse*)response;
@end

@interface HttpServerResponseBlockDelegate : NSObject <HttpServerResponseDelegate>
@property (copy, nonatomic) void (^end)(HttpServerResponse*);
@property (copy, nonatomic) void (^drain)(HttpServerResponse*);
@property (copy, nonatomic) void (^close)(HttpServerResponse*);
@end

@interface HttpServerResponse : NSObject
@property (readonly, nonatomic) HttpResponseHeader *header;
@property (readonly, nonatomic) TcpConnection *connection;

@property (assign, nonatomic) id delegate;

@property (readonly, nonatomic) BOOL ended;

-(id) initWithConnection:(TcpConnection*)connection;

-(BOOL) write:(uint8_t*)data length:(NSUInteger)length;
-(BOOL) write:(NSData*)data;
-(BOOL) write:(NSString*)data encoding:(NSStringEncoding)encoding;

-(void) writeHeaderStatus:(HttpStatusCode)status reasonPhrase:(NSString*)reason headers:(NSDictionary*)headers;
-(void) writeHeaderStatus:(HttpStatusCode)status headers:(NSDictionary *)headers;
-(void) writeHeaderStatus:(HttpStatusCode)status;

-(void) end;
@end
