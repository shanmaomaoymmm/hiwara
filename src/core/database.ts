import Database from '@tauri-apps/plugin-sql';
import { videoDir, pictureDir, downloadDir, join } from '@tauri-apps/api/path';
import { isTauri } from '@tauri-apps/api/core';
const sqlDB = await Database.load('sqlite:database.db');

// 生成UUID的辅助函数
function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = Math.random() * 16 | 0;
    const v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

/**
 * 通用数据库迁移：检查表的现有列，补充缺失的列
 * @param tableName 表名
 * @param columns 期望的列定义 Record<列名, SQL类型定义>
 */
async function migrateTable(tableName: string, columns: Record<string, string>): Promise<void> {
  const result: Array<{ name: string }> = await sqlDB.select(
    `SELECT name FROM sqlite_master WHERE type='table' AND name=?`, [tableName]
  );
  if (result.length === 0) return; // 表不存在，由上层 CREATE TABLE 处理

  // 获取现有列
  const existingColumns: Array<{ name: string }> = await sqlDB.select(
    `PRAGMA table_info(${tableName})`
  );
  const existingNames = new Set(existingColumns.map((c: any) => c.name));

  // 逐个补充缺失的列
  for (const [colName, colDef] of Object.entries(columns)) {
    if (!existingNames.has(colName)) {
      try {
        await sqlDB.execute(`ALTER TABLE ${tableName} ADD COLUMN ${colDef}`);
        console.log(`表 ${tableName} 添加列 ${colName} 成功`);
      } catch (e: any) {
        console.warn(`表 ${tableName} 添加列 ${colName} 失败:`, e);
      }
    }
  }
}

