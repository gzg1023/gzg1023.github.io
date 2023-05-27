---
title: 【技术分享】手写一个A+规范的完整版Promise，让异步处理更流畅
date: 2021-06-03
lastmod: 2021-06-07
tags: ["前端", "Promise", "异步", "手写代码"]
categories: ["前端", "Promise", "异步", "手写代码"]
toc: true
---

> Promise 作为 ES6 系列的新特性，无疑是前端开发的重中之重。在 2021 年的现在无论是开源项目还是业务代码到处是 Promise 的身影。本文基于 A+规范重写一个 Promise 及其静态方法的完整版，加深自己对异步代码的理解。

<!--more-->

## 手写前置

都是手写代码了，肯定是经常使用并且熟悉各种方法。这里回顾一下 Promise 语法规则和静态的方法。

### 语法知识

1. 通过 new 创建（构造函数方式）,或者是 Promise.resolve()等静态方法直接创建
2. 只存在三种状态(`pending[初始等待状态]`,f`ulfilled[成功状态]`,`rejected[失败状态]`)
3. Promise 状态一旦确定，`不可逆转`。不能再次修改
4. 通过 then/catch/finally 方法实现链式调用，都会返回新的 Promise
5. 两个回调函数形参 resolve,reject 分别是成功和失败 回调函数
6. 执行 then(..) 注册回调处理数组（then 方法可被同一个 Promise 调用多次）
7. 本质是在微任务队列进行执行

