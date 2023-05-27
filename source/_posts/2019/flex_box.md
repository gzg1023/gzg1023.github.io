---
title: 【技术笔记】CSS之Flex弹性盒子属性详解
tags: [前端, CSS]
index_img: https://s2.ax1x.com/2019/11/24/MOazKH.png
date: 2019-03-15 15:14:00
toc: true
---

随着移动端软件系统的普及，传统布局方式在很多功能上受到了限制，本文详解flex布局各个属性，在工作中熟练使用flex布局。
<!--more-->


在传统css布局中，一般来说是采用float+margin+positon来解决常见问题。但是随着移动端的普及，尤其是各种“小程序"的出现显然传统的布局是由很多弊端的，比如垂直居中就不好实现。（flex布局兼容到ie10以上）


flex弹性盒子的结构是父容器和子元素组成的，由父元素包裹，子元素组成基本结构如下。需要注意的是在flex布局中，有的属性是作用在父元素，有的属性是作用在子元素，以下介绍相关的属性。

```
<div class="FatherWrap" style="display:flex">
    <div class="Child1"></div>
    <div class="Child2"></div>
</div>
```

开门见山，比如使用flex布局实现一个垂直居中,只需要把父类盒子设置为flex，然后给子属性添加margin:0;即可

```
<div style="display:flex">
    <div style="margin:auto"></div>
</div>
```

![请输入图片描述][1]

## flex<b color="red">父</b>容器布局属性 

| 属性 | 详细说明 | 属性值 |
|-----|:---------:|:---------|
|flex-direction|决定主轴的方向（即项目的排列方向）| row(水平方向，起点在左端) ，row-reverse(起点在右端)  ，column(主轴为垂直方向，起点在上沿)  ，column-reverse(起点在下沿)|
|flex-wrap|控制Flex容器是单行显示还是多行显示，而交叉轴的方向就决定着新线的排列方向| nowrap(不换行) , wrap(换行) , wrap-reverse(换行与wrap相似，但行的顺序是倒过来的)|
|flex-flow|flex-flow属性是flex-direction属性和flex-wrap属性的简写|flex-flow属性是flex-direction属性和flex-wrap属性的简写| 
|justify-content|	定义了Flex项目在主轴方向上的对齐方式| flex-start(类似于左浮动) , flex-end(类似于右浮动) , center(Flex项居中) , space-between(两端对齐容器，各个Flex项目之间的间距相等) , space-around(每一个Flex项目两侧的间隔相等)|
|align-items|定义项目在交叉轴上的对齐方式|  flex-start(对齐交叉轴的起点) , flex-end(对齐交叉轴的终点) , center(以交叉轴为参考，居中对齐) , baseline(Flex项目第一行文字基线对齐) ,  stretch(如果Flex项目未定义高度或者设置为auto，Flex项目将占满整个窗口的高度)|
|align-content|定义了多根轴线的对齐方式，如果只有一条轴线，那么此属性不起作用|  flex-start(对齐交叉轴的起点) , flex-end(对齐交叉轴的终点) , center(以交叉轴为参考，居中对齐) , space-between(交叉轴两端对齐，轴线这间的间隔平均分布) , space-around(Flex项目（沿交叉轴方向）之间的间隔相等) , stretch(Flex项目（沿交叉轴方向）占满整个交叉轴)|
<br>
> **juestify-conent**

![juestify-conent][2]

> **align-items图示**

![align-items][3]

> **align-conent图示**

![align-conent][4]

## flex<b color="red">子</b>元素布局属性 

| 属性     | 值  |   说明  |
|--------|--------|-------|
|order|length|设置子元素排列顺序。数值越小，排列越靠前,（默认为0）|
|flex-grow| length| 设置字元素放大占比。数值越大，占比越大（默认为0）|
|flex-shrink | length| 设置字元素缩小占比。数值越大，占比越小（默认为1）|
|flex-basis|length|设置字元素占比宽度。默认为auto|
|flex|flex-grow, flex-shrink , flex-basis|默认值为0 1 auto。后两个属性可选。|
|align-self|auto,flex-start,flex-end,center,baseline,stretch|设置字元素的对其方式 |
<hr>

> **flex-grow**

![flex-grow图][5]

> **flex-shrink**

![flex-shrink][6]

> **flex-basis**

![flex-basis][7]

> **align-self**

![align-self][8]


  [1]: https://s2.ax1x.com/2019/11/24/MOwNp8.png
  [2]: https://s2.ax1x.com/2019/11/24/MOBszT.jpg
  [3]: https://s2.ax1x.com/2019/11/24/MOBrWV.jpg
  [4]: https://s2.ax1x.com/2019/11/24/MOBDJ0.jpg
  [5]: https://s2.ax1x.com/2019/11/24/MOBBiq.jpg
  [6]: https://s2.ax1x.com/2019/11/24/MOBwon.jpg
  [7]: https://s2.ax1x.com/2019/11/24/MOB6QU.jpg
  [8]: https://s2.ax1x.com/2019/11/24/MOBcyF.jpg