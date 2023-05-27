---
title: 【技术分享】入门浏览器里面的各种Observer对象
date: 2021-04-01
lastmod: 2021-04-01
tags: ['前端','性能优化']
categories: ['前端','性能优化']
toc: true
---

>  日常开发者经常碰到需要优化的需求，除了一些日常的判断和循环及各种监听，了解一下浏览器里面的各种Observer对象。
<!--more-->


## 需求来源

很早之前产品有一个需求，需要在管理系统的页面制作一个水印，但是不允许用户手动更改页面接口，删除水印。那么就用到``MutationObserver``这个api了，可以监听DOM的变化，从而对用户的修改做出反应。 

最近有一个需求，需要实时处理页面滚动内容的情况，于是想到了用``getComputedStyle``来获取DOM的位置，在chrome模拟器做了一个demo感觉效果也还行。于是打开app放到``webview``里面测试，刚访问页面的一瞬间app崩溃掉了。我还没反应过来，重新访问一次又崩溃了。百思不解，我注释了这段内容里面可以访问了，因为还需要找其他同事排查崩溃原因，于是寻找新的解决办法然后就搜索到了``IntersectionObserver`` 这个api。几行代码就实现了监听，并且性能也还不错，app也没崩溃。


解决了滑动的需求，发现自己对各种``Observer``的api不是很熟悉，有的甚至没听说过。于是写了本篇文章总结一些浏览器中好用的``Observer api``。

## 各种Observer

在没有搜索MDN之前，我只听说过个别api，没想到还有这么多(眼界太低了)。这些浏览器api都是浏览器提供的高性能api 专门针对某一些频繁操作/消耗性能 专门进行优化的api，关于各种``Observer``都是微任务，在浏览器空闲阶段触发，所以性能要比同步任务高很多。浏览器兼容方面也很不错，除了老IE 大部分现代浏览器都可以用。在移动端更是可以大展身手。

打开MDN搜索Observer可以看到有很多api，这里我拿出几个常用的进行分析，其他的有需求时候可以在看文档。

- MutationObserver 监视DOM树修改
- IntersectionObserver 观察目标元素状态
- PerformanceObserver 监测性能度量
- ResizeObserver 监视元素的大小更改


## MutationObserver

``MutationObserver``的作用是监听DOM树的变化，无论是修改``CSS``还是添加一个``p标签``，都在``MutationObserver``的管控下。对于DOM树的修改一般来说分为两种情况，一种是预设的dom路径，比如用户点击按钮动态创建一个弹窗，或者是滑动过程中，动态添加的数据项。
另外一种是预设之外的情况，比如用户打开``F12开发者面板``，在自己的浏览器对页面临时修改样式等。

不同的情况对应不同的需求，如果是第一种我们可以通过``MutationObserver``来计划行动监听DOM区域的变化，而且不是实时判断一个DOM区域的值是否产生来变化来解决性能消耗的问题，第二种情况可以用网页水印，防止用户篡改。

说了这么多，那就来看看怎么用吧.

### 创建MutationObserver配置和实例

对于观察DOM的需求，第一步肯定先指定targetNode作为需要观察的对象了，然后我们准备一个``observerOptions``配置对象，来配置``MutationObserver``的观察目标配置。然后就是通过new 来创建一个新的实例。

```javascript
let targetNode = document.getElementById('index-page')
let observerOptions = {
    attributeFilter: ['list', 'attribute'], // 字符串数组，用于指定要监听变化的属性名称,如果指定了会无视attributes
    attributeOldValue: true, // 布尔值， 记录任何有改动的属性的上一个值
    childList: true, // 布尔值，观察目标子节点的变化，是否有添加或者删除
    attributes: true, //  布尔值，观察元素的属性值变更
    characterData: false, // 布尔值， 监视指定目标节点或子节点树中节点所包含的字符数据的变化
    characterDataOldValue: false, // 布尔值， 在文本在受监视节点上发生更改时记录节点文本的先前值
    subtree: true // / 布尔值,观察所有后代节点(孙节点)，默认为 false
}
// 创建观察对象，并指定callback函数
let observerObj = new MutationObserver(callback)
```

### 启动/停止MutationObserver监听

在创建完MutationObserver和实例后，通过我们进行开始和停止的操作

```javascript
// 通过observe方法启动观察，第一个参数是需要观察的节点，第二个是观察配置信息
observerObj.observe(targetNode, observerOptions)

// 通过disconnect来停止观察，并且可以再次调用observe开启
observerObj.disconnect()

// 通过takeRecords来清空当前的观察队列，并返回已检测到但尚未处理的DOM更改的列表
observerObj.takeRecords()
```

### MutationObserver的calback

在创建完成后，并启动创建的实例后，每次变化都会调用``callback函数``，我们每次拿到的是DOM变化的``mutation数组``，每一对象都会存在以下的属性，然后就可以愉快的进行逻辑处理了。

