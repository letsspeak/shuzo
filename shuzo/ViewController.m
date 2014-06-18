//
//  ViewController.m
//  shuzo
//
//  Created by Oomiya Masatsugu on 2014/06/18.
//  Copyright (c) 2014年 eveningsun. All rights reserved.
//

#import "ViewController.h"

#include <stdio.h>
#include <avcodec.h>
#include <avformat.h>
#include <imgutils.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    printf("Hello World!\n");
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"matsuoka_005" ofType:@"flv"];
    NSLog(@"path = %@\n", path);
    const char *filename = [path UTF8String];
    
    AVCodec *codec = NULL;
    AVCodecContext *c= NULL;
    AVPacket pkt;
    int i, out_size, size, x, y, got_output;
    FILE *f;
//    AVFrame *picture;
    AVFrame *frame;
    uint8_t *outbuf, *picture_buf;
    uint8_t endcode[] = { 0, 0, 1, 0xb7 };
    
    printf("Video encoding\n");
    
    printf("CODEC_ID_VP6F = %d\n", CODEC_ID_VP6F);
    
    /* find the mpeg1 video encoder */
    avcodec_register_all();
    while ((codec = av_codec_next((const AVCodec*)codec)) != NULL) {
        printf("codec name: %s (id = %d)\n", codec->name, codec->id);
        if (codec->id == CODEC_ID_VP6F) break;
    }

//    codec = avcodec_find_encoder(CODEC_ID_VP6F);
    if (!codec) {
        fprintf(stderr, "codec not found\n");
        exit(1);
    }
    
    c = avcodec_alloc_context3(codec);
    frame = av_frame_alloc();
//    picture= avcodec_alloc_frame(); // deprecated
    
    /* put sample parameters */
    c->bit_rate = 400000;
    /* resolution must be a multiple of two */
//    c->width = 352;
//    c->height = 288;
    c->width = 640;
    c->height = 468;
    /* frames per second */
    c->time_base= (AVRational){1,25};
    c->gop_size = 10; /* emit one intra frame every ten frames */
    c->max_b_frames=1;
    c->pix_fmt = PIX_FMT_YUV420P;
    
//    /* open it */
//    if (avcodec_open2(c, codec, NULL) < 0) {
//        fprintf(stderr, "could not open codec\n");
//        exit(1);
//    }
//    
//    f = fopen(filename, "wb");
//    if (!f) {
//        fprintf(stderr, "could not open %s\n", filename);
//        exit(1);
//    }
//    
//    /* alloc image and output buffer */
//    outbuf_size = 10000000;
//    outbuf = malloc(outbuf_size);
//    size = c->width * c->height;
//    picture_buf = malloc((size * 3) / 2); /* size for YUV 420 */
//    
//    picture->data[0] = picture_buf;
//    picture->data[1] = picture->data[0] + size;
//    picture->data[2] = picture->data[1] + size / 4;
//    picture->linesize[0] = c->width;
//    picture->linesize[1] = c->width / 2;
//    picture->linesize[2] = c->width / 2;
//    
//    /* encode 1 second of video */
//    for(i=0;i<25;i++) {
//        fflush(stdout);
//        /* prepare a dummy image */
//        /* Y */
//        for(y=0;y<c->height;y++) {
//            for(x=0;x<c->width;x++) {
//                picture->data[0][y * picture->linesize[0] + x] = x + y + i * 3;
//            }
//        }
//        
//        /* Cb and Cr */
//        for(y=0;y<c->height/2;y++) {
//            for(x=0;x<c->width/2;x++) {
//                picture->data[1][y * picture->linesize[1] + x] = 128 + y + i * 2;
//                picture->data[2][y * picture->linesize[2] + x] = 64 + x + i * 5;
//            }
//        }
//        
//        /* encode the image */
//        
//        // deprecated
////        int avcodec_encode_video(AVCodecContext *avctx, uint8_t *buf, int buf_size,
////                                 const AVFrame *pict);
////        out_size = avcodec_encode_video(c, outbuf, outbuf_size, picture);
//        
////        int avcodec_encode_video2(AVCodecContext *avctx, AVPacket *avpkt,
////                                  const AVFrame *frame, int *got_packet_ptr);
//        out_size = avcodec_encode_video2(c, x, picture, );
//        printf("encoding frame %3d (size=%5d)\n", i, out_size);
//        fwrite(outbuf, 1, out_size, f);
//    }
//    
//    /* get the delayed frames */
//    for(; out_size; i++) {
//        fflush(stdout);
//        
//        out_size = avcodec_encode_video(c, outbuf, outbuf_size, NULL);
//        printf("write frame %3d (size=%5d)\n", i, out_size);
//        fwrite(outbuf, 1, out_size, f);
//    }
//    
//    /* add sequence end code to have a real mpeg file */
//    outbuf[0] = 0x00;
//    outbuf[1] = 0x00;
//    outbuf[2] = 0x01;
//    outbuf[3] = 0xb7;
//    fwrite(outbuf, 1, 4, f);
//    fclose(f);
//    free(picture_buf);
//    free(outbuf);
//    
//    avcodec_close(c);
//    av_free(c);
//    av_free(picture);
//    printf("\n");
    
