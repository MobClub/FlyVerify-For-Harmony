import { OperationCallback, FlyVerify, VerifyResult , VerifyException} from '@zztsdk/flyverify';
import { http } from '@kit.NetworkKit';
import { bundleManager, common } from '@kit.AbilityKit';
import {ZztSDK } from '@zztsdk/zztcore';
import { QueryPhoneBody } from './QueryPhoneBody';
import { ThemeChooser } from './ThemeChooser';
import window from '@ohos.window';

let context = getContext(this)
const statusBarType = window.AvoidAreaType.TYPE_SYSTEM;
const navBarType = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;

interface AvoidArea {
  topRectHeight: number
  bottomRectHeight: number
}
@Entry
@Component
struct Index {
  @State content: string = "结果:"
  result: VerifyResult | null = null;
  appkey = "3a2c2a977d3d2";
  secret = "b89d2427a3bc7ad1aea1e1e8c1d36bf3";
  isInited = false;
  scroller: Scroller = new Scroller()
  chooserController?: CustomDialogController
  isFullScreen = false
  private windowClass = (context as common.UIAbilityContext).windowStage.getMainWindowSync();
  @State avoidArea: AvoidArea = { topRectHeight: 0, bottomRectHeight: 0 };

  async aboutToAppear() {
    this.setAvoidArea()
    this.windowClass.on('avoidAreaChange', this.onAvoidAreaChange)
    this.isFullScreen = this.windowClass.getWindowProperties().isLayoutFullScreen;//获取是否为沉浸式
    console.log('FlyVerify', 'isFullscreen = ' + this.isFullScreen)
  }

  setAvoidArea() {
    // status bar area
    const statusBarArea = this.windowClass.getWindowAvoidArea(statusBarType);
    this.avoidArea.topRectHeight = statusBarArea.topRect.height;
    // navigation bar area
    const navBarArea = this.windowClass.getWindowAvoidArea(navBarType);
    this.avoidArea.bottomRectHeight = navBarArea.bottomRect.height;
  }

