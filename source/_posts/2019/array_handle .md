---
title: 【技术笔记】JS的Array的各种API
tags: [前端,JavaScript]
index_img: https://s2.ax1x.com/2019/12/25/lFx0kq.jpg
date: 2019-12-25 22:32:00
toc: true
---


>  操作Array是日常业务最长接触，也是用到最多的数据结构。本文总结操作Array，包括ES5,ES6+版本及一些常见业务场景的例示
<!--more-->



#### 属性

 > Array.prototype.constructor

所有的数组实例都继承了这个属性，它的值就是 Array，表明了所有的数组都是由 Array 构造出来的。

> Array.prototype.length

因为 Array.prototype 也是个数组，所以它也有 length 属性，这个值为 0，因为它是个空数组。

#### 静态方法

##### concat方法

 > concat 连接 2 个或更多数组，并返回结果

        [1,2,3].concat([4,5,6]) // [1,2,3,4,5,6]

##### every方法

> every 对数组中的每个元素运行给定函数，如果该函数对每个元素都返回 true ，则返回 true

        var arr = [1,2,3,4,5,6]
        arr.every((item)=> item !== 7) //true

##### some方法

> some 对数组中的每个元素运行给定函数，如果该函数有一个元素都返回 true ，则返回 true

    var arr = [1,2,3,4,5,6]
    arr.some((item)=> item === 7 )  // false


##### forEach方法

> forEach 对数组中的每个元素运行给定函数。这个方法没有返回值

    var arr = [1,2,3,4,5,6]
    arr.forEach((item)=> console.log(item)) // 1 2 3 4 5 6

##### map方法

> map 对数组中的每个元素运行给定函数，返回每次函数调用的结果组成的数组

    var arr = [1,2,3,4,5,6]
    arr.map((item)=> console.log(item)) // 1 2 3 4 5 6

##### filter方法

> filter 对数组中的每个元素运行给定函数，返回该函数会返回 true 的元素组成的数组

    var arr = [1,2,3,4,5,6]
    arr.filter((item)=> item > 3) // [4,5,6]

##### reduce方法

> reduce() 方法接收一个函数作为累加器，数组中的每个值（从左到右）开始缩减，最终计算为一个值。

    var arr = [1,2,3,4,5,6]
    arr.reduce((item,item2)=> item+item2) // 21

##### join方法

> join 将所有的数组元素连接成一个字符串

    var arr = [1,2,3,4,5,6]
    arr.join() // 1,2,3,4,5,6

##### indexOf方法

> indexOf 返回第一个与给定参数相等的数组元素的索引，没有找到则返回 -1

    var arr = [1,2,3,4,5,6]
    arr.indexOf(1) // 0


##### lastIndexOf方法

> lastIndexOf 返回在数组中搜索到的与给定参数相等的元素的索引里最大的值

    var arr = [1,2,3,4,5,6,1]
    arr.lastIndexOf(1) // 6


##### reverse方法

> reverse 颠倒数组中元素的顺序，原先第一个元素现在变成最后一个，同样原先的最后一个元素变成了现在的第一个

    var arr = [1,2,3,4,5,6]
    arr.reverse() // [6,5,4,3,2,1]

##### slice方法

> slice 传入索引值，将数组里对应索引范围内的元素作为新数组返回

    var arr = [1,2,3,4,5,6]
    arr.slice(2) // [3,4,5,6]

##### splice方法

> splice 方法通过删除或替换现有元素或者原地添加新的元素来修改数组,并以数组形式返回被修改的内容。此方法会改变原数组

     var arr = [1,2,3,4,5,6]
    arr.splice(2,1) //[3]
    
##### sort方法

> sort 按照字母顺序对数组排序，支持传入指定排序方法的函数作为参数(有bug)

     var arr = [6,5,4,3,2,1]
    arr.sort() // [1,2,3,4,5,6]

##### toString方法

> toString 将数组作为字符串返回

     var arr =  [1,2,3,4,5,6]
    arr.toString() // "1,2,3,4,5,6"

##### copyWithin方法

> copyWithin 复制数组中一系列元素到同一数组指定的起始位置(浅拷贝)
   
   var arr =  [1,2,3,4,5,6]
    arr.copyWithin(1,2) // [1, 3, 4, 5, 6, 6]


##### includes方法

> includes 如果数组中存在某个元素则返回 true ，否则返回 false 

    var arr =  [1,2,3,4,5,6]
    arr.includes(1) // true

##### find方法

> find 根据回调函数给定的条件从数组中查找元素，如果找到则返回该元素

    var arr =  [1,2,3,4,5,6]
    arr.find(item=>item > 1) // 2

#####  findIndex方法

> findIndex 根据回调函数给定的条件从数组中查找元素，如果找到则返回该元素在数组中的索引

    var arr =  [1,2,3,4,5,6]
    arr.findIndex(item=>item == 3) // 2

##### fill方法

> fill() 方法用一个固定值填充一个数组中从起始索引到终止索引内的全部元素。不包括终止索引。

    var arr =  [1,2,3,4,5]
    arr.fill(0,2,4) //  [1, 2, 0, 0, 5]
#### 其他方法


##### Array.from方法

> from 根据已有数组创建一个新数组(浅拷贝)

    var arr =  [1,2,3,4,5]
    var arr2 = Array.from(arr)  //  [1, 2, 3, 4, 5]

##### Array.isArray方法

> Array.isArray() 用于确定传递的值是否是一个 Array

    var arr =  [1,2,3,4,5]
    Array.isArray(arr)  //true