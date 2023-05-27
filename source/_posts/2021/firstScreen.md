---
title: 【技术探索】SPA应用的页面加载优化及FPC时间计算
date: 2021-07-28
lastmod: 2021-07-28
tags: ["前端", "性能优化", "首屏"]
categories: ["前端", "性能优化", "首屏"]
author: "gzg1023"
toc: true
---

> 现代前端应用大部分采用 SPA 模式开发，而 SPA 最大的问题就是最开始只会下载一个空白的 html 文档，下载完成后浏览器开始解析文档（加载各种脚本，各种样式文件）当 vue 依赖加载完成，才会开始渲染页面。最大的问题也就体现出来了 会出现白屏问题 及首屏加载缓慢的问题，本文来谈谈前端页面的优化。

<!--more-->

## 什么是首屏

首屏这个概念目前来说没有一个官方的定义，一般来说都以约定俗成的说法为准即 从输入 URL 开始到第一屏（可视区域）的内容加载完毕的时间。根据业务场景的不同，也有不同的指标和规范。以我目前的规范来说就是首屏最大的一张图片加载完成的时间。

从业务场景来说加载页面大概有这些步骤： 客户端 webview 初始化 => webview 初始化完毕,开始加载 SPA 应用 => 查询 DNS 及建立 TCP 连接 => SPA 根 html 下载完成开始加载 js 和 CSS（白屏时间开始）=> 加载 vue 库，CSS 文件 => vue 开始编译 template 或直接开始执行 render => 渲染第一个字符出现,(白屏时间结束)=> 开始加载 html 结构及样式解析（首屏计算中) => 首屏中最大图片加载完毕(首屏时间结束）=> 加载剩余内容，异步组件等 => 页面加载完毕

我们要进行测试和优化的点，就是从 webview 初始化完毕开始，到首屏最大一张图片加载完毕 这段时间。

## 首屏优化

分析了页面加载的步骤，我们开始从第一步开始优化首屏的加载。具体实践需要考虑不同的业务场景和项目结构等各种因素。这里只给出一些通用的点，具体实践需要结合业务进行处理。关于网络缓存一般来说都是服务器设置，这理解就不进行展开了。

### 网络优化

- DNS 预获取 ：通过 link 标签的 dns-prefetch，提前解析域名，掩盖 DNS 解析延迟
- 预连接：通过 link 标签的 preconnect，建立与服务器的连接。如果是 HTTPS，过程包括 DNS 解析，建立 TCP 连接以及执行 TLS 握手
- 预加载：通过 link 标签的 preload 预加载资源，这个需要根据场景来做，比如字体 视频等

```js
<link rel="preconnect" href="https://static.admin.com/" crossorigin>
<link rel="dns-prefetch" href="https://static.admin.com/">
<link rel="preload" href="myVideo.mp4" as="video" type="video/mp4">
```

### 页面优化

- CSS 放头部，js 放底部
- 小图片用雪碧图或者 base64
- 图片无损压缩，可兼容场景用 webp 格式代替（服务器走 ua 头判断（
- script 添加 defer async 标签
- translateZ 加速渲染
- 用骨架屏延迟效果
- 注意重排/重绘的属性少用，找对应的代替方案

### vue

- 图片/路由懒加载
- 适量函数式组件
- 不在首屏的用 异步组件
- keep-alive 组件

### webpack

- ebpack-bundle-analyzer 看依赖
- 减少 vendors，懒加载
- 预渲染
- 按需加载
- 资源压缩

### 浏览器

- 资源 gizp 压缩
- 多域名资源
- http2 / 3
- 合并请求

### webview

- 客户端预先初始化 webview
- 客户端内置 vue 这种长期不变化的依赖
- 首屏请求交给客户端代理请求

## FCP 计算

首屏时间计算主要是基于getBoundingClientRect和MutationObserver，通过观察在页面一段时间内DOM变化的情况，然后通过判断是否在首屏显示进行数据过滤，找出最大一张图片的加载时间。

```js
class FCP {
  static details = [];
  static ignoreEleList = ["script", "style", "link", "br"];
  constructor() {}
  static isEleInArray(target, arr) {
    if (!target || target === document.documentElement) {
      return false;
    } else if (arr.indexOf(target) !== -1) {
      return true;
    } else {
      return this.isEleInArray(target.parentElement, arr);
    }
  }
  // 判断元素是否在首屏内
  static isInFirstScreen(target) {
    if (!target || !target.getBoundingClientRect) return false;
    var rect = target.getBoundingClientRect(),
      screenHeight = window.innerHeight,
      screenWidth = window.innerWidth;
    return (
      rect.left >= 0 &&
      rect.left < screenWidth &&
      rect.top >= 0 &&
      rect.top < screenHeight
    );
  }

  static getFCP() {
    return new Promise((resolve, reject) => {
      // 5s之内先收集所有的dom变化，并以key（时间戳）、value（dom list）的结构存起来。
      var observeDom = new MutationObserver((mutations) => {
        if (!mutations || !mutations.forEach) return;
        var detail = {
          time: performance.now(),
          roots: [],
        };
        mutations.forEach((mutation) => {
          if (!mutation || !mutation.addedNodes || !mutation.addedNodes.forEach)
            return;
          mutation.addedNodes.forEach((ele) => {
            if (
              // nodeType = 1 代表元素节点
              ele.nodeType === 1 &&
              this.ignoreEleList.indexOf(ele.nodeName.toLocaleLowerCase()) ===
                -1
            ) {
              if (!this.isEleInArray(ele, detail.roots)) {
                detail.roots.push(ele);
              }
            }
          });
        });
        if (detail.roots.length) {
          this.details.push(detail);
        }
      });
      observeDom.observe(document, {
        childList: true,
        subtree: true,
      });
      setTimeout(() => {
        observeDom.disconnect();
        resolve(this.details);
      }, 5000);
    }).then((details) => {
      // 分析上面收集到的数据，返回最终的结果
      var result;
      details.forEach((detail) => {
        for (var i = 0; i < detail.roots.length; i++) {
          if (this.isInFirstScreen(detail.roots[i])) {
            result = detail.time;
            break;
          }
        }
      });
      // 遍历当前请求的图片中，如果有开始请求时间在首屏dom渲染期间的，则表明该图片是首屏渲染中的一部分，
      // 所以dom渲染时间和图片返回时间中大的为首屏渲染时间
      window.performance
        .getEntriesByType("resource")
        .forEach(function (resource) {
          if (
            resource.initiatorType === "img" &&
            (resource.fetchStart < result || resource.startTime < result) &&
            resource.responseEnd > result
          ) {
            result = resource.responseEnd;
          }
        });
      return result;
    });
  }
}
```

## 其他优化

* 整个项目接入ssr/或重开新项目
* 新开ssg项目vue如gridsome
* 接入预加载webpack插件解决
