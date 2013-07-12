//
//  HttpRequest.h
//  http
//
//  Created by Mirza Kapetanovic on 7/9/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpHeader.h"
#import "TcpConnection.h"

@class HttpServerRequest;

@protocol HttpServerRequestDelegate <NSObject>
-(void) request:(HttpServerRequest*)request didReceiveData:(NSData*)data;
-(void) requestDidEnd:(HttpServerRequest*)request;
@end

@interface HttpServerRequestBlockDelegate : NSObject <HttpServerRequestDelegate>
@property (copy, nonatomic) void (^data)(HttpServerRequest*, NSData*);
@property (copy, nonatomic) void (^end)(HttpServerRequest*);
@end

@interface HttpServerRequest : NSObject
@property (readonly, nonatomic) HttpRequestHeader *header;
@property (readonly, nonatomic) TcpConnection *connection;

@property (assign, nonatomic) id delegate;

-(id) initWithConnection:(TcpConnection*)connection header:(HttpRequestHeader*)header;
@end
