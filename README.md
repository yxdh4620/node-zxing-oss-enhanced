# node-zxing-oss-enhanced
ZXing qrcode image reader with aliyun oss color tuning enhanced

在zxing 解析二维码图片失败之后，借用阿里云OSS的图像处理功能再试一下。


## Install

```
npm install zxing-oss-enhanced
```

## How to use

### 打开OSS的识别支持

要打开OSS的识别支持，需要初始化这个模块，提供OSS参数如下：

注意：初始化只需要执行一次就好了，用不着反复执行

```coffeescript
# coffeescript
zxing = require 'zxing-oss-enhanced'

zxing.init
  ossKey : "XXXXXXXX"
  ossSecret : "XXXXXXXXXX"
  ossBucket : "your-bucket"
  ossPath : "path-in-your-bucket"
```

### 识别图片


```coffeescript
zxing = require 'zxing-oss-enhanced'

zxing.decode url, (err, result)-> console.log "err:#{err}, result:#{result}"
```

#### 3 种可能的识别结果

 1. `err=null, result!=null` 这种情况是识别成功了。reslt 就是读出来的二维码内容
 1. `err=null, result=null` 这种情况是提供的图片不是二维码
 1. `err!=null, result=null` 这种情况是识别过程中遇到异常


