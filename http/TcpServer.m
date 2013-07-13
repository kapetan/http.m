//
//  TcpServer.m
//  http
//
//  Created by Mirza Kapetanovic on 7/6/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "TcpServer.h"

#import <sys/socket.h>
#import <netinet/in.h>

NSString *const TcpErrorDomain = @"default.tcp";

NSError *TcpError(NSInteger code, NSString *reason) {
    NSDictionary *info = @{ NSLocalizedDescriptionKey : reason };
    return [NSError errorWithDomain:TcpErrorDomain code:code userInfo:info];
}

void TcpErrorDelegate(TcpServer *server, NSInteger code, NSString* reason) {
    NSError *err = TcpError(code, reason);
    [[server delegate] server:server errorOccurred:err];
}

void TcpServerAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    TcpServer *server = (TcpServer *) info;
    
    // For an accept callback, data is a pointer to CFSocketNativeHandle
    CFSocketNativeHandle handle = *(CFSocketNativeHandle *) data;
    [server acceptConnection:handle];
}

@implementation TcpServer {
    CFSocketRef ipv4Socket;
    CFSocketRef ipv6Socket;
}

@synthesize delegate;

-(id) init {
    if(self = [super init]) {
        self->delegate = nil;
    }
    
    return self;
}

-(void)listenOnPort:(NSInteger) port {
    CFSocketContext socketContext = { 0, self, NULL, NULL, NULL };
    
    ipv4Socket = CFSocketCreate(NULL, AF_INET, SOCK_STREAM, 0, kCFSocketAcceptCallBack, &TcpServerAcceptCallback, &socketContext);
    ipv6Socket = CFSocketCreate(NULL, AF_INET6, SOCK_STREAM, 0, kCFSocketAcceptCallBack, &TcpServerAcceptCallback, &socketContext);
    
    if(!ipv4Socket || !ipv6Socket) {
        TcpErrorDelegate(self, TcpErrorConnectionFailed, @"Failed opening socket");
        [self close];
        return;
    }
    
    // Tell the OS to allow the server to reconnect to the same port, while the port is busy.
    int yes = 1;
    
    setsockopt(CFSocketGetNative(ipv4Socket), SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    setsockopt(CFSocketGetNative(ipv6Socket), SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    
    // Configure socket address
    // IPv4 socket
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    
    if(CFSocketSetAddress(ipv4Socket, (CFDataRef) [NSData dataWithBytes:&addr4 length:sizeof(addr4)]) != kCFSocketSuccess) {
        TcpErrorDelegate(self, TcpErrorConnectionFailed, @"Failed opening IPv4 socket");
        [self close];
        return;
    }
    
    if(!port) {
        NSData *addr = (NSData *) CFSocketCopyAddress(ipv4Socket);
        port = ntohs(((struct sockaddr_in *) [addr bytes])->sin_port);
    }
    
    // IPv6 socket
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(port);
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    
    if (CFSocketSetAddress(ipv6Socket, (CFDataRef) [NSData dataWithBytes:&addr6 length:sizeof(addr6)]) != kCFSocketSuccess) {
        TcpErrorDelegate(self, TcpErrorConnectionFailed, @"Failed opening IPv6 socket");
        [self close];
        return;
    }
    
    // Set up the run loop sources for the sockets.
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4Socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
    CFRelease(source4);
    
    CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv6Socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopCommonModes);
    CFRelease(source6);
}

-(void) close {
    if(!ipv4Socket && !ipv6Socket) {
        return;
    }
    
    if(ipv4Socket) {
        CFSocketInvalidate(ipv4Socket);
        CFRelease(ipv4Socket);
    }
    if(ipv6Socket) {
        CFSocketInvalidate(ipv6Socket);
        CFRelease(ipv6Socket);
    }
    
    ipv4Socket = nil;
    ipv6Socket = nil;
    
    [[self delegate] serverDidClose:self];
}

-(void) setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

-(void) acceptConnection:(CFSocketNativeHandle)handle {
    CFReadStreamRef read;
    CFWriteStreamRef write;
    
    CFStreamCreatePairWithSocket(NULL, handle, &read, &write);
    
    if(read && write) {
        // Close and release native socket when the stream is released
        CFReadStreamSetProperty(read, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(write, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        NSOutputStream *outs = (NSOutputStream *) write;
        NSInputStream *ins = (NSInputStream *) read;
        
        TcpConnection *connection = [[TcpConnection alloc] initWithInputStream:ins outputStream:outs];
        
        [connection open];
        
        [[self delegate] server:self acceptedConnection:connection];
        
        [connection release];
    } else {
        close(handle);
    }
    
    if(read) CFRelease(read);
    if(write) CFRelease(write);
}

-(void) dealloc {
    [self close];
    [super dealloc];
}
@end
