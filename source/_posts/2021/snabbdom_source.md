---
title: 【技术分享】virtual DOM的思考及snabbdom库源码解读
date: 2021-02-05
lastmod: 2021-02-11
tags: ['前端','virtual DOM','Vue原理','源码']
categories: ['技术','virtual DOM']
author: "gzg1023"
toc: true
---


> virtual DOM的广泛运用革新了技术框架，带来了更多的可能。本文了解virtual DOM的本质及对snabbdom库的源码进行分析。
<!--more-->


## virtual DOM

### 什么是virtual DOM

virtual DOM的本质是javaScript Object，是对浏览器真实DOM的一种关系映射。用js的对象描述真实DOM的内容，在页面需要重绘时只修改局部内容。从而提高渲染性能。

### virtual DOM优缺点

优点：

- 保存VNode，在需要重新渲染页面内容时候，只需修改局部内容，也就是通过diff提高性能
- 成功的打破了跨平台，可以在没有document对象的地方(node)进行伪DOM操作，如ssr应用的产生
- 针对大量的DOM操作，浏览器渲染引擎是很消耗性能的，可以用过VNode提高性能

缺点：

- 首次渲染更消耗性能，因为需要先转到VNode在转回来或把真实DOM转为v-dom
- 关于svelte框架不使用v-dom的[看法](https://svelte.dev/blog/virtual-dom-is-pure-overhead)


### virtual DOM场景

一个单独的v-dom库很少直接运行，都是作为框架的一部分运行，如vue,和react框架。都是用到了v-dom。


## snabbdom

### 简介

snabbdom一个简单，高效的virtual DOM库。[在vue框架中，v-dom的核心也是基于本库进行二次开发的](https://github.com/vuejs/vue/blob/dev/src/core/vdom/patch.js)。

地址：[https://github.com/snabbdom/snabbdom](https://github.com/snabbdom/snabbdom)

由于整个库的源码还是很多，本文只讨论核心部分的几个函数。

### 例子

snabbdom用起来很简单,通过init生成patch函数进行DOM的渲染对比，通过h函数生成vNode，init接受一个数组，可以使用官方提供的模块，也可以自定义模块。


```jsx
import { h } from "snabbdom/build/package/h"
import { init } from "snabbdom/build/package/init"
import { styleModule } from "snabbdom/build/package/modules/style";
import { eventListenersModule } from "snabbdom/build/package/modules/eventlisteners";

const patch = init([
    styleModule,
    eventListenersModule
])

let vNode = h('div#container', [
    h('h1', {
        style: { backgroundColor: 'red' }
    }, 'h1 texht'),
    h('p', { on: { click: clickEventHandle } }, 'this p tag ')
])

function clickEventHandle() {
    console.log('我被点了')
}
// 需要存在#app根节点作为入口
const app = document.querySelector('#app')
// 通过oldNode和newNode渲染页面
patch(app, vNode)

```

如上创造了一个简单的内容，并添加点击事件。

### 源码结构

` src/package`

| 文件名 | 作用 |
| - | - |
| h.ts | 生成vNode |
| hooks.ts | 整个vNode生命周期钩子函数 |
| htmldomapi.ts | 封装生成dom的原生api |
| init.ts | 项目入口，处理vNode的关键 |
| is.ts | 判断类型工具函数 |
| jsx-global.ts | jsx声明文件 |
| jsx.ts | jsx解析文件 |
| thunk.ts | 优化处理，对复杂视图不可变化的处理 |
| tovnode.ts | 真实DOM转vNode工具函数 |
| vnode.ts | 定义vnode的类型 |
| helpers/attachto.ts | 定义了 vnode.ts 中 AttachData 的数据结构 |
| modules/attributes.ts | 操作DOM的属性 |
| modules/class.ts | 切换类样式 |
| modules/dataset.ts | 处理data-自定义属性 |
| modules/eventlisteners.ts | 注册和移除事件 |
| modules/hero.ts | 自定义钩子函数 |
| modules/module.ts | 导出各种模块 |
| modules/props.ts | 通过对象属性来设置，不处理布尔属性 |
| modules/style.ts | 设置行内样式及动画 |

### VNode结构

一个VNode节点完整的数据结构如下。

```jsx
export type Key = string | number
/**
 * @description 定义Vnode数据的接口类型
 *  @param sel 元素选择器
 *  @param data 节点数据:属性/样式/事件等
 *  @param children 子节点，和 text 只能互斥
 *  @param elm 记录 vnode 对应的真实 DOM
 *  @param text 节点中的内容，和 children 只能互斥
 *  @param key 数据的key对比dom时候用
 * 
 */
export interface VNode {
  sel: string | undefined
  data: VNodeData | undefined
  children: Array<VNode | string> | undefined
  elm: Node | undefined
  text: string | undefined
  key: Key | undefined
}
```

### h函数

h函数的作用是创建VNode节点并返回创建节点。在snabbdom中，h函数是基于ts的重载的定义的函数，参数具有不确定性。
-  第一个参数是sel，可以是tag name(如：h1) 也可以是tag name联合标签选择器(如：div#container)。
-  b参数是元素attributes集合，具有不确定性，可以选择性传入
-  c参数是textConent或者子元素

**为了更好理解运行原理，这里采用ts被编译后的js函数作为演示。** 

```jsx
export function h(sel, b, c) {
    var data = {};
    var children;
    var text;
    var i;
    if (c !== undefined) {
        if (b !== null) {
            data = b;
        }
        if (is.array(c)) {
            children = c;
        }
        // typeof s === 'string' || typeof s === 'number';
        else if (is.primitive(c)) {
            text = c;
        }
        else if (c && c.sel) {
            children = [c];
        }
    }
    else if (b !== undefined && b !== null) {
        if (is.array(b)) {
            children = b;
        }
        else if (is.primitive(b)) {
            text = b;
        }
        else if (b && b.sel) {
            children = [b];
        }
        else {
            data = b;
        }
    }
    if (children !== undefined) {
        for (i = 0; i < children.length; ++i) {
            if (is.primitive(children[i]))
                children[i] = vnode(undefined, undefined, undefined, children[i], undefined);
        }
    }
    // 针对svg元素特殊处理
    if (sel[0] === 's' && sel[1] === 'v' && sel[2] === 'g' &&
        (sel.length === 3 || sel[3] === '.' || sel[3] === '#')) {
        addNS(data, children, sel);
    }
    return vnode(sel, data, children, text, undefined);
}
```



### init函数/patch(内部)

init函数是最核心的函数是一个高阶函数，会返回一个patch函数。用于渲染对比VNode变成真实DOM。

### patch函数流程

1. 调用pre钩子
2. 如果不是Vnode，就创建一个空的vnode节点
3. 先判是否和旧的是用一个节点（判断key和sel）
4. 获取是否存在父节点（方便后续插入）
5. 调用createElm函数
6. 得到elm元素后，判断父节点是否存在，存在就插入到该父节点中
7. 调用removeVnodes函数移除掉旧的节点
8. 循环调用insert钩子函数
9. 循环调用post构造函数
10. 结束patch并返回vNode（下一次的oldNode）


```jsx
export function init (modules: Array<Partial<Module>>, domApi?: DOMAPI) {
  // 初始化patch函数
  let i: number
  let j: number
  // 初始化hooks回调
  const cbs: ModuleHooks = {
    create: [],
    update: [],
    remove: [],
    destroy: [],
    pre: [],
    post: []
  }
  const api: DOMAPI = domApi !== undefined ? domApi : htmlDomApi

  // 依次存储传入的hooks供后面调用
  for (i = 0; i < hooks.length; ++i) {
    cbs[hooks[i]] = []
    for (j = 0; j < modules.length; ++j) {
      const hook = modules[j][hooks[i]]
      if (hook !== undefined) {
        (cbs[hooks[i]] as any[]).push(hook)
      }
    }
  }
  // 创建空vNode的函数 
  function emptyNodeAt (elm: Element) {
    const id = elm.id ? '#' + elm.id : ''
    const c = elm.className ? '.' + elm.className.split(' ').join('.') : ''
    return vnode(api.tagName(elm).toLowerCase() + id + c, {}, [], undefined, elm)
  }
  /**
   * @description /一个高阶函数，返回一个移除节点的函数
   * @param childElm 子元素
   * @param listeners 移除的key，确定移除顺序
   */
  function createRmCb (childElm: Node, listeners: number) {
    return function rmCb () {
      if (--listeners === 0) {
        const parent = api.parentNode(childElm) as Node
        api.removeChild(parent, childElm)
      }
    }
  }
  /**
   * @description 添加vNode函数
   * @param parentElm  父元素
   * @param before  插入前的第一个元素
   * @param vnodes 
   * @param startIdx 
   * @param endIdx 
   * @param insertedVnodeQueue 
   */
  function addVnodes (
    parentElm: Node,
    before: Node | null,
    vnodes: VNode[],
    startIdx: number,
    endIdx: number,
    insertedVnodeQueue: VNodeQueue
  ) {
    for (; startIdx <= endIdx; ++startIdx) {
      const ch = vnodes[startIdx]
      if (ch != null) {
        api.insertBefore(parentElm, createElm(ch, insertedVnodeQueue), before)
      }
    }
  }

  function invokeDestroyHook (vnode: VNode) {
    const data = vnode.data
    if (data !== undefined) {
      //移除节点的destroy钩子回调
      data?.hook?.destroy?.(vnode)
      for (let i = 0; i < cbs.destroy.length; ++i) cbs.destroy[i](vnode)
      if (vnode.children !== undefined) {
        for (let j = 0; j < vnode.children.length; ++j) {
          const child = vnode.children[j]
          if (child != null && typeof child !== 'string') {
            invokeDestroyHook(child)
          }
        }
      }
    }
  }

  /**
   * @description 返回一个patch函数，参数是旧节点 - 新节点
   */
  return function patch (oldVnode: VNode | Element, vnode: VNode): VNode {
    let i: number, elm: Node, parent: Node
    const insertedVnodeQueue: VNodeQueue = []
    // 调用pre钩子
    for (i = 0; i < cbs.pre.length; ++i) cbs.pre[i]()
    // 如果不是Vnode，就创建一个空的vnode节点
    if (!isVnode(oldVnode)) {
      oldVnode = emptyNodeAt(oldVnode)
    }
    // 先判是否和旧的是用一个节点（判断key和sel
    if (sameVnode(oldVnode, vnode)) {
      patchVnode(oldVnode, vnode, insertedVnodeQueue)
    } else {
      elm = oldVnode.elm!
      // 获取是否存在父节点（方便后续插入）
      parent = api.parentNode(elm) as Node
      // 创建新的节点
      createElm(vnode, insertedVnodeQueue)
      // ，判断父节点是否存在，存在就插入到该父节点中
      if (parent !== null) {
        api.insertBefore(parent, vnode.elm!, api.nextSibling(elm))
        // 调用removeVnodes函数移除掉旧的节点
        removeVnodes(parent, [oldVnode], 0, 0)
      }
    }
    // 循环调用insert钩子函数
    for (i = 0; i < insertedVnodeQueue.length; ++i) {
      insertedVnodeQueue[i].data!.hook!.insert!(insertedVnodeQueue[i])
    }
    // 循环调用post构造函数
    for (i = 0; i < cbs.post.length; ++i) cbs.post[i]()
    // 结束patch并返回vNode（下一次的oldNode）
    return vnode
  }
}
```

### patchVnode函数

**patchVnode是对比节点函数的具体实现。**

1. 首先触发preptach钩子
2. 触发update钩子函数
3. 判断是否为文本节点，如果和旧的一样就不处理，如果是不一样的就设置新节点的textConent
4. 如果有chilcren，就对比新旧子元素是否相等，通过updateChildren函数，并更新差异
5. 如果新节点有childeren，就节点没有，那么就清空textConent，然后添加子节点进去
6. 如果老节点有children属性，新节点没有，那么直接移除老节点的内容
7. 判断老节点是否存在text属性，有的话直接清空
8. 触发postpatch钩子函数

```jsx
  /**
   * @description 对比节点函数
   * @param oldVnode  旧节点
   * @param vnode  新节点
   * @param insertedVnodeQueue 
   */
  function patchVnode (oldVnode: VNode, vnode: VNode, insertedVnodeQueue: VNodeQueue) {
    const hook = vnode.data?.hook
    // 首先触发preptach钩子
    hook?.prepatch?.(oldVnode, vnode)
    const elm = vnode.elm = oldVnode.elm!
    const oldCh = oldVnode.children as VNode[]
    const ch = vnode.children as VNode[]
    // 如果一模一样直接返回
    if (oldVnode === vnode) return
    // 执行update钩子函数
    if (vnode.data !== undefined) {
      for (let i = 0; i < cbs.update.length; ++i) cbs.update[i](oldVnode, vnode)
      vnode.data.hook?.update?.(oldVnode, vnode)
    }
    // 判断是否为文本节点，如果和旧的一样就不处理，如果是不一样的就设置新节点的textConent
    if (isUndef(vnode.text)) {
      if (isDef(oldCh) && isDef(ch)) {
        // 如果有chilcren，就对比新旧子元素是否相等，通过updateChildren函数对象，并更新差异  diff核心
        if (oldCh !== ch) updateChildren(elm, oldCh, ch, insertedVnodeQueue)
      } else if (isDef(ch)) {
        // 如果新节点有childeren，就节点没有，那么就清空textConent，然后添加子节点进去
        if (isDef(oldVnode.text)) api.setTextContent(elm, '')
        addVnodes(elm, null, ch, 0, ch.length - 1, insertedVnodeQueue)
      } else if (isDef(oldCh)) {
        // 如果老节点有children属性，新节点没有，那么直接移除老节点的内容
        removeVnodes(elm, oldCh, 0, oldCh.length - 1)
      } else if (isDef(oldVnode.text)) {
        // 判断老节点是否存在text属性，有的话直接清空
        api.setTextContent(elm, '')
      }
      // 如果新旧节都是文本节点，且不一致，那么就移除旧节点的内容，并设置新的
    } else if (oldVnode.text !== vnode.text) {
      if (isDef(oldCh)) {
        removeVnodes(elm, oldCh, 0, oldCh.length - 1)
      }
      api.setTextContent(elm, vnode.text!)
    }
    // 触发postpatch钩子函数
    hook?.postpatch?.(oldVnode, vnode)
  }
```

### createElm函数

1. 先判断是否为注释节点，是就直接渲染
2. 如果是DOM节点，先保存原节点的样式属性
3. 然后调用原生document.createElement创建标签，然后设置相关的id和class到该标签
4. 依次执行create钩子函数
5. 如果有子节点就递归调用该该函数，创建子节点
6. 没有子节点，判断该节点是否为文本节点，如果是就插入到当前vNode中
7. 最后返回该Vnode的elm元素

```jsx
  /**
   * @description 创建新的元素节点
   * @param vnode 
   * @param insertedVnodeQueue 
   */
  function createElm (vnode: VNode, insertedVnodeQueue: VNodeQueue): Node {
    let i: any
    let data = vnode.data
    if (data !== undefined) {
      const init = data.hook?.init
      if (isDef(init)) {
        init(vnode)
        data = vnode.data
      }
    }
    const children = vnode.children
    const sel = vnode.sel
    // 如果是注释节点，直接创建一个空的注释节点
    if (sel === '!') {
      if (isUndef(vnode.text)) {
        vnode.text = ''
      }
      vnode.elm = api.createComment(vnode.text!)
    } else if (sel !== undefined) {
      // 是非空节点
      // 先保存原节点的属性
      const hashIdx = sel.indexOf('#')
      const dotIdx = sel.indexOf('.', hashIdx)
      const hash = hashIdx > 0 ? hashIdx : sel.length
      const dot = dotIdx > 0 ? dotIdx : sel.length
      const tag = hashIdx !== -1 || dotIdx !== -1 ? sel.slice(0, Math.min(hash, dot)) : sel
      // createElementNS一般创建svg标签
      const elm = vnode.elm = isDef(data) && isDef(i = data.ns)
        ? api.createElementNS(i, tag)
        : api.createElement(tag)
      if (hash < dot) elm.setAttribute('id', sel.slice(hash + 1, dot))
      if (dotIdx > 0) elm.setAttribute('class', sel.slice(dot + 1).replace(/\./g, ' '))
      // 调用create钩子函数
      for (i = 0; i < cbs.create.length; ++i) cbs.create[i](emptyNode, vnode)
      // 如果存在子节点，递归调用该函数创建节点
      if (is.array(children)) {
        for (i = 0; i < children.length; ++i) {
          const ch = children[i]
          if (ch != null) {
            api.appendChild(elm, createElm(ch as VNode, insertedVnodeQueue))
          }
        }
        // 
      } else if (is.primitive(vnode.text)) {
        api.appendChild(elm, api.createTextNode(vnode.text))
      }
      const hook = vnode.data!.hook
      if (isDef(hook)) {
        hook.create?.(emptyNode, vnode)
        // 如果存在insert钩子，添加到插入vNode的队列中
        if (hook.insert) {
          insertedVnodeQueue.push(vnode)
        }
      }
    } else {
      // 没有子节点，判断该节点是否为文本节点，如果是就插入到当前vNode中
      vnode.elm = api.createTextNode(vnode.text!)
    }
    // 返回该Vnode的elm元素
    return vnode.elm
  }
```

### removeVnodes函数

1. 循环处理要删除的节点内容
2. 如果是文本节点，直接通过removeChild方式移除
3. 如果是常规节点，先调用传入的destroy钩子函数（可选）
4. 把remove钩子函数的数量添加
5. 然后调用createRmCb高阶函数，并通过listeners来确定唯一的dom防止重复删除
6. 循环调用remove函数
7. 调用外部传入的remove钩子（可选）
8. 最后调用前面高阶函数返回的函数，真正执行删除

```jsx
  /**
   * @description 移除Vnode函数
   * @param parentElm 
   * @param vnodes 
   * @param startIdx 
   * @param endIdx 
   */
  function removeVnodes (parentElm: Node,
    vnodes: VNode[],
    startIdx: number,
    endIdx: number): void {
      // 循环要删除的节点内容
    for (; startIdx <= endIdx; ++startIdx) {
      let listeners: number
      let rm: () => void
      const ch = vnodes[startIdx]
      if (ch != null) {
        if (isDef(ch.sel)) {
          // 如果是常规节点，先调用传入的destroy钩子函数（可选）
          invokeDestroyHook(ch)
          // remove钩子函数的数量添加
          listeners = cbs.remove.length + 1
          // rm是真实执行删除操作的函数
          rm = createRmCb(ch.elm!, listeners)
          // 循环执行remove的hooks钩子函数
          for (let i = 0; i < cbs.remove.length; ++i) cbs.remove[i](ch, rm)
          // 调用外部传入的remove钩子（可选）
          const removeHook = ch?.data?.hook?.remove
          if (isDef(removeHook)) {
            removeHook(ch, rm)
          } else {
            // 真正执行删除
            rm()
          }
        } else { 
          // 如果是文本节点，直接通过removeChild方式移除
          api.removeChild(parentElm, ch.elm!)
        }
      }
    }
  }
```

### updateChildren函数（diff核心）

updateChildren是init内部的函数，也就是核心的diff算法。

- oldStartIdx（旧节点开始索引）
- newStartIdx（新节点开始索引）
- oldEndIdx（旧节点结束索引）
- newEndIdx（新节点结束索引）
1. 先初始化索引和头尾节点的值
2. 分别判断新头/新，旧头/尾 是否为null，如果是那么就在节点队列里面创建一个/减少一个元素
3. 对比旧头和新头，如果是一个节点就处理内部的变化，并更新DOM
4. 对比旧尾和新尾，如果是一个节点就处理内部的变化，并更新DOM
5. 对比旧头和新尾，比较内部差异，把更新的内容移动到插入到旧节点的最后
6. 对比旧尾和新头，然后比较内部差异，把更新的内容移动到插入到旧节点的最前
7. 如果不是以上情况，说明开始节点 是一个全新的节点，而非对比的节点
	- 定义一个方便通过新节点的key找到旧节点数组的索引
	- 然后 用新节点的key 找到老节点的索引
	- 如果没有key，那么就创建dom，并插入到最前方
	- 如果有key。判断sel属性是否相同，如果不相同就创建新的dom，如果相同则代表是相同节点
	- 插入完成后，索引增加

8. 如果新节点/旧节点还有剩余
	- 如果是老节点的子节点先遍历完成，那么就把剩下的新节点元素，都插入到旧节点的后面
	- 如果新节点先完成，那么剩下的就是老节点需要移除的节点


```jsx
 /**
   * 
   * @param parentElm 父亲元素
   * @param oldCh 旧节点元素
   * @param newCh 新节点元素
   * @param insertedVnodeQueue 插入vNode的队列
   * 
   * 通过四个索引地址来进行diff
   * 
   */
  function updateChildren (parentElm: Node,
    oldCh: VNode[],
    newCh: VNode[],
    insertedVnodeQueue: VNodeQueue) {
    // 旧开始节点
    let oldStartIdx = 0
    // 新开始节点
    let newStartIdx = 0
    // 旧结束节点
    let oldEndIdx = oldCh.length - 1
    let oldStartVnode = oldCh[0]
    let oldEndVnode = oldCh[oldEndIdx]
    // 新结束节点
    let newEndIdx = newCh.length - 1
    let newStartVnode = newCh[0]
    let newEndVnode = newCh[newEndIdx]
    let oldKeyToIdx: KeyToIndexMap | undefined
    let idxInOld: number
    let elmToMove: VNode
    let before: any

    while (oldStartIdx <= oldEndIdx && newStartIdx <= newEndIdx) {
      /**
       * 如果四个对比节点其中有为null的，那么就重新赋值，并且为元素数组中 添加/减少 一位
       */
      if (oldStartVnode == null) {
        oldStartVnode = oldCh[++oldStartIdx] 
      } else if (oldEndVnode == null) {
        oldEndVnode = oldCh[--oldEndIdx]
      } else if (newStartVnode == null) {
        newStartVnode = newCh[++newStartIdx]
      } else if (newEndVnode == null) {
        newEndVnode = newCh[--newEndIdx]
      /**
       *  如果是同一个元素，就对比新旧节点内部的变化，然后修改dom
       *  并且把Vnode内容分别添加一项（索引后移）
       */
      } else if (sameVnode(oldStartVnode, newStartVnode)) {
        patchVnode(oldStartVnode, newStartVnode, insertedVnodeQueue)
        oldStartVnode = oldCh[++oldStartIdx]
        newStartVnode = newCh[++newStartIdx]
        // 道理同前者
      } else if (sameVnode(oldEndVnode, newEndVnode)) {
        patchVnode(oldEndVnode, newEndVnode, insertedVnodeQueue)
        oldEndVnode = oldCh[--oldEndIdx]
        newEndVnode = newCh[--newEndIdx]
        /**
         * 对比旧开始和新结束节点，并更新dom
         * 然后比较内部差异，把更新的内容移动到插入到旧节点的最后
         * 旧的索引向后移动 新的索引向前移动
         */
      } else if (sameVnode(oldStartVnode, newEndVnode)) { // Vnode moved right
        patchVnode(oldStartVnode, newEndVnode, insertedVnodeQueue)
        api.insertBefore(parentElm, oldStartVnode.elm!, api.nextSibling(oldEndVnode.elm!))
        oldStartVnode = oldCh[++oldStartIdx]
        newEndVnode = newCh[--newEndIdx]
         /**
         * 对比旧结束和新开始节点，并更新dom
         * 然后比较内部差异，把更新的内容移动到插入到旧节点的最前
         * 旧的索引向前移动 新的索引向后移动
         */
      } else if (sameVnode(oldEndVnode, newStartVnode)) { // Vnode moved left
        patchVnode(oldEndVnode, newStartVnode, insertedVnodeQueue)
        api.insertBefore(parentElm, oldEndVnode.elm!, oldStartVnode.elm!)
        oldEndVnode = oldCh[--oldEndIdx]
        newStartVnode = newCh[++newStartIdx]
        /**
         * 如果不是以上情况，说明开始节点 是一个全新的节点，而非对比的节点
         *  如果没有key，那么就创建dom，并插入到最前方（1）
         *  如果有key。判断sel属性是否相同，如果不相同就创建新的dom，如果相同则代表是相同节点(2)
         */
      } else {
        // 方便通过新节点的key找到旧节点数组的索引
        if (oldKeyToIdx === undefined) {
          oldKeyToIdx = createKeyToOldIdx(oldCh, oldStartIdx, oldEndIdx)
        }
        // 用新节点的key 找到老节点的索引
        idxInOld = oldKeyToIdx[newStartVnode.key as string]
        // （1）新节点
        if (isUndef(idxInOld)) {
          api.insertBefore(parentElm, createElm(newStartVnode, insertedVnodeQueue), oldStartVnode.elm!)
        } else {
        // (2) 旧节点
        // 取出就节点
          elmToMove = oldCh[idxInOld]
          // 被修改过的元素，直接创建一个新的插入
          if (elmToMove.sel !== newStartVnode.sel) {
            api.insertBefore(parentElm, createElm(newStartVnode, insertedVnodeQueue), oldStartVnode.elm!)
          } else {
            // 没有修改过，同patchVnode内部差异并更新
            patchVnode(elmToMove, newStartVnode, insertedVnodeQueue)
            // 把旧节点相应位置的元素设置为undefined
            oldCh[idxInOld] = undefined as any
            // 把修改过的元素移动到盗猎的元素之前
            api.insertBefore(parentElm, elmToMove.elm!, oldStartVnode.elm!)
          }
        }
        // 插入完成后，索引增加
        newStartVnode = newCh[++newStartIdx]
      }
    }
    // 老节点的子节点先遍历完成。或者新节点的子节点先遍历完成
    if (oldStartIdx <= oldEndIdx || newStartIdx <= newEndIdx) {
      if (oldStartIdx > oldEndIdx) {
        // 如果是老节点的子节点先遍历完成，那么就把剩下的新节点元素，都插入到旧节点的后面
        // before是需要插入的参考位置
        before = newCh[newEndIdx + 1] == null ? null : newCh[newEndIdx + 1].elm
        addVnodes(parentElm, before, newCh, newStartIdx, newEndIdx, insertedVnodeQueue)
      } else {
        // 新节点先完成，那么剩下的就是老节点需要移除的节点
        removeVnodes(parentElm, oldCh, oldStartIdx, oldEndIdx)
      }
    }
  }
```

## 常见疑问

### 为什么要设置key

通过阅读diff算法（updateChildren函数）源码我们可以知道，判断两个节点是否相同是通过sameVnode函数。

```jsx
function sameVnode(vnode1, vnode2) {
    return vnode1.key === vnode2.key && vnode1.sel === vnode2.sel;
}
```

如上所示sameVnode是通过key和sel来区分两个节点是否相同，如果没有设置key那么两个VNode的key都是undefined，只需要sel相同即可，那么就会造成数据渲染错误的问题。

在一定程度上设置key的过程更消耗性能，但是在页面渲染和diff过程中。key是不可或缺的。

**源码分析地址： https://github.com/gzg1023/snabbdom-fork** 

