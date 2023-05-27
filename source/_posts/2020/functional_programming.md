---
title: 【技术分享】函数式编程入门初探
date: 2020-11-27
lastmod: 2020-11-27
draft: false
tags: ['前端','JavaScript','函数式编程']
categories: []
author: "gzg1023"
reward: false
mathjax: false
toc: true
---

>  JavaScript作为一门“灵活的语言，在使用过程中有很多”骚操作“，但是带来的问题也是很多的。通过FP编程，让代码健壮。

<!--more-->

函数式编程用来描述数据（函数）之间的映射关系。简单点来说就是把操作数据的过程用函数封装起来，就是函数式编程的思维。
FP编程特点：子任务，纯函数、函子、无状态。

部分手写代码地址： [https://github.com/gzg1023/fackAchieve](https://github.com/gzg1023/fackAchieve) 

## 使用FP思维开发的产物

- **[Redux](https://fe.rualc.com/note/redux.html)**
- **[Immutable](https://immutable-js.github.io/immutable-js/)**

```
//传统方式计算两数之和
let result1 = a + b
let result2 = c + d

// 函数式编程计算两数之和
function addFun(a,b){
   return a + b
}
let result3 = addFun(e,f)
```

## 函数式编程特点

### 1.函数是"一等公民"

- 函数可以存储在变量中
- 函数作为参数
- 函数作为返回值

> 高阶函数

如：map, filter, forEach

实现见 [https://github.com/gzg1023/fackAchieve](https://github.com/gzg1023/fackAchieve)

### 2.纯函数（数学上的函数）

相同的输入，永远会得到相同的输出，而且没有任何可观察的副作用。

好处：

- 可缓存，因为每次输入会输入一样的结果。
- 可测试，纯函数可以让测试更方便
- 并行处理，纯函数不需要共享变量（用在web worker）

副作用包括不限于：

- 更改文件系统
- 往数据库插入记录
- 发送一个 http 请求
- 可变数据
- 打印/log
- 获取用户输入
- DOM 查询
- 访问系统状态

### 3.柯里化

1. 只传递给函数一部分参数来调用它，让它返回一个函数去处理剩下的参数。
2. 内部使用闭包缓存参数，让函数变的更灵活，函数的粒度更小
3. 当一个函数有多个参数的时候先传递一部分参数调用它(这部分参数以后永远不变)当一个函数有多个参数的时候先传递一部分参数调用它(这部分参数以后永远不变)

  然后返回一个新的函数接收剩余的参数，返回结果.

```
const _ = require('lodash') // 要柯里化的函数
function getSum (a, b, c) {
  return a + b + c
}
// 柯里化后的函数
let curried = _.curry(getSum) // 测试
console.log(curried(1, 2, 3)) 
console.log(curried(1)(2)(3))
console.log(curried(1, 2)(3))
```

### 4.函数组合

1. 函数就像是数据的管道，函数组合就是把这些管道连接起来，让数据穿过多个管道形成最终结果
2. 函数组合默认是从右到左执行

```
var loudLastUpper = compose(exclaim, toUpperCase, head, reverse)

loudLastUpper(['jumpkick', 'roundhouse', 'uppercut']);
//=> 'UPPERCUT!'
```

### pointfree

概念：不使用所要处理的值，只合成运算过程

特点：函数无须提及将要操作的数据是什么样的，pointfree 模式能够帮助我们减少不必要的命名，让代码保持简洁和通用。

```
const fp = require('lodash/fp')
// pointfree
// 字符提取
const firstLetterToUpper = fp.flowRight(join('. '),

fp.map(fp.flowRight(fp.first, fp.toUpper)), split(' '))

console.log(firstLetterToUpper('world wild web')) // => W. W. W
```

### 5. debug

定义trace函数，然后插入到要调试到函数位置后面进行打印。

```
var trace = curry(function(tag, x){
  console.log(tag, x);
  return x;
});
```

### 6. Functor 函子

容器:包含值和值的变形关系(这个变形关系就是函数) 

函子:是一个特殊的容器，通过一个普通的对象来实现，该对象具有 map 方法，map 方法可以运 行一个函数对值进行处理(变形关系)

其中实现了of方法的函子就是*Pointed函子*

```
// 函子容器
class Containser {
    constructor(value){
        this._value = value
    }
    static of (value){
        return new Containser(value)
    }
    map(fn){
        return Containser.of(fn(this._value))
    }
}
let a =  Containser.of(5).map(x=>x+1).map(x=>x*x)
console.log(a)
```

特性总结：

- 函数式编程的运算不直接操作值，而是由函子完成
- 函子就是一个实现了 map 契约的对象
- 我们可以把函子想象成一个盒子，这个盒子里封装了一个值
- 想要处理盒子中的值，我们需要给盒子的 map 方法传递一个处理值的函数(纯函数)，由这
个函数来对值进行处理
- 最终 map 方法返回一个包含新值的盒子(函子)

### MayBe函子

进行异常处理的函子

```
class MayBe {
    constructor(value){
        this._value = value
    }
    static  of (value){
        return new MayBe(value)
    }
     map (fn) {
        return this.isNot() ? MayBe.of(null) : MayBe.of(fn(this._value)) 
    }
    isNot(){
        return this._value === undefined || this._value === null
    }

}
let a =  MayBe.of(null).map(x => x.toUpperCase())
let b =  MayBe.of('tset Maybe').map(x => x.toUpperCase())
console.log(a)
console.log(b)

```

### Either函子

Either函子容器,可以进行异常处理的函子，Either定义两个子函数（可以定义多个，类似if/else）作为处理数据的基准， 如果正确进入右函子继续执行，如果报错，进入左函子打印出异常

```
class leftEither {
    constructor(value) {
        this._value = value
    }
    static of(value) {
        return new leftEither(value)
    }
    map(fn) {
        return this._value
    }
}
class rightEither {
    constructor(value) {
        this._value = value
    }
    static of(value) {
        return new rightEither(value)
    }
    map(fn) {
        return rightEither.of((this._value))
    }
}
function parseJSON(json) {
    try {
        return rightEither.of(JSON.parse(json));
    } catch (e) {
        return leftEither.of({ error: e.message });
    }
}

let l = parseJSON('{ "name": zs }').map(x => x.name.toUpperCase())
let r = parseJSON('{ "name": "zs" }').map(x => x.name.toUpperCase())
console.log(l)
console.log(r)
```

### log（调试函子技巧）

通过一个中间函数，打打印日志

```
const _ = require('lodash')
const trace = _.curry((tag, v) => { console.log(tag, v)
return v
})
const split = _.curry((sep, str) => _.split(str, sep)) 
const join = _.curry((sep, array) => _.join(array, sep)) 
const map = _.curry((fn, array) => _.map(array, fn))
const f = _.flowRight(join('-'), trace('map 之后'), map(_.toLower), trace('split 之后'), split(' '))
console.log(f('NEVER SAY DIE'))
```

### IO函子（惰性执行）

- IO 函子中的 _value 是一个函数，在io函子中把函数作为值来处理
- IO 函子可以把不纯的动作存储到 _value 中，延迟执行这个不纯的操作(惰性执行)，包装当前的操作纯
- 把不纯的操作交给调用者来处理

```
class IO {
    constructor(fn) {
        this._value = fn
    }

    static of(value) {
        return new IO(function () {
            return value
        })
    }

    map(fn) {
      return  new IO(_flowRight(fn, this._value))
    }
}
let obj = {
    msg: 'hello io'
}
let a = IO.of(obj).map(p => p.msg)
console.log(a._value())
```

### monad（单子）函子

*Monad 函子是可以变扁的 Pointed 函子，IO(IO(x))，一个函子如果具有 join 和 of 两个方法并遵守一些定律就是一个 Monad*

```
const fs = require('fs')
const fp = require('lodash/fp') // IO Monad
class IO {
    static of(x) {
        return new IO(function () {
            return x
        })
    }
    constructor(fn) {
        this._value = fn
    }
    map(fn) {
        return new IO(fp.flowRight(fn, this._value))
    }
    join() {
        return this._value()
    }
    flatMap(fn) {
        return this.map(fn).join()
    }
}
let readFile = function (filename) { return new IO(function() {
    return fs.readFileSync(filename, 'utf-8') })
    }
    let print = function(x) { return new IO(function() {
        console.log(x)
    return x })
    }
let r = readFile('package.json').map(fp.toUpper)
    .flatMap(print)
    .join()
```