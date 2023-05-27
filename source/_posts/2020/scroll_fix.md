---
title: 【技术笔记】vue中滑动事件触发怎么失灵了？！
tags: [前端, Vue, CSS]
date: 2020-12-09
lastmod: 2020-12-10
draft: false
categories: [Vue]
author: "gzg1023"
reward: false
mathjax: false
toc: true
---

> 理想中的滑动，写完列表加一个@scroll，监听一下。怎么有时候到了局部区域就不触发了呢？
<!--more-->

# 1.常见滑动监听
在项目中经常碰到要处理滑动的情况，下拉滑动加载更多，滑动时候添加配置操作等...总共分为两种情况，一种是整个页面的全体滑动。另一个是页面中局部区域
的滑动处理。

### 整屏滑动

如果是整个页面向下或者向上滑动，一般是给window添加scroll监听函数 然后配合节流处理。

    window.addEventListener('scroll',function(){
        console.log('123')
    })

### 局部滑动

如果是局部区域，分为两种情况；横向滑动和纵向滑动

#### 横向滑动

横行滑动常见于管理系统的tab管理或者是商品推荐位置的滑动处理。

如下所属。添加如下css属性，然后绑定@scroll事件就会触发监听回调

    width: 200px;
    display: flex;
    overflow-x: scroll;



[![riDxFs.gif](https://s3.ax1x.com/2020/12/10/riDxFs.gif)](https://imgchr.com/i/riDxFs)


#### 纵向滑动

纵向滑动是最常见场景，用于局部列表等内容等滑动处理。

如下所属。添加如下css属性，然后绑定@scroll事件就会触发监听回调

    height: 300px;
    overflow-y: scroll;


[![riDjoj.gif](https://s3.ax1x.com/2020/12/10/riDjoj.gif)](https://imgchr.com/i/riDjoj)

# 2.滑动的原因

在上面的实例中，感觉好像很容易就触发了滑动事件，通过简单的几行代码就产生了效果。这其中最重要的就是overflow属性，拿纵向滑动来说，设置一个高为300px的盒子，然后让我们的内容在这个盒子里面进行滑动。如果只添加一个高度属性，会看到内容并不听话，不会乖乖的呆在盒子里，而是冲出了整个盒子放置内容。

那么我们就来详细了解一下overflow属性。

> MDN名词解析

CSS属性 overflow 定义当一个元素的内容太大而无法适应 块级格式化上下文 时候该做什么。它是 overflow-x 和overflow-y的 简写属性 。

overflow属性表，如果不分开写overflow-x 和overflow-y那么默认就是给两个属性都设置。

|属性|属性值|作用|
|---|---|---|
|overflow |  visible| 默认值，不会做任何操作|
|overflow |  hidden| 超出去的内容会被剪切掉|
|overflow |  scroll| 超出被剪切，但是提供滚筒条查看内容|
|overflow |  inherit| 继承父元素的overflow属性的值|
|overflow |  auto| 由浏览器自动决定，可能是不做操作或者是显示滚动条|
|overflow |  overlay| 和auto相同，但是产生的滚动条不用元素空间|


如果想要overflow 产生效果，那么块级容器必须有一个指定的高度（height或者max-height）或者将 white-space设置为nowrap，否则是不生效的，这也就是我们定义不同方向滚动不生效的关键。

> MDN注

* 设置一个轴为visible（默认值），同时设置另一个轴为不同的值，会导致设置visible的轴的行为会变成auto。 
* 即使将overflow设置为hidden，也可以使用JavaScript Element.scrollTop 属性来滚动HTML元素。

# 3.不能滑动的解决办法

在了解了滑动原因后，针对某些情况的不能滑动，我们就可以进行处理了。

### 整体滑动解决

首先是整体滑动，我们可以通过window.addEventListener或者是document.addEventListener来进行添加，但是不能使用document.documentElement.addEventListener来添加绑定。

### 局部滑动

在局部中，我们有时候设置了overflow:scroll，但是还是不会触发事件的情况，是因为盒子没有高度或者宽度。所以无法触发，解决的办法是为高度添加。不可添加百分比进行设置，因为盒子有时候是不知道具体高度是多少的。

        
    height:100vh;      // width:100vw;
    overflow-y:scroll;    // overflow-x:scroll;
