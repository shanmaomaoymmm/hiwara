import i18n from '@/locale/index.js'
var CryptoJS = require('crypto-js')

var xVersion = '5nFp9kmbNnHdAFhaqMvt'
var token = null
var accessToken = null
var retry = 16

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

/**API */
function ajax(url, data, header, method, cb, num) {
	if (typeof (num) == 'undefined') {
		num = 0
	}
	uni.request({
		url: url,
		data: data,
		header: header,
		method: method,
		success: res => {
			if (res.statusCode == 200) {
				cb(res.data, res.statusCode)
			} else if (res.statusCode == 403 || res.statusCode == 429 || res.statusCode == 500) {
				// 403、429暴力重连
				if (num < retry) {
					num++
					ajax(url, data, header, method, (res, code) => {
						cb(res, code)
					}, num)
				} else {
					cb(res.data, res.statusCode)
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

// 重连次数
getStorage('retry', (a) => {
	if (a) {
		retry = a
	} else {
		retry = 16
	}
})

export function getStorage(key, cb) {
	uni.getStorage({
		key: key,
		success: (res) => {
			if (typeof (res.data) == 'string') {
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
						cb(res.data.slice(0, res.data.indexOf('|')))
					}
				}
			} else {
				cb(res.data)
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
	getStorage('token', (res) => {
		if (res) {
			token = res
			let header = {
				authorization: 'Bearer ' + token
			}
			ajax(api + '/user/token', null, header, 'POST', (res, code) => {
				if (code == 200) {
					accessToken = res.accessToken
					cb(true)
				} else {
					cb(false)
				}
			})
		} else {
			token = null
			cb(false)
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
		return (year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second)
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
export function getSubscribeList(type, index, cb) {
	let data = {
		limit: 24,
		subscribed: true,
		page: index
	}
	creatHeader((h) => {
		if (type == 'video') {
			ajax(api + '/videos', data, h, 'GET', (res, code) => {
				cb(res, code)
			})
		} else if (type == 'image')
			ajax(api + '/images', data, h, 'GET', (res, code) => {
				cb(res, code)
			})
	})
}

// 获取视频列表
export function getVideoList(sort, index, date, cb) {
	let data = {
		sort: sort,
		rating: 'all',
		page: index,
		date: date,
		limit: 24
	}
	creatHeader((h) => {
		ajax(api + '/videos', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取图片列表
export function getImageList(index, cb) {
	let data = {
		sort: 'date',
		rating: 'all',
		page: index,
		limit: 24,
	}
	creatHeader((h) => {
		ajax(api + '/images', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取视频地址
export function getVideo(id, cb) {
	let resData
	creatHeader((h) => {
		ajax(api + '/video/' + id, null, h, 'GET', (res, code) => {
			if (code == 200) {
				resData = {
					id: res.id,
					title: res.title,
					author: res.user.name,
					avatar: res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar.id + '/' + res.user.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
					preview: res.file != null ? "https://i.iwara.tv/image/thumbnail/" + res.file.id + "/thumbnail-" + fill0(res.thumbnail, 1) + ".jpg" : null,
					synopsis: res.body,
					date: res.createdAt,
					numView: res.numViews,
					numLikes: res.numLikes,
					liked: res.liked,
					private: res.private,
					following: res.user.following,
					username: res.user.username
				}
				if (res.file) {
					let fileUrlParse = parseGET(res.fileUrl)
					let header = {
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
				// #ifdef APP-PLUS
				// 记录
				let d = new Date()
				addDataForDB('history', [
					res.id,
					res.user.id,
					res.title,
					res.user.name,
					res.createdAt,
					res.file != null ? "https://i.iwara.tv/image/thumbnail/" + res.file.id + "/thumbnail-" + fill0(res.thumbnail, 1) + ".jpg" : null,
					res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar.id + '/' + res.user.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
					'video',
					d.getTime()
				])
				if (res.user.following) {
					addDataForDB('following', [
						res.user.id,
						res.user.username,
						res.user.name,
						res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar.id + '/' + res.user.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
						d.getTime()
					])
				}
				// #endif
			} else {
				resData = null
				cb(resData, code)
			}
		})
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

// 获取视频详情页评论
export function getVideoListForPlayInfoComments(id, page, cb) {
	let data = {
		page: page
	}
	creatHeader((h) => {
		ajax(api + '/video/' + id + '/comments', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 添加视频评论
export function addCommentForVideo(id, body, cb) {
	let data = {
		body: body
	}
	creatHeader((h) => {
		ajax(api + '/video/' + id + '/comments', data, h, 'POST', (res, code) => {
			cb(res, code)
		})
	})
}

// 点赞视频
export function likeVideo(id, opt, cb) {
	let method
	if (opt == 0) {
		method = 'DELETE'
	} else if (opt == 1) {
		method = 'POST'
	}
	creatHeader((h) => {
		ajax(api + '/video/' + id + '/like', null, h, method, (res, code) => {
			cb(res, code)
		})
	})
}

// 关注用户
export function followers(uid, opt, cb) {
	let method
	if (opt == 0) {
		method = 'DELETE'
	} else if (opt == 1) {
		method = 'POST'
	}
	creatHeader((h) => {
		ajax(api + '/user/' + uid + '/followers', null, h, method, (res, code) => {
			cb(res, code)
		})
	})
}

// 加好友
export function friends(uid, opt, cb) {
	let method
	if (opt == 0) {
		method = 'DELETE'
	} else if (opt == 1) {
		method = 'POST'
	}
	creatHeader((h) => {
		ajax(api + '/user/' + uid + '/friends', null, h, method, (res, code) => {
			cb(res, code)
		})
	})
}

// 获取本用户信息
export function getSelfData(cb) {
	creatHeader((h) => {
		ajax(api + '/user', null, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取图片
export function getImage(id, cb) {
	creatHeader((h) => {
		ajax(api + '/image/' + id, null, h, 'GET', (res, code) => {
			let resData = {
				title: res.title,
				body: res.body,
				author: res.user.name,
				createdAt: res.createdAt,
				numLikes: res.numLikes,
				numViews: res.numViews,
				following: res.user.following,
				avatar: res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar.id + '/' + res.user.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
				files: [],
				username: res.user.username,
				liked: res.liked
			}
			for (let i = 0; i < res.files.length; i++) {
				resData.files.push('https://i.iwara.tv/image/large/' + res.files[i].id + '/' + res.files[i].name)
			}
			cb(resData, code)
			// #ifdef APP-PLUS
			// 记录
			let d = new Date()
			addDataForDB('history', [
				res.id,
				res.user.id,
				res.title,
				res.user.name,
				res.createdAt,
				res.thumbnail != null ? "https://i.iwara.tv/image/thumbnail/" + rs.thumbnail.id + "/" + rs.thumbnail.name : null,
				'image',
				d.getTime()
			])
			if (res.user.following) {
				addDataForDB('following', [
					res.user.id,
					res.user.username,
					res.user.name,
					res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar.id + '/' + res.user.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
					d.getTime()
				])
			}
			// #endif
		})
	})
}

// 获取图片详情页评论
export function getImageInfoComments(id, page, cb) {
	let data = {
		page: page
	}
	creatHeader((h) => {
		ajax(api + '/image/' + id + '/comments', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 添加图片评论
export function addCommentForImage(id, body, cb) {
	let data = {
		body: body
	}
	creatHeader((h) => {
		ajax(api + '/image/' + id + '/comments', data, h, 'POST', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取详情页图片该作者图片列表
export function getImageListForImageInfoUser(id, uid, cb) {
	let data = {
		user: uid,
		exclude: id,
		limit: 6
	}
	creatHeader((h) => {
		ajax(api + '/images', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取详情页相关作品图片列表
export function getImageListForImageInfoRelated(id, cb) {
	ajax(api + '/image/' + id + '/related', null, null, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 点赞图片
export function likeImage(id, opt, cb) {
	let method
	if (opt == 0) {
		method = 'DELETE'
	} else if (opt == 1) {
		method = 'POST'
	}
	creatHeader((h) => {
		ajax(api + '/image/' + id + '/like', null, h, method, (res, code) => {
			cb(res, code)
		})
	})
}

// 获取用户信息
export function getpProfile(username, cb) {
	creatHeader((h) => {
		ajax(api + '/profile/' + username, null, h, 'GET', (res, code) => {
			let resData = {
				name: res.user.name,
				body: res.body,
				createdAt: res.user.createdAt,
				seenAt: res.user.seenAt,
				avatar: res.user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.user.avatar
					.id + '/' + res.user
						.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
				background: res.header ? 'https://i.iwara.tv/image/profileHeader/' + res.header.id + '/' + res.header.name : '/static/img/loli.png',
				following: res.user.following,
				friend: res.user.friend
			}
			cb(resData, code)
		})
	})
}

// 获取用户视频列表
export function getVideoListForUser(index, uid, cb) {
	let data = {
		sort: 'date',
		page: index,
		user: uid,
		limit: 24,
	}
	creatHeader((h) => {
		ajax(api + '/videos', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取用户图片列表
export function getImageListForUser(index, uid, cb) {
	let data = {
		sort: 'date',
		page: index,
		user: uid,
		limit: 24,
	}
	creatHeader((h) => {
		ajax(api + '/images', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取我喜欢的视频
export function getFavoritesVideos(page, cb) {
	let data = {
		page: page
	}
	creatHeader((h) => {
		ajax(api + '/favorites/videos', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 获取我喜欢的图片
export function getFavoritesImages(page, cb) {
	let data = {
		page: page
	}
	creatHeader((h) => {
		ajax(api + '/favorites/images', data, h, 'GET', (res, code) => {
			cb(res, code)
		})
	})
}

// 生成Header
function creatHeader(cb) {
	let header
	if (accessToken) {
		header = {
			authorization: 'Bearer ' + accessToken
		}
		cb(header)
	} else {
		getAccessToken((res) => {
			if (res) {
				header = {
					authorization: 'Bearer ' + accessToken
				}
				cb(header)
			} else {
				cb(null)
			}
		})
	}
}

// 搜索
export function search(type, query, page, cb) {
	let data = {
		type: type,
		query: query,
		page: page,
		limit: 24,
	}
	ajax(api + '/search', data, null, 'GET', (res, code) => {
		cb(res, code)
	})
}

// 下载
export function download(type, url, name, cb) {
	plus.nativeUI.toast(i18n.t('download.downloadStart'))
	uni.createPushMessage({
		content: i18n.t('download.downloadStart') + ': ' + name
	})
	let path
	let exte
	if (type == 'video') {
		path = '/Movies/iwara/'
		exte = '.mp4'
	} else if (type = 'image') {
		path = '/Pictures/iwara/'
		exte = '.jpg'
	} else {
		path = '/Download/iwara/'
		exte = '.dat'
	}
	let dtask = plus.downloader.createDownload(url, {
		filename: 'file://storage/emulated/0' + path + name + exte //利用保存路径，实现下载文件的重命名
	}, (d, status) => {
		//d为下载的文件对象
		if (status == 200) {
			uni.createPushMessage({
				content: i18n.t('download.downloadSuccess') + path + name + exte
			})
			plus.nativeUI.toast(i18n.t('download.downloadSuccess') + path + name + exte)
		}
		if (status != 200) {
			//下载失败
			console.log('失败')
			dtask.abort() //清除下载任务
			uni.createPushMessage({
				content: i18n.t('download.downloadFail') + ': ' + name
			})
		}
	})
	dtask.start()
	cb()
}

// 存储权限
export function storagePermission() {
	let Build = plus.android.importClass("android.os.Build")
	let Manifest = plus.android.importClass("android.Manifest")
	let MainActivity = plus.android.runtimeMainActivity()
	let ArrPermissions = [
		Manifest.permission.READ_EXTERNAL_STORAGE,
		Manifest.permission.WRITE_EXTERNAL_STORAGE
	];
	// 检查每一个权限
	function PermissionCheck(permission) {
		if (Build.VERSION.SDK_INT >= 23) {
			if (MainActivity.checkSelfPermission(permission) == -1) {
				return false;
			}
		}
		return true;
	}
	// 申请权限
	function PermissionRequest(Arr) {
		let REQUEST_CODE_CONTACT = 101;
		if (Build.VERSION.SDK_INT >= 23) {
			MainActivity.requestPermissions(Arr, REQUEST_CODE_CONTACT)
		}
	}
	function PermissionChecks(Arr) {
		let HasPermission = true;
		for (let index in Arr) {
			let permission = Arr[index];
			// 如果此处没有权限,则是用户拒绝了  
			if (!PermissionCheck(permission)) {
				HasPermission = false;
				break;
			}
		}
		return HasPermission;
	}
	// 如果没有权限，则申请  
	if (!PermissionChecks(ArrPermissions)) {
		// 申请权限，下次再试
		PermissionRequest(ArrPermissions);
		return false
	} else {
		// 拥有权限
		return true
	}
}

// 获取关注
export function getFollowing(cb) {
	enquiryDBTable('following', 0, (res) => {
		cb(res)
	})
}

// 历史记录
export function getHistory(cb) {
	enquiryDBTable('history', 0, (res) => {
		cb(res)
	})
}

// #ifdef APP-PLUS

/**数据库操作 */

// 打开数据库
plus.sqlite.openDatabase({
	name: "a",
	path: "_doc/a.db",
	success: function () {
		console.log('success')
	},
	fail: function (e) {

	}
});

/**检查数据库是否存在history和follow表
 * 如果没有则创建
 */
enquiryDBTableName('history', (res) => {
	if (res.length == 0) {
		createDBTable('history', 'id TEXT NOT NULL, uid TEXT NOT NULL, title TEXT, username TEXT, date TEXT, preview TEXT, avatar TEXT, type TEXT, logdate TEXT')
	}
})
enquiryDBTableName('following', (res) => {
	if (res.length == 0) {
		createDBTable('following', 'id TEXT PRIMARY KEY NOT NULL, username TEXT, name TEXT, avatar TEXT, logdate TEXT')
	}
})

// 查询数据库是否存在表
function enquiryDBTableName(name, cb) {
	plus.sqlite.selectSql({
		name: "a",
		sql: "SELECT * FROM sqlite_master WHERE name='" + name + "'",
		success: function (data) {
			console.log(data)
			cb(data)
		},
		fail: function (e) {
			cb(null)
		}
	})
}
// 创建表
function createDBTable(name, field) {
	plus.sqlite.executeSql({
		name: "a",
		sql: "CREATE TABLE " + name + " (" + field + ")",
		success: function () {
			console.log('success')
		},
		fail: function (e) {
		}
	});
}
// 向数据库添加数据
function addDataForDB(table, arr) {
	let v = ''
	for (let i = 0; i < arr.length; i++) {
		v = v + '\'' + arr[i] + '\''
		if (i + 1 < arr.length) {
			v = v + ','
		}
	}
	plus.sqlite.executeSql({
		name: "a",
		sql: "INSERT INTO " + table + " VALUES (" + v + ")",
		success: function () {
			console.log('success')
		},
		fail: function (err) {
			console.log(err)
		}
	});
}
// 查询数据库表
function enquiryDBTable(table, sort, cb) {
	plus.sqlite.selectSql({
		name: "a",
		sql: "SELECT * FROM " + table + " ORDER BY logdate " + (sort ? "ASC" : "DESC"),
		success: function (data) {
			console.log(data)
			cb(data)
		},
		fail: function (e) {
			cb(null)
		}
	})
}
// #endif