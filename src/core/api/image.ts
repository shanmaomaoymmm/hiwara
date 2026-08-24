import { API_URL } from './config';
import { getAccessToken } from './auth';
import { getSendRequestIwara, postSendRequestIwara, deleteSendRequestIwara } from './iwara';

// 获取用户订阅插画列表
export async function getSubscribeImageList(page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/images`;
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
    console.error('Get subscribe image list failed:', error);
    throw error;
  }
}

// 获取用户收藏的插画列表
export async function getFavoritesImageList(page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/favorites/images`;
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
    console.error('Get favorites image list failed:', error);
    throw error;
  }
}

// 获取插画列表
export async function getImageList(page: number, sort: string, isAI: boolean, date?: string, user?: string): Promise<any> {
  const path = `${API_URL}/images`;
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
    console.error('Get image list failed:', error);
    throw error;
  }
}

// 获取插画信息
export async function getImageInfo(imageId: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/image/${imageId}`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    console.log(path)
    const response = await getSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Get image info failed:', error);
    throw error;
  }
}

// 点赞插画
export async function likeImage(imageId: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/image/${imageId}/like`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await postSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Like image failed:', error);
    throw error;
  }
}

// 取消点赞插画
export async function unlikeImage(imageId: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/image/${imageId}/like`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await deleteSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Unlike image failed:', error);
    throw error;
  }
}

// 获取插画推荐：该用户的其他插画
export async function getImageRecommendByUser(pid: string, uid: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/images`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const query = {
    rating: 'all',
    user: uid,
    exclude: pid,
    limit: 6
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers, query);
    return response;
  } catch (error) {
    console.error('Get image recommend by user failed:', error);
    throw error;
  }
}

// 获取插画推荐：更多插画
export async function getImageRecommendByOther(pid: string, isAI: boolean): Promise<any> {
  const path = `${API_URL}/image/${pid}/related`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  try {
    const response = await getSendRequestIwara(path, isAI, headers);
    return response;
  } catch (error) {
    console.error('Get image recommend by other failed:', error);
    throw error;
  }
}

// 获取插画评论
export async function getImageComments(pid: string, page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/image/${pid}/comments`;
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
    console.error('Get image comments failed:', error);
    throw error;
  }
}

// 获取插画评论回复
export async function getImageCommentReplies(pid: string, commentId: string, page: number = 0, limit: number = 32, isAI: boolean): Promise<any> {
  const path = `${API_URL}/image/${pid}/comments`;
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
    console.error('Get image comment replies failed:', error);
    throw error;
  }
}

// 发表插画评论
export async function postImageComment(pid: string, body: string, isAI: boolean, parentId?: string): Promise<any> {
  const path = `${API_URL}/image/${pid}/comments`;
  const headers = {
    Authorization: `Bearer ${await getAccessToken()}`,
  };
  const postBody: Record<string, any> = { body, rulesAgreement: true };
  if (parentId) {
    postBody.parentId = parentId;
  }
  try {
    const response = await postSendRequestIwara(path, isAI, headers, postBody);
    return response;
  } catch (error) {
    console.error('Post image comment failed:', error);
    throw error;
  }
}

// 标签搜索插画（参考视频标签搜索: https://api.iwara.tv/videos?rating=all&tags=furry&sort=date）
export async function searchImageByTag(tag: string, page: number, isAI: boolean): Promise<any> {
  const path = `${API_URL}/images`;
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
    console.error('Search image by tag failed:', error);
    throw error;
  }
}
