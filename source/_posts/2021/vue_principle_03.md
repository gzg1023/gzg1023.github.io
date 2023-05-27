---
title: vue.js(2.x)原理 - Vue响应式核心Observer,Dep及Watcher和异步更新队列「03」
date: 2021-05-15
lastmod: 2021-05-20
tags: ["前端", "vue原理", "异步"]
categories: ["技术", "vue原理", "异步"]
author: "gzg1023"
toc: true
---

> Vue 核心对象 Observer, Dep 和 Watcher 到底是干啥的，怎么样让整个框架运行起来的。已经操作页面有时候数据没变化必须使用到的nextTick 是怎么工作的？本篇文章来浅析谈谈。

<!--more-->

## 收集依赖

vue的依赖收集流程如下，最终watcher.newDeps数组中存放dep列表，dep.subs数组中存放watcher列表。在vue中template用到了就收集，没有用到就不收集，从而提高性能。

* observe 处理
* walk方法
* defineReactive 处理每一个key
* get
* dep.depend() 添加依赖
* watcher.addDep(new Dep())
* watcher.newDeps.push(dep)
* dep.addSub(new Watcher())
* dep.subs.push(watcher)

## 视图更新

通过Watcher的update方法进行页面或者数据的更新（从而对视图进行更新）

* set 方法
* dep.notify() 依赖通知
* subs[i].update() 调用更新方法
* watcher.run() || queueWatcher(this) 进队
* watcher.get() || watcher.cb 执行回到
* watcher.getter()
* vm._update()  更新vnode
* ``vm.__patch__()``  更新页面

## Observer

``Observer``是整个vue响应式的核心类，每一个响应式对象都会创建一个dep对象用于收集依赖。
* 接受一个需要设置响应式的对象(一般来说是data返回的对象)
* 创建每个属性的dep
* 定义``__ob__``属性，标记响应式
* 如果是数组，修改原型（在调用数组方法后，调用notify更新）
* 如果是对象，通过walk递归处理

```js
// 响应式数据基类
export class Observer {
  // 观察的对象
  value: any;
  // 依赖对象
  dep: Dep;
  // 实例计数
  vmCount: number;

  constructor(value: any) {
    this.value = value
    this.dep = new Dep()
    this.vmCount = 0
    // 定于__ob__属性
    def(value, '__ob__', this)
    // 针对数组做响应式分析
    if (Array.isArray(value)) {
      if (hasProto) {
        protoAugment(value, arrayMethods)
      } else {
        copyAugment(value, arrayMethods, arrayKeys)
      }
      this.observeArray(value)
    } else {
      // 处理对象，转为getter/setter
      this.walk(value)
    }
  }

  walk(obj: Object) {
    // 把对象中每一个key-value都设置为响应式
    const keys = Object.keys(obj)
    for (let i = 0; i < keys.length; i++) {
      defineReactive(obj, keys[i])
    }
  }
  // 针对数组，把每每一项转成响应式数据
  observeArray(items: Array<any>) {
    for (let i = 0, l = items.length; i < l; i++) {
      observe(items[i])
    }
  }
}
```

## Dep

``Dep``是vue观察者模式中的订阅者，是是整个 getter 依赖收集的核心，在进行Observe中每一个data的key都保留自己的dep对象。
* 每一个响应式对象都会创建dep对象
* 维护一个subs数组，用来存放Watcher
* 包含添加，删除，通知等方法
* 维护一个targetStack栈，存放依赖的目标对象
* notify就是调用watcher的update方法

