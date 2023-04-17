var CryptoJS = require('crypto-js')

var xVersion = '5nFp9kmbNnHdAFhaqMvt'
var token = null
var accessToken = null

var files = '/files'
var api = '/api'

/*#ifdef APP-PLUS*/
files = 'https://files.iwara.tv'
api = 'https://api.iwara.tv'
/*#endif*/


/*#ifdef H5*/
files = '/files'
api = '/api'
/*#endif*/


/*#ifdef MP*/
files = 'https://files.iwara.tv'
api = 'https://api.iwara.tv'
/*#endif*/

function ajax(url, data, header, method, cb, num) {
	if (typeof (num) == 'undefined') {
		num = 0
	}
	console.log(url)
	console.log(data)
	console.log(header)
	console.log(method)
	uni.request({
		url: url,
		data: data,
		header: header,
		method: method,
		success: res => {
			console.log(res.data)
			console.log(res.statusCode)
			if (res.statusCode == 200) {
				cb(res.data, res.statusCode)
			} else if (res.statusCode == (403 || 429)) {
				// 403、429暴力重连
				if (num < 16) {
					num++
					ajax(url, data, header, method, (res, code) => {
						cb(res, code)
					}, num)
				} else {
					cb(res, code)
				}
			} else {
				cb(res.data, res.statusCode)
			}
		},
		fail: (res) => {
			console.log(res)
			cb(res, 408)
		}
	})
}

function parseGET(a) {
	if (a.indexOf('?') != -1) {
		a = a.slice(a.indexOf('?') + 1)
		let b = a.split('&')
		let c = {}
		for (let i = 0; i < b.length; i++) {
			let d = b[i].split('=')
			c[d[0]] = d[1]
		}
		return c
	} else {
		return null
	}
}

export function setStorage(key, data, expire) {
	if (typeof (expire) != 'undefined') {
		let d = new Date()
		uni.setStorage({
			key: key,
			data: data + '|' + (d.getTime() + expire).toString(),
		})
	} else {
		uni.setStorage({
			key: key,
			data: data,
		})
	}
}

export function getStorage(key, cb) {
	uni.getStorage({
		key: key,
		success: (res) => {
			if (res.data.indexOf('|') == -1) {
				cb(res.data)
			} else {
				console.log(res.data)
				let d = new Date()
				let expire = parseInt(res.data.slice(res.data.indexOf('|') + 1))
				if (d.getTime() > expire) {
					cb(null)
					uni.removeStorage({
						key: key
					})
				} else {
					cb(res.data.slice(0, res.data.indexOf('|')))
				}
			}
		},
		fail: () => {
			cb(null)
		}
	})
}

export function removeStorage(key, cb) {
	uni.removeStorage({
		key: key,
		success: function (res) {
			cb()
		}
	})
}

// 获取accessToken
export function getAccessToken(cb) {
	console.log('getAccessToken')
	getStorage('token', (res) => {
		if (res) {
			token = res
			let header = {
				authorization: 'Bearer ' + token
			}
			ajax(api + '/user/token', null, header, 'POST', (res, code) => {
				if (code == 200) {
					accessToken = res.accessToken
					cb()
				} else {
					cb()
				}
			})
		} else {
			token = null
			cb()
		}
	})
}

// 时间格式化
export function formatDate(t) {
	if (t) {
		let d = new Date
		let year = t.slice(0, 4)
		let month = t.slice(5, 7)
		let day = t.slice(8, 10)
		let hour = t.slice(11, 13)
		let minute = t.slice(14, 16)
		let second = t.slice(17, 19)
		return (year + '年' + month + '月' + day + '日' + ' ' + hour + ':' + minute + ':' + second)
	} else {
		return null
	}
}

// 填零
export function fill0(v, l) {
	let a = Math.pow(10, l)
	if (v < a) {
		let b = ''
		for (let i = 0; i < l; i++) {
			b = b + '0'
		}
		return b + v
	} else {
		return v
	}
}

// 登录
export function login(username, passwd, cb) {
	let data = {
		email: username,
		password: passwd
	}
	ajax(api + '/user/login', data, null, 'POST', (res, code) => {
		if (code == 200) {
			token = res.token
			setStorage('token', res.token, 24 * 3600 * 1000)
			getAccessToken(() => {
				cb(res, code)
			})
		} else {
			cb(res, code)
		}
	})
}

