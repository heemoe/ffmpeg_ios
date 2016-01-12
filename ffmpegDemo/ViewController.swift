//
//  ViewController.swift
//  ffmpegDemo
//
//  Created by gdmobZHX on 16/1/6.
//  Copyright © 2016年 gdmobZHX. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
/**
- FFmpeg集成
    - 编译.a静态库
    - 导入.a静态库和头文件
        - include下的文件夹应该导入真实文件夹,不是group
    - build setting中的一些设置
        - 需要在header search path中设置代码目录 `$(PROJECT_DIR)/ffmpegDemo`
        - 以及library search path`$(PROJECT_DIR)/ffmpegDemo`
        - 以及oher link flag中添加`-liconv` `-lz` 不然会报错误,大约20个
        - 还要添加库`libbz2.1.0` 不添加会报BZ开头的错误
*/
    func test(){
    }
    override func viewDidLoad() {
        super.viewDidLoad()
// 打印版本信息
     let cVersion = avcodec_configuration()
      let str = String.fromCString(cVersion)
    print(str)
        let decoder = XZDecoder.init()
//        let s = decoder.decoderWithInputFileName("war3end.mp4")
//        let s = decoder.remuxerWithInputFileName("war3end.mp4", withOutFileName: "output.mov");
        let s = decoder.streamerWithinputFile("war3end.mp4", outputUrlStr: "rtmp://w.gslb.lecloud.com/live/20160109300042599?sign=3e2387ccc6ad1c602a4144434036f775&tm=20160109150249")

        if let s = s{
            print(s)
            
        }
    }
    

}