```js
export default class Dep {
  static target: ?Watcher;
  id: number;
  subs: Array<Watcher>;

  constructor() {
    this.id = uid++;
    this.subs = [];
  }
  // 添加依赖对象
  addSub(sub: Watcher) {
    this.subs.push(sub);
  }
  // 移除依赖
  removeSub(sub: Watcher) {
    remove(this.subs, sub);
  }
  // 收集依赖的方法，添加target数组中
  depend() {
    if (Dep.target) {
      Dep.target.addDep(this);
    }
  }
  // 通知依赖的方法
  notify() {
    // 克隆一个新数组
    const subs = this.subs.slice();
    // 以此调用订阅者的更新方法
    for (let i = 0, l = subs.length; i < l; i++) {
      subs[i].update();
    }
  }
}

// 重置为null 不影响下次搜集
Dep.target = null;
const targetStack = [];
// 入栈，并把传入的watcher复制到当前Dep的目标中
// 父组件会先入栈，然后子组件入栈，执行完出栈，在执行父组件的watcher
export function pushTarget(target: ?Watcher) {
  targetStack.push(target);
  Dep.target = target;
}
// 观察者依赖出栈
export function popTarget() {
  targetStack.pop();
  Dep.target = targetStack[targetStack.length - 1];
}
```

## Watcher

``Watcher``是观察者，用于set的更新，总共分为三类，视图Watcher用于更新模版页面，用户Watcher是.vue文件中的watch属性 用于监听数据变化，还有一种是缓存Watcher，是.vue文件中的computed属性，用于计算属性。
``Watcher``和``Dep``是协作的。
* Watcher分为三类（视图，watch,computed)
* 初始化默认属性和回调函数
* 保存expOrFn（可能是函数或者函数字符串）
* 初始化dep对象需要的属性
* 执行get方法
* 更新时候分为三种情况
* （计算属性不更新，同步属性直接调用run方法，渲染watch 插到更新队列中在nextTick更新）

```js
export default class Watcher {
  vm: Component;
  expression: string;
  cb: Function;
  id: number;
  deep: boolean;
  user: boolean;
  lazy: boolean;
  sync: boolean;
  dirty: boolean;
  active: boolean;
  deps: Array<Dep>;
  newDeps: Array<Dep>;
  depIds: SimpleSet;
  newDepIds: SimpleSet;
  before: ?Function;
  getter: Function;
  value: any;

  constructor(
    vm: Component, // 组件实例
    expOrFn: string | Function,
    cb: Function, // 回掉函数
    options?: ?Object,
    isRenderWatcher?: boolean // 是否为渲染Watcher
  ) {
    this.vm = vm
    if (isRenderWatcher) {
      vm._watcher = this
    }
    // 存储所有的watcher，3种都包括
    vm._watchers.push(this)
    // options
    if (options) {
      this.deep = !!options.deep
      this.user = !!options.user
      this.lazy = !!options.lazy
      this.sync = !!options.sync
      this.before = options.before
    } else {
      this.deep = this.user = this.lazy = this.sync = false
    }
    this.cb = cb
    // 唯一的id
    this.id = ++uid // uid for batching
    // 标识为活动watcher
    this.active = true
    this.dirty = this.lazy // for lazy watchers
    this.deps = []
    this.newDeps = []
    this.depIds = new Set()
    this.newDepIds = new Set()
    this.expression = process.env.NODE_ENV !== 'production'
      ? expOrFn.toString()
      : ''
    // parse expression for getter
    if (typeof expOrFn === 'function') {
      // 如果是函数，直接修改默认的getter为传入的函数
      this.getter = expOrFn
    } else {
      // 如果为字符串，则为watch属性，对应形式是'watch-key':(){}
      // parsePath用来获取对象的值，并已函数的形式返回
      this.getter = parsePath(expOrFn)
    }
    // 默认是false，只有在计算属性中lazy是true，代表延迟执行
    this.value = this.lazy
      ? undefined
      : this.get()
  }

  get() {
    // 把当前watcher入栈
    pushTarget(this)
    let value
    const vm = this.vm
    try {
      // 执行updateComponent函数
      value = this.getter.call(vm, vm)
    } catch (e) {
      if (this.user) {
        handleError(e, vm, `getter for watcher "${this.expression}"`)
      } else {
        throw e
      }
    } finally {
      // 如果watch设置了deep属性，则执行深度监听
      if (this.deep) {
        traverse(value)
      }
      // 执行完成后出栈
      popTarget()
      // 清理依赖
      this.cleanupDeps()
    }
    return value
  }
  // 存储依赖和依赖的id
  addDep(dep: Dep) {
    const id = dep.id
    if (!this.newDepIds.has(id)) {
      this.newDepIds.add(id)
      this.newDeps.push(dep)
      if (!this.depIds.has(id)) {
        dep.addSub(this)
      }
    }
  }

  // 清除依赖，提高性能（如v-if场景，数据切换问题）
  cleanupDeps() {
    let i = this.deps.length
    while (i--) {
      const dep = this.deps[i]
      if (!this.newDepIds.has(dep.id)) {
        dep.removeSub(this)
      }
    }
    let tmp = this.depIds
    this.depIds = this.newDepIds
    this.newDepIds = tmp
    this.newDepIds.clear()
    tmp = this.deps
    this.deps = this.newDeps
    this.newDeps = tmp
    this.newDeps.length = 0
  }

  // 更新方法，分为三种情况
  update() {
    if (this.lazy) {
      this.dirty = true
    } else if (this.sync) {
      this.run()
    } else {
      // 渲染watcher执行
      queueWatcher(this)
    }
  }
  // watch和computed执行
  run() {
    // 如果是活动状态
    if (this.active) {
      // 记录返回值/可能为空
      const value = this.get()
      if (
        value !== this.value ||
        isObject(value) ||
        this.deep
      ) {
        // set new value
        const oldValue = this.value
        this.value = value
        // 如果是用户watcher调用cb函数，添加try防着用户不处理
        if (this.user) {
          try {
            this.cb.call(this.vm, value, oldValue)
          } catch (e) {
            handleError(e, this.vm, `callback for watcher "${this.expression}"`)
          }
        } else {
          this.cb.call(this.vm, value, oldValue)
        }
      }
    }
  }

  evaluate() {
    this.value = this.get()
    this.dirty = false
  }

  // 清除依赖
  depend() {
    let i = this.deps.length
    while (i--) {
      this.deps[i].depend()
    }
  }

  // 情况依赖和_watcher对象，并设置状态为 非活动状态
  teardown() {
    if (this.active) {
      if (!this.vm._isBeingDestroyed) {
        remove(this.vm._watchers, this)
      }
      let i = this.deps.length
      while (i--) {
        this.deps[i].removeSub(this)
      }
      this.active = false
    }
  }
}
```


