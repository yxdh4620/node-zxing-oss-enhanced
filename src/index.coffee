require 'shelljs/global'
_ = require 'underscore'
debuglog = require("debug")("zxing-oss-enhanced")
path = require 'path'
ossEasy = require "oss-easy"
url = require 'url'
assert = require "assert"

IS_JAVA_INSTALLED = which('java')

START_AT = Date.now().toString(36)

ZXIN_PATH = path.join(__dirname, "..", "zxing")

JAR_SET_PATH = "#{path.join(ZXIN_PATH, 'javase-3.3.0.jar')}:#{path.join(ZXIN_PATH, 'jcommander-1.27.jar')}:#{path.join(ZXIN_PATH, 'core-3.3.0.jar')}"

JAR_ENTRY_POINT = "com.google.zxing.client.j2se.CommandLineRunner"

#java -cp ./javase-3.3.0.jar:./jcommander-1.27.jar:core-3.3.0.jar com.google.zxing.client.j2se.CommandLineRunner http://asset-image.weixinzhongxin.com/temp_img_resize/2.pic_hd.jpg@300w_90q_100d.jpg

OssClint = null

OSS_BUKET_PATH = ''
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
    bucket : options.ossBucket

  OssClint = new ossEasy(ossOptions)

  OSS_BUKET_PATH = options.ossPath
  HTTP_PREFIX = options.httpPrefix

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


decode = (uri, callback)->
  unless _.isFunction(callback)
    debuglog '[decode] callback isnt a function. cancel'
    return

  unless IS_JAVA_INSTALLED
    callback 'java is not installed'
    return

  uri = String(uri || '').trim()
  unless uri
    callback "invalid uri:#{uri}"
    return
  #parsedUri = url.parse(uri)
  #unless (parsedUri.protocol is 'http:') or (parsedUri.protocol is 'https:')
    #callback "invalid uri:#{uri} / #{parsedUri.protocol}. please supply http or https uri"
    #return

  cmd = "java -cp #{JAR_SET_PATH} #{JAR_ENTRY_POINT} #{uri}"
  debuglog "[decode] cmd to be exec:#{cmd}"

  exec cmd, {silent:true}, (code, stdout, stderr)->
    debuglog "[parse result] code:#{code}, stdout:#{stdout}, stderr:#{stderr}"
    if code
      errorCache = "ERROR: code:#{code}, err:#{stderr}"
    else
      qrcode = readResultFromStdout stdout

    #errorCache = "No barcode found. stdout:#{stdout}" unless qrcode
    #callback errorCache, qrcode
    return callback(errorCache) if errorCache?  # something wrong
    return callback(null, qrcode) if qrcode?  # found qrcode

    unless OssClint?
      # OSS 客户端没有初始化，所以无法进行下一步尝试
      debuglog "no oss client inited. cancel attemps"
      return callback()

    debuglog "TRY OSS IMG OPTMIZATION"
    filename = generateRandomFilename() + path.extname(uri)
    remoteFilePath = path.join(OSS_BUKET_PATH, filename)

    OssClint.uploadFile uri, remoteFilePath, (err)->
      return callback(err) if err?

      optimizedImgUrl =  HTTP_PREFIX + path.join(OSS_BUKET_PATH, "#{filename}#{ALI_IMG_CMD}")
      cmd = "java -cp #{JAR_SET_PATH} #{JAR_ENTRY_POINT} #{optimizedImgUrl} --try_harder"
      debuglog "[decode] attemp 2 cmd to be exec:#{cmd}"

      exec cmd, {silent:true}, (code, stdout, stderr)->
        debuglog "[parse result] attemp 2 code:#{code}, stdout:#{stdout}, stderr:#{stderr}"
        if code
          errorCache = "ERROR: code:#{code}, err:#{stderr}"
        else
          qrcode = readResultFromStdout stdout

        callback errorCache, qrcode
    return
  return


module.exports =
  init : init
  decode : decode




