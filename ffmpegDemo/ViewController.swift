//
//  ViewController.swift
//  ffmpegDemo
//
//  Created by gdmobZHX on 16/1/6.
//  Copyright © 2016年 gdmobZHX. All rights reserved.
//

import UIKit
import NetworkExtension
class ViewController: UIViewController{
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
//        arc4random_uniform(100)
        
    }

// 成员变量
    var session : VCSimpleSession  = VCSimpleSession(videoSize: CGSize(width: 1280, height: 720), frameRate: 30, bitrate: 1000000, useInterfaceOrientation: false)
    
    let collection : UICollectionView = UICollectionView(frame:UIScreen.mainScreen().bounds,collectionViewLayout: UICollectionViewLayout())
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        view.addSubview(collection)
        collection.delegate = self
        collection.dataSource = self
/*// 打印版本信息
     let cVersion = avcodec_configuration()
      let str = String.fromCString(cVersion)
    print(str)
        let decoder = XZDecoder.init()
        let s = decoder.decoderWithInputFileName("war3end.mp4")
        let s = decoder.remuxerWithInputFileName("war3end.mp4", withOutFileName: "output.mov");
        let s = decoder.streamerWithinputFile("war3end.mp4", outputUrlStr: "rtmp://w.gslb.lecloud.com/live/20160109300042599?sign=3e2387ccc6ad1c602a4144434036f775&tm=20160109150249")

        if let s = s{
            print(s)
        }*/
        /* 直播流代码 ********** begin **********
        view.addSubview(session.previewView);
        session.previewView.frame = view.bounds
        session.delegate = self
        
        switch session.rtmpSessionState {
        case .None, .PreviewStarted, .Ended, .Error:
            session.startRtmpSessionWithURL("rtmp://uni-rtmp-push.loli.video/live", andStreamKey: "568d083200b009a331c81f6a_851065?user=568d083200b009a331c81f6a&publishKey=8a49d5f5d721ba4a6fd08879670edfc259fd868b")
        default:
            session.endRtmpSession()
            break
        }
         *********** end ********** */
    }
    deinit{
        session.delegate = nil
    }
}
extension ViewController : VCSessionDelegate{
    func connectionStatusChanged(sessionState: VCSessionState) {
        switch session.rtmpSessionState{
        case .Starting:
            print("rtmpSessionState Connecting")
        case .Started:
            print("rtmpSessionState Connected")
        case .Error:
            print("rtmpSessionState ERROR")
        default:
            print("rtmpSessionState NONE")
        }
    }
}
extension ViewController : UICollectionViewDataSource,UICollectionViewDelegate{
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        cell.backgroundColor = UIColor.blueColor()
        return cell
    }
}