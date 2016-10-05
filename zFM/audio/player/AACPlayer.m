//
//  AACPlayer.h
//  zFM
//
//  Created by zykhbl on 16-10-05.
//  Copyright (c) 2014年 zykhbl. All rights reserved.
//

#import "AACPlayer.h"
#import <AVFoundation/AVFoundation.h>
#include <pthread.h>

@implementation AACPlayer

- (void)clearAudioPlay {
    if (playAudio != NULL) {
        AudioQueueFlush(playAudio->audioQueue);
        
        AudioQueueStop(playAudio->audioQueue, false);
        
        pthread_mutex_lock(&playAudio->mutex);
        pthread_cond_wait(&playAudio->done, &playAudio->mutex);
        pthread_mutex_unlock(&playAudio->mutex);
        
        AudioFileStreamClose(playAudio->audioFileStream);
        AudioQueueDispose(playAudio->audioQueue, false);
        free(playAudio);
    }
}

- (void)dealloc {    
    [self clearAudioPlay];
}

- (NSData*)adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = (char*)malloc(sizeof(char) * adtsLength);
    int profile = 2;
    int freqIdx = 4;  //44100
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    packet[0] = (char)0xFF;	// 11111111  	= syncword
    packet[1] = (char)0xF9;	// 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile - 1) << 6) + (freqIdx << 2) + (chanCfg >> 2));
    packet[3] = (char)(((chanCfg & 3) << 6) + (fullLength >> 11));
    packet[4] = (char)((fullLength & 0x7FF) >> 3);
    packet[5] = (char)(((fullLength & 7) << 5) + 0x1F);
    packet[6] = (char)0xFC;
    
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    free(packet);
    
    return data;
}

- (void)openAudio {
    if (playAudio == NULL) {
        playAudio = (PlayAudioData*)calloc(1, sizeof(PlayAudioData));
        
        pthread_mutex_init(&playAudio->mutex, NULL);
        pthread_cond_init(&playAudio->cond, NULL);
        pthread_cond_init(&playAudio->done, NULL);
        
        OSStatus err = noErr;
        err = AudioFileStreamOpen((__bridge void *)(self), MyPropertyListenerProc, MyPacketsProc, kAudioFileAAC_ADTSType, &playAudio->audioFileStream);
        if (err) { printf("AudioFileStream open error!!\n"); }
    }
}

- (void)playAudio:(char *)buf len:(int)n {
    OSStatus err = noErr;
    err = AudioFileStreamParseBytes(playAudio->audioFileStream, n, buf, 0);
    if (err) { printf("AudioFileStream parseBytes error!!\n"); }
}

- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID ioFlags:(UInt32*)ioFlags {
    OSStatus err = noErr;
    
    if (!playAudio->isOpenedAudioQueue) {
        switch (inPropertyID) {
            case kAudioFileStreamProperty_DataFormat : {
                UInt32 asbdSize = sizeof(playAudio->asbd);
                err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &playAudio->asbd);
                if (err) { printf("AudioDileStream getProperty error!!\n"); playAudio->failed = true; break; }
                
                err = AudioQueueNewOutput(&playAudio->asbd, MyAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &playAudio->audioQueue);
                if (err) { printf("AudioQueue newOutput error!!\n"); playAudio->failed = true; break; }
                
                for (unsigned int i = 0; i < KNumAQBufs; ++i) {
                    err = AudioQueueAllocateBuffer(playAudio->audioQueue, KAQBufSize, &playAudio->audioQueueBuffer[i]);
                    if (err) { printf("AudioQueue allocateBuffer error!!\n"); playAudio->failed = true; break; }
                }
                
                UInt32 cookieSize;
                Boolean writable;
                err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
                if (err) { printf("AudioDileStream getPropertyInfo error!!\n"); break; }
                
                void* cookieData = calloc(1, cookieSize);
                err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
                if (err) { printf("AudioDileStream getProperty error!!\n"); free(cookieData); break; }
                
                err = AudioQueueSetProperty(playAudio->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
                free(cookieData);
                if (err) { printf("AudioQueue setProperty error!!\n"); break; }
                
                Float32 gain = 1.0;
                AudioQueueSetParameter(playAudio->audioQueue, kAudioQueueParam_Volume, gain);
                
                err = AudioQueueAddPropertyListener(playAudio->audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, (__bridge void *)(self));
                if (err) { printf("AudioQueue addPropertyListener error!!\n"); playAudio->failed = true; break; }
                
                playAudio->isOpenedAudioQueue = true;
                
                break;
            }
            case kAudioFileStreamProperty_FormatList: {
                Boolean outWriteable;
                UInt32 formatListSize;
                err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
                if (err) { printf("AudioQueue AudioFileStreamGetPropertyInfo error!!\n"); playAudio->failed = true; break; }
                
                AudioFormatListItem *formatList = malloc(formatListSize);
                err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
                if (err) { printf("AudioQueue AudioFileStreamGetProperty error!!\n"); playAudio->failed = true; break; }
                
                for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem)) {
                    AudioStreamBasicDescription pasbd = formatList[i].mASBD;
                    if (pasbd.mFormatID == kAudioFormatMPEG4AAC_HE || pasbd.mFormatID == kAudioFormatMPEG4AAC_HE_V2) {
                        playAudio->asbd = pasbd;
                        break;
                    }
                }
                free(formatList);
                
                break;
            }
        }
    }
}

void MyPropertyListenerProc(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags) {
	AACPlayer *player = (__bridge AACPlayer*)inClientData;
    [player handlePropertyChangeForFileStream:inAudioFileStream fileStreamPropertyID:inPropertyID ioFlags:ioFlags];
}

