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
-(void) connectionDidOpen:(TcpConnection*)connection;
-(void) connectionDidClose:(TcpConnection*)connection;
-(void) connection:(TcpConnection*)connection errorOccurred:(NSError*)error;
-(void) connectionDidDrain:(TcpConnection*)connection;
-(void) connection:(TcpConnection*)connection didReceiveData:(NSData *)data;
@end

@interface TcpConnection : NSObject <NSStreamDelegate>
@property (assign, nonatomic) id delegate;

-(id) initWithInputStream:(NSInputStream*)ins outputStream:(NSOutputStream*)outs;
-(id) initWithHost:(NSString*)host port:(NSInteger)port;

-(void) open;
-(void) close;
-(void) closeAfterDrain;
-(BOOL) write:(uint8_t*)data length:(NSUInteger)length;
-(BOOL) write:(NSData*)data;
-(BOOL) write:(NSString*)data encoding:(NSStringEncoding)encoding;
@end
