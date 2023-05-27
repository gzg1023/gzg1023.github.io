---
title: 【原理探索】vue.js(2.x)框架底层原理- 实现mini vue「01」
date: 2021-04-15
lastmod: 2021-04-15
tags: ["前端", "vue原理"]
categories: ["技术", "vue原理"]
author: "gzg1023"
toc: true
---

> 响应式思想，可以理解为自动回复消息，我发送消息给你，你会返回给我相应的回复。vue 通过响应式设计让数据得到自动的控制也就产生了 MVVM 的思想，从而实现数据双向绑定。

<!--more-->

## 引言

当你把一个普通的 JavaScript 对象传入 Vue 实例作为 data 选项，Vue 将遍历此对象所有的 property，并使用 Object.defineProperty 把这些 property 全部转为 getter/setter。这些 getter/setter 对用户来说是不可见的，但是在内部它们让 Vue 能够追踪依赖，在 property 被访问和修改时通知变更。

每个组件实例都对应一个 watcher 实例，它会在组件渲染的过程中把“接触”过的数据 property 记录为依赖。之后当依赖项的 setter 触发时，会通知 watcher，从而使它关联的组件重新渲染。

![vue](https://cn.vuejs.org/images/data.png)

以上内容摘自 vue 文档，可以看到 vue2.x 是通过 Object.defineProperty 对数据进行包裹，在通过内部的转换实现数据的双向绑定，让我们可以在使用 ui 组件(如：输入框)时候，可以非常便捷的操作数据。那么这一套流程是怎么实现的呢，让我们来模拟一个 mini 版本的 vue 了解他的本质。

实现最终代码： [mini vue github 地址](https://github1s.com/gzg1023/fackAchieve/tree/main/framework/vue)

## 模拟实现

提到 vue 很容易想到的就是单向数据流和数据双向绑定，乍一看有点冲突。一会儿单向 一会儿双向，但是其实不然，单向数据流是指用户访问 View，View 发出用户交互的 Action，在 Action 里对 state 进行相应更新。state 更新后会触发 View 更新页面的过程。这样数据总是清晰的单向进行流动，便于维护并且可以预测。 而数据双向绑定是基于单向数据流之上（理解为业务层）的实现，通过 Model 和 View 进行绑定，保持一致的操作。

我们从第一步开始模拟实现，在使用 vue 时候，我们通过 new 关键字创建实例,通过 el 指定一个 CSS 选择器或者是一个 DOM 对象，然后在 data 部分定义我们要操作的数据，就可以愉快的使用了。但是这背后 vue 做了很多工作。如下所示，通过`new Vue`创建了 vm 实例，也是整个框架的入口。

```javascript
const vm = new Vue({
  el: "#app",
  data: {
    message: "Hello Vue.js!",
  },
});
```

我们通过 es6 语法 class 的方式实现整个 mini vue，用来了解整个响应式原理的基本结构和原理。

## Vue

创建 Vue 构造类，我们先来整理一下流程

1. 创建 vue 实例，传入 el 选项来指定模版要替换的元素
2. 传入其他选项 data，methods，computed 等选项来使用 vue 提供的 api
3. 把传入的 data 变成响应式数据，激活数据的双向绑定
4. 通过 v-dom 和 Compiler 把 template 编译成 render
5. 通过 render 转为 AST 在转为 code，并通过 v-dom 的 diff 渲染页面

我们模拟的话，就只涉及响应式原理部分。只处理，Observer 响应式，Compiler 对简单指令的解析 两个部分的实现。关于异常处理，在模拟过程中没有进行涉及，在 vue 中可以看到只要涉及到"用户传入"部分的内容都添加了异常处理和 log 异常日志的输出，这点在开发库类的项目中很值得学习。

```javascript
class Vue {
  constructor(options) {
    // 1. 通过属性保存选项的数据
    this.$options = options || {};
    this.$data = options.data || {};
    // 如果是字符串就说明是选择器
    this.$el =
      typeof options.el === "string"
        ? document.querySelector(options.el)
        : options.el;
    // 2. 把data的成员转化为getter和setter注入到vue实例
    this._proxyData(this.$data);
    // 3. 调用observer对象，把data属性转化为响应式数据，监听数据的变化
    new Observer(this.$data);
    // 4. 调用Compiler对象，处理模版编译
    new Compiler(this);
  }

  _proxyData(data) {
    // 遍历对象
    Object.keys(data).forEach((key) => {
      Object.defineProperty(this, key, {
        enumerable: true,
        configurable: true,
        get() {
          return data[key];
        },
        set(newValue) {
          if (newValue === data[key]) return;
          data[key] = newValue;
        },
      });
    });
  }
}
```

### Dep

我们知道 Vue 使用的设计模式是观察者模式，那么就需要观察者和发布者来完成，我们定义一个 Dep 对象内部包含一个 subs 数组用来存在所有的依赖对象，通过 addSub 方法添加依赖，通过 notify 方法来触发所有以来的更新（调用依赖的 update 方法）

```javascript
// 观察者模式的 发布者
class Dep {
  constructor() {
    // 收集依赖对象
    this.subs = [];
  }
  // 添加依赖对象
  addSub(sub) {
    if (sub && sub.update) {
      this.subs.push(sub);
    }
  }
  // 通知方法
  notify() {
    this.subs.forEach((sub) => {
      sub.update();
    });
  }
}
```

### Observer

Observer 类搜集依赖，在 get 阶段搜集依赖，在 set 阶段触发依赖的更新。内置的 walk 方法就是递归的处理所有对象，添加依赖属性。

```javascript
class Observer {
  constructor(targetData) {
    this.walk(targetData);
  }
  // 遍历对象所有属性
  walk(targetData) {
    // 判断是否为对象
    if (!targetData || typeof targetData !== "object") {
      return;
    }
    // 遍历所有属性
    Object.keys(targetData).forEach((key) => {
      this.defineReactive(targetData, key, targetData[key]);
    });
  }

  // 定义响应式数据
  defineReactive(obj, key, value) {
    // 收集依赖，来统一更新
    let dep = new Dep();
    // 转化对象的内部属性
    this.walk(value);
    const _that = this;
    Object.defineProperty(obj, key, {
      enumerable: true,
      configurable: true,
      // 不返回obj[key]的原因是会递归触发
      get() {
        // 收集依赖
        Dep.target && dep.addSub(Dep.target);
        return value;
      },
      set(newValue) {
        if (newValue === value) return;
        value = newValue;
        // 处理普通值转为对象的情况
        _that.walk(newValue);
        // 发生通知
        dep.notify();
      },
    });
  }
}
```

### Watcher

每一个组件对应一个 Watcher 对象，包含一个 update 方法，作用是调用传入的 callback 函数达到更新数据的目的。也是观察者模式中的观察者对象。

```javascript
class Watcher {
  constructor(vm, key, cb) {
    this.vm = vm;
    this.key = key;
    this.cb = cb;
    // 把watcher对象记录到Dep类的静态属性target
    Dep.target = this;
    // 触发get方法，在get方法中会调用addSub
    this.oldValue = vm[key];
    // 重制依赖对象，防止数据混乱
    Dep.target = null;
  }
  update() {
    let newValue = this.vm[this.key];
    // 如果数据发现变化则更新
    if (this.oldValue === newValue) {
      return;
    }
    this.cb(newValue);
  }
}
```

### Compiler

Compiler 是处理模版编译的对象，在 vue 中处理 template 对象编译成 render 函数并解析指令，大括号语法，等 vue 内置对象。我们这里只针对 html 模版进行简指令的解析。这个过程也是递归的，因为我们并不知道节点有多少层。

在处理完成指令和大括号的解析后，我们可以得到对应的 data 值 然后通过 update 方法进行更新。关于 v-model 就是通过表单的 change 事件来进行双向数据的绑定操作。

```javascript
class Compiler {
  constructor(vm) {
    this.el = vm.$el;
    this.vm = vm;
    this.compiler(this.el);
  }
  // 编译模版，处理各种节点
  compiler(el) {
    const childNodes = el.childNodes;
    Array.from(childNodes).forEach((node) => {
      if (this.isTextNode(node)) {
        // 处理文本
        this.compilerText(node);
      } else if (this.isElementNode(node)) {
        // 处理元素
        this.compilerElement(node);
      }
      // 处理多层节点
      if (node.childNodes && node.childNodes.length !== 0) {
        this.compiler(node);
      }
    });
  }
  // 编译元素节点，处理指令
  compilerElement(node) {
    Array.from(node.attributes).forEach((attr) => {
      let attrName = attr.name;
      // 判断是否为指令
      if (this.isDirective(attrName)) {
        // 转化指令
        attrName = attrName.substr(2);
        let key = attr.value;
        this.update(node, key, attrName);
      }
    });
  }
  // 编译文本节点，处理差值表达式
  compilerText(node) {
    let reg = /\{\{(.+?)}\}/;
    let content = node.textContent;
    if (reg.test(content)) {
      // 获取正则匹配的第一个内容
      let key = RegExp.$1.trim();
      node.textContent = content.replace(reg, this.vm[key]);
      // 触发依赖
      new Watcher(this.vm, key, (newValue) => {
        node.textContent = newValue;
      });
    }
  }
  // 判断元素是否为指令
  isDirective(attrName) {
    return attrName.startsWith("v-");
  }
  // 判断元素是否为文本节点
  isTextNode(node) {
    return node.nodeType === 3;
  }
  // 判断元素是否为元素节点
  isElementNode(node) {
    return node.nodeType === 1;
  }
  // 更新指令数据
  update(node, key, attrName) {
    let updateFn;
    if (attrName.indexOf(":") !== -1) {
      attrName = attrName.substr(3);
      updateFn = this.onUpdater;
      updateFn && updateFn.call(this, node, key, this.vm[key], attrName);
    } else {
      updateFn = this[attrName + "Updater"];
      // 此处的this的Compiler对象
      updateFn && updateFn.call(this, node, key, this.vm[key]);
    }
  }
  // 处理v-text指令
  textUpdater(node, key, value) {
    // 文本节点的值用textContent
    node.textContent = value;
    // 收集依赖
    new Watcher(this.vm, key, (newValue) => {
      node.textContent = newValue;
    });
  }
  // 处理v-model指令
  modelUpdater(node, key, value) {
    // 表单的值是value
    node.value = value;
    // 收集依赖
    new Watcher(this.vm, key, (newValue) => {
      node.value = newValue;
    });
    // 双向绑定
    node.addEventListener("input", (e) => {
      console.log(e);
      this.vm[key] = node.value;
    });
  }

  // 处理v-show
  showUpdater(node, key, value) {
    if (value) {
      node.style.display = "block";
    } else {
      node.style.display = "none";
    }
    new Watcher(this.vm, key, (newValue) => {
      node.style.display = newValue ? "block" : "none";
    });
  }
  // 处理v-on
  onUpdater(node, key, value, handleType) {
    // value = value.substr(2)
    console.log("🚀 onUpdater", node, key, value);
    node.addEventListener(handleType, (e) => {
      this.vm[key]();
    });
  }
}
```

### index.html

最后通过html文件创建实例来测试mini vue。

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>mini vue</title>
</head>
<body>
    <div id="app">
        <h1>差值表达式</h1>
        <h3>{{ msg }}</h3>
        <div class="box" data-img="http://google.com">
        <h3>{{ count }}</h3>
        <h3>{{ person }}</h3>
        </div>
        <h1>v-text</h1>
        <div class="msg" v-text="msg"></div>
        <h1>v-model</h1>
        <input type="text" v-model="msg"></input>
        <input type="text" v-model="count"></input>
        <h1>v-if</h1>
        <button v-show="showFlag">测试</button>
        <h1>v-on</h1>
        <button v-on:click="clickHandle">测试</button>
    </div>
    <script src="./dep.js"></script>
    <script src="./watcher.js"></script>
    <script src="./compiler.js"></script>
    <script src="./observer.js"></script>
    <script src="./vue.js"></script>
    <script>
        let vm = new Vue({
            el:'#app',
            data:{
                msg:'hello mini vue',
                count: 200,
                showFlag:true,
                person:{
                    name:{
                        alex:{
                            age:19
                        }
                    }
                },
                clickHandle(){
                    this.showFlag = !this.showFlag
                    console.log('123',this)
                }
            }
        })
    </script>
</body>
</html>
```

## 总结

我们可以看到整个vue进行响应式处理的流程是：（patch方法就是v-dom进行diff后更新为真实页面的操作）

响应式触发``setter->Dep->Watcher->update->patch``。
