require 'shelljs/global'
_ = require 'underscore'
debuglog = require("debug")("zxing-oss-enhanced")
path = require 'path'
url = require 'url'

IS_JAVA_INSTALLED = which('java')


ZXIN_PATH = path.join(__dirname, "..", "zxing")

JAR_SET_PATH = "#{path.join(ZXIN_PATH, 'javase-3.3.0.jar')}:#{path.join(ZXIN_PATH, 'jcommander-1.27.jar')}:#{path.join(ZXIN_PATH, 'core-3.3.0.jar')}"

JAR_ENTRY_POINT = "com.google.zxing.client.j2se.CommandLineRunner"

#java -cp ./javase-3.3.0.jar:./jcommander-1.27.jar:core-3.3.0.jar com.google.zxing.client.j2se.CommandLineRunner http://asset-image.weixinzhongxin.com/temp_img_resize/2.pic_hd.jpg@300w_90q_100d.jpg

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

  uri = String(uri || '')
  parsedUri = url.parse(uri)
  unless (parsedUri.protocol is 'http:') or (parsedUri.protocol is 'https:')
    callback "invalid uri:#{uri} / #{parsedUri.protocol}. please supply http or https uri"
    return

  cmd = "java -cp #{JAR_SET_PATH} #{JAR_ENTRY_POINT} #{uri}"
  debuglog "[decode] cmd to be exec:#{cmd}"

  exec cmd, (code, stdout, stderr)->
    debuglog "[parse result] code:#{code}, stdout:#{stdout}, stderr:#{stderr}"
    if code
      errorCache = "ERROR: code:#{code}, err:#{stderr}"
    else
      qrcode = readResultFromStdout stdout

    #errorCache = "No barcode found. stdout:#{stdout}" unless qrcode
    callback errorCache, qrcode
    return
  return


module.exports =
  decode : decode