- (void)handleAudioPackets:(const void*)inInputData numberBytes:(UInt32)inNumberBytes numberPackets:(UInt32)inNumberPackets packetDescriptions:(AudioStreamPacketDescription*)inPacketDescriptions {
    if (inPacketDescriptions) {
        for (int i = 0; i < inNumberPackets; ++i) {
            size_t packetOffset, packetSize;
            size_t bufSpaceRemaining, packetsDescsRemaining;
            packetOffset = (size_t)inPacketDescriptions[i].mStartOffset;
            packetSize = inPacketDescriptions[i].mDataByteSize;
            
            bufSpaceRemaining = KAQBufSize - playAudio->bytesFilled;
            
            if (bufSpaceRemaining < packetSize) {
                [self enqueueBuffer];
            }
            
            bufSpaceRemaining = KAQBufSize - playAudio->bytesFilled;
            if (bufSpaceRemaining < packetSize) {
                return;
            }
            
            AudioQueueBufferRef fillBuf = playAudio->audioQueueBuffer[playAudio->fillBufferIndex];
            memcpy((char*)fillBuf->mAudioData + playAudio->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
            playAudio->packetDescs[playAudio->packetsFilled] = inPacketDescriptions[i];
            playAudio->packetDescs[playAudio->packetsFilled].mStartOffset = playAudio->bytesFilled;
            playAudio->bytesFilled += packetSize;
            playAudio->packetsFilled += 1;
            
            packetsDescsRemaining = KAQMaxPacketDescs - playAudio->packetsFilled;
            
            if (packetsDescsRemaining == 0) {
                [self enqueueBuffer];
            }
        }
    } else {
        printf("the following code assumes we're streaming CBR data.");
    }
}

void MyPacketsProc(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions) {
    AACPlayer *player = (__bridge AACPlayer*)inClientData;
    [player handleAudioPackets:inInputData numberBytes:inNumberBytes numberPackets:inNumberPackets packetDescriptions:inPacketDescriptions];
}

- (OSStatus)startQueueIfNeeded {
    OSStatus err = noErr;
    if (!playAudio->started || playAudio->buffersUsed == KNumAQBufs-1) {
        err = AudioQueueStart(playAudio->audioQueue, NULL);
        if (err) { printf("AudioQueue start error!!\n"); playAudio->failed = true; return err; }
        playAudio->started = true;
    }
    return err;
}

- (void)waitForFreeBuffer {
    if (++playAudio->fillBufferIndex >= KNumAQBufs) playAudio->fillBufferIndex = 0;
    playAudio->bytesFilled = 0;
    playAudio->packetsFilled = 0;
    
    pthread_mutex_lock(&playAudio->mutex);
    while(playAudio->inuse[playAudio->fillBufferIndex]) {
        pthread_cond_wait(&playAudio->cond, &playAudio->mutex);
    }
    pthread_mutex_unlock(&playAudio->mutex);
}

- (OSStatus)enqueueBuffer {
    OSStatus err = noErr;
    playAudio->inuse[playAudio->fillBufferIndex] = true;
    playAudio->buffersUsed++;
    
    AudioQueueBufferRef fillBuf = playAudio->audioQueueBuffer[playAudio->fillBufferIndex];
    fillBuf->mAudioDataByteSize = playAudio->bytesFilled;
    err = AudioQueueEnqueueBuffer(playAudio->audioQueue, fillBuf, playAudio->packetsFilled, playAudio->packetDescs);
    if (err) { printf("AudioQueue enqueueBuffer error!!\n"); playAudio->failed = true; return err; }
    
    [self startQueueIfNeeded];
    
    [self waitForFreeBuffer];
    
    return err;
}

- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer {
    for (int i = 0; i < KNumAQBufs; ++i) {
        if (inBuffer == playAudio->audioQueueBuffer[i])
            return i;
    }
    return -1;
}

- (void)audioQueueOutputCallback:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer {
    int bufIndex = [self findQueueBuffer:inBuffer];
    
    if(bufIndex == -1) {
        pthread_mutex_lock(&playAudio->mutex);
        pthread_cond_signal(&playAudio->cond);
        pthread_mutex_unlock(&playAudio->mutex);
    } else {
        pthread_mutex_lock(&playAudio->mutex);
        playAudio->inuse[bufIndex] = false;
        playAudio->buffersUsed--;
        pthread_cond_signal(&playAudio->cond);
        pthread_mutex_unlock(&playAudio->mutex);
    }
}

void MyAudioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
	AACPlayer *player = (__bridge AACPlayer*)inClientData;
    [player audioQueueOutputCallback:inAQ inBuffer:inBuffer];
}

- (void)audioQueueIsRunningCallback:(AudioQueueRef)inAQ propertyID:(AudioQueuePropertyID)inID {
    UInt32 running;
    UInt32 size;
    OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &running, &size);
    if (err) { printf("AudioQueue getProperty error!!\n"); return; }
    if (!running) {
        pthread_mutex_lock(&playAudio->mutex);
        pthread_cond_signal(&playAudio->done);
        pthread_mutex_unlock(&playAudio->mutex);
    }
}

void MyAudioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ, AudioQueuePropertyID	inID) {
	AACPlayer *player = (__bridge AACPlayer*)inClientData;
	[player audioQueueIsRunningCallback:inAQ propertyID:inID];
}

- (UInt32)getmBytesPerFrame {
    printf("mFramesPerPacket: %ld\n", playAudio->asbd.mFramesPerPacket);
    return playAudio->asbd.mFramesPerPacket;
}

@end
