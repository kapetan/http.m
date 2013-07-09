//
//  main.m
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpHeaders.h"
#import "TcpConnection.h"
#import "TcpServer.h"

@class TcpConnectionDelegateImpl;

@interface TcpServerDelefateImpl : NSObject <TcpServerDelegate>
@end

@implementation TcpServerDelefateImpl
-(void) server:(TcpServer *)server acceptedConnection:(TcpConnection *)connection {
    TcpConnectionDelegateImpl *listener = [[TcpConnectionDelegateImpl alloc] init];
    
    [connection setDelegate:listener];
    [connection open];
    
    //[connection write:@"HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello" encoding:NSUTF8StringEncoding];
    //[connection close];
}

-(void) server:(TcpServer *)server errorOccurred:(NSError *)error {
    NSLog(@"@Server error %@", error);
}

-(void) serverDidClose:(TcpServer *)server {
    NSLog(@"Server close");
}
@end

@interface TcpConnectionDelegateImpl : NSObject <TcpConnectionDelegate>
@end

@implementation TcpConnectionDelegateImpl
-(void) connectionDidOpen:(TcpConnection *)connection {
    NSLog(@"Connection open");
}

-(void) connectionDidDrain:(TcpConnection *)connection {
    NSLog(@"Connection drain");
}

-(void) connectionDidClose:(TcpConnection *)connection {
    NSLog(@"Connection close");
}

-(void) connection:(TcpConnection *)connection errorOccurred:(NSError *)error {
    NSLog(@"Connection error: %@", error);
}

-(void) connection:(TcpConnection *)connection didReceiveData:(NSData *)data {
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"Connection data (%lu)", [data length]);
    
    [str release];
    
    [connection write:@"HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello" encoding:NSUTF8StringEncoding];
    [connection closeAfterDrain];
    //[connection release];

}
@end

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        TcpServer *server = [[TcpServer alloc] init];
        TcpServerBlockDelegate *delegate = server.delegate;
        
        delegate.accept = ^(TcpServer *server, TcpConnection *connection) {
            NSLog(@"Accepted");
            
            TcpConnectionBlockDelegate *delegate = [connection delegate];
            
            delegate.open = ^(TcpConnection *connection) {
                NSLog(@"Open");
            };
            delegate.data = ^(TcpConnection *connection, NSData *data) {
                NSLog(@"Data");
            };
            
            //[connection open];
        };
        
        //TcpServerDelefateImpl *listener = [[TcpServerDelefateImpl alloc] init];
        
        //[server setDelegate:listener];
        [server listenOnPort:8080];
        
        [[NSRunLoop currentRunLoop] run];
        
        /*TcpConnectionDelegateImpl *listener = [[TcpConnectionDelegateImpl alloc] init];
        //TcpConnection *connection = [[TcpConnection alloc] initWithHost:@"www.foo.com" port:80];
        TcpConnection *connection = [[TcpConnection alloc] initWithHost:@"localhost" port:8080];
        
        [connection setDelegate:listener];
        [connection open];
        
        //[connection write:@"GET / HTTP/1.1\r\nHost:www.foo.com\r\n\r\n" encoding:NSUTF8StringEncoding];
        [connection write:[NSMutableData dataWithLength:32000]];
        
        [[NSRunLoop currentRunLoop] run];*/
        
        /*NSError *err;
        NSString *data = @"HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: 5\r\nConnection: close\r\n\r\n";
        
        HttpResponseHeaders *headers = [[HttpResponseHeaders alloc] initWithString:data error:&err];
        
        headers.status = 300;
        
        // insert code here...
        NSLog(@"Error:\n %@", err);
        NSLog(@"Headers:\n %@", headers);
        
        NSLog(@"\n%@", [headers toString]);*/
    }
    
    return 0;
}

