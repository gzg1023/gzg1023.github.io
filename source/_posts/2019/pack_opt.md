---
title: 【前端技术】基于vue的webpack打包优化浅析
tags: [前端, webpack]
index_img: https://s2.ax1x.com/2019/12/15/QfkCFg.jpg
date: 2019-11-19 13:24:00
toc: true
---

在项目迭代的过程中，打包后的资源越来越大。于是我们通过一些优化手段减小打包后的静态资源
<!--more-->


webpack优化（基于vue-cli3）
------

前端webpack优化研究
## 1.	打包优化

优化webpack打包项目，从两方面来解决问题，一方面是检查项目中未使用或只使用了部分的功能模块（js库），我们进行按需加载。另一方面是引入一些打包优化的loader和plugins。
首先我们安装webpack-bundle-analyzer模块，来查看项目构建模块的大小。如下图所示，项目比较大的资源文件都是引入的UI库和一些图表，时间的插件组成。
 
  ![请输入图片描述][1]

赘余优化
我们可以看到，项目中最大的组件是element-ui，由于我们项目中使用了90%的组件，这里就不再进行按需加载，全部引入即可。看图中项目构建结构，发现moment.js库是比较大的，而在项目中我们只是用的一部分的API。由于该组件没有办法进行按需加载，我们使用IgnorePlugin插件进行优化。我们看到引入了该插件后，打包后的资源从2.16M变成了1.95M
 
   ![请输入图片描述][2]

插件优化
在项目构建的过程中，默认情况下项目会自动为我们分解多个chunk，此时可能有的文件只有几B，但是也会产生多一次的http请求。于是我们考虑使用LimitChunkCountPlugin插件来分离chunk，减少http请求优化我们的项目。该插件的方法很简单，通过MaxChunks来限制chunk产生的数量，通过minChunkSize来设置每个chunk最小的值。如下图所示，我们配置好该plugin，然后构建项目，发现项目的大小从1.95M变成的1.79M.

   ![请输入图片描述][3]
 
## 2.	构建优化
在项目的构建过程中，有时候会很耗时，影响开发效率，我们引入UglifyJsPlugin插件来提高构建速度，如下所示
 
  ![请输入图片描述][4]

如果是大型项目，我们需要引入DLLplugin插件来实现bundles

  ![请输入图片描述][5]
 
可以看到进行一系列的优化后，

  ![请输入图片描述][6]

  ![请输入图片描述][7]

  ![请输入图片描述][8]

  ![请输入图片描述][9]

 
## 3.	参考链接
Webpack plugins插件 https://webpack.docschina.org/plugins/
Vue-cli 配置https://cli.vuejs.org/zh/config/  

[1]:https://s2.ax1x.com/2019/12/07/QtcvWD.png
[2]:https://s2.ax1x.com/2019/12/07/QtczSe.png
[3]:https://s2.ax1x.com/2019/12/07/QtcLo6.png
[4]:https://s2.ax1x.com/2019/12/07/QtcjJO.png
[5]:https://s2.ax1x.com/2019/12/07/Qtcqdx.jpg
[6]:https://s2.ax1x.com/2019/12/07/QtgSQH.png
[7]:https://s2.ax1x.com/2019/12/07/Qtgpyd.jpg
[8]:https://s2.ax1x.com/2019/12/07/Qtg9OA.jpg
[9]:https://s2.ax1x.com/2019/12/07/QtgPeI.png