//
//  TcpServer.h
//  http
//
//  Created by Mirza Kapetanovic on 7/6/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TcpConnection.h"

extern NSString *const TcpErrorDomain;

enum {
    TcpErrorConnectionFailed = 0,
};

@class TcpServer;

@protocol TcpServerDelegate <NSObject>
@optional
-(void) serverDidClose:(TcpServer*)server;
-(void) server:(TcpServer*)server errorOccurred:(NSError*)error;
-(void) server:(TcpServer*)server acceptedConnection:(TcpConnection*)connection;
@end

@interface TcpServerBlockDelegate : NSObject <TcpConnectionDelegate>
@property (nonatomic, copy) void (^close)(TcpServer *server);
@property (nonatomic, copy) void (^error)(TcpServer *server, NSError *error);
@property (nonatomic, copy) void (^accept)(TcpServer *server, TcpConnection *connection);
@end

@interface TcpServer : NSObject
-(void) listenOnPort:(NSInteger) port;
-(void) close;

-(id) delegate;
-(void) setDelegate:(id)newDelegate;

// This method is called from the CFCreateSocket function, when a new connection is accepted
-(void) acceptConnection:(CFSocketNativeHandle)handle;
@end