// 初始化数据库
export function initDatabase(): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      // 独立检查并创建用户表
      const userResult: Array<{ name: string }> = await sqlDB.select(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='users'`
      );
      if (userResult.length === 0) {
        await sqlDB.execute(`CREATE TABLE IF NOT EXISTS users (
          uuid TEXT PRIMARY KEY,
          uid TEXT,
          username TEXT,
          email TEXT,
          password TEXT,
          token TEXT
        );`);
      }

      // 独立检查并创建设置表
      const setupResult: Array<{ name: string }> = await sqlDB.select(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='setup'`
      );

      if (setupResult.length === 0) {
        await sqlDB.execute(`CREATE TABLE IF NOT EXISTS setup (
          auto_play BOOLEAN,
          reconnect INTEGER,
          definition TEXT,
          search_mode INTEGER,
          language TEXT,
          video_save_path TEXT,
          image_save_path TEXT,
          aria2_rpc TEXT,
          aria2_token TEXT,
          aria2_download TEXT,
          aria2_switch BOOLEAN,
          max_concurrent_downloads INTEGER DEFAULT 2
        );`);

        // 根据平台获取合适的默认下载路径
        let videoSavePath: string;
        let imageSavePath: string;

        if (isTauri()) {
          const isAndroid = /android/i.test(navigator.userAgent);
          if (isAndroid) {
            videoSavePath = '/storage/emulated/0/Movies/iwara';
            imageSavePath = '/storage/emulated/0/Pictures/iwara';
          } else {
            const videoPath = await downloadDir();
            const imagePath = await pictureDir();
            videoSavePath = await join(videoPath, 'iwara');
            imageSavePath = await join(imagePath, 'iwara');
          }
        } else {
          const videoPath = await videoDir();
          const imagePath = await pictureDir();
          videoSavePath = await join(videoPath, 'iwara');
          imageSavePath = await join(imagePath, 'iwara');
        }

        await sqlDB.execute(`INSERT INTO setup (auto_play, reconnect, definition, search_mode, language, video_save_path, image_save_path, aria2_rpc, aria2_token, aria2_download, aria2_switch) VALUES (TRUE, 1, 'Source', 0, 'auto', ?, ?, '', '', '', FALSE);`, [videoSavePath, imageSavePath]);
      } else {
        await migrateTable('setup', { max_concurrent_downloads: 'max_concurrent_downloads INTEGER DEFAULT 2' });
      }

      // 独立检查并创建视频历史表
      const videoHistoryResult: Array<{ name: string }> = await sqlDB.select(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='video_history'`
      );
      if (videoHistoryResult.length === 0) {
        await sqlDB.execute(`CREATE TABLE IF NOT EXISTS video_history (
          id TEXT,
          title TEXT,
          author TEXT,
          cover_url TEXT,
          long_num INTEGER,
          create_time INTEGER,
          access_time INTEGER,
          ai BOOLEAN DEFAULT 0
        );`);
        console.log('视频历史表创建成功');
      } else {
        await migrateTable('video_history', { ai: 'ai BOOLEAN DEFAULT 0' });
      }

      // 独立检查并创建插画历史表
      const imageHistoryResult: Array<{ name: string }> = await sqlDB.select(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='image_history'`
      );
      if (imageHistoryResult.length === 0) {
        await sqlDB.execute(`CREATE TABLE IF NOT EXISTS image_history (
          id TEXT,
          title TEXT,
          author TEXT,
          cover_url TEXT,
          long_num INTEGER,
          create_time INTEGER,
          access_time INTEGER,
          ai BOOLEAN DEFAULT 0
        );`);
        console.log('插画历史表创建成功');
      } else {
        await migrateTable('image_history', { ai: 'ai BOOLEAN DEFAULT 0' });
      }

      // 独立检查并创建历史搜索表
      const searchHistoryResult: Array<{ name: string }> = await sqlDB.select(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='search_history'`
      );
      if (searchHistoryResult.length === 0) {
        await sqlDB.execute(`CREATE TABLE IF NOT EXISTS search_history (
          search_text TEXT PRIMARY KEY,
          search_time INTEGER
        );`);
        console.log('历史搜索表创建成功');
      }

      // 独立检查并创建下载缓存表
      const downloadCacheResult: Array<{ name: string }> = await sqlDB.select(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='download_cache'`
      );
      if (downloadCacheResult.length === 0) {
        await sqlDB.execute(`CREATE TABLE IF NOT EXISTS download_cache (
          id TEXT PRIMARY KEY,
          title TEXT,
          author TEXT,
          cover_url TEXT,
          long_num INTEGER,
          view_num INTEGER DEFAULT 0,
          like_num INTEGER DEFAULT 0,
          is_r18 INTEGER DEFAULT 0,
          ai INTEGER DEFAULT 0,
          file_path TEXT,
          file_size INTEGER DEFAULT 0,
          progress INTEGER DEFAULT 0,
          status TEXT DEFAULT 'downloading',
          cache_time INTEGER,
          url TEXT
        );`);
        console.log('下载缓存表创建成功');
      }

      resolve();
    } catch (error) {
      reject(error);
    }
  });
}

// 检查用户是否已经登录
export function checkUserIsLogin(): Promise<boolean> {
  return new Promise(async (resolve, reject) => {
    try {
      const result: Array<{ count: number }> = await sqlDB.select(
        `SELECT COUNT(*) as count FROM users WHERE token IS NOT NULL AND token != ''`
      );
      resolve(result[0].count > 0);
    } catch (error) {
      reject(error);
    }
  });
}

// 登录：插入用户到数据库，确保表中最多只有一行数据
export function login(
  email: string,
  password: string,
  token: string
): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      // 删除现有所有用户数据，确保表中只有一行
      await sqlDB.execute(`DELETE FROM users`);
      const uuid = generateUUID();
      await sqlDB.execute(`INSERT INTO users (uuid, email, password, token) VALUES (?, ?, ?, ?)`,
        [uuid, email, password, token]
      );
      console.log('User logged in and saved with uuid:', uuid);
      resolve();
    } catch (error) {
      reject(error);
    }
  });
}

