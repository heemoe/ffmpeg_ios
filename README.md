# ffmpegDemo_ios
A ffmeg demo use objective c and swfit mixed
-------------
- FFmpeg集成
    - 编译.a静态库
    - 导入.a静态库和头文件
        - include下的文件夹应该导入真实文件夹,不是group
    - build setting中的一些设置
        - 需要在header search path中设置代码目录 `$(PROJECT_DIR)/ffmpegDemo`
        - 以及library search path`$(PROJECT_DIR)/ffmpegDemo`
        - 以及oher link flag中添加`-liconv` `-lz` 不然会报错误,大约20个
        - 还要添加库`libbz2.1.0` 不添加会报BZ开头的错误

-------------
## 杂七杂八
  
  ffmpeg版本为2.8~
  
  界面用swift ffmpeg相关逻辑用oc 混编~
  
  实现了视频转码(目前还有点问题mp4不能转avi)~
  
  视频解码出YUV~
  
  视频推流~
  
  还在研究更多东西~
  
  里面注释还算可以.
  
  主要参考了 http://blog.csdn.net/leixiaohua1020/article/details/15811977
  
  感谢.
  
  
