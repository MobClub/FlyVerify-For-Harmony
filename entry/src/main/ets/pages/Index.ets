import { OperationCallback, FlyVerify, VerifyResult , VerifyException} from '@zztsdk/flyverify';
import { http } from '@kit.NetworkKit';
import { bundleManager, common } from '@kit.AbilityKit';
import { ZztSDK } from '@zztsdk/zztcore';
import { QueryPhoneBody } from './QueryPhoneBody';
import { ThemeChooser } from './ThemeChooser';

let context = getContext(this)
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
  async aboutToAppear() {
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
                return;
              }
              let callback: OperationCallback<void> = {
                onSuccess: () => {
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
                return;
              }
              FlyVerify.preVerifySync().then((data)=>{
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
                return;
              }
              let theme = ThemeChooser.theme
              FlyVerify.setTheme(theme)
              FlyVerify.verifySync().then((data)=>{
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
      }
    }
    .width('100%')
  }


}

@Builder
export function authPageComponent(): void {
  Column() {
    Text('自定义布局')
      .fontSize(40)
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: '__container__', align: VerticalAlign.Top },

      })

    Button('自定义按钮')
      .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      top: { anchor: '__container__', align: VerticalAlign.Top },

    }).margin({top:'150%'}).onClick(()=>{
      console.log("FlyVerify","custom click")
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


