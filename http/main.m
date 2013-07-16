//
//  main.m
//  http
//
//  Created by Mirza Kapetanovic on 7/2/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../examples/HelloServer.m"
#import "../examples/EchoServer.m"
#import "../examples/FileServer.m"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        HttpServer *server = CreateFileServer(@"/Users/mirza/Documents/"); // CreateEchoServer();  //CreateHelloServer();
        
        [server listenOnPort:8080];
        
        [[NSRunLoop currentRunLoop] run];
    }
    
    return 0;
}
