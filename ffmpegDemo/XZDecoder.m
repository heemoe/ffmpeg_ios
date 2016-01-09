//
//  XZDecoder.m
//  ffmpegDemo
//
//  Created by gdmobZHX on 16/1/7.
//  Copyright © 2016年 gdmobZHX. All rights reserved.
//

#import "XZDecoder.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/time.h"
#include "libavutil/mathematics.h"


@implementation XZDecoder
- (NSString *)decoderWithInputFileName:(NSString *)str{
    AVFormatContext *pFormatContext;
    int i,videoindex;
    AVCodecContext *pCodecContext;
    AVCodec *pCodec;
    AVFrame *pFrame,*pFrameYUV;
    uint8_t *out_buffer;
    AVPacket *packet;
    int y_size;
    int ret,got_picture;
    struct SwsContext *img_convert_ctx;
    FILE *fp_yuv;
    int frame_cnt;
    clock_t time_start,time_finish;
    double time_duration = 0.0;
    char input_str_full[500] = {0};
    char output_str_full[500] = {0};
    char info[1000] = {0};
    
    // 取出文件路径
    NSString *input_nsstr = [[NSBundle mainBundle]pathForResource:str ofType:nil];
    NSString *output_nsstr = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"output.yuv"];
    
    sprintf(input_str_full, "%s",[input_nsstr UTF8String]); // 字符串格式化 写入char
    sprintf(output_str_full, "%s",[output_nsstr UTF8String]);
    
    NSLog(@"Input:%s Output:%s",input_str_full,output_str_full);
    
    av_register_all(); // 初始化libavformat和分离器,注册所有容器格式和CODEC
    avformat_network_init(); // 网络模块初始化 打开网络流
    pFormatContext = avformat_alloc_context(); // 初始化(开辟内存空间)AVFormat
    if (avformat_open_input(&pFormatContext, input_str_full, NULL, NULL) != 0) {
        return @"文件打开失败,可能是文件(名)路劲错误";
    }
    if (avformat_find_stream_info(pFormatContext, NULL) < 0){
        return @"找不到流信息,可能是流地址错误";
    }
    videoindex = -1; // 默认值为错误值,如果遍历完还是-1 则找不到流
    for (i = 0; i<pFormatContext -> nb_streams; i++) { // 遍历(nb_streams 流个数)流
        if (pFormatContext ->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) { // 判断遍历出的流类型是否为Video 
            videoindex = i; // 拿到流的位置
            break;
        }
    }
    if (videoindex == -1) {
        return @"找不到流";
    }
    pCodecContext = pFormatContext -> streams[videoindex] -> codec; // 取出 对应的流 的解码器hub(codec)
    pCodec = avcodec_find_decoder(pCodecContext ->codec_id);  //通过context中的codec_id找到对应的流的格式的解码器
    if (pCodec == NULL) {
        return @"找不到解码器";
    }
    if (avcodec_open2(pCodecContext, pCodec, NULL) <0 ) { // 初始化一个视音频编解码器的AVCodecContext(打开解码器) 0为成功 负数失败
        return @"打不开解码器";
    }
    // 存储器分配内存,初始化(为每一帧图像分配内存)
    pFrame = av_frame_alloc();
    pFrameYUV = av_frame_alloc();
    // 根据存储格式(源格式),视频的像素,拿到每个picture存储大小
    out_buffer = (uint8_t *)av_malloc(avpicture_get_size(PIX_FMT_YUV420P, pCodecContext->width, pCodecContext->height));
    // 对pFrameYUV中的data linesize初始化
    avpicture_fill((AVPicture *)pFrameYUV, out_buffer, PIX_FMT_YUV420P, pCodecContext->width, pCodecContext->height);
    // 数据压缩器开辟内存
    packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    // 获取图像转换器(sws)的上下文 参数:原始宽高格式,目标宽高格式,缩放算法,后三个空
    img_convert_ctx = sws_getContext(pCodecContext->width, pCodecContext->height, pCodecContext->pix_fmt, pCodecContext->width, pCodecContext->height, PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
    // 输出一些信息至info中
    sprintf(info,   "[Input     ]%s\n", [str UTF8String]);
    sprintf(info, "%s[Output    ]%s\n",info,[@"output.yuv" UTF8String]);
    sprintf(info, "%s[Format    ]%s\n",info, pFormatContext->iformat->name);
    sprintf(info, "%s[Codec     ]%s\n",info, pCodecContext->codec->name);
    sprintf(info, "%s[Resolution]%dx%d\n",info, pCodecContext->width,pCodecContext->height);

    // 打开文件...
    fp_yuv = fopen(output_str_full, "wb+");
    if (fp_yuv == NULL) {
        return @"打不开输出文件";
    }
    frame_cnt = 0;
    time_start = clock();
    
    while (av_read_frame(pFormatContext, packet) >= 0) { // 循环读取每一帧
//        printf(@"pFormatContext:%p\npacket:%p",pFormatContext,packet);
        if (packet->stream_index == videoindex) { // 取出的是否对应
            ret = avcodec_decode_video2(pCodecContext, pFrame, &got_picture, packet); // 解码一帧数据
            if (ret < 0) {
                return @"解码错误";
            }
            if (got_picture) {
                /**
                 第一個參數即是由 sws_getContext 所取得的參數。
                 第二個 src 及第六個 dst 分別指向input 和 output 的 buffer。
                 第三個 srcStride 及第七個 dstStride 分別指向 input 及 output 的 stride；如果不知道什麼是 stride，姑且可以先把它看成是每一列的 byte 數。
                 第四個 srcSliceY，就註解的意思來看，是指第一列要處理的位置；這裡我是從頭處理，所以直接填0。想知道更詳細說明的人，可以參考 swscale.h 的註解。
                 第五個srcSliceH指的是 source slice 的高度。
                 */
                sws_scale(img_convert_ctx, (const uint8_t *const*)pFrame->data, pFrame->linesize, 0, pCodecContext->height, pFrameYUV->data, pFrameYUV->linesize);
                y_size = pCodecContext -> width * pCodecContext->height; // 缩放转码
                
                fwrite(pFrameYUV->data[0], 1, y_size, fp_yuv); // Y
                fwrite(pFrameYUV->data[1], 1, y_size/4, fp_yuv); // U
                fwrite(pFrameYUV->data[2], 1, y_size/4, fp_yuv); // V
                // 输出信息
                char picType_str[10] = {0};
                switch (pFrame->pict_type) {
                    case AV_PICTURE_TYPE_I:
                        sprintf(picType_str, "I");
                        break;
                    case AV_PICTURE_TYPE_P:
                        sprintf(picType_str, "P");
                        break;
                    case AV_PICTURE_TYPE_B:
                        sprintf(picType_str, "B");
                        break;
                    default:
                        sprintf(picType_str, "Other");
                        break;
                }
                NSLog(@"Frame Index :%5d\nType:%s\nframe_cnt:%d",frame_cnt,picType_str,frame_cnt);
                frame_cnt++; // 记录多少帧?
            }
        }
        av_free_packet(packet);
    }
    while (1) {
        ret = avcodec_decode_video2(pCodecContext, pFrame, &got_picture, packet);
        if (ret < 0)
            break;
        if (!got_picture)
            break;
        sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecContext->height,
                  pFrameYUV->data, pFrameYUV->linesize);
        int y_size=pCodecContext->width*pCodecContext->height;
        fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
        fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
        fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
        //Output info
        char pictype_str[10]={0};
        switch(pFrame->pict_type){
            case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
            case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
            case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
            default:sprintf(pictype_str,"Other");break;
        }
        printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
        frame_cnt++;
    }
    time_finish = clock();
    time_duration = (double)(time_finish - time_start); //计算了下解码时间
    
    sprintf(info, "%s[Time      ]%fus\n",info,time_duration);
    sprintf(info, "%s[Count     ]%d\n",info,frame_cnt);
    
    sws_freeContext(img_convert_ctx); //释放内存
    
    fclose(fp_yuv);// 关闭文件
    av_frame_free(&pFrameYUV);
    av_frame_free(&pFrame);
    avcodec_close(pCodecContext);
    avformat_close_input(&pFormatContext);
    NSLog(@"info=======>:\n%s",info);
    return output_nsstr;
}
- (NSString *)remuxerWithInputFileName:(NSString *)iname withOutFileName:(NSString *)oname{
    AVOutputFormat *ofmt = NULL;
    // input fmt veido  input fmt auido  output fmt
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    const char *in_filename,*out_filename;
    AVPacket pkt;
    int ret,i;
    int frame_index=0;
    
    in_filename = [[NSBundle mainBundle]pathForResource:iname ofType:nil].UTF8String;
    NSString *output_nsstr = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:oname];
    out_filename = output_nsstr.UTF8String;
    
    av_register_all();
    // ret 是 return值 用来记录错误
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, NULL, NULL)) < 0){
        return @"文件打开失败";
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, NULL)) < 0) {
        return @"读取流失败";
    }
    // 输出一些流信息
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    // output初始化
    avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    if (!ofmt_ctx) {
        ret = AVERROR_UNKNOWN;
        return @"不能创建输出上下文";
    }
    // 初始化输出容器
    ofmt = ofmt_ctx->oformat;
    // 遍历每个流
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_stream->codec->codec);
        if (!out_stream) {
            ret = AVERROR_UNKNOWN;
            return @"输出流创建失败";
        }
        // 复制上下文设置
        if (avcodec_copy_context(out_stream->codec, in_stream->codec)<0) {
            return @"从输入流的解码器复制到输出流解码器失败.";
        }
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER) {
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
        }
    }
    // 输出信息
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    // 打开输出文件
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            return @"不能打开输出文件";
        }
    }
    // 写入文件头
    if (avformat_write_header(ofmt_ctx, NULL) < 0) {
        return @"写入输出文件头失败";
    }
    while (1) {
        AVStream *in_stream,*out_stream;
        // 获取包AVPacket
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0) {
            break;
        }
        // 取包
        in_stream = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        // 计算pts dts duration
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base,AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base,AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.duration = (int)av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        // 写入
        if (av_interleaved_write_frame(ofmt_ctx, &pkt) < 0) {
            return @"写入包失败";
        }
        printf("写入 %8d 帧输出文件\n",frame_index);
        av_free_packet(&pkt);
        frame_index++;
    }
    av_write_trailer(ofmt_ctx);
    avformat_close_input(&ifmt_ctx);
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE)) {
        avio_close(ofmt_ctx->pb);
    }
    avformat_free_context(ofmt_ctx);
    return output_nsstr;
}
- (NSString *)streamerWithinputFile:(NSString *)input_nss outputUrlStr:(NSString *)output_nss{
    // url
    char input_str_full[500] = {0};
    char output_str_full[500] = {0};
    
    NSString *ipathstr = [[NSBundle mainBundle] pathForResource:input_nss ofType:nil];
    sprintf(input_str_full, "%s",[ipathstr UTF8String]);
    sprintf(output_str_full, "%s",[output_nss UTF8String]);
    
    NSLog(@"Input Path:%s\n",input_str_full);
    NSLog(@"Output Path:%s\n",output_str_full);
    
    AVOutputFormat *ofmt = NULL;
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;
    char in_filename[500] = {0};
    char out_filename[500] = {0};
    int ret,i;
    int videoindex = -1;
    int frame_index = 0;
    int64_t start_time = 0;
    
    strcpy(in_filename, input_str_full);
    strcpy(out_filename, output_str_full);
    
    av_register_all();
    avformat_network_init();
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, NULL, NULL)) < 0) {
        return @"打开失败";
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, NULL)) < 0) {
        return @"找不到流";
    }
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        if (ifmt_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoindex = i;
            break;
        }
    }
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    // 输出初始化 RTMP是flv UDP是mpegts
    avformat_alloc_output_context2(&ofmt_ctx, NULL, "flv", out_filename);

    if (!ofmt_ctx) {
        return @"不能创建输出上下文";
    }
    ofmt = ofmt_ctx->oformat;
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *in_stm = ifmt_ctx->streams[i];
        AVStream *out_stm = avformat_new_stream(ofmt_ctx, in_stm->codec->codec);
        if (!out_stm) {
            return @"输出流创建失败";
        }
        ret = avcodec_copy_context(out_stm->codec, in_stm->codec);
        if (ret < 0) {
            return @"复制失败";
        }
        out_stm->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER) {
            out_stm->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
        }
    }
    // 输出一些信息
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    // 打开输出地址
    if (!ofmt->flags & AVFMT_NOFILE) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            return @"打开输出流失败";
        }
    }
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        return @"打开流传输错误";
    }
    start_time = av_gettime();
    while (1) {
        AVStream *in_stream, *out_stream;
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0) {
            break;
        }
        if (pkt.pts == AV_NOPTS_VALUE) {
            AVRational time_base1 = ifmt_ctx->streams[videoindex]->time_base;
            
            int64_t calc_duration = (double)AV_TIME_BASE/av_q2d(ifmt_ctx->streams[videoindex]->r_frame_rate);
            pkt.pts = (double)(frame_index*calc_duration)/(double)(av_q2d(time_base1)*AV_TIME_BASE);
            pkt.dts = pkt.pts;
            pkt.duration = (double)calc_duration/(double)(av_q2d(time_base1)*AV_TIME_BASE);
        }
        if (pkt.stream_index == videoindex) {
            AVRational time_base = ifmt_ctx->streams[videoindex]->time_base;
            AVRational time_base_q = {1,AV_TIME_BASE};
            int64_t pts_time = av_rescale_q(pkt.dts, time_base, time_base_q);
            int64_t now_time = av_gettime() - start_time;
            if (pts_time > now_time) {
                av_usleep((int)(pts_time - now_time));
            }
        }
        in_stream = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        
        // 复制packet
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
        pkt.duration = (int)av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        if (pkt.stream_index == videoindex) {
            NSLog(@"send %8d video frames to output Url\n",frame_index);
            frame_index++;
        }
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        if (ret < 0) {
            return @"混包错误";
            break;
        }
        av_free_packet(&pkt);
    }
    av_write_trailer(ofmt_ctx);
    
    avformat_close_input(&ifmt_ctx);
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE)) {
        avio_close(ofmt_ctx->pb);
    }
    avformat_free_context(ofmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        return @"错误";
    }
    return output_nss;
}
@end
