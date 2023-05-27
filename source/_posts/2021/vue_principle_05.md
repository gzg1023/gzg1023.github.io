---
title: vue.js(2.x)原理 - Virtual dom及Compile模版编译器原理分析)「05」
date: 2021-07-22
lastmod: 2021-07-22
tags: ["前端", "vue原理"]
categories: ["技术", "vue原理"]
author: "gzg1023"
toc: true
---

> vue2 增加了 v-dom 功能让 vue 大方光彩也可以跨平台。而模版语法是 vue 最重要的特性，本文让我们来看看编写的模版语法是怎么一步步变成浏览器中真实 DOM 元素。

<!--more-->

## v-dom

### 是什么

在之前写个一片文章介绍了 v-dom 和 snabbdom 的源码，vue2.x 就是基于改库进行二次封装的。

### 改进部分

在 vue2 中不是完全照搬 snabbdom，而是基于 vue 的场景进行了一些修改。此部分重点说一下两个部分，判断 key 和 diff 部分。

#### key 的变化

在 snabbdom 中 通过 key 和 sel 就判断是否为同一节点，那么在 vue 中，增加了一些判断 在满足 key 相等的同时会判断，tag 名称是否一致，是否为注释节点，是否为异步节点，或者为 input 时候类型是否相同等。

```js
const hooks = ["create", "activate", "update", "remove", "destroy"];
/**
 *
 * @param a 被对比节点
 * @param {*} b  对比节点
 * 对比两个节点是否相同
 * 需要组成的条件：key相同，tag相同，是否都为注释节点，是否同事定义了data，如果是input标签，那么type必须相同
 */
function sameVnode(a, b) {
  return (
    a.key === b.key &&
    ((a.tag === b.tag &&
      a.isComment === b.isComment &&
      isDef(a.data) === isDef(b.data) &&
      sameInputType(a, b)) ||
      (isTrue(a.isAsyncPlaceholder) &&
        a.asyncFactory === b.asyncFactory &&
        isUndef(b.asyncFactory.error)))
  );
}
```

#### patchVnode

patch 是对比模版变化的函数，可能会用到 diff 也可能直接更新

patchVnode 规则

1. 如果新旧 VNode 都是静态的，同时它们的 key 相同（代表同一节点），并且新的 VNode 是 clone 或者是标记了 once（标记 v-once 属性，只渲染一次），那么只需要替换 elm 以及 componentInstance 即可。
2. 新老节点均有 children 子节点，则对子节点进行 diff 操作，调用 updateChildren，这个 updateChildren 也是 diff 的核心。
3. 如果老节点没有子节点而新节点存在子节点，先清空老节点 DOM 的文本内容，然后为当前 DOM 节点加入子节点。
4. 当新节点没有子节点而老节点有子节点的时候，则移除该 DOM 节点的所有子节点。
5. 当新老节点都无子节点的时候，只是文本的替换

