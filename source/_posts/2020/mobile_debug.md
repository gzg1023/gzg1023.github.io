---
title: 【前端技术】移动端h5项目调试技巧与总结
tags: [调试,前端]
categories: [调试,前端]
index_img: 
date: 2020-02-21 12:00:00
toc: true
---
> 移动端真机调试的方法

<!--more-->
### 准备工具

移动端调试工具[eruda地址](https://github.com/liriliri/eruda)
Fiddler2抓包工具[下载地址](https://sm.myapp.com/original/Development/fiddler2setup_2.6.2.3.exe)
草料二维码[官网](https://cli.im/)

### 安装配置
#### 1. 项目安装eruda

 1）方法一，通过npm安装

        npm install eruda 
        import eruda from 'eruda'
        eruda.init()

 2) 方法二，CDN加载

    <script src="http://cdn.jsdelivr.net/npm/eruda"></script>
    <script>eruda.init();</script>

#### 2. 修改host

先找到hosts文件(windows系统) /c/Windows/System32/drivers/etc/hosts，如果不存在就新建一个名为hosts的文件；没有后缀（如果不能新建就在桌面新建一个然后复制进来）
强烈推荐使用[SwitchHosts](https://github.com/oldj/SwitchHosts)工具

![3uXQYT.png](https://s2.ax1x.com/2020/02/21/3uXQYT.png)

**这里修改127.0.0.1本机地址为gzg1023.company.com**
**gzg1023是自己的名称，company.com是自定义公司的域名，方便共享Cooike。**(也可以自定义任意的域名)
现在把项目跑起来。地址由localhost:8080改为gzg1023.company.com:8080,进行访问如果成功，如下图所示，说明host修改成功了。

![3uXlfU.jpg](https://s2.ax1x.com/2020/02/21/3uXlfU.jpg)

注意如果是vue-cli搭建的项目需要设置vue.config.js文件如下。关闭默认的host地址检测

     devServer:{
        disableHostCheck:true
    }

#### 3. Fiddler代理，修改手机代理

    配置好电脑host以后，我们打开下载的Fiddler，如下图所示右上角有一个online，我们查看当前电脑的局域网IP。

![3uXZOs.jpg](https://s2.ax1x.com/2020/02/21/3uXZOs.jpg)

然后打开手机来配置代理，、如下图所示，先打开wifi找到与电脑同一个局域网，然后点击进入详情

![3uXmmn.png](https://s2.ax1x.com/2020/02/21/3uXmmn.png)


![3uXuT0.png](https://s2.ax1x.com/2020/02/21/3uXuT0.png)

在详情最下方，找到配置代理，然后进去

![3uXnwq.png](https://s2.ax1x.com/2020/02/21/3uXnwq.png)

输入电脑的IP端口号默认为8888，然后我们手机随便访问一个网页，观察Fiddler是否有新的网络请求。

#### 4. 通过二维码访问

配置好代理后，我们通过草料二维码生成当前网站的二维码，通过手机来访问。这里推荐安装草料二维码的浏览器插件。
    
![3uXElQ.png](https://s2.ax1x.com/2020/02/21/3uXElQ.png)

![3uXMkV.png](https://s2.ax1x.com/2020/02/21/3uXMkV.png)

### 项目调试

配置好代理后，我们通过eruda来调试项目了，点击右下方的的小按钮，如下所示。展开工具可以看到调试面板，进行功能调试了。


[![3uzdDH.md.jpg](https://s2.ax1x.com/2020/02/21/3uzdDH.md.jpg)](https://imgchr.com/i/3uzdDH)
