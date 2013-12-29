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

#define ONCE(guard) \
    if(guard) return; \
    guard = YES;

@implementation TcpConnection {
    NSOutputStream *output;
    NSInputStream *input;
    NSMutableData *buffer;
    
    NSInteger bufferPosition;
    
    NSInteger open;
    BOOL hasSpaceAvailable;
    BOOL bufferFull;
    
    BOOL destroyed;
    BOOL outputDestroyed;
    BOOL inputDestroyed;
}

@synthesize delegate;
@synthesize ended;
@synthesize finished;

-(id)init {
    if(self = [super init]) {
        self->input = nil;
        self->output = nil;
        self->buffer = [[NSMutableData alloc] initWithCapacity:TcpConnectionBufferLength];
        
        self->bufferPosition = 0;
        self->delegate = nil;
        self->ended = NO;
        self->finished = NO;
        
        self->open = 0;
        self->hasSpaceAvailable = NO;
        self->bufferFull = NO;
        
        self->destroyed = NO;
        self->outputDestroyed = NO;
        self->inputDestroyed = NO;
    }
    
    return self;
}

-(id)initWithInputStream:(NSInputStream *)ins outputStream:(NSOutputStream *)outs {
    if(self = [self init]) {
        self->input = [ins retain];
        self->output = [outs retain];
    }
    
    return self;
}

-(id) initWithHost:(NSString *)host port:(NSInteger)port {
    if(self = [self init]) {
        CFReadStreamRef read;
        CFWriteStreamRef write;
        
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) host, (UInt32) port, &read, &write);
        
        self->input = (NSInputStream *) read;
        self->output = (NSOutputStream *) write;
    }
    
    return self;
}

-(NSUInteger) bufferSize {
    return buffer.length;
}

-(void) open {
    for (NSStream *stream in @[input, output]) {
        [stream setDelegate:self];
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [stream open];
    }
}

-(void) destroy {
    ONCE(destroyed);
    
    [self destroyInput];
    [self destroyOutput];
    
    [self.delegate connectionDidClose:self];
}

-(void) destroyOutput {
    ONCE(outputDestroyed);
    
    if([output streamStatus] != NSStreamStatusClosed) {
        [output setDelegate:nil];
        [output close];
        [output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    if(inputDestroyed) {
        [self destroy];
    }
}

-(void) destroyInput {
    ONCE(inputDestroyed);
    
    if([input streamStatus] != NSStreamStatusClosed) {
        [input setDelegate:nil];
        [input close];
        [input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    if(outputDestroyed) {
        [self destroy];
    }
}

-(void) end {
    ONCE(ended);
    
    if(!buffer.length) {
        finished = YES;
        [self.delegate connectionDidFinish:self];
        [self destroyOutput];
    }
}

-(BOOL) write:(uint8_t *)data length:(NSUInteger)length {
    if(length) {
        [buffer appendBytes:data length:length];
        
        if(hasSpaceAvailable) {
            [self writeBuffer];
        }
    }
    
    BOOL mark = buffer.length <= TcpConnectionBufferLength;
    bufferFull = bufferFull || !mark;
    
    return mark;
}

-(BOOL) write:(NSData *)data {
    return [self write:(uint8_t *)[data bytes] length:data.length];
}

-(BOOL) write:(NSString *)data encoding:(NSStringEncoding)encoding {
    return [self write:[data dataUsingEncoding:encoding]];
}

-(void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            if(++open == 2) {
                [self.delegate connectionDidOpen:self];
            }
            
            break;
        case NSStreamEventHasBytesAvailable:
            if(aStream == input) {
                uint8_t buf[TcpConnectionIOBufferLength];
                NSInteger len = [input read:buf maxLength:TcpConnectionIOBufferLength];
                
                if(len > 0) {
                    NSData *data = [[NSData alloc] initWithBytes:buf length:len];
                    [self.delegate connection:self didReceiveData:data];
                    
                    [data release];
                }
            }
            
            break;
        case NSStreamEventHasSpaceAvailable:
            if(aStream == output) {
                if(buffer.length) {
                    [self writeBuffer];
                    
                    if(bufferFull && !bufferPosition) {
                        bufferFull = NO;
                        [self.delegate connectionDidDrain:self];
                    }
                    if(ended && !bufferPosition) {
                        finished = YES;
                        [self.delegate connectionDidFinish:self];
                        [self destroyOutput];
                    }
                } else {
                    hasSpaceAvailable = YES;
                }
            }
            
            break;
        case NSStreamEventErrorOccurred: {
            NSError *err = [aStream streamError];
            [self.delegate connection:self errorOccurred:err];
            
            [self destroy];
            
            break;
        }
        case NSStreamEventEndEncountered:
            if(aStream == output) {
                [self destroyOutput];
            }
            if(aStream == input) {
                [self.delegate connectionDidEnd:self];
                [self destroyInput];
            }
            
            break;
        case NSStreamEventNone:
            break;
    }
}

-(void) writeBuffer {
    uint8_t *from = ((uint8_t *) [buffer mutableBytes]) + bufferPosition;
    NSUInteger bufferLength = buffer.length;
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
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self.delegate selector:@selector(connectionDidSendData:) object:self];
    [self.delegate performSelector:@selector(connectionDidSendData:) withObject:self afterDelay:0];
}

-(void)dealloc {
    self.delegate = nil;
    
    [self destroy];
    
    [buffer release];
    [input release];
    [output release];
    
    [super dealloc];
}
@end
