---
title: 【技术分享】观察者模式VS发布/订阅模式
date: 2021-01-09
lastmod: 2021-01-09
tags: ['前端','设计模式','Vue原理']
categories: ['技术','设计模式']
author: "gzg1023"
toc: true
---



> 在vue中，观察者模式和发布/订阅模式被用到了方方面面，在刚开始了解时候感觉这两者总是分不清楚，本文对两者来个区分。
<!--more-->

## 概念

`观察者模式`：定义对象间的一种一对多的依赖关系，当一个对象的状态发生改变时，所有依赖于它的对象都得到通知并被自动更新。

`发布/订阅模式` ：发布者不会将消息直接发送给特定的接收者（称为订阅者）。而是将发布的消息分为不同的类别，无需了解哪些订阅者（如果有的话）可能存在。同样的，订阅者可以表达对一个或多个类别的兴趣，只接收感兴趣的消息，无需了解哪些发布者（如果有的话）存在。

### 观察者模式


* 观察者模式不存在接收器（中间商）
* 通过notify方法跟更新所有依赖

         // 发布者目标
        class Dep {
            constructor(){
                // 记录所有订阅者
                this.subs = []
            }
            // 添加订阅者
            addSub(sub) {
                if(sub && sub.update){
                    this.subs.push(sub)
                }
            }
            // 发布通知
            notify() {
                // 调用每个订阅者的方法
                this.subs.forEach((sub)=>{
                    sub.update()
                })
            }
        }

        // 观察者
        class Watcher{
            update() {
                console.log('update')
            }
        }

        let dep = new Dep()
        let wather1 = new Watcher()
        let wather2 = new Watcher()
        dep.addSub(wather1)
        dep.addSub(wather2)
        dep.notify()

### 发布/订阅模式 

* A组件负责发布消息，B,C,D...组件可以订阅A组件发送的事件，从而接收
* 依靠事件中心来完成发布和订阅
* 发布者不需要知道订阅者的存在

       // 发布订阅的事件中心
        class EventEmitter{
            constructor(){
                // 不需要原型的空对象
                // 可以注册多个事件，多个函数 {'click':[fn1,fn2],'change':[fn1,fn2]}
                this.subs = Object.create(null)
            }

            // 注册事件
            $on (eventType,handler) {
                //  如果方法不存在则传递一个空数组，保证eventType是数组结构
                this.subs[eventType] = this.subs[eventType] || []
                this.subs[eventType].push(handler)
            }

            // 触发事件
            $emit (eventType) {
                // 依次执行订阅的函数,如果有值则挨个执行，没有的话就不处理
                if(this.subs[eventType]){
                    this.subs[eventType].forEach((eventHandle) => {
                        eventHandle()
                    });
                }
            }
        }

        let vm = new EventEmitter()
        
        vm.$on('click',()=>{
            console.log('click handler1')
        })

        vm.$on('click',()=>{
            console.log('click handler2')
        })

        vm.$emit('click')