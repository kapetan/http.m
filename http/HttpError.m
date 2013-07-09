//
//  HttpError.m
//  http
//
//  Created by Mirza Kapetanovic on 7/3/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import "HttpError.h"

NSString *const HttpErrorDomain = @"default.http";

NSError *NSErrorWithReason(NSInteger code, NSString *reason) {
    NSDictionary *info = @{ NSLocalizedDescriptionKey : reason };
    return [NSError errorWithDomain:HttpErrorDomain code:code userInfo:info];
}