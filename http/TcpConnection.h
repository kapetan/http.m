//
//  TcpConnection.h
//  http
//
//  Created by Mirza Kapetanovic on 7/8/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TcpConnection;

@protocol TcpConnectionDelegate
@optional
-(void) connectionDidOpen:(TcpConnection*)connection;
-(void) connectionDidClose:(TcpConnection*)connection;
-(void) connection:(TcpConnection*)connection errorOccurred:(NSError*)error;
-(void) connectionDidDrain:(TcpConnection*)connection;
-(void) connection:(TcpConnection*)connection didReceiveData:(NSData *)data;
@end

@interface TcpConnectionBlockDelegate : NSObject <TcpConnectionDelegate>
@property (nonatomic, copy) void (^open)(TcpConnection *connection);
@property (nonatomic, copy) void (^close)(TcpConnection *connection);
@property (nonatomic, copy) void (^error)(TcpConnection *connection, NSError *error);
@property (nonatomic, copy) void (^drain)(TcpConnection *connection);
@property (nonatomic, copy) void (^data)(TcpConnection *connection, NSData *data);
@end

@interface TcpConnection : NSObject <NSStreamDelegate>
-(id) initWithInputStream:(NSInputStream*)ins outputStream:(NSOutputStream*)outs;
-(id) initWithHost:(NSString*)host port:(NSInteger)port;

-(void) open;
-(void) close;
-(void) closeAfterDrain;
-(BOOL) write:(uint8_t*)data length:(NSUInteger)length;
-(BOOL) write:(NSData*)data;
-(BOOL) write:(NSString*)data encoding:(NSStringEncoding)encoding;

-(id) delegate;
-(void) setDelegate:(id)newDelegate;
@end
