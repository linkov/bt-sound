//
//  SDWBTManager.h
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SDWBTManagerCompletionBlock)(id object, NSError *error);


@interface SDWBTManager : NSObject


- (void)fetchNearbyDeviceDataWithCompletion:(SDWBTManagerCompletionBlock)block;
- (void)updateTrackToCurrent;


@end
