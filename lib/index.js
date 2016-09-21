// Generated by CoffeeScript 1.8.0
var IS_JAVA_INSTALLED, JAR_ENTRY_POINT, JAR_SET_PATH, ZXIN_PATH, debuglog, decode, path, readResultFromStdout, url, _;

require('shelljs/global');

_ = require('underscore');

debuglog = require("debug")("zxing-oss-enhanced");

path = require('path');

url = require('url');

IS_JAVA_INSTALLED = which('java');

ZXIN_PATH = path.join(__dirname, "..", "zxing");

JAR_SET_PATH = "" + (path.join(ZXIN_PATH, 'javase-3.3.0.jar')) + ":" + (path.join(ZXIN_PATH, 'jcommander-1.27.jar')) + ":" + (path.join(ZXIN_PATH, 'core-3.3.0.jar'));

JAR_ENTRY_POINT = "com.google.zxing.client.j2se.CommandLineRunner";

readResultFromStdout = function(stdout) {
  var i, line, lines, _i, _len;
  lines = stdout.split("\n");
  for (i = _i = 0, _len = lines.length; _i < _len; i = ++_i) {
    line = lines[i];
    if (line.indexOf('Raw result:') >= 0) {
      return lines[i + 1];
    }
  }
};

decode = function(uri, callback) {
  var cmd, parsedUri;
  if (!_.isFunction(callback)) {
    debuglog('[decode] callback isnt a function. cancel');
    return;
  }
  if (!IS_JAVA_INSTALLED) {
    callback('java is not installed');
    return;
  }
  uri = String(uri || '');
  parsedUri = url.parse(uri);
  if (!((parsedUri.protocol === 'http:') || (parsedUri.protocol === 'https:'))) {
    callback("invalid uri:" + uri + " / " + parsedUri.protocol + ". please supply http or https uri");
    return;
  }
  cmd = "java -cp " + JAR_SET_PATH + " " + JAR_ENTRY_POINT + " " + uri;
  debuglog("[decode] cmd to be exec:" + cmd);
  exec(cmd, function(code, stdout, stderr) {
    var errorCache, qrcode;
    debuglog("[parse result] code:" + code + ", stdout:" + stdout + ", stderr:" + stderr);
    if (code) {
      errorCache = "ERROR: code:" + code + ", err:" + stderr;
    } else {
      qrcode = readResultFromStdout(stdout);
    }
    callback(errorCache, qrcode);
  });
};

module.exports = {
  decode: decode
};