---
title: 【技术笔记】JS的String的各种API
tags: [前端,JavaScript]
index_img: https://s2.ax1x.com/2019/12/15/QfFzef.jpg
date: 2019-09-06 22:32:00
toc: true
---


String是js最常用的数据结果，本文最常见操作做一个总结
<!--more-->


> 操作字符串是前端开发中最常见的任务之一，本文总结操作字符串的一些方法，包括ES5,ES6版本及一些常见业务场景的例示

<span style="font-size:24px;color:#000;">方法开头有<b style="color:red">改</b>字的代表该方法会改变原Srting。
有<b style="color:#CC9900">原</b>字的代表，该方法不会改变原Srting</span>




### 基础知识

* 字符串可以视为字符数组可以用下标来访问（只读属性）。如：str[0]。## 标题文字 ##
* 通过String(5)把任意类型转为字符串

### 静态方法


#### charAt方法

> <b style="color:red">改</b>String.prototype.charAt() 方法返回指定位置的字符 

      'hello'.charAt(1) // "e"

#### concat方法

> <b style="color:#CC9900">原</b> String.prototype.concat() 方法用于连字符串，可以多选

       'hello'.concat('world') // "helloworld"

#### slice方法     

>  <b style="color:#CC9900">原</b> String.prototype.slice() 方法用原字符串提取子字符串。第一个参数是子字符串的开始位置，第二个参数是子字符串的结束位置（不含该位置）

      'hello'.slice(0,2) // he

#### substr方法     

>  <b style="color:#CC9900">原</b> String.prototype.substr()可在字符串中抽取从 start 下标开始的指定数目的字符。第一个参数是要抽取的子串的起始下标，第二个参数是子串中的字符数

      'hello'.substr(3) // lo

#### substring方法     

>  <b style="color:#CC9900">原</b> String.prototype.substring() 方法用于提取字符串中介于两个指定下标之间的字符。第一个参数是要抽取的子串的起始下标，第二个参数是子串中的字符数

      hello'.substring(3) // lo

#### indexOf方法

>  <b style="color:#CC9900">原</b> String.prototype.indexOf() / lastIndexOf()  方法用于确定一个字符串在另一个字符串中第一次出现的位置，返回结果是匹配开始的位置。如果返回-1，就表示不匹配 (lastIndexOf从尾部开始匹配，indexOf则是从头部开始匹配。)

      'hello world'.indexOf('o') // 4
      'hello world'.lastindexOf('o') // 7

#### trim方法

>  <b style="color:#CC9900">原</b>String.prototype.trim()方法用于去除字符串两端的空格

      ' fdf '.trim()  //'fdf'
#### toLowerCase方法
> <b style="color:#CC9900">原</b>String.prototype.toLowerCase()  / toUpperCase() 将一个字符串全部转为小写 / 大写

      'Hello World'.toLowerCase()// "hello world"
      'Hello World'.toUpperCase()// "HELLO WORLD"

#### match方法

> <b style="color:#CC9900">原</b>String.prototype.match()方法用于确定原字符串是否匹配某个子字符串，返回一个数组，成员为匹配的第一个字符串。如果没有找到匹配，则返回null

      var matches = 'cat, bat, sat, fat'.match('at'); <br>
      matches.index // 1
      matches.input // "cat, bat, sat, fat"

#### split方法

> String.prototype.split() 方法按照给定规则分割字符串，返回一个由分割出来的子字符串组成的数组. 第一个参数是分割规则，第二个参数，限定返回数组的最大成员数。
     
      'a|b|c'.split('|') // ["a", "b", "c"]

#### relapce方法

> String.prototype.relapce()  用于在字符串中用一些字符替换另一些字符，或替换一个与正则表达式匹配的子串。

      'Im your father'.replace('father','mother') // Im your mother

#### search方法

> \ String.prototype.search() 强于indxOf)  检索字符串中指定的子字符串，或检索<b>正则表达式</b>相匹配的子字符串。

      '123456ONE'.search('O') // 6

#### localeCompare方法

>  String.prototype.localeCompare()方法用于比较两个字符串。它返回一个整数，如果小于0，表示第一个字符串小于第二个字符串；如果等于0，表示两者相等；如果大于0，表示第一个字符串大于第二个字符串

      'apple'.localeCompare('banana') // -1
      'apple'.localeCompare('apple') // 0

#### includes方法

> String.prototype.includes() 方法用于判断一个字符串是否包含在另一个字符串中，根据情况返回 true 或 false。第一个参数是要在此字符串中搜索的字符串，第二个参数是从当前字符串的哪个索引位置开始搜寻子字符串，默认值为0 (区分大小写)

      'Blue Whale'.includes('blue'); // returns false

#### startsWith方法

> String.prototype.startsWith() 方法用来判断当前字符串是否以另外一个给定的子字符串开头，并根据判断结果返回 true 或 false (区分大小写)

      "To be, or not to ".startsWith("To be"); // returns true

#### padStart方法
> String.prototype.padStart() / padEnd() 方法用另一个字符串填充当前字符串(重复，如果需要的话)，以便产生的字符串达到给定的长度。填充从当前字符串的开始(左侧) / (右侧)应用的。 第一个参数 当前字符串需要填充到的目标长度。如果这个数值小于当前字符串的长度，则返回当前字符串本身，第二个参数 填充字符串。如果字符串太长，使填充后的字符串长度超过了目标长度，则只保留最左侧的部分，其他部分会被截断。此参数的缺省值为 " "（U+0020）

      'abc'.padStart(10, "foo");  // "foofoofabc"
      'abc'.padEnd(10, "foo");   // "abcfoofoof"

### 其他方法

#### btoa方法
> btoa() 把任意值转为Base编码

      btoa('hello world') // "SGVsbG8gV29ybGQh"
      
#### atob方法
> atob() 把Base64编码转为原来的值

      atob("SGVsbG8gV29ybGQh") // 'hello world'
