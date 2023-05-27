---
title: 【原理探索】vue.js超级全家桶--原理分析及技术学习清单
date: 2021-03-05
lastmod: 2021-04-25
tags: ['前端','vue原理']
categories: ['技术','vue原理']
author: "gzg1023"
toc: true
---


> vue.js在2016年爆🔥，到现在在中国已经是非常主流的前端框架，使用框架已经2年时间从本文开始，啃源码，解析原理，学习超级全家桶。
<!--more-->

## 目录

系列文章，针对vue超级全家桶原理进行分析及新技术的学习的清单，鞭策自己一步一步完成。根据时间和学习进度同步修改。系列文章并不是详细的针对Vue源码的分析 深入到什么行实现了什么功能，而是个人对Vue框架的一些理解和常用api的一些解析。能帮助自己更好的使用Vue框架。

1. vue.js(2.x)框架底层原理- 实现mini vue
2. vue.js(2.x)原理 - new Vue流程梳理 及源码版生命周期分析
3. vue.js(2.x)原理 - Vue响应式核心Observer,Dep及Watcher和异步更新队列
4. vue.js(2.x)原理 -  Vue内置指令及内置组件（v-show, v-if, v-for , v-model,keep-alive
5. vue.js(2.x)原理 - Virtual dom及Compile模版编译器原理分析
6. vue-router(3.x) - vue官方路由库原理学习
7. vuex(3.x) - Vue官方状态管理库源码分析
8. vue-ssr(2.x) - vue主流ssr框架手动搭建及主流nuxt.js原理学习
9. vue-cli(3.x) - Vue官方脚手架工具源码分析
10. vue.js(3.x) - vue3新版本学习及原理分析
11. vite2 - vue官方新开发工具使用及原理分析
12. gridsome - vue主流ssg框架使用及原理


## 源码附录

| 文件名 | 作用 |
| - | - |
| .circleci | 持续集成/持续部署(ci/cd)配置 |
| .github | 存放针对项目开发/贡献代码的文档（基于github） |
| benchmarks | vue的一些性能测试文件和demo （好几年没维护了） |
| dist | 打包后的vue源码（多种构建/规范版本） |
| examples | 基于vue的一些demo小项目（好几年没维护） |
| flow | 类型检查工具flow定义的地方（各种内置功能的类型定义） |
| packages | vue插件包，在配合开发工具项目时候按需使用 |
| scripts | vue打包的配置文件及一些自动化脚本 |
| src | 源码目录结构 |
| test | 单元测试/e2e测试用例目录 |
| types | 针对typeScript的类型声明文件及配置 |

### 源码核心模块

```javascript
 src/

- compiler：编译源码相关文件夹
- core：核心代码文件夹
- platforms：不同平台支持文件夹
- server：支持服务端渲染文件夹
- sfc：.vue单文件解析文件夹
- shared: 共享代码

```

### 构建后的版本

打包后会产生很多类型的文件，默认的vue是Runtime +  UMD 版本的构建，也是vue-cli默认导出的版本。

runtime版本是不包含Compiler的版本。其中带min的是压缩版本，适用于线上生产环境。

| 模块类型| UMD 规范 | CommonJS 规范| ES Module 规范 |
| --- | --- | --- | --- |
| **全部** | vue.js | vue.common.js | vue.esm.js |
| **Runtime版本** | vue.runtime.js | vue.runtime.common.js | vue.runtime.esm.js |