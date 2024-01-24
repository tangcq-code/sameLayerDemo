import webview from '@ohos.web.webview';
import { UIContext } from '@ohos.arkui.UIContext';
import { NodeController, BuilderNode, NodeRenderType, FrameNode } from '@ohos.arkui.node';
import { AVPlayerDemo } from './PlayerDemo';
import mapCommon from '@hms.core.map.mapCommon';
import map from '@hms.core.map.map';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { MapComponent } from '@hms.core.map.MapComponent';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { JsCodeHandle } from './JsCodeHandle'

declare class Params {
  text: string
  width : number
  height : number
  mapOption: mapCommon.MapOptions
  mapCallback: AsyncCallback<map.MapComponentController>
}

class MyNodeController extends NodeController {
  private rootNode: BuilderNode<[Params]> | undefined | null;
  private embedId: string | undefined;
  private wrapBuilder = new WrappedBuilder(ButtonBuilder);

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.rootNode == null) {
      this.rootNode = new BuilderNode(uiContext);
      this.rootNode.build(this.wrapBuilder, { text: "button1" })
    }
    return this.rootNode.getFrameNode();
  }

  setBuilderNode(rootNode: BuilderNode<Params[]> | null): void {
    this.rootNode = rootNode;
  }

  setEmbedId(embedId: string | undefined): void {
    this.embedId = embedId;
  }

  getBuilderNode(): BuilderNode<[Params]> | undefined | null {
    return this.rootNode;
  }

  getEmbedId(): string | undefined{
    return this.embedId;
  }
}

@Component
struct MyComponent {
  @Prop params: Params
  @State bkColor: Color = Color.Red
  testController: WebviewController = new webview.WebviewController();
  mXComponentController: XComponentController = new XComponentController();
  @State player_changed: boolean = false;
  player?: AVPlayerDemo

  build() {
    Column() {
      Button(this.params.text) {
        if (true) {
          Row() {
            LoadingProgress().width(20).height(20).margin({ left: 12 }).color(0xFFFFFF)
            Text('loading').fontSize(12).fontColor(0xffffff).margin({ left: 5, right: 12 })
          }.alignItems(VerticalAlign.Center)
        }
      }
        .height(50)
        .width(200)
        .border({ width: 2, color: Color.Red })
        .backgroundColor(this.bkColor)
        .onClick(() => {
          console.log("NativeEmbed button onClick")
          if ( this.bkColor == Color.Blue) {
            this.bkColor = Color.Red
          } else {
            this.bkColor = Color.Blue
          }
        })

      XComponent({ id: 'video_player_id', type: XComponentType.SURFACE, controller: this.mXComponentController })
        .width(300)
        .height(300)
        .border({ width: 1, color: Color.Red })
        .onLoad(()=>{
          this.player = new AVPlayerDemo();
          this.player.setSurfaceID(this.mXComponentController.getXComponentSurfaceId());
          this.player_changed = !this.player_changed;
          this.player.avPlayerLiveDemo()
        })
      // MapComponent({ mapOptions: this.params.mapOption, mapCallback: this.params.mapCallback })
      //   .width(500)
      //   .height(700)
    }
    .width(this.params.width)
    .height(this.params.height)
  }
}

@Builder
function ButtonBuilder(params: Params) {
  MyComponent({ params: params })
    .backgroundColor(Color.Green)
}

@Entry
@Component
struct WebIndex {
  browserTabController: WebviewController = new webview.WebviewController()
  private nodeControllerMap: Map<string, MyNodeController> = new Map();
  private jsCodeHandle: JsCodeHandle = new JsCodeHandle()
  @State componentIdArr: Array<string> = []
  @State flag: boolean = false
  @State isRegisterEmbedJs: boolean = false
  @State nodeContainerWidth:number = 0
  @State nodeContainerHeight:number = 0

  private mapOption: mapCommon.MapOptions | undefined
  private mapCallback: AsyncCallback<map.MapComponentController> | undefined
  private mapController: map.MapComponentController = new map.MapComponentController();

