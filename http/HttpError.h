//
//  HttpError.h
//  http
//
//  Created by Mirza Kapetanovic on 7/3/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const HttpErrorDomain;

enum {
    HttpErrorUnparsableHeader = 0,
    HttpErrorConnectionFailed,
};

NSError *NSErrorWithReason(NSInteger code, NSString *reason);