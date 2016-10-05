//
//  AACToPCM.m
//  zFM
//
//  Created by zykhbl on 16-10-4.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AACToPCM.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CAXException.h"
#import "CAStreamBasicDescription.h"
#import "rtmp.h"

#define kDefaultSize        1024 * 20

@interface AACToPCM ()

@property (nonatomic, assign) AudioConverterRef converter;
@property (nonatomic, assign) UInt32 maxPacketSize;
@property (nonatomic, assign) char *outputBuffer;
@property (nonatomic, assign) AudioStreamPacketDescription *outputPacketDescriptions;

@end

@implementation AACToPCM

@synthesize converter;
@synthesize maxPacketSize;
@synthesize outputBuffer;
@synthesize outputPacketDescriptions;

- (void)dealloc {
    if (self.converter) {
        AudioConverterDispose(self.converter);
    }
    
    if (self.outputBuffer) {
        delete [] self.outputBuffer;
    }
    
    if (self.outputPacketDescriptions) {
        delete [] self.outputPacketDescriptions;
    }
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.converter = 0;
        self.maxPacketSize = 0;
        self.outputBuffer = NULL;
        self.outputPacketDescriptions = NULL;
    }
    
    return self;
}

- (void)createConverter {
    try {
        AudioStreamBasicDescription sourceDes, targetDes;
        
        memset(&sourceDes, 0, sizeof(sourceDes));
        sourceDes.mSampleRate = SAMPLERATE;
        sourceDes.mFormatID = kAudioFormatMPEG4AAC;
        sourceDes.mChannelsPerFrame = 1;
        UInt32 size = sizeof(sourceDes);
        XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &sourceDes), "couldnt create target data format");
        
        targetDes.mSampleRate = SAMPLERATE;
        targetDes.mFormatID = kAudioFormatLinearPCM;
        targetDes.mChannelsPerFrame = 1;
        targetDes.mBitsPerChannel = 16;
        targetDes.mBytesPerPacket = targetDes.mBytesPerFrame = 2 * targetDes.mChannelsPerFrame;
        targetDes.mFramesPerPacket = 1;
        targetDes.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
        
        XThrowIfError(AudioConverterNew(&sourceDes, &targetDes, &converter), "cant new convertRef");
        
        size = sizeof(sourceDes);
        XThrowIfError(AudioConverterGetProperty(self.converter, kAudioConverterCurrentInputStreamDescription, &size, &sourceDes), "cant get kAudioConverterCurrentInputStreamDescription");
        
        size = sizeof(targetDes);
        XThrowIfError(AudioConverterGetProperty(self.converter, kAudioConverterCurrentOutputStreamDescription, &size, &targetDes), "cant get kAudioConverterCurrentOutputStreamDescription");
        
        size = sizeof(self.maxPacketSize);
        XThrowIfError(AudioConverterGetProperty(self.converter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &maxPacketSize), "cant get max size of packet");
        self.outputBuffer = new char[kDefaultSize];
        memset(self.outputBuffer, 0, kDefaultSize);
        
        self.outputPacketDescriptions = new AudioStreamPacketDescription [kDefaultSize / self.maxPacketSize];
    } catch (CAXException e) {
		char buf[256];
		NSLog(@"Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
}

OSStatus AACToPCMComplexInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    AudioBufferList *aacBufferList = (AudioBufferList*)inUserData;
    ioData->mBuffers[0].mData = aacBufferList->mBuffers[0].mData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mDataByteSize = aacBufferList->mBuffers[0].mDataByteSize;
    *ioNumberDataPackets = 1;
    
    return 0;
}

- (NSMutableData*)convertAACToPCM:(void*)inInputData numberBytes:(UInt32)inNumberBytes {
    try {
        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0].mNumberChannels = 1;
        bufferList.mBuffers[0].mData = self.outputBuffer;
        bufferList.mBuffers[0].mDataByteSize = kDefaultSize;
        
        NSMutableData *audioData = [[NSMutableData alloc] init];
        NSData *adtsData = [self adtsDataForPacketLength:inNumberBytes];
        [audioData appendData:adtsData];
        [audioData appendBytes:inInputData length:inNumberBytes];
        
        AudioBufferList aacBufferList;
        aacBufferList.mBuffers[0].mData = (void*)audioData.bytes;
        aacBufferList.mBuffers[0].mDataByteSize = audioData.length;
        
        UInt32 packetSize = kDefaultSize / self.maxPacketSize;
        XThrowIfError(AudioConverterFillComplexBuffer(self.converter, AACToPCMComplexInputDataProc, &aacBufferList, &packetSize, &bufferList, self.outputPacketDescriptions), "cant set AudioConverterFillComplexBuffer");
        
        NSMutableData *audioData2 = [[NSMutableData alloc] init];
        [audioData2 appendBytes:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize];
        
        return audioData2;
    } catch (CAXException e) {
		char buf[256];
		NSLog(@"Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
    
    return nil;
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

@end