![Promise](https://media.prod.mdn.mozit.cloud/attachments/2014/09/18/8633/51a934a714e191f53e588bff719bc321/promises.png)

<p align="center">(来自MDN的Promise执行流程图)</p>

方法：

- Promise.prototype.then(onFulfilled, onRejected) 添加成功或失败的 回调到当前 Promise, 并返回一个新的 Promise

- Promise.prototype.catch(onRejected) 添加失败的 回调到当前 Promise, 并返回一个新的 Promise

- Promise.prototype.finally(onFinally) 添加一个回调到当前 Promise（无论成功 或者失败）

静态方法（全部返回新 Promise）：

- Promise.resolve(value)：返回一个状态为成功的 Promise 对象，并将给定的成功信息传递给对应的处理方法

- Promise.reject(reason)：返回一个状态为失败的 Promise 对象，并将给定的失败信息传递给对应的处理方法

- Promise.all(iterable) ：iterable 参数里所有的 Promise 对象都成功的时候才会触发成功，有一个失败则直接失败

- Promise.allSettled(iterable)：iterable 参数所有 Promises 都完成后（包含成功和失败）返回

- Promise.any(iterable)：接收一个 Promise 对象的集合，当其中的一个 Promise 成功，就返回那个成功的 Promise 的值

- Promise.race(iterable)：接收一个 Promise 对象的集合，当其中的一个 Promise 成功或者失败以后，就返回这个 Promise 的值

## 手写代码

这里用 es6 语法来构建 Promise

### 基本结构

我们知道 Promise 总共有三种状态，这里通过静态常量的方式定义

```js
const PENDING = "pending";
const RESOLVE = "fulfilled";
const REJECT = "rejected";
```

通过 class 语法来定义 Promise 并初始化状态，因为同一个 Promise 的 then 方法可以调用多次，所以失败和成功的回调都是数组，当`new Promise`时候会传入一个函数，函数有两个方法，分别是成功和失败的回调，我们通过定义一个 executor 来执行传入的回调。如果传入了错误的内容，那么同`try catch`直接捕获错误并通过`reject`返回错误信息。

```js
class Promise {
  constructor(execurte) {
    // 默认状态是等待
    this.status = PENDING;
    // 成功的回调默认值
    this.value = undefined;
    // 失败的回调默认值
    this.resaon = undefined;
    // 成功的回调队列,可以多次then，所以存在多个定义为数组
    this.resolveCallBacks = [];
    // 失败的回调
    this.rejecteCallBacks = [];
    // 针对执行器进行异常处理
    try {
      execurte(this.resolve, this.reject);
    } catch (error) {
      this.reject(error);
    }
  }
}
```

编写完成基本结构，我们可以看到在使用如下例示代码,就可以进行第一步的创建了。

```js
let promise = new Promise((resolve, reject) => {
  // executor（"hello Promise"）
});
```

在执行 executor 过程中。我们需要处理 resolve, reject 函数的内容，对状态和数据进行处理。
如果当前状态是 pending（也就是初始化状态），那么我们修改的相应的状态为成功或者失败。并保存成功或失败的值，然后在回调队列中以此执行。
通过 ``queueMicrotask`` 我们来执行微任务

```js
resolve = (value) => {
  queueMicrotask(() => {
    if (this.status === PENDING) {
      this.status = FULFILLED; // 修改状态
      this.value = value;
      this.resolveCallBacks.forEach((fn) => fn(this.value)); // 成功的回调
    }
  });
};
// 失败时候的回调
reject = (resaon) => {
  queueMicrotask(() => {
    if (this.status === PENDING) {
      this.status = REJECTED; // 修改状态
      this.resaon = resaon;
      this.rejecteCallBacks.forEach((fn) => fn(this.resaon)); // 失败的回调
    }
  });
};
```

到这里基本的 Promise 结构就已经完成了，然后来实现最重要的链式调用

### 链式调用

我们知道 Promise 是通过 then 来实现链式调用的，再来总结一下规则：

1. 每次 then 都会返回一个新的 Promise
2. 接受两个参数，类型都为 Function，分别在 Promise 改变状态时候调用，第一个参数在状态为 resolved 运行并接受结果，第二个参数在状态为 rejected 运行并接受结果
3. 除了接收两个函数参数，在 then 的后面可以继续的 then
4. then 可能返回一个普通值，也可能返回一个 Promise

如上，第 4 点在 then 的过程中，我们可能直接返回一个普通值：如：`return 100`，也可以返回一个 Promise 如：`return new Promise()`，那么先定义一个工具函数`_returnValue`，用来处理返回的值。
需要注意的是，可能一种情况如下所示。创建当前对象，然后在 then 返回当前对象的情况，那么就产生了循环引用。所以需要添加一个循环引用的逻辑处理.

```js
// 循环引用测试
let p1 = new MyPromise((resolve, reject) => {
  resolve("yes");
});
let p2 = p1.then((res) => {
  return p2;
});
// 从这then以后，产生了循环引用
p2.then(
  () => {},
  (reson) => {
    console.log(reson);
  }
);
```

然后就得到了一个处理返回值的工具函数`_returnValue`

```js
/**
 *
 * @param {*} p 当前在运行的Promise
 * @param {*} callbackValue  返回值（then出来的值）
 * @param {*} resolve 成功回调
 * @param {*} reject  失败回调
 * @returns
 */
_returnValue(p, callbackValue, resolve, reject) {
      // 如果p和callbackValue相等，则说明产生了循环引用
      if (p === callbackValue) {
          return reject(new TypeError('靓仔，你的代码循环引用了'))
      }
      // 判断callbackValue是不是Promise类型
      if (callbackValue instanceof MyPromise) {
          callbackValue.then(value => resolve(value), resaon => reject(resaon))
      } else {
          resolve(callbackValue)
      }
}
```

有了工具函数，在实现 then 的链式调用就可以直接进行结果的处理了。
在该方法内接收两个之前提到的函数参数，如果是没有传递空值给我们，那么直接返回一个函数，或者是直接抛出错误供后续then的过程中拿到。
在then的处理过程中状态总共分为3种

- 成功状态
- 失败状态
- 等待状态

关于成功和失败两个状态，我们直接执行相应的回调函数，或者是捕获异常处理即可。通过前面定义的``_returnValue``来直接返回值。

如果是pending状态，说明在是通过异步的方式返回的callback函数，还没有调用``resolve或者reject``来改变状态，那么通过``resolveCallBacks 和 rejecteCallBacks``来存储需要执行的任务，并加入到微任务队列，等待结果的返回以后 然后执行想要的回调函数。 如果不存在这一步那么当``Promise``中存在异步任务时候，同步代码就会直接直接完成，而不会在异步任务完成后修改``Promise``的状态。

```js
then = (resolveCallBack, rejecteCallBack) => {
  // 如果传递空值，则默认向后传递所以添加一个默认情况
  resolveCallBack = resolveCallBack ? resolveCallBack : (value) => value;
  // 参数可选
  rejecteCallBack = rejecteCallBack ? rejecteCallBack : (reason) => { throw reason; };
  let p = new MyPromise((resolve, reject) => {
    // 处理不同的返回，如果是正常值直接返回，如果是Promise对象，则返回一个Promise供继续调用
    // 成功
    if (this.status === FULFILLED) {
      // 开启一个微任务，等待p结果的返回。否则程序限制性后返回p的值
      // 针对执行的函数进行异常处理
      queueMicrotask(() => {
        try {
          let callbackValue = resolveCallBack(this.value);
          this._returnValue(p, callbackValue, resolve, reject);
        } catch (error) {
          reject(error);
        }
      });
      // 失败
    } else if (this.status === REJECTED) {
      queueMicrotask(() => {
        try {
          let callbackValue = rejecteCallBack(this.resaon);
          this._returnValue(p, callbackValue, resolve, reject);
        } catch (error) {
          reject(error);
        }
      });
      // 等待过程
    } else {
      // 判断为等待状态的情况，存储任务然后后续执行
      // 存储成功的任务
      this.resolveCallBacks.push(() => {
        queueMicrotask(() => {
          try {
            let callbackValue = resolveCallBack(this.value);
            this._returnValue(p, callbackValue, resolve, reject);
          } catch (error) {
            reject(error);
          }
        });
      });
      // 存储失败的情况
      this.rejecteCallBacks.push(() => {
        queueMicrotask(() => {
          try {
            let callbackValue = rejecteCallBack(this.resaon);
            this._returnValue(p, callbackValue, resolve, reject);
          } catch (error) {
            reject(error);
          }
        });
      });
    }
  });
  return p;
};
```

完成then之后catch就很容易实现了，直接调用then方法，传入一个失败的函数。

```js
// 注册一个非静态的方法,catch收集错误信息
catch(rejecteCallBack) {
    return this.then(undefined, rejecteCallBack)
}
```

finally方法是无论成功或者失败都会执行的方法，直接通过then返回一个方法

```js
// 注册一个非静态的方法,无论成功或者失败finally都会执行
finally(callback) {
    return this.then((value) => {
        return MyPromise.resolve(callback()).then(() => value)
    }, (resaon) => {
        return MyPromise.resolve(callback()).then(() => { throw resaon })
    })
}
```

## 静态方法

### resolve

这个就直接返回一个成功的Promise，没什么可说的

```js
static resolve(value) {
    // 如果是promise对象则直接返回
    if (value instanceof MyPromise) {
        return value
    } else {
        // 如果不是promise对象，则重新创建一个
        return new MyPromise((resolve) => {
            resolve(value)
        })
    }
}
```

### reject

// 返回一个失败的Promise

```js
    // 静态方法，返回错误的Promise
    static reject(resaon) {
        if (resaon instanceof MyPromise) {
            return resaon
        } else {
            // 如果不是promise对象，则重新创建一个
            return new MyPromise((resolve, reject) => {
                reject(resaon)
            })
        }
    }
```

### all

all主要是保留每一个的结果，当结果全部完成后返回，用``then``来获取成功的Promise

```js
static all(promises) {
    // 保存回调结果的数组
    let result = [];
    // 累加器，用来判断执行的方法队列是否执行完成
    let count = 0;
    // all 方法也返回一个promise对象
    return new MyPromise((resolve, reject) => {
        function pushResult(key, value) {
            result[key] = value
            count++
            // 如果累加器和执行的任务列表长度相等，则说明已经完成了整个任务
            if (count === promises.length) {
                resolve(result)
            }
        }
        // 循环处理要执行的任务
        promises.forEach((task, index) => {
            if (task instanceof MyPromise) {
                task.then((v) => pushResult(index, v), (resaon) => reject(resaon))
            } else {
                pushResult(index, promises[index])
            }
        })
    })
}
```

### allSettled

allSettled不管成功或者失败，反正都给你返回出去，所以在处理的时候直接使用``finally``关键字。如果是普通类型直接存value

```js
static allSettled(promises) {
    return new MyPromise((resolve) => {
        let results = []
        let count = 0
        promises.forEach((task, index) => {
            if (task instanceof MyPromise) {
                task.finally(_ => {
                    count++
                    results[index] = {
                        status: task.status,
                        value: task.value || task.resaon
                    }
                    if (count === promises.length) {
                        resolve(results)
                    }
                })
            } else {
                count++
                results[index] = {
                    status: 'fulfilled',
                    value: task
                }
                if (count === promises.length) {
                    resolve(results)
                }
            }
        })
    })
}
```

### any

只要有一个成功就返回，同样用``then``获取

```js
static any(promises) {
    return new MyPromise((resolve) => {
        promises.forEach((task) => {
            if (task instanceof MyPromise) {
                task.then(_ => {
                    resolve(task.value)
                })
            } else {
                resolve(task)
            }
        })
    })
}
```

### race

只要有一个成功或者就返回，用``finally``获取

```js
static race(promises) {
    return new MyPromise((resolve) => {
        promises.forEach((task) => {
            if (task instanceof MyPromise) {
                task.finally(_ => {
                    resolve(task.value || task.resaon)
                })
            } else {
                resolve(task)
            }
        })
    })
}
```

### 添加测试配置

然后添加defer用例，执行测试用例

```js
promises-aplus-tests Promise.js 
```

```js
MyPromise.defer = MyPromise.deferred = function () {
    let testObj = {}
    testObj.promise = new Promise((resolve, reject) => {
        testObj.resolve = resolve
        testObj.reject = reject
    })
    return testObj
}
module.exports = MyPromise
```


## 完整代码

完整代码 [GitHub地址](https://github.com/gzg1023/fackAchieve/blob/main/feature/attribute/MyPromise.js)