//    if(codec_id == AV_CODEC_ID_H264)
//        av_opt_set(c->priv_data, "preset", "slow", 0);
    
    /* open it */
    if (avcodec_open2(c, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        exit(1);
    }
    
    f = fopen(filename, "wb");
    if (!f) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(1);
    }
    
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }
    frame->format = c->pix_fmt;
    frame->width  = c->width;
    frame->height = c->height;
    
    /* the image can be allocated by any means and av_image_alloc() is
     * just the most convenient way if av_malloc() is to be used */
    int ret;
    ret = av_image_alloc(frame->data, frame->linesize, c->width, c->height, c->pix_fmt, 32);
    if (ret < 0) {
        fprintf(stderr, "Could not allocate raw picture buffer\n");
        exit(1);
    }
    
    /* encode 1 second of video */
    for(i=0;i<25;i++) {
        av_init_packet(&pkt);
        pkt.data = NULL;    // packet data will be allocated by the encoder
        pkt.size = 0;
        
        fflush(stdout);
        /* prepare a dummy image */
        /* Y */
        for(y=0;y<c->height;y++) {
            for(x=0;x<c->width;x++) {
                frame->data[0][y * frame->linesize[0] + x] = x + y + i * 3;
            }
        }
        
        /* Cb and Cr */
        for(y=0;y<c->height/2;y++) {
            for(x=0;x<c->width/2;x++) {
                frame->data[1][y * frame->linesize[1] + x] = 128 + y + i * 2;
                frame->data[2][y * frame->linesize[2] + x] = 64 + x + i * 5;
            }
        }
        
        frame->pts = i;
        
        /* encode the image */
        if (!c) {
            NSLog(@"AVCodecContext is invalid.\n");
        }
        ret = avcodec_encode_video2(c, &pkt, frame, &got_output);
        if (ret < 0) {
            fprintf(stderr, "Error encoding frame\n");
            exit(1);
        }
        
        if (got_output) {
            printf("Write frame %3d (size=%5d)\n", i, pkt.size);
            fwrite(pkt.data, 1, pkt.size, f);
            av_free_packet(&pkt);
        }
    }
    
    /* get the delayed frames */
    for (got_output = 1; got_output; i++) {
        fflush(stdout);
        
        ret = avcodec_encode_video2(c, &pkt, NULL, &got_output);
        if (ret < 0) {
            fprintf(stderr, "Error encoding frame\n");
            exit(1);
        }
        
        if (got_output) {
            printf("Write frame %3d (size=%5d)\n", i, pkt.size);
            fwrite(pkt.data, 1, pkt.size, f);
            av_free_packet(&pkt);
        }
    }
    
    /* add sequence end code to have a real mpeg file */
    fwrite(endcode, 1, sizeof(endcode), f);
    fclose(f);
    
    avcodec_close(c);
    av_free(c);
    av_freep(&frame->data[0]);
//    avcodec_free_frame(&frame); // deprecated
    av_frame_free(&frame);
    printf("\n");

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
