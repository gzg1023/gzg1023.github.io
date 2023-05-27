---
title: 【技术总结】C端web开发经验总结及工作实用工具分享（webview侧）
date: 2021-09-16
lastmod: 2021-09-17
tags: ["前端", "C端", "总结"]
categories: ["前端", "C端", "总结"]
author: "gzg1023"
toc: true
---

> 本文主要写一些在C端 webview侧（直白点就是app内部的页面）所碰到的一些坑和经验的一些总结。以及自己在开发过程中觉得比较舒适的工具推荐。

<!--more-->

## C端特供

这里就是一些在pc系统或者是常规浏览器中不会接触到的一些内容，主要是嵌入到APP内部的webview页面相关的一些技术点的总结。

### js bridge

在原生开发中，webview是一个基础组件。前端所开发的页面只需要丢给客户的一个链接。当用户进行相关操作时候，就可以初始化webview容器然后开始页面的加载渲染。 那么我的页面想要和客户端进行交互，就需要使用到js bridge了。

通俗点说js bridge就是前端和客户端经过约定而封装的一些函数，通过互相调用的方式达到交互的目的。实现方式主要有以下几种。

* url scheme

最常使用的是前两种，url scheme一般来说是通过前端自己创建iframe请求，客户端拦截的方式。通过约定的参数来达到交互的目的。优点就是兼容性好，缺点也很明显就是不能有太大长度数据否则浏览器会拦截（类似GET请求）

```js
const appBridge = function (type, data) {
  var iframe = document.createElement('IFRAME')
  // app-jsb是和公司客户端协商定的一个自定义字段
  iframe.setAttribute('src', 'app-jsb://' + type + '/' + data)
  document.documentElement.appendChild(iframe)
  iframe.parentNode.removeChild(iframe)
  iframe = null
}
```

* window对象注入

window对象注入就更容易理解了，web侧可以注入方法供客户端使用，客户端也可以注入方法供web侧使用。还有一种情况就是可能客户端数据也是异步的那我们就需要使用到callback的方式等待数据的返回。通过window.addEventListener和window.removeEventListener来注册和接触自定义事件

```js
document.addEventListener(evt, callback)
document.removeEventListener(evt, cb)
```

* 拦截浏览器行为

拦截浏览器行为，主要是指``window.alert, window.prompt``等方法，通过和客户端协商的方式进行拦截，然后自定义相关的行为。

### 唤端

唤端主要指的是在外部浏览器或者其他app中，通过跳转的方式打开公司自己的app并定位到相应内容的一个行为，最常见的就是各种落地页（入拉新活动，邀请拼团等）实现唤端也是需要 客户端和web侧 配合来完成的工作。主要实现有以下几种（都有兼容性问题，需要大量测试）：

* url scheme

这种方式实现起来兼容性好，缺点就是有一个对话框询问是否跳转。实现方式同样是通过iframe发送请求，通过约定好的参数跳转库客户端。如在浏览器输入：``weixin://``即可打开微信

```js
     行为(应用的某个功能)    
            |
scheme://[path][?query]
   |               |
应用标识       功能需要的参数
```

* Intent

Intent是安卓独有的一个协议，也是通过url方式跳转要遵循安卓所规定的格式进行交互。需要客户端在安装APP时候注册协议到系统内部（类似window系统的注册表内容）经过测试 如果需要兼容不同浏览器跳转需要看不同浏览器的文档和相关的参数进行设置 不能做到一劳永逸）

```js
intent://platformapi/startapp[?query]
```


* Universal Link

iOS机型独有的协议，在iOS9出现的，需要在苹果应用后台配置一个地址 然后通过转跳该地址打开app或者跳转应用商店。



### js sdk封装

和app交互是家常便饭，所以封装一个js sdk供同事们使用也是必须要做的事。这里说一下要主动一些点。

采用 ``基础结构+ 按需方法``的方式进行封装，基础结构指的是js bridge的交互方式，按需方法指的是把方法和结构分类 不耦合在一个大的函数中，不然随着方法变多 我们很多页面可能只用到了一个方法就加载了全部资源 浪费资源加载体积。

基础功能点：
* navigator.userAgent数据封装，使用时候方便获取
* url参数封装，直接通过方法获取地址栏参数（可能客户端会注入）
* 屏幕的宽度(screen.width)，高度(screen.height)，及物理像素分辨率与CSS像素分辨率之比(devicePixelRatio)
* js bridge封装
* localStorage的封装（根据业务需求而定）
* 获取app信息的封装（如app版本号，设备信息等）
* 网络请求等统一封装


按需功能点：
* 微信二次分享内容封装
* 加解密数据封装函数
* 唤端 方法的兼容封装处理
* 控制webview下拉刷新等操作

### 布局容器

这里的布局容器主要是指wbeview在app中所占的比例及不同的情况。前面说到webview是客户端开发的一个组件，那么就可以自定义这个组件的大小，一般来说有三种：
* 全屏webview（沉浸式体验，状态栏也包含在内）
* 基础webview（最常用页面，上面有一个客户端的操作栏，下面全部的内容是wbeview页面）
* 自定义大小webview（用于部分需求页面的特殊位置页面，如一个很小的的悬浮窗但是内容是显示网页）

在日常开发者这三种情况最常见，可以和客户端协商好参数，通过前端url参数直接控制大小等内容。来适应不一样的需求。


## 兼容的坑

### 1px

老生常谈的问题，移动端1px。解决问题大概就是如下：
* ::after + transform:scale
* box-shadow
* 图片

### 垂直居中

垂直居中这里主要是window.devicePixelRatio参数大于等于3的安卓机型， 不管是使用flex还是绝对定位，都会出现居中偏上的情况，就需要自己根据实际情况添加padding来做兼容处理了。

### 关于动画

动画主要是通过 过渡,关键帧 来实现，如果是复杂动画会用到动画引擎。还有就是一些动画手写难以实现。那么会使用gif来代替（缺点就是有锯齿），或者是webp图片来代替（iOS有兼容问题）。还可以使用svga文件来解析动画，之前实践也比较多效果很不错）直接使用svga库解析文件即可。

### 微信分享

客户端分享到微信的内容会存在一个对话框的内容，但是进入页面以后再分享给其他人就变成了一个很丑的链接地址。那么这里就需要对微信的二次分享做处理。需要使用``https://res.wx.qq.com/open/js/jweixin-1.0.0.js``并且在微信后台配置，然后对jsApiList进行设置，初始化二次分享的对话框（可以封装在js sdk中）


### 长按相关

长安主要指的是一些文字内容和图片，当加载webview页面时候不控制的话会出现复制内容或者图片弹窗的情况。通过user-select来控制这个行为 提高用户体验。
```js
-webkit-user-select: none;
 -moz-user-select: none;
 -khtml-user-select: none;
 user-select: none;
```
、
## 实用工具

工具部分主要分享一些日常开发使用的好工具

### 网络代理

网络代理主要是Charles，可以拦https界面也好看

### 调试

webview内部页面调试用vconsole和eruda

远程调试页面使用LightProxy

### 截图

无敌截图Snipaste