---
title: 【前端技术】Vue递归组件的简单运用
tags: [Vue]
index_img: 
date: 2020-02-03 21:00:00
toc: true
---

> 后台管理系统的菜单，树结构...当需求超过二级菜单时候，就要考虑使用递归组件了。
<!--more-->

顾名思义，递归组件就是组件调用自身；从而不管数据包含基层，都能顺利遍历的结构。构建一个基础的递归组件主要是两个部分组成，其一就是有一份可循环递归的数据。然后就是调用自身的DOM结构。
优秀递归组件：ElementUI的Tree组件[源码](https://github.com/ElemeFE/element/tree/dev/packages/tree)

### DOM结构
    
    // menu-item.vue
    <ul>
    <li v-for="(item,index) in list" :key="index"> // 循环遍历数据
      <p v-show="item.show" class="title" @click="clickHandle(item,index)">{{item.name}}</p> // 子项
      <div>
            <menu-item v-if="item.child" :list="item.child"></menu-item> // 递归调用
      </div>
    </li>
    </ul>

    // index.vue
    <menu-item :list="info"></menu-item> // 父组件调用，并通过props传入数据

### JS结构

     // menu-item.vue
     props:{
      list: Array
    },
    methods:{
        clickHandle(item,index){
            console.log(item,index)
        }
    }

    // index.vue

     info:[  // 组件需要遍历的数据，如果数组对象有child属性，说明包含子菜单
        {
          name:'超级菜单',
          show:true,
          child:[
             {
               name : '超级菜单二级菜单1',
               show: false,
             },
             {
               name : '超级菜单二级菜单2',
               show: false,
             }
          ]
        },
        {
        name:'设置菜单',
        show:true,
        child:[
             {
               name : '设置菜单二级菜单1',
               show: false,
             },
             {
               name : '设置菜单二级菜单2',
               show: false,
             }
          ]
        }
        ]

本文是一个简单例示，在示例项目中会存在各种情况。如果在处理数据事件处理时可以考虑以下优化方案
1. 使用event事件委托进行元素事件处理
2. 提取为两个组件，大层负责控制总统，内部负责每一项的展示和计算（参考ElementUI的Tree组件）
3. 添加CSS3过渡效果，提升用户体验