```js
function patchVnode(
  oldVnode,
  vnode,
  insertedVnodeQueue,
  ownerArray,
  index,
  removeOnly
) {
  if (oldVnode === vnode) {
    return;
  }

  if (isDef(vnode.elm) && isDef(ownerArray)) {
    // clone reused vnode
    vnode = ownerArray[index] = cloneVNode(vnode);
  }

  const elm = (vnode.elm = oldVnode.elm);

  if (isTrue(oldVnode.isAsyncPlaceholder)) {
    if (isDef(vnode.asyncFactory.resolved)) {
      hydrate(oldVnode.elm, vnode, insertedVnodeQueue);
    } else {
      vnode.isAsyncPlaceholder = true;
    }
    return;
  }
  if (
    isTrue(vnode.isStatic) &&
    isTrue(oldVnode.isStatic) &&
    vnode.key === oldVnode.key &&
    (isTrue(vnode.isCloned) || isTrue(vnode.isOnce))
  ) {
    vnode.componentInstance = oldVnode.componentInstance;
    return;
  }

  let i;
  const data = vnode.data;
  if (isDef(data) && isDef((i = data.hook)) && isDef((i = i.prepatch))) {
    i(oldVnode, vnode);
  }

  const oldCh = oldVnode.children;
  const ch = vnode.children;
  if (isDef(data) && isPatchable(vnode)) {
    for (i = 0; i < cbs.update.length; ++i) cbs.update[i](oldVnode, vnode);
    if (isDef((i = data.hook)) && isDef((i = i.update))) i(oldVnode, vnode);
  }
  if (isUndef(vnode.text)) {
    // 定义了子节点，且不相同，用diff算法对比
    if (isDef(oldCh) && isDef(ch)) {
      if (oldCh !== ch)
        updateChildren(elm, oldCh, ch, insertedVnodeQueue, removeOnly);
      // 新节点有子元素。旧节点没有
    } else if (isDef(ch)) {
      if (process.env.NODE_ENV !== "production") {
        // 检查key
        checkDuplicateKeys(ch);
      }
      // 清空旧节点的text属性
      if (isDef(oldVnode.text)) nodeOps.setTextContent(elm, "");
      // 添加新的Vnode
      addVnodes(elm, null, ch, 0, ch.length - 1, insertedVnodeQueue);
      // 如果旧节点的子节点有内容，新的没有。那么直接删除旧节点子元素的内容        } else if (isDef(oldCh)) {
      removeVnodes(oldCh, 0, oldCh.length - 1);
      // 如上。只是判断是否为文本节点
    } else if (isDef(oldVnode.text)) {
      nodeOps.setTextContent(elm, "");
    }
    // 如果文本节点不同，替换节点内容
  } else if (oldVnode.text !== vnode.text) {
    nodeOps.setTextContent(elm, vnode.text);
  }
  if (isDef(data)) {
    if (isDef((i = data.hook)) && isDef((i = i.postpatch))) i(oldVnode, vnode);
  }
}
```

#### 核心 diff

- 首先，在新老两个 VNode 节点的左右头尾两侧都有一个变量标记，在遍历过程中这几个变量都会向中间靠拢。当 oldStartIdx > oldEndIdx 或者 newStartIdx > newEndIdx 时结束循环。
  索引与 VNode 节点的对应关系： oldStartIdx => oldStartVnode oldEndIdx => oldEndVnode newStartIdx => newStartVnode newEndIdx => newEndVnode

- 在遍历中，如果存在 key，并且满足 sameVnode，会将该 DOM 节点进行复用，否则则会创建一个新的 DOM 节点。

- oldStartVnode、oldEndVnode 与 newStartVnode、newEndVnode 两两比较一共有 2\*2=4 种比较方法。
  当新老 VNode 节点的 start 或者 end 满足 sameVnode 时，也就是 sameVnode(oldStartVnode, newStartVnode)或者 sameVnode(oldEndVnode, newEndVnode)，直接将该 VNode 节点进行 patchVnode 即可。

- 如果 oldStartVnode 与 newEndVnode 满足 sameVnode，即 sameVnode(oldStartVnode, newEndVnode)。

这时候说明 oldStartVnode 已经跑到了 oldEndVnode 后面去了，进行 patchVnode 的同时还需要将真实 DOM 节点移动到 oldEndVnode 的后面。

- 如果 oldEndVnode 与 newStartVnode 满足 sameVnode，即 sameVnode(oldEndVnode, newStartVnode)。

- 这说明 oldEndVnode 跑到了 oldStartVnode 的前面，进行 patchVnode 的同时真实的 DOM 节点移动到了 oldStartVnode 的前面。
  如果以上情况均不符合，则通过 createKeyToOldIdx 会得到一个 oldKeyToIdx，里面存放了一个 key 为旧的 VNode，value 为对应 index 序列的哈希表。
- 从这个哈希表中可以找到是否有与 newStartVnode 一致 key 的旧的 VNode 节点，如果同时满足 sameVnode，
  patchVnode 的同时会将这个真实 DOM（elmToMove）移动到 oldStartVnode 对应的真实 DOM 的前面。

- 有可能 newStartVnode 在旧的 VNode 节点找不到一致的 key，或者是即便 key 相同却不是 sameVnode，这个时候会调用 createElm 创建一个新的 DOM 节点。

