#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "mangopay.h"
#import "MPAPIClient.h"
#import "MPCardApiObject.h"
#import "MPCardInfoObject.h"

FOUNDATION_EXPORT double mangopayVersionNumber;
FOUNDATION_EXPORT const unsigned char mangopayVersionString[];