```javascript
// mutationsList DOM变化数组，每一项代表一个DOM的独立变化
// observer 观察者的实例
const callback = (mutationsList, observer) => {
    let mutation = mutationsList[0] 
    // 每一个返回mutation节点
    mutation = {
        addedNodes: ' NodeList [comment]', // 被添加的节点
        attributeName: null, // 被修改的属性的属性名
        attributeNamespace: null, // 被修改属性的命名空间
        nextSibling: 'div', // 被添加或移除的节点之后的兄弟节点
        oldValue: null, // 根据type返回值
        previousSibling: 'text', // 被添加或移除的节点之前的兄弟节点
        removedNodes: ' NodeList []', // 返回被移除的节点。
        target: 'div.limit-lottery-box', // 变化影响的节点
        type: 'childList' // 变化的类型 。属性变化，返回 "attributes"
    } 
}
```


## IntersectionObserver

``IntersectionObserver``学名叫 交叉观察器，简单来说就是指定一个DOM元素然后观察位置变化，然后根据自己的需求做出处理。

### 创建IntersectionObserver


通过new创建``IntersectionObserver``实例，第一次参数是回调函数，在到达指定阀值的时候触发，第二个参数是配置对象

```javascript
let targetNode = document.getElementById('index-page')
let option = {
    root: document.documentElement, // 监听元素的祖先元素Element对象
    rootMargin: '0px 0px 0px 0px', //在计算交叉值时添加至根的边界盒中的一组偏移量
    threshold:[0.1，0.5.1.0] // 监听目标与边界盒交叉区域的比例(阈值)
}
let intersectionObj = new IntersectionObserver(callback,option)
```

### 启动/关闭IntersectionObserver实例

```javascript
// 通过observe方法启动观察,指定一个观察的元素节点,此元素必须是根元素的后代多次调用即可观察多个DOM节点
intersectionObj.observe(targetNode)

// 通过disconnect来停止全部观察
intersectionObj.disconnect()

// 通过takeRecords清除挂起的相交状态列表。返回一个 IntersectionObserverEntry 对象数组, 每个对象的目标元素都包含每次相交的信息, 可以显式通过调用此方法或隐式地通过观察者的回调自动调用.
intersectionObj.takeRecords()

// 停止对一个元素的观察
intersectionObj.unobserve(targetNode)
```


### IntersectionObserver的callback


回调函数，当触发滑动距离发生偏差时候触发。

```javascript
// entriesList IntersectionObserverEntry对象的数组
// observer 观察者的实例
const callback = (entriesList, observer) => {
    let entrie = entriesList[0] 
    entrie = {
        // 包含目标元素的边界信息的值与  Element.getBoundingClientRect() 相同
        boundingClientRect: DOMRectReadOnly {x: 0, y: -76, width: 1, height: 75, top: -76 …}
        // intersectionRect 与 boundingClientRect 的比例值.完全可见时为1，完全不可见时小于等于0
        intersectionRatio: 0
        // DOMRectReadOnly 用来描述根和目标元素的相交区域
        intersectionRect: DOMRectReadOnly {x: 0, y: 0, width: 0, height: 0, top: 0, …}
        // 布尔，目标元素与交叉区域观察者对象的根相交为true 否则false
        isIntersecting: false
        // 暂无介绍
        isVisible: false
        // 根元素的矩形区域的信息
        rootBounds: DOMRectReadOnly {x: 0, y: 0, width: 375, height: 812, top: 0, …}
        // 根出现相交区域改变的元素
        target: DOM
        // 可见性发生变化的时间
        time: 3445.7450000045355
    } 
}
```

### IntersectionObserver实现无限滚动

基于vue实现建议版高性能无限滚动组件,so easy 有木有！


```javascript

// infiniteLoad.vue 组件
<template>
  <div class="infiniteLoad">
    <slot>
    </slot>
  </div>
</template>

<script>
export default {
  name: 'infiniteLoad',
  data () {
    return {
    }
  },
  mounted () { 
    let intersectionObserver = new IntersectionObserver((entries)=> {
    console.log(entries)
    if (entries[0].intersectionRatio <= 0) return;
        this.$emit('loadmore')
      });
    intersectionObserver.observe(document.querySelector('.infiniteLoad'));
  }
}
</script>


// 使用

import  infiniteLoad  from "../components/infiniteLoad.vue"

<infinite-load
    @loadmore="loadmore"
></infinite-load>

loadmore() {
    console.log('loadMore')
}

```

## PerformanceObserver

``PerformanceObserver``还不太熟悉，也没碰到应用场景。先知道有这个东西，下次一定。😬

## ResizeObserver

这个api功能和``window.resize``类似，但是具有更高的性能。主要用来监听元素的大小更改，可以观察普通dom元素和svg元素。


### 创建ResizeObserver实例
```javascript
 const resizeObserver = new ResizeObserver(callback)
 resizeObserver.observe(document.documentElement)
```

### 启动/关闭ResizeObserver实例

```javascript
// 开始观察
resizeObserver.observe(targetNode)

// 通过disconnect来停止全部观察
resizeObserver.disconnect()

// 停止对一个元素的观察
resizeObserver.unobserve(targetNode)
```
### ResizeObserver的callback

```javascript
// entriesList IntersectionObserverEntry对象的数组
// observer 观察者的实例
const callback = (entries, observer) => {
    let entrie = entries[0] 
    entrie = {
        // 包含改变尺寸大小的元素的contentRect属性
        contentRect: contentRect {x: 0, y: -76, width: 1, height: 75, top: -76 …}
        // 当前改变尺寸大小的元素的 Element 引用
        target:  DOM
    } 
}
```