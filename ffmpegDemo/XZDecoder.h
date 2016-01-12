//
//  XZDecoder.h
//  ffmpegDemo
//
//  Created by gdmobZHX on 16/1/7.
//  Copyright © 2016年 gdmobZHX. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface XZDecoder : NSObject
// 返回的都是路劲

/// 解码
- (NSString *)decoderWithInputFileName:(NSString *)str;
/// 转码
- (NSString *)remuxerWithInputFileName:(NSString *)iname withOutFileName:(NSString *)oname;
// 推流
- (NSString *)streamerWithinputFile:(NSString *)input_nss outputUrlStr:(NSString *)output_nss;
@end
