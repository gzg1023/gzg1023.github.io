---
title: vue.js(2.x)原理 - new Vue流程梳理 及源码版生命周期分析「02」
date: 2021-04-24
lastmod: 2021-04-25
tags: ["前端", "vue原理", ]
categories: ["技术", "vue原理"]
author: "gzg1023"
toc: true
---

> 在实现完成 mini vue 以后，对深入源码分析。本篇文章来理一理从 new Vue 开始都执行了哪些操作，并且基于源码对生命周期进行更深入的理解。

<!--more-->

## 搭建调试环境

从本篇开始就是分析整个[Vue 框架源码](https://github.com/gzg1023/vue2-fork)的流程了，前面说过系列文章并非深入到行，而是自己对 Vue 的理解。首先开始搭建一个调试环境,我这里使用`anywhere`作为 web 服务器，然后在`package.json`添加一个命令生成我们的`sourcemap`版本的 vue 文件的`debug`命令。这里只分析 web 不分析 weex。

```javascript
"debug": "rollup -w -c scripts/config.js --environment TARGET:web-full-dev --sourcemap"
```

通过 yarn debug 启动服务会生成 sourcemap，然后在通过 anywhere 开一个 web 服务器，在浏览器中通过 Sources 对代码进行断点就可以进行调试了。

## 分析入口文件

vue 框架在使用 vue 的 template 语法时候，会用到`vue-template-compiler`来对模版进行编译，我们可以在脚手架开发项目时候，配置编译。或者是直接引入带有编译器版本的 vue cdn。分析源码需要走整个流程，以下文件就是要分析的入口文件。

```javascript
src/platforms/web/entry-runtime-with-compiler.js
```

经过一层一层的推进，最终在`src/core/instance/index.js`中找到了 Vue 的构造函数，看到该文件，对 Vue 整个初始化流程有了一个大概的认识。

```javascript
function Vue(options) {
  // 由initMixin初始化，在创建实例时候调用
  this._init(options);
}

// 初始化vm
initMixin(Vue);
// 初始化 $data $props $set $delete $watch
stateMixin(Vue);
// 初始化@on @once @off @emit方法
eventsMixin(Vue);
// 初始化生命周期 update destory
lifecycleMixin(Vue);
// 处理$nextTick和render
renderMixin(Vue);
```

## 初始化流程/源码版生命周期分析

通过对构造函数分析，看到首先是调用`__init`方法，而`_init`方法是由`initMixin`进行添加的，先来看看这个初始化做了哪些操作。


1. `uid` 为每个实例都标记一个 uid 标识唯一的 id，并添加属性\_isVue 标识是 vue 的实例
2. `mergeOptions等` 合并组件的 options(具体就是合并 Vue 配置与用户传入的配置，如 el，data，template 等)
3. `initProxy` 代理 vm 实例,在后续\_render 函数执行中，提供更友好的错误检测能力和变量名称检测等[详见](https://www.bookstack.cn/read/5865c0921b69e6006b3145a1/spilt.2.src-%E5%9F%BA%E7%A1%80%E7%9A%84%E6%95%B0%E6%8D%AE%E4%BB%A3%E7%90%86%E6%A3%80%E6%B5%8B.md) 。
4. `initLifecycle` 把当前实例添加到父实例的 children 属性中，并设置自身的$parent 属性指向父实例，及初始化一些生命周期相关变量
5. `initEvents` 初始化当前组件的事件监听器 on 和 emit（如 @fatherEvent="myEvent")
6. `initRender` 初始化 slot 插槽相关的内容，以及 render 函数的相关内容（h 函数核心）以及$attrs $listeners 属性
7. `callHook(vm, 'beforeCreate')` 触发 Vue 的<font color=blue>**beforeCreate**</font>生命周期钩子函数
8. `initInjections` 初始化`inject`并设置 shouldObserve 为 false 标识，标识数据为非响应式（可以传入对象，属性是响应式）
9. `initState` 依次初始化实例对象<font color=red>**props=>methods=>data=>computed=>watch**</font>，统一数据结构并判断重名
10. `initProvide`初始化`provide`并调用传入的 provide 方法
11. `callHook(vm, 'created')`触发 Vue 的<font color=blue>**created**</font>生命周期钩子函数
12. `mark measure` 可配置使用，标记 Vue.config.performance 配置开启后可以在开发者工具追踪性能


```javascript
// initMixin函数删除了部分内容
// 实例的唯一标识
let uid = 0;

export function initMixin(Vue: Class<Component>) {
  Vue.prototype._init = function (options?: Object) {
    const vm: Component = this;
    vm._uid = uid++;
    // 标识是vue实例，不需要被响应式处理
    vm._isVue = true;
    // merge options
    if (options && options._isComponent) {
      initInternalComponent(vm, options);
    } else {
      vm.$options = mergeOptions(
        // vue本身的选项，如全局api，vue内置组件等
        resolveConstructorOptions(vm.constructor),
        // 用户传入的option，如el，data，template等
        options || {},
        vm
      );
    }
    if (process.env.NODE_ENV !== "production") {
      initProxy(vm);
    } else {
      // 生产环境渲染对象就是自己
      vm._renderProxy = vm;
    }
    // expose real self
    vm._self = vm;
    // 初始化vue实例的各种东西
    // 初始化生命周期相关变量
    initLifecycle(vm);
    // 初始化当前组件的事件监听器等内容
    initEvents(vm);
    // 初始化slot $attrs $listeners 相关属性
    initRender(vm);
    // 触发beforeCreate生命周期钩子函数
    callHook(vm, "beforeCreate");
    // 实现依赖注入（start）
    initInjections(vm); // resolve injections before data/props
    // 初始化props methods data computed watch
    initState(vm);
    // 实现依赖注入（end）
    initProvide(vm); // resolve provide after data/props
    // 触发created生命周期钩子函数
    callHook(vm, "created");
    /* istanbul ignore if */
    // 通过$mount挂载页面
    if (vm.$options.el) {
      vm.$mount(vm.$options.el);
    }
  };
}
```


13. `$mount` 调用 vm 的$mount 方法(内部调用 mountComponent 方法）

```javascript
Vue.prototype.$mount = function (
  el?: string | Element,
  hydrating?: boolean
): Component {
  el = el && inBrowser ? query(el) : undefined;
  return mountComponent(this, el, hydrating);
};
```

14. `mountComponent`函数的作用是<font color=red>确认挂载节点,编译模板为 render 函数，渲染函数转换 Virtual DOM,创建真实节点。</font>
15. `callHook(vm, 'beforeMount')`触发 Vue 的<font color=blue>**beforeMount**</font>生命周期钩子函数
16. ``_update``通过vm实例调用update方法进行v-dom到真实dom的渲染，传入的``_render``是编译好的渲染函数(编译模板或传入的render，**如果同时存在 template 和 render 会优先使用 render**)
17.  然后首次初始化Watcher（此处为渲染Watcher），并且在更新Watcher的回调函数中注册beforeUpdate生命周期钩子函数
18. 当``$vnode``节点为null，则表明是new Vue创建的，触发Vue 的<font color=blue>**mounted**</font>生命周期钩子函数。如果是.vue文件的组件会在所有子组件的``mounted``钩子函数触发完成后触发[详见](https://ustbhuangyi.github.io/vue-analysis/v2/components/lifecycle.html#beforemount-mounted)，父/根组件的``beforeMount``会比子组件先触发。

```javascript
export function mountComponent(
  vm: Component,
  el: ?Element,
  hydrating?: boolean
): Component {
  vm.$el = el;
  if (!vm.$options.render) {
    vm.$options.render = createEmptyVNode;
  }
  callHook(vm, "beforeMount");

  let updateComponent;
  updateComponent = () => {
    // 接受Vnode对象和
    vm._update(vm._render(), hydrating);
  };

  // 首次初始化Watcher
  new Watcher(
    vm,
    updateComponent,
    noop,
    {
      before() {
        if (vm._isMounted && !vm._isDestroyed) {
          callHook(vm, "beforeUpdate");
        }
      },
      // 标识为渲染Watcher
    },
    true /* isRenderWatcher */
  );
  hydrating = false;

  if (vm.$vnode == null) {
    vm._isMounted = true;
    callHook(vm, "mounted");
  }
  return vm;
}
```
19. 一次Vue初始化的过程就结束了,当我们修改data或者props会触发watcher的更新，进行虚拟dom的diff，然后vue会以最小的更新来刷新页面，但是这个刷新不是实时的，而且用Vue内部维护的刷新队列``queueWatcher``进行刷新
20. queueWatcher通过``flushSchedulerQueue``方法来进行更新watcher队列，并用watch的id进行重新排序，来保证更新的顺序[详见](https://www.bookstack.cn/read/5865c0921b69e6006b3145a1/spilt.2.src-%E6%B7%B1%E5%85%A5%E5%93%8D%E5%BA%94%E5%BC%8F%E7%B3%BB%E7%BB%9F%E6%9E%84%E5%BB%BA-%E4%B8%AD.md)
21. 通过循环的方式依次处理每一个watcher，首先触发Vue 的<font color=blue>**beforeUpdate**</font>生命周期钩子函数
22. 通过``has``对象保存该更新过的id，提高更新的效率，然后调用``watcher.run()``方法进行watcher的更新操作（如果watch一次性更新的次数超过100次，那么会被当成循环调用，会进行info提示）
23. 通过slice()方法，保存一份需要更新队列的数据备份，然后清空当前队列的数据/
24. 如果是keep-alive组件内部的组件，会触发Vue的<font color=blue>**activated**</font>生命周期钩子函数。
25. 如果是常规的组件，触发Vue的<font color=blue>**updated**</font>生命周期钩子函数。此时一次diff更新的操作就已经全部完成。

```javascript
function flushSchedulerQueue () {
  currentFlushTimestamp = getNow()
   // 设置正在刷新watcher队列
  flushing = true
  let watcher, id
  // 排序队列，具体以下任务
  // 1.组件从父级更新为子级。（因为父母总是在子级之前创建）
  // 2.组件的用户监视程序在其呈现监视程序之前运行（因为用户观察者先于渲染观察者创建）
  // 3.如果在父组件的观察者运行期间某个组件被破坏，可以跳过其观察者。
  queue.sort((a, b) => a.id - b.id)

  for (index = 0; index < queue.length; index++) {
    watcher = queue[index]
    if (watcher.before) {
       // 在更新视图之前，触发beforeUpdate生命周期钩子函数
      watcher.before()
    }
    id = watcher.id
    // 标记id为null，已经在进行的数据
    has[id] = null
    // 运行
    watcher.run()
    if (process.env.NODE_ENV !== 'production' && has[id] != null) {
      circular[id] = (circular[id] || 0) + 1
      // 如果watch连续更新超过100次，那么可能存在watch嵌套的引用
      if (circular[id] > MAX_UPDATE_COUNT) {
        warn(
          'You may have an infinite update loop ' + (
            watcher.user
              ? `in watcher with expression "${watcher.expression}"`
              : `in a component render function.`
          ),
          watcher.vm
        )
        break
      }
    }
  }

  // 备份已经活动。更新的队列
  const activatedQueue = activatedChildren.slice()
  const updatedQueue = queue.slice()
  // 清空队列
  resetSchedulerState()

  // 触发keep-alive组件更新的activated生命周期钩子
  callActivatedHooks(activatedQueue)
  // 触发组件的updated生命周期钩子
  callUpdatedHooks(updatedQueue)
}
```

26. 分析完创建和更新的流程，就剩下组件销毁生命周期，在 切换路由, v-if,手动 $destroy() 几个场景中会触发``beforeDestroy``和``destroyed``生命周期
27. 先判断是否正在执行销毁如果是直接返回，否则触发Vue的<font color=blue>**beforeDestroy**</font>生命周期钩子函数，并标识为正在销毁
28. 然后移除``parent``的``$children``节点，调用watcher的``teardown``方法移除当前实例的所有watcher（_watchers），并删除dep依赖，标签为非活动组件。
29. 对Vue实例的__ob__的计数属性进行递减 ，标记``_isDestroyed``状态为已经注销状态，然后通过``__patch__``方向对节点的v-dom进行注销，重置为``null`
30. `callHook(vm, 'beforeMount')`触发 Vue 的<font color=blue>**destroyed**</font>生命周期钩子函数
31. 最后当前实例的绑定的事件进行注销，根据清空重置``$el.__vue__``和``$vnode.parent``属性。

```javascript
 Vue.prototype.$destroy = function () {
    const vm: Component = this
    if (vm._isBeingDestroyed) {
      return
    }
    callHook(vm, 'beforeDestroy')
    vm._isBeingDestroyed = true
    const parent = vm.$parent
    if (parent & & !parent._isBeingDestroyed && !vm.$options.abstract) {
      remove(parent.$children, vm)
    }
    if (vm._watcher) {
      vm._watcher.teardown()
    }
    let i = vm._watchers.length
    while (i--) {
      vm._watchers[i].teardown()
    }
    if (vm._data.__ob__) {
      vm._data.__ob__.vmCount--
    }
    vm._isDestroyed = true
    vm.__patch__(vm._vnode, null)
    callHook(vm, 'destroyed')
    vm.$off()
    if (vm.$el) {
      vm.$el.__vue__ = null
    }
    if (vm.$vnode) {
      vm.$vnode.parent = null
    }
  }
```

32. 到此一个完整版本的Vue创建过程就分析完成了，keep-alive会另外有activated & deactivated两个钩子可以自行调试分析

 

## 钩子附录

```javascript
// v-dom的生命周期钩子
const hooks = ['create', 'activate', 'update', 'remove', 'destroy']

// vue组件的生命周期钩子
export const LIFECYCLE_HOOKS = [
  'beforeCreate',
  'created',
  'beforeMount',
  'mounted',
  'beforeUpdate',
  'updated',
  'beforeDestroy',
  'destroyed',
  'activated',
  'deactivated',
  'errorCaptured',
  'serverPrefetch'
]

```