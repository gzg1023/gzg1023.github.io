---
title : 【技术分享】产品要在输入框输入高亮文字！？除了使用MD解析器，自己来模拟一个文本输入框
description : ""
summary : ""
toc : true
authors : ["gzg1023"]
tags : ["前端", "HTML",Vue]
categories : ["前端", "技术", "输入框"]
series : []
date :  "2021-01-26"
lastmod : "2021-01-26"
draft : false
---

需求是这样的，运营需要在输入框输入高亮的文本用来表示一个动态的文本（如用户名），后端去匹配相应动态的内容用来给客户端推送动态内容。(本文基于vue，原理通用)
<!--more-->

## 需求补充

运营通过添加按钮，为输入框内部添加 相应的标识符。添加完成的内容高亮显示，并且在发送给后端之前，把高亮的html代码字符转为约定的标识符。当进行编辑是，在重新把标识符匹配成相应高亮的文字。如下图所示。

![1111.png](https://i.loli.net/2021/03/06/7EuogSaYpjZWicQ.png)



## 1. 模拟输入框

第一部分很简单，就根据设计图或者原型模拟出来我们需要的文本框，这里我们在输入的时候添加一个有色边框，在未输入的情况，隐藏边框。尽量和真实文本框保持一致。

```html
 <div class="input-wrapper" :class="{ focus: msgTitleInputFocusFlag }">
    <p
      ref="inputRef"
      class="input-text
      @focus="msgTitleInputFocusFlag = true"
      @blur="msgTitleInputFocusFlag = false"
    ></p>
</div>
```
```CSS
.input-wrapper{
  width: 500px;
  height: 300px;
  padding: 0 15px;
  border: 1px solid #c0c4cc;
  border-radius: 4px;
}
.input-text {
    height: 100%;
    overflow: hidden;
    color: #606266;
    line-height: 30px;
  }
  &.focus {
    border-color: #409eff;
  }
```

## 2. 修改DOM性contenteditable


在html标签中有一个contenteditable属性，对应两个布尔值，true表示可以编辑，false表示不可以编辑。该属性支持所有浏览器（没错包括ie6）。
我们把模拟的输入框修改为contenteditable="true"，并且在我们处理高亮文本时候，把需要处理的文本contenteditable设置false，防止用户选中一半，或者是删除的过程中可以删除整个文本词组。

```html
 <div>
    <p
      contenteditable="true"
    ></p>
</div>
```

定义我们约定的高亮标示符。

```javascript
// 点击添加时候，插入到文本中
const hightext =  '<span class="fack-name" contenteditable="false">【动态名称】</span>'
```

## 3. 修改innerHtml属性

在vue中我们通过ref可以拿到DOM节点，然后获取innerHtml属性的内容，在我们输入的时候进行修改

```javascript
// 点击添加按钮时候，把高亮文本拼接到我们的editString变量中，并赋值给DOM节点的内容
 addDynamicName() {
      this.editString += hightext  
      this.$refs.inputRef.innerHTML = this.editString
    }
```

此时，我们在输入框就可以输入，并点击按钮可以添加高亮字符到页面中进行显示。

## 4. 处理光标及后续匹配

在上面完成后，可以输入内容并且添加高亮内容了。但是我们会发现一个问题，添加完成高亮文本后，光标跑到了最前面，而且页面的内容，无法进行选择。如下图。

![222.png](https://i.loli.net/2021/03/06/OrDjLzSKEmBcdi1.png)

但是在输入完成后，我们还是需要输入内容的，所以为输入框解决输入问题。在之前添加名称完成后，我们再重置光标的位置。通过locateToLastIndex函数，我们手动更改光标的位置，传入的参数是DOM

```javascript
locateToLastIndex(obj) {
    if (window.getSelection) {
    obj.focus() // 解决ff不获取焦点无法定位问题
    let range = window.getSelection() // 创建range
    range.selectAllChildren(obj) // range 选择obj下所有子内容
    range.collapseToEnd() // 光标移至最后
    } else if (document.selection) {
    let range = document.selection.createRange() // 创建选择对象
    range.moveToElementText(obj) // range定位到obj
    range.collapse(false) // 光标移至最后
    range.select()
    }
}
```
```javascript
 addDynamicName() {
      this.editString += hightext  
      this.$refs.inputRef.innerHTML = this.editString
      // 补充移动光标函数
      this.locateToLastIndex(this.$refs.inputRef)
    }
```


光标问题完成后，在我们每次输入内容时候，都需要更新内容。
通过绑定keydown和input事件，在每次输入完成后，我们把文本内容赋值给显示内容（相当于显示是用innerHtml，字符串用我们之前的editString来保存）


```html
 <div>
    <p
      contenteditable="true"
      @keydown="inputMsgConent"
      @input="inputMsgConent"
    ></p>
</div>
```
```javascript
inputMsgConent() {
      this.$nextTick(() => {
        this.editString = this.$refs.inputRef.innerHTML
      })
    }
```

最后我们就完成了输入框的开发，在提交数据时候通过正则匹配，变成约定的字符串，在修改时候通过约定的内容匹配回来。这样就完成了。

```javascript
// 通过正则匹配高亮字符串，发送接口时候修改为相应的标识符
const highReg = /\<span class="fack-name" contenteditable="false"\>【动态名称】\<\/span\>/g
// #MSG_MARK 是和后端约定的字符串，用来标示高亮区域的内容
let str = this.editString.replace(highReg, '#MSG_MARK')
// 拿到str后发送给后端
```


## 5. 处理复制来的文本

完成需求后，在测试阶段，发现当运营输入了内容页面没有办法进行正常当读取和显示。因为HTML的内容没有同步到我们的输入框绑定的值中。需要给
模拟的输入添加paste事件，来监听用户的输入，然后同步用户复制的输入内容。

### 绑定paste事件

```jsx
<div class="msg-title-input-wrapper" :class="{ focus: msgTitleInputFocusFlag }">
  <p
    ref="inputRef"
    class="msg-title-input"
    @keydown="inputMsgConent"
    @input="inputMsgConent"
    contenteditable="true"
    @paste="checkPastedMsgTitle"
    @focus="msgTitleInputFocusFlag = true"
    @blur="msgTitleInputFocusFlag = false"
  ></p>
</div>
``` 

### 处理paste事件

```jsx
checkPastedMsgTitle(e) {
     // 阻止末默认事件,手动获取剪切板的内容，同步到editString上
      e.preventDefault()
      let pasteData = (e.clipboardData || window.clipboardData).getData('text')
      const selection = window.getSelection()
      if (!selection.rangeCount) {
        return false
      }
      selection.deleteFromDocument()
      selection.getRangeAt(0).insertNode(document.createTextNode(pasteData))
      this.$nextTick(() => {
        this.editString = this.$refs.inputRef.innerHTML
      })
    }
```