```js
function updateChildren(
  parentElm,
  oldCh,
  newCh,
  insertedVnodeQueue,
  removeOnly
) {
  let oldStartIdx = 0;
  let newStartIdx = 0;
  let oldEndIdx = oldCh.length - 1;
  let oldStartVnode = oldCh[0];
  let oldEndVnode = oldCh[oldEndIdx];
  let newEndIdx = newCh.length - 1;
  let newStartVnode = newCh[0];
  let newEndVnode = newCh[newEndIdx];
  let oldKeyToIdx, idxInOld, vnodeToMove, refElm;
  const canMove = !removeOnly;

  if (process.env.NODE_ENV !== "production") {
    checkDuplicateKeys(newCh);
  }

  while (oldStartIdx <= oldEndIdx && newStartIdx <= newEndIdx) {
    if (isUndef(oldStartVnode)) {
      oldStartVnode = oldCh[++oldStartIdx]; // Vnode has been moved left
    } else if (isUndef(oldEndVnode)) {
      oldEndVnode = oldCh[--oldEndIdx];
    } else if (sameVnode(oldStartVnode, newStartVnode)) {
      patchVnode(
        oldStartVnode,
        newStartVnode,
        insertedVnodeQueue,
        newCh,
        newStartIdx
      );
      oldStartVnode = oldCh[++oldStartIdx];
      newStartVnode = newCh[++newStartIdx];
    } else if (sameVnode(oldEndVnode, newEndVnode)) {
      patchVnode(
        oldEndVnode,
        newEndVnode,
        insertedVnodeQueue,
        newCh,
        newEndIdx
      );
      oldEndVnode = oldCh[--oldEndIdx];
      newEndVnode = newCh[--newEndIdx];
    } else if (sameVnode(oldStartVnode, newEndVnode)) {
      // Vnode moved right
      patchVnode(
        oldStartVnode,
        newEndVnode,
        insertedVnodeQueue,
        newCh,
        newEndIdx
      );
      canMove &&
        nodeOps.insertBefore(
          parentElm,
          oldStartVnode.elm,
          nodeOps.nextSibling(oldEndVnode.elm)
        );
      oldStartVnode = oldCh[++oldStartIdx];
      newEndVnode = newCh[--newEndIdx];
    } else if (sameVnode(oldEndVnode, newStartVnode)) {
      // Vnode moved left
      patchVnode(
        oldEndVnode,
        newStartVnode,
        insertedVnodeQueue,
        newCh,
        newStartIdx
      );
      canMove &&
        nodeOps.insertBefore(parentElm, oldEndVnode.elm, oldStartVnode.elm);
      oldEndVnode = oldCh[--oldEndIdx];
      newStartVnode = newCh[++newStartIdx];
    } else {
      if (isUndef(oldKeyToIdx))
        oldKeyToIdx = createKeyToOldIdx(oldCh, oldStartIdx, oldEndIdx);
      idxInOld = isDef(newStartVnode.key)
        ? oldKeyToIdx[newStartVnode.key]
        : findIdxInOld(newStartVnode, oldCh, oldStartIdx, oldEndIdx);
      if (isUndef(idxInOld)) {
        // New element
        createElm(
          newStartVnode,
          insertedVnodeQueue,
          parentElm,
          oldStartVnode.elm,
          false,
          newCh,
          newStartIdx
        );
      } else {
        // vnodeToMove将要移动的节点
        vnodeToMove = oldCh[idxInOld];
        if (sameVnode(vnodeToMove, newStartVnode)) {
          patchVnode(
            vnodeToMove,
            newStartVnode,
            insertedVnodeQueue,
            newCh,
            newStartIdx
          );
          oldCh[idxInOld] = undefined;
          canMove &&
            nodeOps.insertBefore(parentElm, vnodeToMove.elm, oldStartVnode.elm);
        } else {
          // same key but different element. treat as new element
          createElm(
            newStartVnode,
            insertedVnodeQueue,
            parentElm,
            oldStartVnode.elm,
            false,
            newCh,
            newStartIdx
          );
        }
      }
      // vnodeToMove将要移动的节点
      newStartVnode = newCh[++newStartIdx];
    }
  }
  // 旧节点完成，新的没完成
  if (oldStartIdx > oldEndIdx) {
    refElm = isUndef(newCh[newEndIdx + 1]) ? null : newCh[newEndIdx + 1].elm;
    addVnodes(
      parentElm,
      refElm,
      newCh,
      newStartIdx,
      newEndIdx,
      insertedVnodeQueue
    );
    // 新的完成，老的没完成
  } else if (newStartIdx > newEndIdx) {
    removeVnodes(oldCh, oldStartIdx, oldEndIdx);
  }
}
```

