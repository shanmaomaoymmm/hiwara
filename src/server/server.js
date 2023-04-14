var https = require('https')
var http = require('http')
var url = require('url');
var fs = require('fs')

// let options = {
//   hostname: 'api.iwara.tv',
//   // hostname: 'ro.qisato.com',
//   path: '/videos?sort=date&rating=all',
//   // path: '/',
//   method: 'GET',
//   port: 443,
//   headers: {
//     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/111.0',
//     'Accept': 'application/json',
//     'Referer': 'https://www.baidu.com',
//     'Origin': 'https://www.baidu.com',
//   }
// }
// let data = ''
// const req = https.request(options, (res) => {
//   res.setEncoding('utf-8')
//   res.on('data', (chuck) => {
//     data += chuck
//   })
//   res.on('end', () => {
//     console.log(data)
//   })
// })
// req.on('error', (e) => {
//   console.error(e);
// })
// req.end()

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain;charset=utf8' })
  let params = url.parse(req.url, true);
  console.log(params.query)
  res.write('hello')
  res.end()
}).listen(2333)