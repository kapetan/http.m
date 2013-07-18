//
//  HttpUrl.m
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpUrl.h"

#define IsEmpty(obj) obj == (id)[NSNull null] || !obj || ![obj length]

NSString *UrlEncode(NSString *str) {
    if(IsEmpty(str)) return @"";
    
    str = (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) str,
                                                                NULL, CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8);
    
    return [str autorelease];
}

NSString *UrlDecode(NSString *str) {
    if(IsEmpty(str)) return @"";
    
    return [[str stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

NSDictionary *ParseQuery(NSString *search) {
    if([search hasPrefix:@"?"]) {
        search = [search substringFromIndex:1];
    }
    if(IsEmpty(search)) {
        return [NSDictionary dictionary];
    }
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSArray *pairs = [search componentsSeparatedByString:@"&"];
    
    for(NSString *p in pairs) {
        NSArray *pair = [p componentsSeparatedByString:@"="];
        id value = [pair count] < 2 || ![[pair objectAtIndex:1] length] ? [NSNull null] : UrlDecode([pair objectAtIndex:1]);
        
        [result setObject:value forKey:UrlDecode([pair objectAtIndex:0])];
    }

    return [result autorelease];
}

NSString *SerializeQuery(NSDictionary *query) {
    NSMutableArray *result = [NSMutableArray array];
    
    for(NSString *key in query) {
        NSString *pair = [NSString stringWithFormat:@"%@=%@", UrlEncode(key), UrlEncode([query objectForKey:key])];
        [result addObject:pair];
    }
    
    return [result componentsJoinedByString:@"&"];
}

@implementation HttpUrl
@synthesize href;
@synthesize pathname;
@synthesize search;
@synthesize query;

-(id) init {
    if(self = [super init]) {
        self->href = @"/";
        self->pathname = @"/";
        self->search = nil;
        self->query = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(id) initWithString:(NSString *)url {
    if(self = [super init]) {
        self->href = [url copy];
        
        NSRange questionmark = [url rangeOfString:@"?"];
        
        if(questionmark.location == NSNotFound) {
            self->pathname = [url copy];
            self->search = nil;
        } else {
            self->pathname = [[url substringToIndex:questionmark.location] retain];
            self->search = [[url substringFromIndex:questionmark.location] retain];
        }
        
        if(self->search) {
            self->query = [[NSMutableDictionary alloc] initWithDictionary:ParseQuery(self->search)];
        } else {
            self->query = [[NSMutableDictionary alloc] init];
        }
    }
    
    return self;
}

-(id) initWithPathname:(NSString *)path query:(NSDictionary *)q {
    if(self = [self init]) {
        self->pathname = [path retain];
        self->query = [[NSMutableDictionary alloc] initWithDictionary:q];
    }
    
    return self;
}

-(id) initWithPathname:(NSString *)pathname {
    return [self initWithPathname:pathname query:[NSDictionary dictionary]];
}

-(NSString *) serialize {
    return [query count] ? [NSString stringWithFormat:@"%@?%@", pathname, SerializeQuery(query)] :
                            [[pathname copy] autorelease];
}

-(NSString *) description {
    return [self serialize];
}

-(void) dealloc {
    [href release];
    [pathname release];
    [search release];
    [query release];
    
    [super dealloc];
}
@end