  aboutToAppear() {
    // 配置Web开启调试模式
    webview.WebviewController.setWebDebuggingAccess(true);

    // 地图初始化参数，设置地图中心点坐标及层级
    console.log('NativeEmbed 设置地图参数')
    this.mapOption = {
      position: {
        target: {
          latitude: 2.922865,
          longitude: 101.58584
        },
        zoom: 2
      },
      myLocationControlsEnabled: true
    }
    // 地图初始化的回调
    this.mapCallback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        this.mapController.on("mapLoad", () => {
          console.info('NativeEmbed', `on-mapLoad`);
        });
      }
    }
  }

  getRunJavaScript(): string {
    let context = getContext(this) as common.UIAbilityContext;
    let fileContent = context.resourceManager.getRawFileContentSync('nativeEmbed.js')
    let textDecoder = util.TextDecoder.create("utf-8", { ignoreBOM: true });
    let result = textDecoder.decodeWithStream(fileContent, { stream: false });
    return result
  }

  build() {
    Row() {
      Column({ space: 5 }) {
        Stack(){
          ForEach(this.componentIdArr, (componentId: string) => {
            NodeContainer(this.nodeControllerMap.get(componentId))
          }, (embedId: string) => embedId)
          Web({ src: $rawfile("index.html"), controller: this.browserTabController })
            .onConsole((event) => {
              console.debug('[WEB]', `${event?.message.getMessage()}`)
              return false
            })
            .enableNativeEmbedMode(true)
            .onNativeEmbedLifecycleChange((embed) => {
              console.log("NativeEmbed surfaceId" + embed.surfaceId);
              // 获取web侧embed元素的id
              const componentId = embed.info?.id?.toString() as string
              // 一次性注入事件处理JSCode
              // if (!this.isRegisterEmbedJs) {
              //   try {
              //     this.browserTabController.runJavaScript(
              //       this.getRunJavaScript(),
              //       (error, result) => {
              //         if (error) {
              //           return;
              //         }
              //         if (result) {
              //         }
              //       });
              //   } catch (error) {
              //   }
              // }
              if (embed.status == NativeEmbedStatus.CREATE) {
                console.log("NativeEmbed create" + JSON.stringify(embed.info));
                // 注入事件处理代码
                console.log('NativeEmbed componentId-------: ', componentId)
                this.jsCodeHandle.setJsCode(componentId)
                try {
                  this.browserTabController.runJavaScript(
                    this.jsCodeHandle.getJsCode(),
                    (error, result) => {
                      if (error) {
                        console.log('NativeEmbed register js code error: ', error)
                        return;
                      }
                      if (result) {
                        console.log('NativeEmbed register js code result: ', result)
                      }
                    });
                } catch (error) {
                  console.log('NativeEmbed register js code error: ', error)
                }
                // 创建nodeController节点控制器
                let nodeController = new MyNodeController()
                let uiContext = AppStorage.get<UIContext>("UIContext");
                let rootNode: BuilderNode<Params[]> = new BuilderNode(uiContext as UIContext, { surfaceId: embed.surfaceId, type: NodeRenderType.RENDER_TYPE_TEXTURE });
                // 根据type类型构建对应的原生组件
                if (embed.info?.type === 'native/camera') {
                  rootNode.build(new WrappedBuilder(ButtonBuilder), {text: 'myButton', width : px2vp(embed.info.width), height : px2vp(embed.info.height)});
                } else if (embed.info?.type === 'native/video') {
                  // 构建video
                } else if (embed.info?.type === 'native/map') {
                  // 构建map
                } else if (embed.info?.type === 'native/button') {
                  // 构建button
                } else {
                  // 其它
                }
                nodeController.setBuilderNode(rootNode)
                nodeController.setEmbedId(embed.embedId)
                nodeController.rebuild()
                // 根据web传入的embed的id属性作为key，将nodeController存入Map
                this.nodeControllerMap.set(componentId, nodeController)
                // 将web传入的embed的id属性存入@State状态数组变量中，用于动态创建nodeContainer节点容器,需要将push动作放在set之后
                this.componentIdArr.push(componentId)
              } else if (embed.status == NativeEmbedStatus.UPDATE) {
                let nodeController = this.nodeControllerMap.get(componentId);
                let rootNode = nodeController?.getBuilderNode()
                rootNode?.update({text: 'update', width: px2vp(embed.info?.width), height: px2vp(embed.info?.height)} as ESObject);
                nodeController?.rebuild()
              } else {
                let nodeController = this.nodeControllerMap.get(componentId);
                nodeController?.setBuilderNode(null)
                nodeController?.rebuild()
              }
            })
            .onNativeEmbedGestureEvent((touch) => {
              console.log("NativeEmbed onNativeEmbedGestureEvent" + JSON.stringify(touch.touchEvent));
              this.componentIdArr.forEach((componentId: string) => {
                let nodeController = this.nodeControllerMap.get(componentId);
                if (nodeController?.getEmbedId() === touch.embedId) {
                  let rootNode = nodeController?.getBuilderNode()
                  let ret = rootNode?.postTouchEvent(touch.touchEvent)
                  if (ret) {
                    console.log("onNativeEmbedGestureEvent success ", componentId);
                  } else {
                    console.log("onNativeEmbedGestureEvent fail ", componentId);
                  }
                }
              })
            })
        }
      }
    }
  }
}