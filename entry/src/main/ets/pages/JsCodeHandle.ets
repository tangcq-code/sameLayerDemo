export class JsCodeHandle {
  private embedEventHandleCode: string = ''

  getJsCode() {
    return this.embedEventHandleCode
  }

  setJsCode(componentId: string) {
    this.embedEventHandleCode = `
    let nativeEmbed_${componentId} = {
    //判断设备是否支持touch事件
    touch:('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch,
    nativeEmbed_${componentId} : document.getElementById('${componentId}'),

    //事件
    events:{
        // this为slider对象
        nativeEmbed_${componentId}:document.getElementById('${componentId}'),
        handleEvent:function(event){
            console.log("[WebEmbedEventHandle] event")
            //this指events对象
            var self = this;
            if(event.type == 'touchstart'){
                self.start(event);
            }else if(event.type == 'touchmove'){
                self.move(event);
            }else if(event.type == 'touchend'){
                self.end(event);
            }
        },

        //滑动开始
        start:function(event){
            console.log("[WebEmbedEventHandle] start slide");
            this.nativeEmbed_${componentId}.removeEventListener('touchmove', this, false);
            this.nativeEmbed_${componentId}.removeEventListener('touchend', this, false);
        },

        move:function(event){
            console.log("[WebEmbedEventHandle] start move");
            //当屏幕有多个touch或者页面被缩放过，就不执行move操作
        },

        //滑动释放
        end:function(event){
            // 解绑事件
            console.log("[WebEmbedEventHandle] end slide.");
            this.nativeEmbed_${componentId}.removeEventListener('touchmove', this, false);
            this.nativeEmbed_${componentId}.removeEventListener('touchend', this, false);
        }
    },

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