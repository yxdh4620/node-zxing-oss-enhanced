require 'shelljs/global'
_ = require 'underscore'
debuglog = require("debug")("zxing-oss-enhanced")
path = require 'path'
#oss = require('ali-oss').oss
oss = require('aliyun-oss')
url = require 'url'
assert = require "assert"

IS_JAVA_INSTALLED = which('java')

START_AT = Date.now().toString(36)

ZXIN_PATH = path.join(__dirname, "..", "zxing")

JAR_SET_PATH = "#{path.join(ZXIN_PATH, 'javase-3.3.0.jar')}:#{path.join(ZXIN_PATH, 'jcommander-1.27.jar')}:#{path.join(ZXIN_PATH, 'core-3.3.0.jar')}"

JAR_ENTRY_POINT = "com.google.zxing.client.j2se.CommandLineRunner"



#java -cp ./javase-3.3.0.jar:./jcommander-1.27.jar:core-3.3.0.jar com.google.zxing.client.j2se.CommandLineRunner http://asset-image.weixinzhongxin.com/temp_img_resize/2.pic_hd.jpg@300w_90q_100d.jpg

OssClient = null

OSS_BUCKET = ""
HTTP_PREFIX = ''
ALI_IMG_CMD = "@500w_800h_100d.png"

init = (options)->
  assert options, "missing options"
  assert options.ossKey, "missing options.ossKey"
  assert options.ossSecret, "missing options.ossSecret"
  assert options.ossBucket , "missing options.ossBucket "
  assert options.ossPath, "missing options.ossPath"
  assert options.httpPrefix, "missing options.httpPrefix"
  ossOptions =
    accessKeyId : options.ossKey
    accessKeySecret : options.ossSecret
    #bucket : options.ossBucket
    #region: options.ossRegion || 'oss-cn-hangzhou'
    host: options.ossRegion || 'oss-cn-hangzhou.aliyuncs.com'
  OssClient = oss.createClient(ossOptions)

  OSS_BUCKET = options.ossBucket
  HTTP_PREFIX = options.httpPrefix
  ALI_IMG_CMD = options.aliImgCmd

  debuglog 'init ok'
  return

Cnt = 0

generateRandomFilename = (basename)-> return "#{Date.now().toString(36)}_#{START_AT}_#{++Cnt}#{basename || ''}"

readResultFromStdout = (stdout)->
  lines = stdout.split("\n")
  for line, i in lines
    if line.indexOf('Raw result:') >= 0
      return lines[i + 1]
  return

decode = (stream, options = {}, callback) ->
  unless _.isFunction(callback)
    debuglog '[decode] callback isnt a function. cancel'
    return
  unless IS_JAVA_INSTALLED
    callback 'java is not installed'
    return
  unless stream? and Buffer.isBuffer(stream)
    callback "invalid uri:#{uri}"
    return
  #ref = OssClint.put 'filepath', stream
  opt =
    bucket: options.bucket || OSS_BUCKET
    object: "#{options.object}"
    source: stream
  OssClient.putObject opt, (err, ref) ->
    return callback(err) if err?
    filepath = "#{filepath}#{ALI_IMG_CMD}"
    uri = "#{HTTP_PREFIX}#{options.object}"
    cmd = "java -cp #{JAR_SET_PATH} #{JAR_ENTRY_POINT} #{uri} --try_harder"
    debuglog "[decode] cmd to be exec:#{cmd}"
    exec cmd, {silent:true}, (code, stdout, stderr)->
      debuglog "[parse result] attemp 2 code:#{code}, stdout:#{stdout}, stderr:#{stderr}"
      if code
        errorCache = "ERROR: code:#{code}, err:#{stderr}"
      else
        qrcode = readResultFromStdout stdout
      callback errorCache, qrcode

copy = (options={}, callback) ->
  opt =
    sourceBucket: options.sourceBucket || OSS_BUCKET
    sourceObject: options.sourceObject
    bucket: options.bucket||OSS_BUCKET
    object: options.object
  OssClient.copyObject opt, (err, res) ->
    callback err, res


module.exports =
  init : init
  decode : decode
  copy: copy



