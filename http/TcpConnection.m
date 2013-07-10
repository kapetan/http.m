//
//  TcpConnection.m
//  http
//
//  Created by Mirza Kapetanovic on 7/8/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "TcpConnection.h"

NSUInteger const TcpConnectionBufferLength = 16 * 1024;
NSUInteger const TcpConnectionIOBufferLength = 4 * 1024;

void TcpConnectionReleaseDelegate(TcpConnection *connection) {
    if([connection.delegate isKindOfClass:[TcpConnectionBlockDelegate class]]) {
        [connection.delegate release];
    }
}

@implementation TcpConnectionBlockDelegate
-(void) connectionDidOpen:(TcpConnection *)connection {
    if(self.open) self.open(connection);
}

-(void) connectionDidDrain:(TcpConnection *)connection {
    if(self.drain) self.drain(connection);
}

-(void) connectionDidClose:(TcpConnection *)connection {
    if(self.close) self.close(connection);
}

-(void) connection:(TcpConnection *)connection errorOccurred:(NSError *)error {
    if(self.error) self.error(connection, error);
}

-(void) connection:(TcpConnection *)connection didReceiveData:(NSData *)data {
    if(self.data) self.data(connection, data);
}

-(void) dealloc {
    [self.open release];
    [self.drain release];
    [self.close release];
    [self.error release];
    [self.data release];
    
    [super dealloc];
}
@end

@implementation TcpConnection {
    NSOutputStream *output;
    NSInputStream *input;
    NSMutableData *buffer;
    
    NSInteger bufferPosition;
    
    NSInteger open;
    BOOL bufferFull;
    BOOL closeOnDrain;
}

@synthesize delegate;

-(id)init {
    if(self = [super init]) {
        self->input = nil;
        self->output = nil;
        self->buffer = [[NSMutableData alloc] initWithCapacity:TcpConnectionBufferLength];
        
        self->bufferPosition = 0;
        self->delegate = [[TcpConnectionBlockDelegate alloc] init];
        
        self->open = 0;
        self->bufferFull = NO;
        self->closeOnDrain = NO;
    }
    
    return self;
}

-(id)initWithInputStream:(NSInputStream *)ins outputStream:(NSOutputStream *)outs {
    if([self init]) {
        self->input = [ins retain];
        self->output = [outs retain];
    }
    
    return self;
}

-(id) initWithHost:(NSString *)host port:(NSInteger)port {
    if([self init]) {
        CFReadStreamRef read;
        CFWriteStreamRef write;
        
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) host, (UInt32) port, &read, &write);
        
        self->input = (NSInputStream *) read;
        self->output = (NSOutputStream *) write;
    }
    
    return self;
}

-(void) open {
    for (NSStream *stream in @[input, output]) {
        [stream setDelegate:self];
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [stream open];
    }
}

-(void) close {
    if([input streamStatus] == NSStreamStatusClosed || [output streamStatus] == NSStreamStatusClosed) {
        return;
    }
    
    for(NSStream *stream in @[input, output]) {
        [stream setDelegate:nil];
        [stream close];
        [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    [[self delegate] connectionDidClose:self];
}

-(void) closeAfterDrain {
    if(![buffer length]) {
        [self close];
    }
    
    closeOnDrain = YES;
}

-(BOOL) write:(uint8_t *)data length:(NSUInteger)length {
    if(length) {
        [buffer appendBytes:data length:length];
        
        if([output hasSpaceAvailable]) {
            [self writeBuffer];
        }
    }
    
    BOOL mark = [buffer length] <= TcpConnectionBufferLength;
    bufferFull = bufferFull || !mark;
    
    return mark;
}

-(BOOL) write:(NSData *)data {
    return [self write:(uint8_t *)[data bytes] length:[data length]];
}

-(BOOL) write:(NSString *)data encoding:(NSStringEncoding)encoding {
    return [self write:[data dataUsingEncoding:encoding]];
}

-(void) setDelegate:(id)newDelegate {
    TcpConnectionReleaseDelegate(self);
    delegate = newDelegate;
}

-(void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if(++open == 2) {
                [[self delegate] connectionDidOpen:self];
            }
            
            break;
        case NSStreamEventHasBytesAvailable:
            if(aStream == input) {
                uint8_t buf[TcpConnectionIOBufferLength];
                NSInteger len = [input read:buf maxLength:TcpConnectionIOBufferLength];
                
                if(len) {
                    NSData *data = [[NSData alloc] initWithBytes:buf length:len];
                    [[self delegate] connection:self didReceiveData:data];
                    
                    [data release];
                }
            }
            
            break;
        case NSStreamEventHasSpaceAvailable:
            if(aStream == output && [buffer length]) {
                [self writeBuffer];
                
                if(bufferFull && !bufferPosition) {
                    bufferFull = NO;
                    [[self delegate] connectionDidDrain:self];
                }
                if(closeOnDrain && !bufferPosition) {
                    [self close];
                }
            }
            
            break;
        case NSStreamEventErrorOccurred: {
            NSError *err = [aStream streamError];
            [[self delegate] connection:self errorOccurred:err];
        }
        case NSStreamEventEndEncountered:
            [self close];
            break;
        case NSStreamEventNone:
            break;
    }
}

-(void) writeBuffer {
    uint8_t *from = ((uint8_t *) [buffer mutableBytes]) + bufferPosition;
    NSUInteger bufferLength = [buffer length];
    NSInteger len = bufferLength - bufferPosition;
    
    len = len > TcpConnectionIOBufferLength ? TcpConnectionIOBufferLength : len;
    len = [output write:from maxLength:len];
    
    if(len <= 0) {
        // Error writing to stream or EOF
        return;
    }
    
    bufferPosition += len;
    
    if(bufferPosition == bufferLength) {
        bufferPosition = 0;
        [buffer setLength:0];
    }
}

-(void)dealloc {
    [self close];
    
    [buffer release];
    [input release];
    [output release];
    TcpConnectionReleaseDelegate(self);
    
    [super dealloc];
}
@end
