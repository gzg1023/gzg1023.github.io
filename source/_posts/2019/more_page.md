---
title: 【技术分享】vue-cli3脚手架工具搭建多页面应用
tags: [前端, webpack]
index_img: https://s2.ax1x.com/2019/09/21/nvR8rn.png
date: 2019-09-20 21:02:00
toc: true
---

公司需要做一个新的项目，需要用vue构建一个多页面应用，网上看了一些博客不是写了一半，就是写的很高深。于是自己摸索搭建了项目，现在来总结一下。
<!--more-->


### 第一步：用脚手架搭建一个vue项目

> 话不多说先创建项目 vue create 项目名称   这里我们选sfa默认配置，然后直接把项目跑起来

![请输入图片描述][1]

### 第二步：手动添加一个vue.config.js来配置webpack

![请输入图片描述][2]

#### 在vue-cli3的项目中，我们通过pages对象来配置多页应用

> 参考链接  https://cli.vuejs.org/zh/config/#pages 

如下所示，我们通过pages对象来配置多页应用的入口及其他参数，project1和project2是两个单页，我们分别对其进行配置入口文件及模板来源，其他配置信息可点击上方参考链接。

![请输入图片描述][3]

### 第三步：配置项目结构

  在配置为入口后，我们现在pulic文件夹建好模板文件 project1.html 和 project2.html ,然后在我们的src目录建一个文件夹pages 里面放我们两个应用的源码。正常项目vuex和vue-router都是封装起来的，这边我们只演示内容。

![请输入图片描述][4]

### 第四步：重启项目，访问
我们在最初的项目url上加上相应页面的路由信息，就可以访问了。

![请输入图片描述][5]


  [1]: https://s2.ax1x.com/2019/09/20/nvBzrT.png
  [2]: https://s2.ax1x.com/2019/09/20/nvrvHU.png
  [3]: https://s2.ax1x.com/2019/09/20/nvgCdK.png
  [4]: https://s2.ax1x.com/2019/09/21/nvg4YD.png
  [5]: https://s2.ax1x.com/2019/09/21/nv20Bt.png