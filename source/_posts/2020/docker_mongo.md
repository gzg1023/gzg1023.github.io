---
title: 【技术分享】配置开发环境脑壳痛，docker真香！
tags: [调试,docker,mongdb]
categories: ["docker"]
date: 2020-12-22
lastmod: 2020-12-24
toc: true
---


> 某一天习惯性的把电脑升级到最新版，升级完成后有一个软件打开崩溃，平时没有用到过。索性就直接删除。直到前段时间，想学习下MongoDB，按照官网教程安装时候就出现了问题。
<!--more-->

无效操作

1. 通过brew安装后，一直显示Mac系统版本高，然后服务运行不起来。

2. 通过下载压缩包跑服务，运行起来以后还是显示stop服务。

搞了半天脑壳痛，还是安装不起来。查资料也没有太多Mac新系统的解决办法。于是就想到了用docker试一下，很早就听说过docker这个技术，但是自己一直没有接触过，这次就简单的基于docker安装一个mongo进行简单的了解。不得不说是真的很方便，安装简单，天然沙箱。


### 1. 安装docker客户端

因为国内网络的问题，brew也总出现问题，这里直接下载dmg安装文件进行安装，下面是链接

https://download.docker.com/mac/edge/Docker.dmg

直接拖动安装，就得到了这条小鲸鱼

[![rgRvnS.png](https://s3.ax1x.com/2020/12/24/rgRvnS.png)](https://imgchr.com/i/rgRvnS)

### 2. 注册docker账号，并配置docker镜像

注册账号就不说了，直接输入邮箱，收个验证码就可以了，
https://www.docker.com/

然后我们打开docker登陆账号，就看到下面的一个页面

[![rg2ACq.md.png](https://s3.ax1x.com/2020/12/24/rg2ACq.md.png)](https://imgchr.com/i/rg2ACq)


依然是国内的网络问题，我们配置docker的镜像源，如下图所示，在Dashboard配置镜像，这里采用七牛云和网易的镜像源服务。

        {
        "registry-mirrors": [
            "https://reg-mirror.qiniu.com",
            "https://hub-mirror.c.163.com/"
        ],
        "features": {
            "buildkit": true
        },
        "experimental": false
        }

[![rg2iUs.md.png](https://s3.ax1x.com/2020/12/24/rg2iUs.md.png)](https://imgchr.com/i/rg2iUs)

配置完成后，重启一下docker客户端。到这里docker安装配置就完成了。

### 3. docker下载MongoDB

打开命令行输入

    docker pull mongo

可以下载mongo的docker镜像，稍等一下下。完成后在命令行输入，如下图可以看到电脑中所有的镜像。

    docker images

[![rg2E80.png](https://s3.ax1x.com/2020/12/24/rg2E80.png)](https://imgchr.com/i/rg2E80)

#### 4. 运行docker镜像

在配置好环境，下载好镜像。我们通过命令行运行一个mongo的容器，默认不需要密码

    docker run -itd --name mongo-name -p 27017:27017 mongo

参数解释

    --name 是自己指定一个docker的名称如：mongo-name
    -p 27017:27017 ：映射容器服务的 27017 端口到宿主机的 27017 端口。外部可以直接通过 宿主机 ip:27017 访问到 mongo 的服务。

然后在命令行输入

    docker ps

[![rg2mKU.md.png](https://s3.ax1x.com/2020/12/24/rg2mKU.md.png)](https://imgchr.com/i/rg2mKU)

如下图所示，就可以看到运行的docker容器了，同时我们也可以在docker客户端的面板看到刚创建的服务。


创建好容器服务后，我们在命令行输入

    docker exec -it mongo-name mongo admin

就进入了docker的mongo命令行后终端。

[![rg2ZvT.md.png](https://s3.ax1x.com/2020/12/24/rg2ZvT.md.png)](https://imgchr.com/i/rg2ZvT)

也可以通过面板直接可视化的点击启动。打开mongo服务并进入终端或停止服务等

[![rg2F5n.md.png](https://s3.ax1x.com/2020/12/24/rg2F5n.md.png)](https://imgchr.com/i/rg2F5n)



#### 5. 项目中使用

在前面，我们配置了-p 27017:27017 ，也就是docker的mongo服务端口号映射到本地一致的端口号上面，我们直接打开项目，连接运行即可。
如果映射了不同的端口号，或者多个服务，记得修改相关映射即可。


