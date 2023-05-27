---
title: vue.js(2.x)原理 - Vue内置指令及内置组件（v-show, v-if, v-for , v-model,keep-alive)「04」
date: 2021-06-12
lastmod: 2021-06-13
tags: ["前端", "vue原理", ]
categories: ["技术", "vue原理"]
author: "gzg1023"
toc: true
---

> 分析完成响应式原理后，vue的内置指令和组件就是日常开发中最熟悉的内容了，平时一直用组件，这次来看看这些指令到底是怎么实现的。

<!--more-->

## v-show

渲染原理是，无论是true还是false都会渲染组件实例，当值为false时候，改变元素的``display``属性，第一次始终会创建，切换时候性能高。
* 本质是切换display 为none或者display
* 如果存在过渡属性，那么触发动画组件的生命周期

```js
export default {
  bind (el:, { value }, vnode) {
    const transition = vnode.data && vnode.data.transition
    const originalDisplay = el.__vOriginalDisplay =
      el.style.display === 'none' ? '' : el.style.display
    if (value && transition) {
      vnode.data.show = true
      enter(vnode, () => {
        el.style.display = originalDisplay
      })
    } else {
      el.style.display = value ? originalDisplay : 'none'
    }
  },
  // 
  update (el, { value, oldValue }, vnode) {
    if (!value === !oldValue) return
    vnode = locateNode(vnode)
    const transition = vnode.data && vnode.data.transition
    if (transition) {
      vnode.data.show = true
      if (value) {
        enter(vnode, () => {
          el.style.display = el.__vOriginalDisplay
        })
      } else {
        leave(vnode, () => {
          el.style.display = 'none'
        })
      }
    } else {
      el.style.display = value ? el.__vOriginalDisplay : 'none'
    }
  },

  unbind (
    el: any,
    binding: VNodeDirective,
    vnode: VNodeWithData,
    oldVnode: VNodeWithData,
    isDestroy: boolean
  ) {
    if (!isDestroy) {
      el.style.display = el.__vOriginalDisplay
    }
  }
}

```

## v-if 

## v-model
## keep-alive

``keep-alive``是一个内置的组件，用于缓存我们的vue组件，提高加载的性能。以下是option api的源码部分
* 可以看到通过include和exclude来定义要缓存的组件
* 通过cache对象和keys来保存缓存的实例（非响应式）
* 维护一个pruneCacheEntry结构，用来管理保存和删除 缓存内容
* 用max来指定最大的缓存数量，如果超过该数量 那么清除掉，第一个保存的组件
* 分为首次渲染和缓存渲染
* 在 patch 过程中对于已缓存的组件不会执行 mounted，通过 activated 和 deactivated 钩子函数控制
* 本质是LRU算法[https://leetcode-cn.com/problems/lru-cache-lcci](https://leetcode-cn.com/problems/lru-cache-lcci)

```js
/  keep-alive组件的option api
export default {
  name: 'keep-alive',
  // 取消$child和$parent的裙带关系
  abstract: true,

  props: {
    include: patternTypes,
    exclude: patternTypes,
    max: [String, Number] // 最大缓存数量
  },

  created () {
    // 缓存对象 
    this.cache = Object.create(null)
    this.keys = []
  },

  destroyed () {
    for (const key in this.cache) {
      pruneCacheEntry(this.cache, key, this.keys)
    }
  },

  mounted () {
    // 处理包含或者未包含的组件，进行过滤
    this.$watch('include', val => {
      pruneCache(this, name => matches(val, name))
    })
    this.$watch('exclude', val => {
      pruneCache(this, name => !matches(val, name))
    })
  },

  render () {
    const slot = this.$slots.default
    // keep-alive> 只处理第一个子元素，所以一般和它搭配使用的有 component 动态组件或者是 router-view
    const vnode: VNode = getFirstComponentChild(slot)
    const componentOptions: ?VNodeComponentOptions = vnode && vnode.componentOptions
    if (componentOptions) {
      // check pattern
      const name: ?string = getComponentName(componentOptions)
      const { include, exclude } = this
      if (
        // not included
        (include && (!name || !matches(include, name))) ||
        // excluded
        (exclude && name && matches(exclude, name))
      ) {
        return vnode
      }

      const { cache, keys } = this
      const key: ?string = vnode.key == null
        ? componentOptions.Ctor.cid + (componentOptions.tag ? `::${componentOptions.tag}` : '')
        : vnode.key
      if (cache[key]) {
        vnode.componentInstance = cache[key].componentInstance
        remove(keys, key)
        keys.push(key)
      } else {
        cache[key] = vnode
        keys.push(key)
        if (this.max && keys.length > parseInt(this.max)) {
          pruneCacheEntry(cache, keys[0], keys, this._vnode)
        }
      }

      vnode.data.keepAlive = true
    }
    return vnode || (slot && slot[0])
  }
}
```