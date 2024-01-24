let nativeEmbed = {
    //判断设备是否支持touch事件
    touch:('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch,
    nativeEmbed : document.getElementById('cameraTest'),//或者“cameraTest”
    nativeEmbed1 : document.getElementById('cameraTest1'),

    //事件
    events:{
        nativeEmbed:document.getElementById('cameraTest'),     //this为slider对象
        nativeEmbed1:document.getElementById('cameraTest1'),
        handleEvent:function(event){
            console.log("yupeng event")
            var self = this;     //this指events对象
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
            console.log("yupeng start slide");
            this.nativeEmbed.removeEventListener('touchmove',this,false);
            this.nativeEmbed.removeEventListener('touchend',this,false);
            this.nativeEmbed1.removeEventListener('touchmove',this,false);
            this.nativeEmbed1.removeEventListener('touchend',this,false);
            console.log("yupeng start slide 1111");
        },
        move:function(event){
            console.log("yupeng start move");
            //当屏幕有多个touch或者页面被缩放过，就不执行move操作

        },
        //滑动释放
        end:function(event){
            //解绑事件
            console.log("yupeng end slide");
            this.nativeEmbed.removeEventListener('touchmove',this,false);
            this.nativeEmbed.removeEventListener('touchend',this,false);
            this.nativeEmbed1.removeEventListener('touchmove',this,false);
            this.nativeEmbed1.removeEventListener('touchend',this,false);
        }

    },

    //初始化
    init:function(){
        let self = this;     //this指slider对象
        console.log("yupeng init:function");
        self.nativeEmbed.addEventListener('touchstart', self.events, false);    // addEventListener第二个参数可以传一个对象，会调用该对象的handleEvent属性
        self.nativeEmbed1.addEventListener('touchstart', self.events, false);
    }
};

nativeEmbed.init();