//
//  SDWMusicBTManager.m
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//
@import CoreBluetooth;
#import "SDWMusicBTManager.h"
#import "SDWMusicManager.h"
#import "Utils.h"


NSString * const SongIDCharacteristicID = @"7E56";
NSString * const SongInfoCharacteristicID = @"7E55";
NSString * const PhoneNameCharacteristicID = @"7E53";
NSString * const SongElapsedTimeCharacteristicID = @"7E52";

@interface SDWMusicBTManager () <SDWMusicManagerDelegate>

@property SDWMusicManager *musicManager;

// music

@property (strong) CBMutableCharacteristic *songInfoCharacteristic;
@property (strong) CBMutableCharacteristic *songIDCharacteristic;
@property (strong) CBMutableCharacteristic *songElapsedTimeCharacteristic;

@property (strong) CBMutableCharacteristic *phoneInfoCharacteristic;

@end

@implementation SDWMusicBTManager


#pragma mark - API

- (void)updateTrackToCurrent {
    [self musicDidChangeTrack];
}

- (void)syncCurrentTrackWithDeviceInfo:(SDWDeviceInfo *)deviceInfo {

    [self.musicManager playItemWithID:deviceInfo.songID beginFrom:deviceInfo.songElapsedTime];
    
}

#pragma mark - SDWMusicManagerDelegate

- (void)musicDidChangeTrack {

    if (self.mainInfoService.characteristics) {
        [self sendValue:[self.musicManager currentTrack] forCharacteristic:self.songInfoCharacteristic];
        [self sendValue:[self.musicManager currentTrackID] forCharacteristic:self.songIDCharacteristic];
        [self sendValue:[Utils phoneName] forCharacteristic:self.phoneInfoCharacteristic];
        [self sendValue:[self.musicManager elapsedTime] forCharacteristic:self.songElapsedTimeCharacteristic];
    }
}


#pragma mark - Setup

- (void)setup {

    [super setup];

    self.musicManager = [SDWMusicManager new];
    self.musicManager.delegate = self;

}

- (NSArray *)publish {

    self.songElapsedTimeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SongElapsedTimeCharacteristicID]
                                                                            properties:CBCharacteristicPropertyNotify
                                                                                 value:nil
                                                                           permissions:CBAttributePermissionsReadable];

    self.phoneInfoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PhoneNameCharacteristicID]
                                                                      properties:CBCharacteristicPropertyNotify
                                                                           value:nil
                                                                     permissions:CBAttributePermissionsReadable];

    self.songIDCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SongIDCharacteristicID]
                                                                   properties:CBCharacteristicPropertyNotify
                                                                        value:nil
                                                                  permissions:CBAttributePermissionsReadable];

    self.songInfoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:SongInfoCharacteristicID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];


    return @[self.songInfoCharacteristic,self.phoneInfoCharacteristic,self.songIDCharacteristic,self.songElapsedTimeCharacteristic];
}


- (NSArray *)subscribe {

    return @[
             self.songInfoCharacteristic.UUID,
             self.phoneInfoCharacteristic.UUID,
             self.songIDCharacteristic.UUID,
             self.songElapsedTimeCharacteristic.UUID
             ];
}




#pragma mark - Parse data

- (void)didUpdateCharacteristicValue {

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

        [deviceInfoObjects addObject:info];
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
