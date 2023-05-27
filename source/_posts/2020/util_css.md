---
title: "【技术笔记】工具类css"
date: 2020-11-08
lastmod: 2020-11-09
draft: false
tags: []
categories: []
author: "gzg1023"
reward: true
mathjax: false
toc: true
---

> 总结一些常用的css工具类
<!--more-->

### 省略号控制

#### 单行显示省略号

```
.ellipsis{
overflow: hidden;
text-overflow: ellipsis;
white-space: nowrap;
}
```

##### n行显示省略号

```
.ellipsis-wrap {
    width: 100%;
    overflow: hidden;
    display: -webkit-box; 
    -webkit-box-orient: vertical;   
    -webkit-line-clamp: 3;
}
```


### 文字换行控制

##### 不换行

```
.nowrap {
  white-space:nowrap;
}
```

##### 自动换行
```
.wrap-auto {
  word-wrap: break-word;
  word-break: normal;
}
```
##### 强制换行
```
.break-wrap {
  word-break:break-all;
}
```
#### 文本两端对齐
```
.text-justify {
    text-align: justify;
    text-justify: distribute-all-lines;  
    text-align-last: justify; 
}
```

### 操作控制

#### 禁止用户双击屏幕或者选中某些内容
```
.none-select {
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  -khtml-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-none: none;
}
```

#### 不同的鼠标图案
```
  cursor：pointer; //小手指；
  cursor：help; //箭头加问号；
  cursor：wait; //转圈圈；
  cursor：move; //移动光标；
  cursor：crosshair; //十字光标
  cursor: not-allowed; // 禁止选中
```
#### css使用硬件加速
```
.fast-machine{
  transform: translateZ(0);
}
```

#### css转换文字大小
```
.text-opp {text-transform: uppercase}  // 将所有字母变成大写字母
.text-low {text-transform: lowercase}  // 将所有字母变成小写字母
.text-cap {text-transform: capitalize} // 首字母大写
.text-small {font-variant: small-caps}   // 将字体变成小型的大写字母
```
#### 小于10px的字体显示
```
  font-size: 20px;
  transform: scale(0.5);
```
#### 自定义滚动条
```
overflow-y: scroll;
```
整个滚动条
```
::-webkit-scrollbar {
    width: 5px;
}
```

#### 滚动条的轨道
```
::-webkit-scrollbar-track {
    background-color: #ffa336;
    border-radius: 5px;
}
```

#### 滚动条的滑块
```
::-webkit-scrollbar-thumb {
    background-color: #ffc076;
    border-radius: 5px;
}
```


### flex相关

##### 设置为flex
```
.flex{
  display: flex;
}
```
##### flex垂直居中
```
.flex-center{
  display: flex;
  justify-content: center;
  align-items: center;
}
```
##### flex居中，分侧
```
.flex-center{
  display: flex;
  justify-content: space-between;
  align-items: center;
}
```


#### 常用动画

##### 转圈圈
animation: rotaCircle 1.5s linear infinite;
@keyframes rotaCircle {
  0% {
    transform: rotate(0deg);
  }
  25% {
    transform: rotate(90deg);
  }
  50% {
    transform: rotate(180deg);
  }
  75% {
    transform: rotate(270deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

##### 渐变

animation: gradientOpacity 1.5s linear infinite;
@keyframes gradientOpacity {
  0% {
    transform: opacity(0);
  }
  25% {
    transform: opacity(0.2);
  }
  50% {
    transform: opacity(0.6);
  }
  75% {
    transform: opacity(0.8);
  }
  100% {
    transform: opacity(1);
  }
}




