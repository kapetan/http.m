//
//  main.m
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HttpServer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        HttpServer *server = [[HttpServer alloc] init];
        HttpServerBlockDelegate *delegate = server.delegate;
        
        delegate.request = ^(HttpServer *server, HttpServerRequest *request, HttpServerResponse *response) {
            NSLog(@"Request received");
            
            HttpServerRequestBlockDelegate *requestDelegate = request.delegate;
            HttpServerResponseBlockDelegate *responseDelegate = response.delegate;
            
            NSMutableData *body = [[NSMutableData alloc] init];
            
            requestDelegate.data = ^(HttpServerRequest *request, NSData *data) {
                NSLog(@"Request data %lu", (unsigned long)[data length]);
                [body appendData:data];
            };
            requestDelegate.end = ^(HttpServerRequest *request) {
                NSLog(@"Request end");
                
                //NSData *file = [NSData dataWithContentsOfFile:@"/Users/mirza/Downloads/CocoaEcho/Server/EchoServer.m"];
                
                [response.header setValue:@"text/plain" forField:@"content-type"];
                //response.header.contentLength = [file length];
                
                //[response writeHeaderStatus:HttpStatusCodeOk headers:@{ @"content-length" : @"5" }];
                //[response write:@"HELLO" encoding:NSASCIIStringEncoding];
                //[response writeHeaderStatus:HttpStatusCodeOk headers:@{ @"content-type" : @"text/plain" }];
                [response write:body];
                [response end];
                
                [body release];
            };
            
            //[response writeHeaderStatus:HttpStatusCodeOk headers:@{ @"content-type" : @"text/plain", @"content-length" : @"12" }];
            //[response write:@"Hello World\n" encoding:NSASCIIStringEncoding];
            //[response end];
            
            responseDelegate.end = ^(HttpServerResponse *response) {
                NSLog(@"%@ -> %@", [request.header lineToString], [response.header lineToString]);
            };
            responseDelegate.close = ^(HttpServerResponse *response) {
                NSLog(@"Response close");
            };
        };
        
        [server listenOnPort:8080];
        [[NSRunLoop currentRunLoop] run];
    }
    
    return 0;
}