## nextTick

官方定义：下次 DOM 更新循环结束之后执行延迟回调。 在日常开发我们也经常用到这个 api，用于 DOM 更新后的数据修改和逻辑操作，它的本质是执行一个`flushCallbacks`的队列任务。通过不同的微任务/宏任务环境

- 首先通过 Promise 包裹该队列
- 如果不支持使用 MutationObserver 包裹队列
- 如果不支持使用 setImmediate 包裹队列
- 以上全部不支持，则使用 setTimeout 来处理

```js
if (typeof Promise !== "undefined" && isNative(Promise)) {
  const p = Promise.resolve();
  timerFunc = () => {
    p.then(flushCallbacks);
    if (isIOS) setTimeout(noop);
  };
  isUsingMicroTask = true;
  // 兼容低版本手机浏览器
} else if (
  !isIE &&
  typeof MutationObserver !== "undefined" &&
  (isNative(MutationObserver) ||
    MutationObserver.toString() === "[object MutationObserverConstructor]")
) {
  let counter = 1;
  const observer = new MutationObserver(flushCallbacks);
  const textNode = document.createTextNode(String(counter));
  observer.observe(textNode, {
    characterData: true,
  });
  timerFunc = () => {
    counter = (counter + 1) % 2;
    textNode.data = String(counter);
  };
  isUsingMicroTask = true;
} else if (typeof setImmediate !== "undefined" && isNative(setImmediate)) {
  timerFunc = () => {
    setImmediate(flushCallbacks);
  };
} else {
  timerFunc = () => {
    setTimeout(flushCallbacks, 0);
  };
}
```
