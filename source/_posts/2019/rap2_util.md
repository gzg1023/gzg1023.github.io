---
title: 【技术分享】rap2接口管理工具使用分享
tags: [前端,工具]
index_img: https://s2.ax1x.com/2019/09/06/nQAycD.jpg
date: 2019-07-05 21:50:00
toc: true
---

公司用的淘宝的rap2来作为接口管理工具，一方面方便前后端联调，另一方面可以为前端开发Mock数据。也能保证在维护项目的过程中，提高效率。
<!--more-->
## 1. 什么是rap2 ##
RAP是一个可视化接口管理工具 通过分析接口结构，动态生成模拟数据，校验真实接口正确性， 围绕接口定义，通过一系列自动化工具提升我们团队开发的协作效率。
 
 ## 2. 为什么要用rap ##
在前端开发过程中，我们需要实时与后端进行数据交互。然而大多数时候，前端开发都是在没有后端数据提供的情况下进行的，这时我们就需要用到假数据模拟。rap2是一款在线模拟数据生成器，可以拦截Ajax请求，其作用在于帮助前端工程师独立于后端进行开发，实现前后端分离。
* 支持mock.js语法：RAP本身基于mcok.js
* 支持接口管理：可管理url地址，不同模块分类。
* 支持团队协作：拥有团队仓库
* 支持历史修改操作查看：可查看接口修改情况，但不支持操作回溯。
*  接口共享：不需要重复编写接口
*  自动化测试：一键测试接口情况
 ## 3. 怎么使用rap ##

3.1   搭建rap环境 
3.2 用户使用Rap

![rap][1]

如上图所示，在我们在定义好Rap接口后，在生成规则部分填写我们的Mock语句，Rap系统就会自动生成数据。
如果我们前端想在项目中进行Mock，需要用npm在项目中安装Mockjs模块，然后在项目中的Mock.js中配置需要Mock的属性项
3.3 Mock.js数据模板规则
数据模板中的每个属性由 3 部分构成：属性名、生成规则、属性值：
*	属性名   name
*	生成规则 rule
*	属性值   value
生成的规则如 'name|rule': value
1.	name是规则的属性值，对应真实数据结构的key

2.	rule（生成规则）解析：必须写在|后面。生成规则依赖于属性值（value）的
类型

|  属性 | 备注 |
|--------|--------|
|   min-max     |    最小值到最大值    |        
|   count    |   数量     |        
|    min-max.dmin-dmax   |     最小值到最大值及小数点后保留的位数范围   | 
|   min-max.dcount    |    	最小值到最大值及小数点后保留dcount位    | 
|   count.dmin-dmax    |    	数量及小数点后保留的位数范围    | 
|    count.dcount   |    	数量及小数点后保留dcount位    | 
|    +/-step   |    从value递增/减    | 

	
3.	value解析

|属性|备注|
|----|---|
|  String   |   属性值是字符串  |
|  Number	  |  属性值是数字   |
|   Boolean  |  属性值是布尔值   |
|   Object  |   属性值是对象  |
|  Array   |  属性值是数组   |
|   Function  |  属性值是函数   |
|  RegExp   |  属性值是正则   |
4.	数据占位符规范
占位符只是在属性值字符串中占个位置，并不会出现在最终的属性值中。
格式：
@占位符
@占位符(参数 [, 参数])
1)	用 @ 来标识其后的字符串是 占位符。

2)	占位符 引用的是 Mock.Random 中的方法。

3)	通过 Mock.Random.extend() 来扩展自定义占位符。

4)	占位符 也可以引用 数据模板 中的属性。

5)	占位符 会优先引用 数据模板 中的属性。

6)	占位符 支持 相对路径 和 绝对路径。
3.4 Rap2-Mock数据模板规则
如下表所示，如果需要特定的数据时候，只需在占位符前面加上@符合即可
（例：@date,随机产生一个时间）。

| 类型	| 占位符	| 备注 |
|-----|-------|------|
|  Basic（基础类）  |  boolean, natural, integer, float, character, string, range, date, time, datetime, now  |     |
|  Image（图片）  |  image, dataImage  |  图片地址   |
|  Color（颜色值）  |  color  |   16进制字符串  |
|  Text  |  	paragraph, sentence, word, title, cparagraph, csentence, cword, ctitle  |  段落，标题等   |
|  Name  |  first, last, name, cfirst, clast, cname  |   姓名，姓，名占位符最前面是c的代表产生中文数据  |
|  Web  |  url, domain, email, ip, tld  |  地址，域名，邮箱，ip地址   |
|  Address  |  	area, region  |  地区，方向   |
|  Helper  |   capitalize, upper, lower, pick, shuffle |     |
|  Miscellaneous  |  guid, id	  |     |
		
		
 
特殊类型例示

|类型	|初始值	|备注|
|-----|-------|------|
|  纯数字   |   @integer(1,100)    |    	括号里面1-100表示随机生成一个1-100里面的数字   |
|  指定长度的字符串   |    @string(5,8)   |   括号里面5-8表示随机生成一个5-8位的字符串，写一个数字代表，指定长度    |
|   指定类型的日期  |   @date(yyyy-MM-dd)    |    括号里面(yyyy-MM-dd)代表格式日期的规范，如果想要指定年份，月份直接修改字符串如@date(2019-01-dd)   |
|  纯数字数组   |   [5]	    |       |
|  纯字符串数组   |   ['a','b']	    |   只需要给数据加上引号即可    |

 ## 4.  维护和持续使用Mock ##

持续使用rap需要前端和后端一起配合，当确定项目需求后，后端程序员开始定义数据库和rap接口的数据结构。由前端进行Mock的语法规则编写。Rap定义完成后，我们可以直接通过网页url来查询Mock数据是否自动生成。然后前后端就可以分别进行各自的开发工作了。
如果在项目的开发过程中缺少参数或接口，要先沟通清楚产品需求，在进行Rap的更改，并标明哪些是新添加的字段或接口。


通过rap平台，可以直接Mock数据供开发使用，我们直接点击接口地址，就可以打开Mock数据的链接了。
 ![图4.3][2] 

当打开链接路径为http://192.168.1.24/api/app/mock/57/table 但是没有匹配到需要的数据，此时我们的请求是post请求，在postman中测试即可得到数据。如图4.4所示。就可以拿到想要的数据了。
 
![请输入图片描述][3]

4.2.在Mock.js中使用

1)获取列表数据Mock实例

    router.post('/amdin/getOrderList', async (ctx) => {
          let items = Mock.mock({
           'items|10': [
              {
            'orderId|1-8': '1',
            'applicantUserId|1-999': 1,
            'productName': '@productName',
            'productId|1-10': '2',
            'departmentName': '@departmentName',
            'departmentDn': '@departmentDn',
            'applicationType|1-3': '1',
            'description|1-3': '调整配置',
            'applicationTime': '@time',
            'applicationId': '@applicationId'
              }
        ]
      })
      await sleep(2000)
      res.data = { ...page, ...items }
      ctx.body = res
    })


## 5.	附录 ##
(1).Mock数据规则查询http://mockjs.com/examples.html <br>
(2)Rap2官网http://rap2.taobao.org/



  [1]: https://s2.ax1x.com/2019/09/06/nQPdWF.jpg
  [2]: https://s2.ax1x.com/2019/09/06/nQkPRU.jpg
  [3]: https://s2.ax1x.com/2019/09/06/nQkkM4.jpg