// 获取订阅列表
export function getSubscribeList(index, cb) {
	let data = {
		limit: 24,
		subscribed: true,
		page: index
	}
	let header
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
	} else {
		header = null
	}
	ajax(api + '/videos', data, header, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取视频列表
export function getVideoList(index, cb) {
	let data = {
		sort: 'date',
		rating: 'all',
		page: index
	}
	let header
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
	} else {
		header = null
	}
	ajax(api + '/videos', data, header, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取图片列表
export function getPictureList(index, cb) {
	let data = {
		sort: 'date',
		rating: 'all',
		page: index
	}
	let header
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
	} else {
		header = null
	}
	ajax(api + '/images', data, header, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取视频地址
export function getVideo(id, cb) {
	let header
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
	} else {
		header = null
	}
	let resData
	ajax(api + '/video/' + id, null, header, 'GET', (res, code) => {
		if (code == 200) {
			resData = {
				id: res.id,
				title: res.title,
				author: res.user.name,
				avatar: res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar
					.id + '/' + res.user
						.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
				synopsis: res.body,
				date: res.createdAt,
				numView: res.numViews,
				numLikes: res.numLikes,
				liked: res.liked,
				private: res.private,
				following: res.user.following,
			}
			if (res.file) {
				let fileUrlParse = parseGET(res.fileUrl)
				header = {
					'x-version': CryptoJS.SHA1(res.file.id + '_' + fileUrlParse.expires + '_' + xVersion).toString()
				}
				ajax(files + res.fileUrl.slice(22), null, header, 'GET', (res, code) => {
					resData.sources = []
					if (code == 200) {
						for (let i = 0; i < res.length; i++) {
							if (res[i].name != 'preview') {
								resData.sources.push({
									name: res[i].name,
									view: res[i].src.view,
									download: res[i].src.download
								})
							}
						}
					}
					cb(resData, code)
				})
			} else {
				cb(resData, 408)
			}
		} else {
			resData = null
			cb(resData, code)
		}
	})
}

// 获取图片地址
export function getPicture(id, cb) {
	let header
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
	} else {
		header = null
	}
	ajax(api + '/image/' + id, null, header, 'GET', (res, code) => {
		let resData = {
			title: res.title,
			body: res.body,
			author: res.user.name,
			createdAt: res.createdAt,
			numLikes: res.numLikes,
			numViews: res.numViews,
			following:res.user.following,
			avatar: res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar
				.id + '/' + res.user
					.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
			files: []
		}
		for (let i = 0; i < res.files.length; i++) {
			resData.files.push('https://i.iwara.tv/image/large/' + res.files[i].id + '/' + res.files[i].name)
		}
		cb(resData, code)
	})
}

// 获取详情页视频该作者视频列表
export function getVideoListForPlayInfoUser(id, uid, cb) {
	let data = {
		user: uid,
		exclude: id,
		limit: 6
	}
	ajax(api + '/videos', data, null, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取详情页相关作品视频列表
export function getVideoListForPlayInfoRelated(id, cb) {
	ajax(api + '/video/' + id + '/related', null, null, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取详情页评论
export function getVideoListForPlayInfoComments(id, page, cb) {
	let data = {
		page: page
	}
	let header = null
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
	}
	ajax(api + '/video/' + id + '/comments', data, header, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 添加评论
export function addComment(id, body, cb) {
	let header = {
		authorization: 'Bearer ' + accessToken
	}
	let data = {
		body: body
	}
	ajax(api + '/video/' + id + '/comments', data, header, 'POST', (res, code) => {
		cb(res, code)
	})
}

// 关注用户
export function followers(uid, opt, cb) {
	let header = {
		authorization: 'Bearer ' + accessToken
	}
	let method
	if (opt == 0) {
		method = 'DELETE'
	} else if (opt == 1) {
		method = 'POST'
	}
	ajax(api + '/user/' + uid + '/followers', null, header, method, (res, code) => {
		cb(res, code)
	})
}

// 获取本用户信息
export function getSelfData(cb) {
	let header = {
		authorization: 'Bearer ' + accessToken
	}
	ajax(api + '/user', null, header, 'GET', (res, code) => {
		cb(res, code)
	})
}