// 修改用户信息（uid，username）
export function updateUserInfo(uid: string, username: string): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      await sqlDB.execute(`UPDATE users SET uid = ?, username = ?`,
        [uid, username]
      );
      console.log('User info updated:', uid, username);
      resolve();
    } catch (error) {
      reject(error);
    }
  })
}

// 获取用户信息（uid 和 username）
export function getUserInfo(): Promise<{ uid: string | null, username: string | null }> {
  return new Promise(async (resolve, reject) => {
    try {
      const result: Array<any> = await sqlDB.select(`SELECT uid, username FROM users LIMIT 1`);
      if (result.length > 0) {
        resolve({
          uid: result[0].uid || null,
          username: result[0].username || null
        });
      } else {
        resolve({ uid: null, username: null });
      }
    } catch (error) {
      reject(error);
    }
  });
}

// 返回上次登录记住的用户email和password
export function getLastLoginAuth(): Promise<any> {
  return new Promise(async (resolve, reject) => {
    try {
      const result: Array<any> = await sqlDB.select(`SELECT email, password FROM users LIMIT 1`);
      if (result.length > 0) {
        resolve(result[0]);
      } else {
        resolve(null);
      }
    } catch (error) {
      reject(error);
    }
  });
}

// 获取用户token
export function getUserToken(): Promise<string> {
  return new Promise(async (resolve, reject) => {
    try {
      const result: Array<{ token: string }> = await sqlDB.select(`SELECT token FROM users LIMIT 1`);
      if (result.length > 0) {
        resolve(result[0].token);
      } else {
        reject({
          message: '用户未登录'
        });
      }
    } catch (error) {
      reject(error);
    }
  })
}

// 退出登录：清空用户token
export function logout(): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      await sqlDB.execute(`UPDATE users SET token = ''`);
      console.log('用户已退出登录，token已清空');
      resolve();
    } catch (error) {
      reject(error);
    }
  });
}

// 获取设置数据
export async function getSetupData(): Promise<any> {
  try {
    const result: Array<any> = await sqlDB.select(`SELECT * FROM setup LIMIT 1`);
    if (result.length > 0) {
      return result[0];
    } else {
      // 如果没有找到设置数据，根据平台返回合适的默认路径
      const isAndroid = isTauri() && /android/i.test(navigator.userAgent);
      const defaultVideoPath = isAndroid ? '/storage/emulated/0/Movies/iwara' : '';
      const defaultImagePath = isAndroid ? '/storage/emulated/0/Pictures/iwara' : '';
      return {
        auto_play: true,
        reconnect: 1,
        definition: 'Source',
        search_mode: 0,
        language: 'auto',
        video_save_path: defaultVideoPath,
        image_save_path: defaultImagePath,
        aria2_rpc: '',
        aria2_token: '',
        aria2_download: '~/Downloads/Iwara',
        aria2_switch: false
      };
    }
  } catch (error) {
    console.error('Error fetching setup data:', error);
    // 发生错误时返回默认值（根据平台使用合适的默认路径）
    const isAndroid = isTauri() && /android/i.test(navigator.userAgent);
    return {
      auto_play: true,
      reconnect: 1,
      definition: 'Source',
      search_mode: 0,
      language: 'auto',
      video_save_path: isAndroid ? '/storage/emulated/0/Movies/iwara' : '',
      image_save_path: isAndroid ? '/storage/emulated/0/Pictures/iwara' : '',
      aria2_rpc: '',
      aria2_token: '',
      aria2_download: '~/Downloads/Iwara',
      aria2_switch: false
    };
  }
}

