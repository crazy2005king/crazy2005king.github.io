---
layout: post
title: ffmpeg过滤器入门介绍
date: 2016-11-03 10:53
author: admin
comments: true
categories: [Blog]
tags: [ffmpeg, filter]
---

ffmpeg过滤器入门介绍
===============


参考资料：
---------------
+ [FFmpeg filter简介](http://www.cnblogs.com/tocy/p/ffmpeg-filter-intro.html)
+ [ffmpeg filter过滤器 基础实例及全面解析](http://blog.csdn.net/newchenxf/article/details/51364105)




本文说明：
---------------
+ 对ffmpeg过滤器的入门介绍，主要基于网文“[FFmpeg filter简介](http://www.cnblogs.com/tocy/p/ffmpeg-filter-intro.html)”



引言及示例
---------------
### 提供了一整套的基于filter的机制
filter本身是一个插件的形式，可以快速的组装需要的效果,
比如下面的filter，可以实现视频的水平镜像效果:

`````````````````````
ffplay.exe sample.rmvb -vf hflip
`````````````````````

### 重新定义filter API
+ ffmpeg定义的libavcodec接口已经成为在编解码领域的事实上的行业标准。
+ 但音视频filter并没有类似的标准，多个不同的多媒体项目
  （比如MPlayer、Xine、GStreamer等）都实现了自定义的filter系统。
+ 为了统一filter库API接口，ffmpeg提出了参考DirectDraw实现了高质量、高效、灵活的音视频filter接口。
+ 详细的接口定义文档资料可以参考[ffmpeg filter](http://ffmpeg.org/ffmpeg-filters.html)

### 传统概念上filter是什么？
本部分资料参考filter-def
filter可以翻译成过滤器，滤波器。
物理概念上，常见的过滤器跟净化器概念重复，比如滤水器、空气净化器等。

在计算机程序中，filter是指一段代码，可用于检查输入或者输出，按照预定的规则处理并传递这些数据。
换种说法，filter是一种传递（pass-through）代码块，将输入数据做特定的变换并输出。通常filter自身不做任何输入/输出。
举个例子，linux下的grep可以认为是一个filter，按照正则表达式匹配选择，从输入中选择输出数据。
在电信工程领域，filter通常指的用于信号处理的设备，比如音频处理比较典型的低通滤波器、高通滤波器、带通滤波器、去噪滤波器等。

### filter的分类
按照处理数据的类型，通常多媒体的filter分为：

* 音频filter
* 视频filter
* 字幕filter

另一种按照处于编解码器的位置划分：

+ prefilters: used before encoding
+ intrafilters: used while encoding (and are thus an integral part of a video codec)
+ postfilters: used after decoding

ffmpeg中filter分为：

* source filter （只有输出）
* audio filter
* video filter
* Multimedia filter
* sink filter （只有输入）


**除了source和sink filter，其他filter都至少有一个输入、至少一个输出。**

介绍了这么多，下面也是一个例子，使用filter实现宽高减半显示：


`````````````````````
ffplay.exe sample.rmvb -vf scale=iw/2:ih/2
`````````````````````

下面是使用mptestsrc的source filter作为ffplay输入，直接显示：

`````````````````````
ffplay -f lavfi mptestsrc=t=dc_luma
ffplay -f lavfi life=s=300x200:mold=10:r=60:ratio=0.1:death_color=#C83232:life_color=#00ff00,scale=1200:800:flags=16
`````````````````````

基本原理
---------------
ffmpeg filter可以认为是一些预定义的范式，可以实现类似积木的多种功能的自由组合。
**每个filter都有固定数目的输入和输出，而且实际使用中不允许有空悬的输入输出端。**
使用文本描述时我们可以通过标识符指定输入和输出端口，将不同filter串联起来，构成更复杂的filter。
这就形成了嵌套的filter。当然每个filter可以通过ffmpeg/ffplay命令行实现，但通常filter更方便。

ffmpeg.exe、ffplay.exe能够通过filter处理原始的音视频数据。
**ffmpeg将filtergraph分为simple filtergraph和complex filtergraph。**

+ 常simple filtergraph只有一个输入和输出,

	ffmpeg命令行中使用-vf、-af识别，基本原理图如下：

`````````````````````
     _________                        ______________
    |         |                      |              |
    | decoded |                      | encoded data |
    | frames  |\                   _ | packets      |
    |_________| \                  /||______________|
                 \   __________   /
      simple     _\||          | /  encoder
      filtergraph   | filtered |/
                    | frames   |
                    |__________|
`````````````````````

					
+ complex filtergraph，通常是具有多个输入输出文件，并有多条执行路径；

	ffmpeg命令行中使用-lavfi、-filter_complex，基本原理图如下：

`````````````````````
 _________
|         |
| input 0 |\                    __________
|_________| \                  |          |
             \   _________    /| output 0 |
              \ |         |  / |__________|
 _________     \| complex | /
|         |     |         |/
| input 1 |---->| filter  |\
|_________|     |         | \   __________
               /| graph   |  \ |          |
              / |         |   \| output 1 |
 _________   /  |_________|    |__________|
|         | /
| input 2 |/
|_________|

`````````````````````


filtergraph的基本语法和构成。
---------------
### 在libavfilter, 一个filter可以包含多个输入、多个输出。
下图是一个filtergraph的示例：

`````````````````````
                [main]
input --> split ---------------------> overlay --> output
            |                             ^
            |[tmp]                  [flip]|
            +-----> crop --> vflip -------+
			
`````````````````````

上图中filtergraph将输入流分成两个流，

+ 一个通过crop filter和vflip filter，
+ 然后通过overlay filter将这两个流合成一个流输出。
+ 这个filtergraph可以用下面命令行表示：

`````````````````````
ffmpeg -i INPUT -vf "split [main][tmp]; [tmp] crop=iw:ih/2:0:0, vflip [flip]; [main][flip] overlay=0:H/2" OUTPUT
`````````````````````

### 语法识别
**ffmpeg中filter包含三个层次，filter->filterchain->filtergraph。** 
**filter是ffmpeg的libavfilter提供的基础单元。**
**在同一个线性链中的filter使用逗号分隔，在不同线性链中的filter使用分号隔开，**

比如下面的例子：

`````````````````````
ffmpeg -i INPUT -vf "split [main][tmp]; [tmp] crop=iw:ih/2:0:0, vflip [flip]; [main][flip] overlay=0:H/2" OUTPUT
`````````````````````

这里crop、vflip处于同一个线性链，
split、overlay位于另一个线性链。
二者连接通过命名的label实现（位于中括号中的是label的名字）。
在上例中split filter有两个输出，依次命名为[main]和[tmp]；

+ [tmp]作为crop filter输入，
+ 之后通过vflip filter输出[flip]；
+ overlay的输入是[main]和[flilp]。
+ 如果filter需要输入参数，多个参数使用冒号分割。
+ 对于没有音频、视频输入的filter称为source filter，
+ 没有音频、视频输出的filter称为sink filter。

经典的filter
---------------

ffmpeg支持的所有filter可以通过filters查看。
这里选几个相对经典的filter。

### 音频filter

+ adelay filter
  实现不同声道的延时处理。使用参数如下adelay=1500|0|500，这个例子中实现第一个声道的延迟1.5s，第三个声道延迟0.5s，第二个声道不做调整。
+ aecho filter
  实现回声效果，具体参考http://ffmpeg.org/ffmpeg-filters.html#aecho。
+ amerge filter
  将多个音频流合并成一个多声道音频流。具体参考http://ffmpeg.org/ffmpeg-filters.html#amerge-1。
+ ashowinfo filter
  显示每一个audio frame的信息，比如时间戳、位置、采样格式、采样率、采样点数等。具体参考http://ffmpeg.org/ffmpeg-filters.html#ashowinfo。
+ panfilter

  * 特定声道处理，比如立体声变为单声道，或者通过特定参数修改声道或交换声道。主要有两大类：
  * 混音处理，比如下面的例子pan=1c|c0=0.9*c0+0.1*c1，实现立体声到单声道的变换；
  * 声道变换，比如5.1声道顺序调整，pan="5.1| c0=c1 | c1=c0 | c2=c2 | c3=c3 | c4=c4 | c5=c5"。
  
+ silencedetect和silenceremove filter
  根据特定参数检测静音和移除静音。
+ volume和volumedetect filter
  这两个filter分别实现音量调整和音量检测。
+ audio source filter
+ aevalsrc filter按照特定表达式生成音频信号。
+ anullsrc filter生成特定的原始音频数据，用于模板或测试。
+ anoisesrc filter生成噪声音频信号。
+ sine filter生成正弦波音频信号。
+ audio sink filter
+ abuffersink filter和anullsink filter，这些filter只是用于特定情况下结束filter chain。

### 视频filter
+ blend和tblend filter
  将两帧视频合并为一帧。具体参数参考http://ffmpeg.org/ffmpeg-filters.html#blend_002c-tblend。
+ crop filter
  按照特定分辨率裁剪输入视频，具体参数参考http://ffmpeg.org/ffmpeg-filters.html#crop。
+ drawbox、drawgrid、drawtext filter
  绘制box（对话框）、grid（表格）、text（文本）。
+ edgedetect filter
  边缘检测filter。
+ fps filter
  按照指定帧率输出视频帧（丢帧或者复制）。具体参考http://ffmpeg.org/ffmpeg-filters.html#fps-1。
+ hflip、vflip filter
  水平和垂直镜像。
+ histogram filter
  生成每帧的各颜色分量的直方图。
+ noise filter
  在输入视频帧中添加白噪声。
+ overlay filter
  视频叠加。具体参考http://ffmpeg.org/ffmpeg-filters.html#overlay-1。
+ pad filter
  视频边界填充。具体参考http://ffmpeg.org/ffmpeg-filters.html#pad-1。
+ rotate filter
  视频任意角度旋转。具体参考http://ffmpeg.org/ffmpeg-filters.html#rotate。
+ scale filter
  使用libswscale库完成视频缩放的filter。
+ showinfo filter
  显示视频帧的参数信息，比如时间戳、采样格式、帧类型等。
+ subtitles filter
  使用libass库绘制subtitle（字幕）。
+ thumbnail filter
  提取缩略图的filter。
+ transpose filter
  图像转置的filter。参数参考http://ffmpeg.org/ffmpeg-filters.html#transpose。
+ source filter
  主要有cellatuo、coreimagesrc、mptestsrc、life等filter，具体效果建议参考ffmpeg用户手册。
+ source sink
  主要有buffersink、nullsink两个filter。

### 多媒体filter
+ ahistogram filter
  将音频转化为视频输出，并显示为音量的直方图。
+ concat filter
  将音频流、视频流拼接成一个。具体参考http://ffmpeg.org/ffmpeg-filters.html#concat。
+ metadata、ametadata filter
  操作metadata信息。
+ setpts、asetpts filter
  改变输入音频帧或视频帧的pts。
+ showfreqs、showspectrum、showspertrumpic、showvolume、showwaves filter
  将输入音频转换为视频显示，并显示频谱、音量等信息
+ split、asplit filter
  将输入切分为多个相同的输出。
+ source filter
  主要是movie、amovie filter。从movie容器中读取音频或者视频帧。
  
实例demo
---------------

ffmpeg提供了很多有趣的filter实例，
详见Fancy Filtering Examples。
我们这里先从几个简单的实例开始。


+ 实例一：缩放scale
  将输入缩小宽度缩小一半，并保持宽高比。
  
`````````````````````
ffmpeg -i input.jpg -vf scale=iw/2:-1 output.jpg
`````````````````````

+ 实例二：filter、filterchain和filtergraph的使用
  先将输入去交织，然后减半显示。
  以下三个命令是等价的。

`````````````````````
//2 chains form, one filter per chain, chains linked by the [middle] pad
ffmpeg -i input -vf [in]yadif=0:0:0[middle];[middle]scale=iw/2:-1[out] output

//1 chain form, with 2 filters in the chain, linking implied
ffmpeg -i input -vf [in]yadif=0:0:0,scale=iw/2:-1[out] output

//the input and output are implied without ambiguity
ffmpeg -i input -vf yadif=0:0:0,scale=iw/2:-1 output
`````````````````````

+ 实例三：2x2布局画面拼接
  这个实例主要说明下filtergraph使用。命令行如下：
  
`````````````````````
./ffmpeg -f lavfi -i testsrc -f lavfi -i testsrc -f lavfi -i testsrc -f lavfi -i testsrc -filter_complex \
"[0:v]pad=iw*2:ih*2[a]; \
 [1:v]negate[b]; \
 [2:v]hflip[c]; \
 [3:v]edgedetect[d]; \
 [a][b]overlay=w[x]; \
 [x][c]overlay=0:h[y]; \
 [y][d]overlay=w:h[out]" -map "[out]" -c:v ffv1 -t 5 multiple_input_grid.avi
`````````````````````

 
参考资料
---------------

libavfilter-multimedia
ffmpeg filter HOWTO
ffmpeg Filtering Guide
ffmpeg-filtering
ffmpeg Bug Tracker and Wiki

