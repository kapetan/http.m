//
//  HttpServer.h
//  http
//
//  Created by Mirza Kapetanovic on 7/10/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TcpServer.h"

#import "HttpServerRequest.h"
#import "HttpServerResponse.h"

@class HttpServer;

@protocol HttpServerDelegate <NSObject>
-(void) server:(HttpServer*)server request:(HttpServerRequest*)request response:(HttpServerResponse*)response;
-(void) serverDidClose:(HttpServer*)server;
-(void) server:(HttpServer*)server acceptedConnection:(TcpConnection*)connection;
-(void) server:(HttpServer*)server errorOccurred:(NSError*)error;
@end

@interface HttpServerBlockDelegate : NSObject <HttpServerDelegate>
@property (copy, nonatomic) void (^request)(HttpServer*, HttpServerRequest*, HttpServerResponse*);
@property (copy, nonatomic) void (^close)(HttpServer*);
@property (copy, nonatomic) void (^accept)(HttpServer*, TcpConnection*);
@property (copy, nonatomic) void (^error)(HttpServer*, NSError*);
@end

@interface HttpServerAcceptDelegate : NSObject <TcpServerDelegate>
-(id) initWithServer:(HttpServer*)server;
@end

@interface HttpServerConnectionDelegate : NSObject <TcpConnectionDelegate>
-(id) initWithServer:(HttpServer*)server;
@end

@interface HttpServer : NSObject
@property (assign, nonatomic) id delegate;
@property (readonly, nonatomic) NSMutableArray *connections;

-(void) listenOnPort:(NSInteger)port;
-(void) close;

-(void) removeConnection:(TcpConnection*)connection;
-(void) addConnection:(TcpConnection*)connection;
@end