// 更新设置数据
export async function updateSetupData(setupData: any): Promise<void> {
  try {
    // 由于setup表只应该有一条记录，我们使用UPDATE而不使用INSERT或DELETE
    let updateFields = [];
    let values = [];

    for (const [key, value] of Object.entries(setupData)) {
      updateFields.push(`${key} = ?`);
      values.push(value);
    }

    const updateQuery = `UPDATE setup SET ${updateFields.join(', ')}`;
    await sqlDB.execute(updateQuery, values);
  } catch (error) {
    console.error('Error updating setup data:', error);
    throw error;
  }
}

// 插入视频历史记录
export function insertVideoHistory(
  id: string,
  title: string,
  author: string,
  coverUrl: string,
  longNum: number,
  createTime: number,
  ai: boolean = false
): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      const accessTime = Date.now(); // 当前时间戳
      
      // 查询该ID是否已存在于表中（全局去重）
      const existingRecord: Array<{ id: string }> = await sqlDB.select(
        `SELECT id FROM video_history WHERE id = ?`,
        [id]
      );
      
      // 如果已存在，更新所有字段（access_time排到最前，其他字段可能变化）
      if (existingRecord.length > 0) {
        await sqlDB.execute(
          `UPDATE video_history SET title = ?, author = ?, cover_url = ?, long_num = ?, create_time = ?, access_time = ?, ai = ? WHERE id = ?`,
          [title, author, coverUrl, longNum, createTime, accessTime, ai, id]
        );
        console.log('视频历史记录已更新:', id);
      } else {
        // 否则插入新记录
        await sqlDB.execute(
          `INSERT INTO video_history (id, title, author, cover_url, long_num, create_time, access_time, ai) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [id, title, author, coverUrl, longNum, createTime, accessTime, ai]
        );
        console.log('视频历史记录已添加:', id);
      }
      resolve();
    } catch (error) {
      console.error('插入视频历史记录失败:', error);
      reject(error);
    }
  });
}

// 插入插画历史记录
export function insertImageHistory(
  id: string,
  title: string,
  author: string,
  coverUrl: string,
  longNum: number,
  createTime: number,
  ai: boolean = false
): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      const accessTime = Date.now(); // 当前时间戳
      
      // 查询该ID是否已存在于表中（全局去重）
      const existingRecord: Array<{ id: string }> = await sqlDB.select(
        `SELECT id FROM image_history WHERE id = ?`,
        [id]
      );
      
      // 如果已存在，更新所有字段（access_time排到最前，其他字段可能变化）
      if (existingRecord.length > 0) {
        await sqlDB.execute(
          `UPDATE image_history SET title = ?, author = ?, cover_url = ?, long_num = ?, create_time = ?, access_time = ?, ai = ? WHERE id = ?`,
          [title, author, coverUrl, longNum, createTime, accessTime, ai, id]
        );
        console.log('插画历史记录已更新:', id);
      } else {
        // 否则插入新记录
        await sqlDB.execute(
          `INSERT INTO image_history (id, title, author, cover_url, long_num, create_time, access_time, ai) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [id, title, author, coverUrl, longNum, createTime, accessTime, ai]
        );
        console.log('插画历史记录已添加:', id);
      }
      resolve();
    } catch (error) {
      console.error('插入插画历史记录失败:', error);
      reject(error);
    }
  });
}

// 获取视频历史记录列表（分页）
export function getVideoHistoryList(page: number, pageSize: number = 15): Promise<any[]> {
  return new Promise(async (resolve, reject) => {
    try {
      const offset = page * pageSize;
      const result: Array<any> = await sqlDB.select(
        `SELECT id, title, author, cover_url, long_num, create_time, access_time, ai
         FROM video_history
         ORDER BY access_time DESC
         LIMIT ? OFFSET ?`,
        [pageSize, offset]
      );
      // console.log('从数据库获取到', result.length, '条视频历史记录');
      // 转换数据格式
      const formattedResult = result.map(item => ({
        id: item.id,
        title: item.title,
        author: item.author,
        img: item.cover_url, // 直接返回 cover_url，由子组件调用 getImageIwara 处理
        longNum: item.long_num ? item.long_num.toString() : '', // 视频时长
        createTime: item.create_time ? new Date(item.create_time).toISOString().split('T')[0] : '', // 作品发布时间
        isR18: false, // 数据库中未存储此字段，默认为false
        ai: item.ai ? true : false, // 是否为AI站
        lastWatchDate: new Date(item.access_time).toISOString().split('T')[0],
        accessTime: item.access_time // 保留原始时间戳用于显示完整时间
      }));
      resolve(formattedResult);
    } catch (error) {
      console.error('获取视频历史记录失败:', error);
      reject(error);
    }
  });
}

