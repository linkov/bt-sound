//
//  SDWMusicManager.m
//  Trax
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//
@import MediaPlayer;
#import "SDWMusicManager.h"

@implementation SDWMusicManager

- (instancetype)init {

    self = [super init];
    if (self) {

        [self setup];
    }
    return self;
}

- (void)dealloc {
    [[MPMusicPlayerController systemMusicPlayer] endGeneratingPlaybackNotifications];
}

- (void)setup {

    [[MPMusicPlayerController systemMusicPlayer] beginGeneratingPlaybackNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidChange:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
}



- (void)trackDidChange:(NSNotification *)note {

    [self.delegate musicDidChangeTrack];
}



- (void)playItemWithID:(NSNumber *)itemID beginFrom:(NSNumber *)elapsedTime {

    //MPNowPlayingInfoPropertyElapsedPlaybackTime and MPMediaItemPropertyPlaybackDuration.

    MPMediaPredicate *filter = [MPMediaPropertyPredicate predicateWithValue:itemID forProperty:MPMediaItemPropertyPersistentID];
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:filter]];
    NSArray *songs = [songQuery items]; // [songs count] is zero here
    NSLog(@"found songs - %@",songs);

    //    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    //    [everything addFilterPredicate:nil]
    //    NSArray *itemsFromGenericQuery = [everything items];
    //
    //    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];
    //
    //    MPMediaItemCollection *collection = [[MPMediaItemCollection alloc] initWithItems:@[item]];
    ////    MPMediaItem *item = [collection representativeItem];
    //
    //
    //    [iPodMusicPlayerController setQueueWithItemCollection:collection];
    //    [iPodMusicPlayerController setNowPlayingItem:item];
    //
    //    [iPodMusicPlayerController prepareToPlay];
    //    [iPodMusicPlayerController play];
}

- (NSString *)elapsedTime {

    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];

    double nowPlayingItemDuration = [[[iPodMusicPlayerController nowPlayingItem] valueForProperty:MPMediaItemPropertyPlaybackDuration]doubleValue];
    double currentTime = (double) [iPodMusicPlayerController currentPlaybackTime];
    double remainingTime = nowPlayingItemDuration - currentTime;


    NSNumber *tID = [NSNumber numberWithDouble:remainingTime];
    return [tID stringValue];
}

- (NSString *)currentTrackID {

    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];
    MPMediaItem *nowPlayingItem = [iPodMusicPlayerController nowPlayingItem];
    NSNumber *tID = [nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID];
    return [tID stringValue];
}

- (NSString *)currentTrack {

    NSString *track;

    MPMusicPlayerController *iPodMusicPlayerController = [MPMusicPlayerController systemMusicPlayer];

    MPMediaItem *nowPlayingItem = [iPodMusicPlayerController nowPlayingItem];

    if(nowPlayingItem)
    {
        NSString *itemTitle = [nowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
        NSString *itemArtist = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtist];
        track = [NSString stringWithFormat:@"%@-%@",itemArtist,itemTitle];
        
    }else {
        track = @"nothing";
    }
    
    return track;
}


@end
