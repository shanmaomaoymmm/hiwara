var CryptoJS = require('@/common/crypto-js-4.1.1/crypto-js.js')

var xVersion = '5nFp9kmbNnHdAFhaqMvt'
var token = null

getStorage('token', (res) => {
	if (res) {
		token = res
	} else {
		token = null
	}
})

function ajax(url, data, header, method, cb) {
	uni.request({
		url: url,
		data: data,
		header: header,
		method: method,
		success: res => {
			cb(res.data, res.statusCode)
		},
		fail: (res) => {
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
	if (typeof(expire) != 'undefined') {
		let d = new Date()
		uni.setStorage({
			key: key,
			data: data + '|' + (d + expire),
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
				let d = new Date()
				let expire = parseInt(res.data.slice(res.data.indexOf('|') + 1))
				if (d.getTime() > expire) {
					cb(null)
					uni.removeStorage({
						key: key
					})
				} else {
					cb(res.data)
				}
			}
		},
		fail: () => {
			cb(null)
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

// 登录
export function login(username, passwd, cb) {
	let data = {
		email: username,
		password: passwd
	}
	ajax('https://api.iwara.tv/user/login', data, null, 'POST', (res, code) => {
		if (code == 200) {
			token = res.token
			setStorage('token', res.token, 24 * 3600 * 1000)
		}
		cb(res, code)
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
	if (token) {
		header = {
			authorization: 'Bearer ' + token
		}
	} else {
		header = null
	}
	ajax('https://api.iwara.tv/videos', data, header, 'GET', (res, code) => {
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
	if (token) {
		header = {
			authorization: 'Bearer ' + token
		}
	} else {
		header = null
	}
	ajax('https://api.iwara.tv/videos', data, header, 'GET', (res, code) => {
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
	if (token) {
		header = {
			authorization: 'Bearer ' + token
		}
	} else {
		header = null
	}
	ajax('https://api.iwara.tv/images', data, header, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取视频地址
export function getVideo(id, cb) {
	let header
	if (token) {
		header = {
			authorization: 'Bearer ' + token
		}
	} else {
		header = null
	}
	let resData
	ajax('https://api.iwara.tv/video/' + id, null, header, 'GET', (res, code) => {
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
				ajax(res.fileUrl, null, header, 'GET', (res, code) => {
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

// 获取详情页视频该作者视频列表
export function getVideoListForPlayInfoUser(id, uid, cb) {
	let data = {
		user: uid,
		exclude: id,
		limit: 6
	}
	ajax('https://api.iwara.tv/videos', data, null, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取详情页相关作品视频列表
export function getVideoListForPlayInfoRelated(id, cb) {
	ajax('https://api.iwara.tv/video/' + id + '/related', null, null, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 获取详情页评论
export function getVideoListForPlayInfoComments(id, page, cb) {
	let data = {
		page: page
	}
	let header = null
	if (token) {
		header = {
			authorization: 'Bearer ' + token
		}
	}
	ajax('https://api.iwara.tv/video/' + id + '/comments', data, header, 'GET', (res, code) => {
		cb(res, code)
	})
}