// 获取插画历史记录列表（分页）
export function getImageHistoryList(page: number, pageSize: number = 15): Promise<any[]> {
  return new Promise(async (resolve, reject) => {
    try {
      const offset = page * pageSize;
      const result: Array<any> = await sqlDB.select(
        `SELECT id, title, author, cover_url, long_num, create_time, access_time, ai
         FROM image_history
         ORDER BY access_time DESC
         LIMIT ? OFFSET ?`,
        [pageSize, offset]
      );
      // console.log('从数据库获取到', result.length, '条插画历史记录');
      // 转换数据格式
      const formattedResult = result.map(item => ({
        id: item.id,
        title: item.title,
        author: item.author,
        img: item.cover_url, // 直接返回 cover_url，由子组件调用 getImageIwara 处理
        longNum: item.long_num ? item.long_num.toString() : '', // 插画张数
        createTime: item.create_time ? new Date(item.create_time).toISOString().split('T')[0] : '', // 作品发布时间
        isR18: false, // 数据库中未存储此字段，默认为false
        ai: item.ai ? true : false, // 是否为AI站
        lastWatchDate: new Date(item.access_time).toISOString().split('T')[0],
        accessTime: item.access_time // 保留原始时间戳用于显示完整时间
      }));
      
      resolve(formattedResult);
    } catch (error) {
      console.error('获取插画历史记录失败:', error);
      reject(error);
    }
  });
}

// 插入或更新历史搜索记录
export function insertSearchHistory(searchText: string): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      const searchTime = Date.now(); // 当前时间戳
      
      // 查询是否已存在该搜索文本
      const existingRecord: Array<{ search_text: string }> = await sqlDB.select(
        `SELECT search_text FROM search_history WHERE search_text = ?`,
        [searchText]
      );
      
      if (existingRecord.length > 0) {
        // 如果已存在，只更新搜索时间
        await sqlDB.execute(
          `UPDATE search_history SET search_time = ? WHERE search_text = ?`,
          [searchTime, searchText]
        );
        console.log('历史搜索记录已更新:', searchText);
      } else {
        // 否则插入新记录
        await sqlDB.execute(
          `INSERT INTO search_history (search_text, search_time) VALUES (?, ?)`,
          [searchText, searchTime]
        );
        console.log('历史搜索记录已添加:', searchText);
      }
      resolve();
    } catch (error) {
      console.error('插入历史搜索记录失败:', error);
      reject(error);
    }
  });
}

// 获取历史搜索列表（倒序排序，可选限制数量）
export function getSearchHistoryList(limit?: number): Promise<string[]> {
  return new Promise(async (resolve, reject) => {
    try {
      let query = `SELECT search_text FROM search_history ORDER BY search_time DESC`;
      let params: any[] = [];
      
      if (limit) {
        query += ` LIMIT ?`;
        params.push(limit);
      }
      
      const result: Array<{ search_text: string }> = await sqlDB.select(query, params);
      
      // 提取搜索文本数组
      const searchTexts = result.map(item => item.search_text);
      
      console.log('从数据库获取到', searchTexts.length, '条历史搜索记录');
      resolve(searchTexts);
    } catch (error) {
      console.error('获取历史搜索记录失败:', error);
      reject(error);
    }
  });
}

// ========== 下载缓存相关 =========

