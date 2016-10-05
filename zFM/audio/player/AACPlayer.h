//
//  AACPlayer.h
//  zFM
//
//  Created by zykhbl on 16-10-05.
//  Copyright (c) 2014年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define KCanNewOpenStream 5
#define KNumAQBufs 6 //必须为大于KCanNewOpenStream的偶数
#define KAQMaxPacketDescs 1024
#define KAQDefaultBufSize 1024
#define KAQBufSize 1024

struct PlayAudioData {
	AudioFileStreamID audioFileStream;
    AudioStreamBasicDescription asbd;
	AudioQueueRef audioQueue;
	AudioQueueBufferRef audioQueueBuffer[KNumAQBufs];
	AudioStreamPacketDescription packetDescs[KAQMaxPacketDescs];
	
	unsigned int fillBufferIndex;
	size_t bytesFilled;
	size_t packetsFilled;
    
	bool inuse[KNumAQBufs];
    NSInteger buffersUsed;
	bool started;
	bool failed;
    
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	pthread_cond_t done;
    
    bool isOpenedAudioQueue;
};

typedef struct PlayAudioData PlayAudioData;

@interface AACPlayer : NSObject {
    PlayAudioData *playAudio;
}

- (NSData*)adtsDataForPacketLength:(NSUInteger)packetLength;
- (void)openAudio;
- (void)playAudio:(char *)buf len:(int)n;
- (UInt32)getmBytesPerFrame;

@end
