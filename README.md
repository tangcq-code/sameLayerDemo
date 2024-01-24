# sameLayerRenderDemo
### 简介
sameLayerRenderDemo为测试webview同层渲染能力的一个简单DEMO，当前DEMO只演示了button和video组件的同层渲染效果，尚未包含组件属性更新及监听传递。

### 使用示例
1. web侧编写包含embed元素的HTML代码，存放在DEMO的src/main/resources/rawfile下，当前同层渲染embed元素仅支持id、type、width、height、src、style六个参数设置，示例片段如下：
```html
<div>
    <div id="bodyId">
        <form name="myForm" onsubmit="return validateForm()" method="post">
            <label for="name">姓名：</label>
            <input type="text" id="name" name="name" required><br><br>

            <label for="email">电子邮件：</label>
            <input type="email" id="email" name="email" required><br><br>

            <label for="message">留言：</label><br>
            <textarea id="message" name="message" rows="5" cols="40" required></textarea><br><br>

            <label for="phone">电话号码：</label>
            <input type="text" id="phone" name="phone" required><br><br>

            <input type="submit" value="提交">
        </form>
        <div id="error-message"></div>
        <embed id="cameraTest" type="native/camera" width="900" height="1050" src="test" style="background-color:red"/>
        <br>
        <h1>同层渲染测试</h1>
        <br>
        <embed id="cameraTest1" type="native/camera" width="900" height="1050" src="test" style="background-color:red"/>
    </div>
</div>
```
2. WEB容器组件使用enableNativeEmbedMode开启同层渲染模式。
3. onNativeEmbedLifecycleChange用于订阅HTML中的embed元素的信息。
    - embed入参有四个属性，分别为status、info、embedId、surfaceId。
    - embed.status代表embed元素的三个状态CREATE、UPDATE、DESTROY。
    - embed.embedId为每个embed对应的数字id，用于onNativeEmbedGestureEvent定位触摸位置。
    - embed.surfaceId作为创建根节点new BuilderNode的入参。
    - embed.info包含embed元素中id、type等信息。
4. onNativeEmbedGestureEvent用于发送触摸事件。
```typescript
Web({ src: $rawfile("index.html"), controller: this.browserTabController })
  .enableNativeEmbedMode(true)
  .onNativeEmbedLifecycleChange((embed) => {
    console.log("NativeEmbed surfaceId" + embed.surfaceId);
  })
  .onNativeEmbedGestureEvent((touch) => {
    console.log("NativeEmbed onNativeEmbedGestureEvent" + JSON.stringify(touch.touchEvent));
  })
```
5. 在onNativeEmbedLifecycleChange读取到HTML页面中的embed元素时，还需要给WEB侧注入触摸事件处理的代码，参考如下（详见JsCodeHandle.ets文件）：
```typescript
export class JsCodeHandle {
  private embedEventHandleCode: string = ''

  getJsCode() {
    return this.embedEventHandleCode
  }

  setJsCode(componentId: string) {
    this.embedEventHandleCode = `
    let nativeEmbed_${componentId} = {
    //判断设备是否支持touch事件
    ......
    //初始化
    init:function(){
        // this为slider对象
        let self = this;
        console.log("[WebEmbedEventHandle] init:function");
        // addEventListener第二个参数可以传一个对象，会调用该对象的handleEvent属性
        self.nativeEmbed_${componentId}.addEventListener('touchstart', self.events, false);
    }
};

nativeEmbed_${componentId}.init();
`
  }
}
```
6. onNativeEmbedLifecycleChange每读取到一个embed，根据它的状态，如Create状态，则需要构建对应的rootNode和nodeController以完成同层渲染配置，
   且每个rootNode都对应一个nodeContainer，此处使用ForEach动态创建的方式，示例如下：
```typescript
    Row() {
      Column({ space: 5 }) {
        Stack(){
          ForEach(this.componentIdArr, (componentId: string) => {
            NodeContainer(this.nodeControllerMap.get(componentId))
          }, (embedId: string) => embedId)
          Web({ src: $rawfile("index.html"), controller: this.browserTabController })
        }
      }
    }
```