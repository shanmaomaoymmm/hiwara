import { API_URL } from './config';
import { getAccessToken } from './auth';
import { getSendRequestIwara, postSendRequestIwara, deleteSendRequestIwara } from './iwara';
import { sha1 } from '../crypto';

// 获取用户订阅视频列表
export async function getSubscribeVideoList(page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/videos`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    rating: 'all',
    page: page,
    limit: 48,
    subscribed: true
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get subscribe video list failed:', error);
    throw error;
  }
}

// 获取用户收藏视频列表
export async function getFavoritesVideoList(page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/favorites/videos`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    page: page,
    limit: 32,
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get favorites video list failed:', error);
    throw error;
  }
}

// 获取视频列表
export async function getVideoList(page: number, sort: string, isAI: boolean, date?: string, user?: string): Promise<any> {
  const path = `${API_URL}/videos`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    rating: 'all',
    page: page,
    limit: 48,
    sort: sort,
    ...(date && { date }),
    ...(user && { user })
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get video list failed:', error);
    throw error;
  }
}

// 获取视频信息
export async function getVideoInfo(videoId: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/video/${videoId}`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Get video info failed:', error);
    throw error;
  }
}

// 获取视频文件信息
export async function getVideoFileSQ(url: string, download: string, isAI: boolean): Promise<any> {
  // 示例url：https://filesq.iwara.tv/file/703f6909-71cd-4562-90d8-d03641ad4706?expires=1776910833478&hash=bfaa8a6c942a9553af1c976dc56b1585fc119ad522e7fc8970a1f18a50823b09
  const urlObj = new URL(url);
  const id = urlObj.pathname.split('/').pop();
  const expires = urlObj.searchParams.get('expires');
  const hash = urlObj.searchParams.get('hash');
  const salt = 'mSvL05GfEmeEmsEYfGCnVpEjYgTJraJN'
  const headers = {
    'x-version': await sha1(`${id}_${expires}_${salt}`)
  };
  const path = download ? `${url}${url.includes('?') ? '&' : '?'}download=${encodeURIComponent(download)}` : url;
  try {
    const response = await getSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Get video file info failed:', error);
    throw error;
  }
}

// 点赞视频
export async function likeVideo(videoId: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/video/${videoId}/like`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await postSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Like video failed:', error);
    throw error;
  }
}

// 取消点赞视频
export async function unlikeVideo(videoId: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/video/${videoId}/like`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await deleteSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Unlike video failed:', error);
    throw error;
  }
}

// 获取视频推荐：该用户的其他视频
export async function getVideoRecommendByUser(vid: string, uid: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/videos`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    rating: 'all',
    user: uid,
    exclude: vid,
    limit: 6
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get video recommend by user failed:', error);
    throw error;
  }
}

// 获取视频推荐：更多视频
export async function getVideoRecommendByOther(vid: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/video/${vid}/related`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Get video recommend by other failed:', error);
    throw error;
  }
}

// 获取视频评论
export async function getVideoComments(vid: string, page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/video/${vid}/comments`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    page: page,
    limit: 32
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get video comments failed:', error);
    throw error;
  }
}

// 获取视频评论的回复（使用 parent 参数过滤）
export async function getVideoCommentReplies(vid: string, commentId: string, page: number = 0, limit: number = 32, isAI: boolean): Promise<any> {
  const path = `${API_URL}/video/${vid}/comments`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    parent: commentId,
    page: page,
    limit: limit
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get video comment replies failed:', error);
    throw error;
  }
}

// 发表视频评论
export async function postVideoComment(vid: string, body: string, isAI: boolean, parentId?: string): Promise<any> {
  const path = `${API_URL}/video/${vid}/comments`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const postBody: Record<string, any> = {
    body: body,
    rulesAgreement: true
  };
  if (parentId) {
    postBody.parentId = parentId;
  }
  try {
    const response = await postSendRequestIwara(path, isAI, headers, postBody);
    return response;
  } catch (error) {
    console.error('Post video comment failed:', error);
    throw error;
  }
}

// 搜索
export async function search(text: string, page: number, type: 'videos' | 'images' | 'users', isAI: boolean): Promise<any> {
  const path = `${API_URL}/search`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    query: text,
    page: page,
    type: type,
    sort: 'relevance'
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Search failed:', error);
    throw error;
  }
}

// 标签搜索视频（参考 API: https://api.iwara.tv/videos?rating=all&tags=furry&sort=date）
export async function searchVideoByTag(tag: string, page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/videos`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    rating: 'all',
    tags: tag,
    sort: 'date',
    page: page,
    limit: 32,
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Search video by tag failed:', error);
    throw error;
  }
}