## Compile

一个 vue 组件如下所属，是由 3 部分组成，template,script,style。而在刚学 vue 的时候，写起 template 就和我们直接写 html 一样，只需要记几个指令，就可以享受流畅的开发体验。刚学 vue 的我并不知道模版编译，v-dom 这些东西。 天真的以为就是纯 html 而已。

过了很久，我了解到并不是单纯的 html，对 spa 应用也有了更深入的了解。本文就来聊聊模版编译。

```javascript
<template>
    <div class="">

    </div>
</template>
<script>
export default {
   name:"",
   props: {
   },
   components: {
   },
   data() {
      return {
      }
   },
   computed: {
   },
   watch: {
   },
   created() {
   },
   mounted() {
   }
}
</script>

<style lang="less" scoped>

</style>
```

### 渲染器

vue 中模版编译的核心是渲染器。渲染器的工作流程分为两个阶段：mount 和 patch，如果旧的 VNode 存在，则会使用新的 VNode 与旧的 VNode 进行对比，试图以最小的资源开销完成 DOM 的更新，这个过程就叫 patch，或“打补丁”。如果旧的 VNode 不存在，则直接将新的 VNode 挂载成全新的 DOM，这个过程叫做 mount。

渲染器会针对不同类型的模版元素进行分别处理，主要包括组件，hmtl 元素，web components 元素，svg 元素，纯文本元素等。如下所示会通过`flags`来标记不同的类型，然后通过类型来处理不同等元素。

```js
function mount(vnode, container) {
  const { flags } = vnode;
  if (flags & VNodeFlags.ELEMENT) {
    // 挂载普通标签
    mountElement(vnode, container);
  } else if (flags & VNodeFlags.COMPONENT) {
    // 挂载组件
    mountComponent(vnode, container);
  } else if (flags & VNodeFlags.TEXT) {
    // 挂载纯文本
    mountText(vnode, container);
  } else if (flags & VNodeFlags.FRAGMENT) {
    // 挂载 Fragment
    mountFragment(vnode, container);
  } else if (flags & VNodeFlags.PORTAL) {
    // 挂载 Portal
    mountPortal(vnode, container);
  }
}
```

### 编译器

vue 对整个模版的编译的工作很多，包括处理各种类型的组件，添加事件监听，处理模版语法，处理作用域，DOM 属性和 vue attrs

vue 中是通过`createCompilerCreator`来创建编译器对象，对模版进行编译。它本身是一个高阶函数 会在此返回一个函数。

- createCompiler 用以创建编译器，返回值是 compile 以及 compileToFunctions。
- compile 是一个编译器，它会将传入的 template 转换成对应的 AST、render 函数以及 staticRenderFns 函数。
- 而 compileToFunctions 则是带缓存的编译器，同时 staticRenderFns 以及 render 函数会被转换成 Funtion 对象。
- 因为不同平台有一些不同的 options，所以 createCompiler 会根据平台区分传入一个 baseOptions，会与 compile 本身传入的 options 合并得到最终的 finalOptions。

```js
export function createCompilerCreator(baseCompile: Function): Function {
  return function createCompiler(baseOptions: CompilerOptions) {
    // compile函数
    function compile(
      template: string,
      options?: CompilerOptions
    ): CompiledResult {
      const finalOptions = Object.create(baseOptions);
      const errors = [];
      const tips = [];

      let warn = (msg, range, tip) => {
        (tip ? tips : errors).push(msg);
      };
      // 合并options
      if (options) {
        // 合并modules
        if (options.modules) {
          finalOptions.modules = (baseOptions.modules || []).concat(
            options.modules
          );
        }
        // 合并directives
        if (options.directives) {
          finalOptions.directives = extend(
            Object.create(baseOptions.directives || null),
            options.directives
          );
        }
        //拷贝一份option api
        for (const key in options) {
          if (key !== "modules" && key !== "directives") {
            finalOptions[key] = options[key];
          }
        }
      }
      const compiled = baseCompile(template.trim(), finalOptions);
      compiled.errors = errors;
      compiled.tips = tips;
      return compiled;
    }
    return {
      compile,
      // compileToFunctions是一个函数
      compileToFunctions: createCompileToFunctionFn(compile),
    };
  };
}
```