// 插入或更新下载缓存记录
export function upsertDownloadCache(
  id: string,
  title: string,
  author: string,
  coverUrl: string,
  longNum: number,
  viewNum: number,
  likeNum: number,
  isR18: boolean,
  ai: boolean,
  url: string
): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      const cacheTime = Date.now();
      await sqlDB.execute(
        `INSERT OR REPLACE INTO download_cache (id, title, author, cover_url, long_num, view_num, like_num, is_r18, ai, progress, status, cache_time, url)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'downloading', ?, ?)`,
        [id, title, author, coverUrl, longNum, viewNum, likeNum, isR18 ? 1 : 0, ai ? 1 : 0, cacheTime, url]
      );
      console.log('下载缓存记录已添加:', id);
      resolve();
    } catch (error) {
      console.error('插入下载缓存记录失败:', error);
      reject(error);
    }
  });
}

// 更新下载进度
export function updateDownloadProgress(
  id: string,
  progress: number,
  status: 'downloading' | 'completed' | 'failed' | 'cancelled' | 'paused',
  filePath?: string,
  fileSize?: number
): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      const updates: string[] = ['progress = ?', 'status = ?'];
      const params: any[] = [progress, status];

      if (filePath !== undefined) {
        updates.push('file_path = ?');
        params.push(filePath);
      }
      if (fileSize !== undefined) {
        updates.push('file_size = ?');
        params.push(fileSize);
      }

      params.push(id);
      await sqlDB.execute(
        `UPDATE download_cache SET ${updates.join(', ')} WHERE id = ?`,
        params
      );
      resolve();
    } catch (error) {
      console.error('更新下载进度失败:', error);
      reject(error);
    }
  });
}

// 获取下载缓存列表
export function getDownloadCacheList(
  page: number,
  pageSize: number = 15
): Promise<any[]> {
  return new Promise(async (resolve, reject) => {
    try {
      const offset = page * pageSize;
      const result: Array<any> = await sqlDB.select(
        `SELECT id, title, author, cover_url, long_num, view_num, like_num, is_r18, ai,
                file_path, file_size, progress, status, cache_time, url
         FROM download_cache
         ORDER BY cache_time DESC
         LIMIT ? OFFSET ?`,
        [pageSize, offset]
      );
      const formattedResult = result.map(item => ({
        id: item.id,
        title: item.title,
        author: item.author,
        img: item.cover_url,
        longNum: item.long_num ? item.long_num.toString() : '',
        viewNum: item.view_num?.toString() || '0',
        likeNum: item.like_num?.toString() || '0',
        isR18: !!item.is_r18,
        ai: !!item.ai,
        filePath: item.file_path || '',
        fileSize: item.file_size || 0,
        progress: item.progress || 0,
        status: item.status || 'downloading',
        cacheDate: item.cache_time ? new Date(item.cache_time).toISOString().split('T')[0] : '',
        url: item.url || '',
      }));
      resolve(formattedResult);
    } catch (error) {
      console.error('获取下载缓存列表失败:', error);
      reject(error);
    }
  });
}

// 删除下载缓存记录
export function deleteDownloadCache(id: string): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      await sqlDB.execute(`DELETE FROM download_cache WHERE id = ?`, [id]);
      console.log('下载缓存记录已删除:', id);
      resolve();
    } catch (error) {
      console.error('删除下载缓存记录失败:', error);
      reject(error);
    }
  });
}

// 清除已结束的下载记录（completed/failed），仅清理记录，不影响磁盘文件
// 保留 paused / downloading 等仍在进行中的记录
export function clearFinishedDownloadCache(): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      await sqlDB.execute(
        `DELETE FROM download_cache WHERE status IN ('completed', 'failed')`
      );
      console.log('已清除已完成/失败的下载记录');
      resolve();
    } catch (error) {
      console.error('清除下载记录失败:', error);
      reject(error);
    }
  });
}
