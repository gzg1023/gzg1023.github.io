---
title: 【技术分享】从前端的角度，谈谈解决跨域的一些方案
tags: [前端]
index_img: https://s2.ax1x.com/2019/09/18/nHXVfK.jpg
date: 2019-08-31 23:08:00
toc: true
---


跨域开发是web系统中前后端分离开发模式必须考虑的事情，本篇文章从前端角度谈谈跨域的解决办法。
<!--more-->

前端跨域研究
--------
## 1. 什么是跨域
在所有支持JavaScript的浏览器中，都有一个约定叫同源策略。所谓同源是指"协议+域名+端口"三者相同。如果缺少了同源策略，浏览器很容易受到XSS、CSFR等攻击。如果应用程序违反了同源策略进行通信，那么就会产生跨域问题。 
> 同源策略有以下几种行为限制：
* Cookie、Local Storage 和 Index DB 无法读取
* DOM和JS对象无法获得
* AJAX 请求不能发送

在DOM结构中，有三个标签可以进行跨域行为`<link>`，`<img>`，`<script>`，有一种解决跨域的方式叫JSONP，利用的就是script可以跨域的特性。解决跨域有很多办法，如果是在企业内部开发中，最推荐的是设置CORS和跨域代理。
前端项目设置跨域代理都是通过`http-proxy-middleware`模块实现的。

## 2. CORS配置跨域
由后端程序员直接设置CORS响应字段，这种情况不支持IE10以下的浏览器。
1）	`Access-Control-Allow-Origin`：必选
  它的值要么是请求时Origin字段的值，要么是一个*，表示接受任意域名的请求。
2）	`Access-Control-Allow-Credentials`：可选
  它的值是一个布尔值，表示是否允许发送Cookie。默认情况下，Cookie不包括在CORS请求之中。设为true，即表示服务器明确许可，Cookie可以包含在请求中，一起发给服务器。这个值也只能设为true，如果服务器不要浏览器发送Cookie，删除该字段即可。
3）	`Access-Control-Expose-Headers`：可选
  CORS请求时，XMLHttpRequest对象的`getResponseHeader()`方法只能拿到6个基本字段：`Cache-Control、Content-Language、Content-Type、Expires、Last-Modified、Pragma`。如果想拿到其他字段，就必须在`Access-Control-Expose-Headers`里面指定。上面的例子指定，`getResponseHeader('FooBar')`可以返回`FooBar`字段的值。
<
## 3.	Vue-cli2配置跨域代理
由于vue-cli2是配合webpack2使用的，首先需要找到config文件夹的index.js文件然后配置proxyTable参数，如下所示，具体参数如表1.1所示参数说明：

    proxyTable: {
          '/api/': {
            target: 'http://192.168.1.22:9001',
            changeOrigin: true,
            pathRewrite: {
              '^/api/': ''
          }
          }

|参数|	类型|备注|
|----|-------|----|
|'/api'	| api对象 |捕获API的标志，如果API中有这个字符串，那么就开始匹配代理比如API请求/api/users, 会被代理到请求 http:baidu.com/api/users|
|target|域名/IP地址|代理的API地址，就是需要跨域的API地址，地址可以是域名,如：http://www.baidu.com 也可以是IP地址：http://192.168.1.22:9001
|pathRewrite|'^/api/': ' ' |路径重写，也就是说会修改最终请求的API路径比如访问的API路径：/api/users, 设置pathRewrite: {'^/api' : ''},后，最终代理访问http://www.baidu.com/users， 这个参数的目的是给代理命名后，在访问时把命名删除掉|
|changeOrigin|布尔值|如果后端服务是一个IP对应多个域名。需要通过域名区分服务，则该值必须是true|
|secure|布尔值|设置false(默认)后，可以接受运行在 HTTPS 上，可以使用无效证书的后端服务器|	

(表1.1) 

## 4.	Vue-cli3配置跨域代理
Vue-cli3的配置项目没有cli2那么多文件结构了，只需要在devServe对象(所有 webpack-dev-server都可以在这配置)里面配置proxy对象即可，如下所示。具体参数和表1.1相同。

    proxy: {
        '/api': {
          target: 'http://192.168.1.21:9101/daas',
          changeOrigin: true,
          pathRewrite: {
            '/api': ''
           }
          }
      }

## 5.	Koa配置跨域代理
我们创建一个js文件(例如proxy.js)，来构建代理服务，先实例化一个koa对象，然后配置app对象的proxy属性，详情参数见表1.1。配置到代理属性，需要本地启动一个node服务，然后我们通过命令行启动该服务node  proxy.js

    const app = new Koa()  // 创建koa对象
      app.use(async (ctx, next) => {
        ctx.respond = false //绕过koa内置对象response ，写入原始res对象，而不是koa处理过的response
          return proxy({
            target: 'http://192.168.1.21:9003',
            changeOrigin: true,
            secure: false,
            pathRewrite: {
            '^/proxyAPI': ''
            }
          })(ctx.req, ctx.res, next)
        }
        return next()
      })
      app.listen(3000, () => {
          console.log('Listening 3000...')
      })

## 6.	Nuxt.js配置跨域代理
在nuxt项目中首先安装proxy代理库 npm i @nuxtjs/proxy -D 然后在next.config.js配置文件中添加模块设置代理

     modules: [
        '@nuxtjs/axios',
         '@nuxtjs/proxy'
      ],
       axios: {
        proxy: true
      },
        proxy: {
          '/api': {
              target: 'http://example.com',
            pathRewrite: {
           '^/api' : '/'
         }
       }
      }

## 7.	Nginx配置跨域代理
通过nginx的反向代理，把客户端的请求转发到服务端，然后服务端返回数据以后，在转发回客户端。
如果是开发环境需要配置两个代理，一个是把项目代理到本地nginx服务器，另一个是代理服务器传来的数据。
如果是打包线上环境，那么只要配置一个代理做转发即可。

      server {
        listen       8085;
        server_name  localhost;
        location / {
            proxy_pass http://localhost:8080;
        }
        location /daas/api {
            proxy_pass http://192.168.1.21:9097/daas;
            rewrite ^/api/(.*)$ /$1 break;
        }
     }

## 8.	Apache配置跨域代理
Apache和nginx原理相同，都是做反向代理。只是需要修改相关的配置文件来完成
   <`proxy ` `http://192.168.1.21:9091/daas`>
      `AllowOverride None`
     ` Order Deny,Allow`
      `Allow from all`
   </`proxy`>

## 9.	Chrome插件配置跨域代理
通过安装`Allow-Control-Allow-Origin`浏览器插件，来解决跨域问题，前提是后端会判断你是否存在跨域权限，发送一个options请求先预判断，然后在进行跨域处理。
 