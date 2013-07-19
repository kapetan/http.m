//
//  HttpUrl.h
//  http
//
//  Created by Mirza Kapetanovic on 7/17/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *UrlEncode(NSString *str);
NSString *UrlDecode(NSString *str);

NSDictionary *ParseQuery(NSString *search);
NSString *SerializeQuery(NSDictionary *query);

@interface HttpUrl : NSObject
@property (readonly, nonatomic) NSString *href;
@property (readonly, nonatomic) NSString *pathname;
@property (readonly, nonatomic) NSString *search;
@property (readonly, nonatomic) NSDictionary *query;

-(id) initWithString:(NSString*)href;
-(id) initWithPathname:(NSString *)pathname query:(NSDictionary *)query;
-(id) initWithPathname:(NSString *)pathname;

-(NSString *) serialize;
@end
