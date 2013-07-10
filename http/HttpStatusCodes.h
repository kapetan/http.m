//
//  HttpStatusCodes.h
//  http
//
//  Created by Mirza Kapetanovic on 7/9/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HttpStatusCodeContinue = 100,
    HttpStatusCodeSwitchingProtocols = 101,
    HttpStatusCodeProcessing = 102,
    HttpStatusCodeOk = 200,
    HttpStatusCodeCreated = 201,
    HttpStatusCodeAccepted = 202,
    HttpStatusCodeMultipleChoices = 300,
    HttpStatusCodeMovedPermanently = 301,
    HttpStatusCodeFound = 302,
    HttpStatusCodeSeeOther = 303,
    HttpStatusCodeNotModified = 304,
    HttpStatusCodeTemporaryRedirect = 307,
    HttpStatusCodePermanentRedirect = 308,
    HttpStatusCodeBadRequest = 400,
    HttpStatusCodeUnauthorized = 401,
    HttpStatusCodePaymentRequired = 402,
    HttpStatusCodeForbidden = 403,
    HttpStatusCodeNotFound = 404,
    HttpStatusCodeMethodNotAllowed = 405,
    HttpStatusCodeConflict = 409,
    HttpStatusCodeLengthRequired = 411,
    HttpStatusCodeInternalServerError = 500,
    HttpStatusCodeBadGateway = 501,
    HttpStatusCodeServiceUnavailable = 502,
    HttpStatusCodeHttpVersionNotSupported = 505
} HttpStatusCode;

NSString *const HttpStatusCodeReason[HttpStatusCodeHttpVersionNotSupported + 1];

NSString *HttpStatusCodeReasonPhrase(HttpStatusCode code);