  onAvoidAreaChange = (data: window.AvoidAreaOptions) => {
    if (data.type === statusBarType) {
      this.avoidArea.topRectHeight = data.area.topRect.height;
    } else if (data.type === navBarType) {
      this.avoidArea.bottomRectHeight = data.area.bottomRect.height;
    }
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        Text("FlyVerify DEMO")
          .width('100%')
          .margin(10)
          .align(Alignment.Center)
          .textAlign(TextAlign.Center)
        Button("初始化（每次启动必须调用）")
          .width('90%')
          .margin(10)
          .padding(15)
          .onClick(() => {
            ZztSDK.init(context, this.appkey, this.secret);
            this.content = "调用ZztSDK.init()"
            this.isInited = true;
            FlyVerify.setPreVerifyTimeout(8000);
          })
        Row(){
          Button("同意隐私")
            .width('45%')
            .margin(5)
            .padding(15)
            .onClick(() => {
              ZztSDK.submitPolicyGrantResult(true);
              this.content = "隐私状态isForb: " +ZztSDK.isForb()
            })
          Button("不同意隐私")
            .width('45%')
            .margin(5)
            .padding(15)
            .onClick(() => {
              ZztSDK.submitPolicyGrantResult(false);
              this.content = "隐私状态isForb: " +ZztSDK.isForb()
            })
        }

        Row(){
          Button("预取号")
            .width('45%')
            .margin(5)
            .padding(15)
            .onClick(() => {
              if(!this.isInited){
                this.content = "请先初始化！"
                return;
              }
              let callback: OperationCallback<void> = {
                onSuccess: (data) => {
                  this.content = new Date() + " onSuccess"
                },
                onFailure: (e) => {
                  this.content = new Date() + " onFailure:" + JSON.stringify(e)
                }
              };
              FlyVerify.preVerify(callback);
              console.log("FlyVerify", "preVerify invoked")
            })
          Button("预取号promise")
            .width('45%')
            .margin(5)
            .padding(15)
            .onClick(() => {
              if(!this.isInited){
                this.content = "请先初始化！"
                return;
              }
              FlyVerify.preVerify().then((data)=>{
                this.content = new Date() + " onSuccess"
              }).catch((e:VerifyException)=>{
                this.content = new Date() + " onFailure:" + JSON.stringify(e)
              })
              console.log("FlyVerify", "preVerify invoked")
            })
        }
        Row(){
          Button("取号")
            .width('30%')
            .margin(5)
            .padding(15)
            .onClick(() => {
              if(!this.isInited){
                this.content = "请先初始化！"
                return;
              }
              let callback: OperationCallback<VerifyResult> = {
                onSuccess: (data) => {
                  this.content = new Date() + " onSuccess:" + JSON.stringify(data)
                  this.result = data;
                },
                onFailure: (error) => {
                  this.content = new Date() + " onFailure:" + JSON.stringify(error)
                }
              };
              let theme = ThemeChooser.theme
              FlyVerify.setTheme(theme)
              FlyVerify.verify(callback);
              console.log("FlyVerify", "verify invoked")
            })
          Button("取号promise")
            .width('30%')
            .margin(5)
            .padding(15)
            .onClick(() => {
              if(!this.isInited){
                this.content = "请先初始化！"
                return;
              }
              let theme = ThemeChooser.theme
              FlyVerify.setTheme(theme)
              FlyVerify.verify().then((data)=>{
                this.content = new Date() + " onSuccess:" + JSON.stringify(data)
                this.result = data;
              }).catch((e:VerifyResult)=>{
                this.content = new Date() + " onFailure:" + JSON.stringify(e)
              });
              console.log("FlyVerify", "verify invoked")
            })
          Button("设置主题")
              .width('30%')
              .margin(5)
              .padding(15)
              .onClick(() => {
                this.chooserController = new CustomDialogController({
                  builder: ThemeChooser({
                    controller: this.chooserController
                  }),
                  cornerRadius: 0,
                  alignment: DialogAlignment.Center,
                })
                this.chooserController.open()
              })

          }

        TextInput({placeholder:'请输入预取号超时时间ms'})
          .width('90%')
          .margin(10)
          .padding(15)
          .type(InputType.Number)
          .onChange(value=>{
            if(!this.isInited){
              this.content = "请先初始化！"
              return;
            }
            let timeout = Number.parseInt(value);
            console.log("FlyVerify", "timeout = " +timeout);
            FlyVerify.setPreVerifyTimeout(timeout);

          })
        Button("登录")
          .width('90%')
          .margin(10)
          .padding(15)
          .onClick(async () => {
            if(!this.isInited){
              this.content = "请先初始化！"
              return;
            }
            if (this.result === null) {
              this.content = "请先取号！";
              return;
            }
            let URL_LOGIN = "http://demo.accuratead.cn/demo/sdkLogin";
            let bundleInfo: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
            let sign:string = bundleInfo.signatureInfo.fingerprint;
            sign = sign.toLowerCase()
            let body = new QueryPhoneBody()
            body.opToken = this.result.opToken
            body.operator = this.result.operator
            body.phoneOperator = this.result.operator
            body.token = this.result.token
            body.md5 = sign
            body.appkey = this.appkey
            let json = JSON.stringify(body)
            console.log("FlyVerify", "request:"+json)
            try {
              let data = await http.createHttp().request(URL_LOGIN, {
                method: http.RequestMethod.POST,
                extraData: json,
                header: {
                  "Content-Type": "application/json"
                }
              });
              this.content = new Date() + JSON.stringify(data.result);
              console.log('FlyVerify', this.content)
            } catch (e) {
              this.content = new Date() + JSON.stringify(e);
              console.log('FlyVerify', this.content)
            }
          })

        Text(this.content)
          .fontSize(20)
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Bold)
          .margin(10)
          .width('90%')
      }.padding({
        top: this.isFullScreen?this.avoidArea.topRectHeight + 'px':'0',
        bottom: this.isFullScreen?this.avoidArea.bottomRectHeight + 'px':'0'
      })
    }
    .width('100%')
  }

}

@Builder
function authPageComponent(): void {
  Column() {
    RelativeContainer(){
      Marquee({
        start: true,
        step: 5,
        loop: -1,
        fromStart: true,
        src:'  调用FlyVerify.closeAuthLoginPage()关闭'
      })
        .fontSize(20)
        .width(120)
        .alignRules({
          left: { anchor: '__container__', align: HorizontalAlign.Start},
        }).onClick(()=>{
        FlyVerify.closeAuthLoginPage()
      })
      Text('自定义布局')
        .fontSize(20)
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center }

        })
    }
    .width('100%')
    .height('40%')
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
    })


    Button('自定义按钮')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: '__container__', align: VerticalAlign.Top },

      })
      .width('60%')
      .height('40%')
      .margin({top:'150%'}).onClick(()=>{
      // showToast("click")
    })
  }.width('100%')
  .height('100%')
  .alignRules({
    top: { anchor: '__container__', align: VerticalAlign.Top },
    bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
    left:{ anchor: '__container__', align: HorizontalAlign.Start }
  })
  .id("111")
}

