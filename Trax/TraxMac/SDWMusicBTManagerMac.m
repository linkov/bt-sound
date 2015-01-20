//
//  SDWMusicBTManagerMac.m
//  Trax
//
//  Created by alex on 1/19/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//



#import "SDWMusicBTManagerMac.h"
#import "SDWDeviceInfo.h"

NSString * const SongIDCharacteristicID = @"7E56";
NSString * const SongInfoCharacteristicID = @"7E55";
NSString * const PhoneNameCharacteristicID = @"7E53";
NSString * const SongElapsedTimeCharacteristicID = @"7E52";

@interface SDWMusicBTManagerMac ()

// music

@property (strong) CBMutableCharacteristic *songInfoCharacteristic;
@property (strong) CBMutableCharacteristic *songIDCharacteristic;
@property (strong) CBMutableCharacteristic *songElapsedTimeCharacteristic;

@property (strong) CBMutableCharacteristic *phoneInfoCharacteristic;

@end

@implementation SDWMusicBTManagerMac


- (NSArray *)subscribe {

    return @[
             [CBUUID UUIDWithString:SongInfoCharacteristicID],
             [CBUUID UUIDWithString:PhoneNameCharacteristicID],
             [CBUUID UUIDWithString:SongIDCharacteristicID],
             [CBUUID UUIDWithString:SongElapsedTimeCharacteristicID]
             ];
}

- (void)didUpdateCharacteristicValue {

    NSLog(@"self.discoveredDevices - %@",self.discoveredDevices);

    NSMutableArray *deviceInfoObjects = [[NSMutableArray alloc]initWithCapacity:self.discoveredDevices.count];

    for (CBPeripheral *per in self.discoveredDevices) {


        SDWDeviceInfo *info = [SDWDeviceInfo new];


        for (CBService *ser in per.services) {

            for (CBCharacteristic *ch in ser.characteristics) {


                //NSLog(@"ch.UUID.UUIDString - %@",ch.UUID.UUIDString);

                if ([ch.UUID.UUIDString isEqualToString:SongIDCharacteristicID]) {
                    NSString *sID = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.songID = [NSNumber numberWithLongLong:[sID longLongValue]];
                }

                if ([ch.UUID.UUIDString isEqualToString:SongElapsedTimeCharacteristicID]) {
                    NSString *sID = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.songElapsedTime = [NSNumber numberWithLongLong:[sID longLongValue]];
                }

                if ([ch.UUID.UUIDString isEqualToString:PhoneNameCharacteristicID]) {
                    NSString *sID = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.deviceName = sID;
                }

                if ([ch.UUID.UUIDString isEqualToString:SongInfoCharacteristicID]) {
                    NSString *printable = [[NSString alloc] initWithData:ch.value encoding:NSUTF8StringEncoding];
                    info.songInfo = printable;
                }


            }
        }
        
    }

    for (SDWDeviceInfo *info in deviceInfoObjects) {

        NSLog(@"trackID - %@",info.songID);
        NSLog(@"trackName - %@",info.songInfo);
        NSLog(@"trackElapsed - %f",[info.songInfo doubleValue]);
        NSLog(@"deviceName - %@",info.deviceName);
    }
    
    [self.delegate managerDidPopulateData:deviceInfoObjects];
    
}

@end