### 编译流程

编译流程： baseCompile -> parse -> parseHTML -> options.start -> options.end -> closeElement -> processSlotContent

createCompilerCreator 函数处理完成后，就得到了优化的 js 代码

```js
export const createCompiler = createCompilerCreator(function baseCompile(
  template: string,
  options: CompilerOptions
): CompiledResult {
  // 把模版编译成ast语法树
  const ast = parse(template.trim(), options);
  if (options.optimize !== false) {
    // 优化ast
    optimize(ast, options);
  }
  // 把ast变成字符串形式的js代码
  const code = generate(ast, options);
  return {
    ast,
    render: code.render,
    staticRenderFns: code.staticRenderFns,
  };
});
```

得到了转化后的代码，通过 createCompileToFunctionFn 进行下一步的操作，在进入 compileToFunctions 以后，会先检查缓存中是否有已经编译好的结果，如果有结果则直接从缓存中读取。 这样做防止每次同样的模板都要进行重复的编译工作。

```js
export function createCompileToFunctionFn(compile: Function): Function {
  const cache = Object.create(null);

  return function compileToFunctions(
    template: string,
    options?: CompilerOptions,
    vm?: Component
  ): CompiledFunctionResult {
    options = extend({}, options);
    const warn = options.warn || baseWarn;
    delete options.warn;

    // check cache
    // 读取缓存，空间换时间
    const key = options.delimiters
      ? String(options.delimiters) + template
      : template;
    if (cache[key]) {
      return cache[key];
    }

    // 保存编译结果
    const compiled = compile(template, options);

    const res = {};
    const fnGenErrors = [];
    res.render = createFunction(compiled.render, fnGenErrors);
    res.staticRenderFns = compiled.staticRenderFns.map((code) => {
      return createFunction(code, fnGenErrors);
    });

    return (cache[key] = res);
  };
}
```

缓存完成模版编译的结果，通过 createFunction 返回 render 函数。该函数的作用就是直接把字符串 js 代码转为一个函数。

```js
// 把字符串代码，通过new Function转为执行的函数
function createFunction(code, errors) {
  try {
    return new Function(code);
  } catch (err) {
    errors.push({ err, code });
    return noop;
  }
}
```

然后就得到了可行性的 render 函数 compileToFunctions。在入口处会调用该函数对 template 进行编译（源码已精简）

```js
Vue.prototype.$mount = function (
  el?: string | Element,
  hydrating?: boolean
): Component {
  // 如果存在el，就取到当前到DOM，可以是css选择器，也可以是DOM节点
  el = el && query(el)
  // el不能是body或者html元素
  if (el === document.body || el === document.documentElement) {
    process.env.NODE_ENV !== 'production' && warn(
      `Do not mount Vue to <html> or <body> - mount to normal elements instead.`
    )
    return this
  }

  const options = this.$options
  /**
   *  解析模板 转为render
   *  如果不存在render就是用template模版的内容
   */
  if (!options.render) {
    let template = options.template
    if (template) {
      if (typeof template === 'string') {
        if (template.charAt(0) === '#') {
          template = idToTemplate(template)
        }
      } else if (template.nodeType) {
        template = template.innerHTML
      } else {
        if (process.env.NODE_ENV !== 'production') {
          warn('invalid template option:' + template, this)
        }
        return this
      }
    } else if (el) {
      template = getOuterHTML(el)
    }
    if (template) {
      /* istanbul ignore if */
      if (process.env.NODE_ENV !== 'production' && config.performance && mark) {
        mark('compile')
      }
      // 在这边编译模版，产生render函数
      const { render, staticRenderFns } = compileToFunctions(template, {
        outputSourceRange: process.env.NODE_ENV !== 'production',
        shouldDecodeNewlines,
        shouldDecodeNewlinesForHref,
        delimiters: options.delimiters,
        comments: options.comments
      }, this)
      options.render = render
      options.staticRenderFns = staticRenderFns
    }
  }
  // 渲染DOM
  return mount.call(this, el, hydrating)
}
```
