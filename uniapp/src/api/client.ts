const API_BASE = import.meta.env.VITE_API_BASE || 'https://your-domain.example/api';

type RequestMethod = UniApp.RequestOptions['method'] | 'PATCH';
type RequestOptions = { method?: RequestMethod; data?: any };

async function request<T = any>(path: string, options: RequestOptions = {}): Promise<T> {
  const token = uni.getStorageSync('care-today-token');
  return new Promise((resolve, reject) => {
    uni.request({
      url: `${API_BASE}${path}`,
      method: (options.method || 'GET') as UniApp.RequestOptions['method'],
      data: options.data,
      header: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      success(response) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          resolve(response.data as T);
          return;
        }
        const body = (response.data || {}) as any;
        if (response.statusCode === 401 && !path.startsWith('/auth/')) {
          uni.removeStorageSync('care-today-token');
          uni.removeStorageSync('care-today-user');
        }
        reject(new Error(body.reason || body.message || `请求失败（${response.statusCode}）`));
      },
      fail: (error) => reject(new Error(error.errMsg || '网络连接失败')),
    });
  });
}

/// 图片附件的访问地址（fileId 为不可猜测的 UUID）。
export function photoUrl(id: string): string {
  return `${API_BASE}/files/${id}`;
}

/// 上传一张图片（本地临时路径），返回 {id, url}。
function uploadPhoto(spaceId: string, filePath: string): Promise<{ id: string; url: string }> {
  const token = uni.getStorageSync('care-today-token');
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: `${API_BASE}/spaces/${spaceId}/files`,
      filePath,
      name: 'file',
      header: token ? { Authorization: `Bearer ${token}` } : {},
      success(response) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            resolve(JSON.parse(response.data));
          } catch (e) {
            reject(new Error('上传返回解析失败'));
          }
          return;
        }
        let reason = `上传失败（${response.statusCode}）`;
        try { reason = JSON.parse(response.data).reason || reason; } catch (e) { /* ignore */ }
        reject(new Error(reason));
      },
      fail: (error) => reject(new Error(error.errMsg || '图片上传失败')),
    });
  });
}

export const api = {
  register: (data: any) => request('/auth/register', { method: 'POST', data }),
  uploadPhoto,
  login: (data: any) => request('/auth/login', { method: 'POST', data }),
  listSpaces: () => request<any[]>('/spaces'),
  createSpace: (data: any) => request('/spaces', { method: 'POST', data }),
  getSpace: (id: string) => request<any>(`/spaces/${id}`),
  createInvite: (id: string, data: any) => request<any>(`/spaces/${id}/member-invites`, { method: 'POST', data }),
  removeMember: (spaceId: string, memberId: string) => request(`/spaces/${spaceId}/members/${memberId}`, { method: 'DELETE' }),
  leaveSpace: (spaceId: string) => request(`/spaces/${spaceId}/leave`, { method: 'DELETE' }),
  deleteAccount: () => request('/account', { method: 'DELETE' }),
  listEvents: (id: string) => request<any[]>(`/spaces/${id}/events`),
  createEvent: (id: string, data: any) => request(`/spaces/${id}/events`, { method: 'POST', data }),
  updateEvent: (id: string, eventId: string, data: any) => request(`/spaces/${id}/events/${eventId}`, { method: 'PATCH', data }),
  deleteEvent: (id: string, eventId: string) => request(`/spaces/${id}/events/${eventId}`, { method: 'DELETE' }),
  listBody: (id: string) => request<any[]>(`/spaces/${id}/body-records`),
  createBody: (id: string, data: any) => request(`/spaces/${id}/body-records`, { method: 'POST', data }),
  listQuestions: (id: string) => request<any[]>(`/spaces/${id}/doctor-questions`),
  createQuestion: (id: string, data: any) => request(`/spaces/${id}/doctor-questions`, { method: 'POST', data }),
  updateQuestion: (id: string, questionId: string, data: any) => request(`/spaces/${id}/doctor-questions/${questionId}`, { method: 'PATCH', data }),
  deleteQuestion: (id: string, questionId: string) => request(`/spaces/${id}/doctor-questions/${questionId}`, { method: 'DELETE' }),
  listMessages: (id: string) => request<any[]>(`/spaces/${id}/messages`),
  createMessage: (id: string, data: any) => request(`/spaces/${id}/messages`, { method: 'POST', data }),
  updateMessage: (id: string, messageId: string, data: any) => request(`/spaces/${id}/messages/${messageId}`, { method: 'PATCH', data }),
  deleteMessage: (id: string, messageId: string) => request(`/spaces/${id}/messages/${messageId}`, { method: 'DELETE' }),
  listSymptoms: (id: string) => request<any[]>(`/spaces/${id}/symptoms`),
  createSymptom: (id: string, data: any) => request(`/spaces/${id}/symptoms`, { method: 'POST', data }),
  listMedications: (id: string) => request<any[]>(`/spaces/${id}/medications`),
  createMedication: (id: string, data: any) => request(`/spaces/${id}/medications`, { method: 'POST', data }),
  listNotices: (id: string) => request<any[]>(`/spaces/${id}/notices`),
  createNotice: (id: string, data: any) => request(`/spaces/${id}/notices`, { method: 'POST', data }),
  updateNotice: (spaceId: string, noticeId: string, data: any) => request(`/spaces/${spaceId}/notices/${noticeId}`, { method: 'PATCH', data }),
  deleteNotice: (spaceId: string, noticeId: string) => request(`/spaces/${spaceId}/notices/${noticeId}`, { method: 'DELETE' }),
  listNotes: (id: string) => request<any[]>(`/spaces/${id}/notes`),
  createNote: (id: string, data: any) => request(`/spaces/${id}/notes`, { method: 'POST', data }),
  updateNote: (id: string, noteId: string, data: any) => request(`/spaces/${id}/notes/${noteId}`, { method: 'PATCH', data }),
  deleteNote: (id: string, noteId: string) => request(`/spaces/${id}/notes/${noteId}`, { method: 'DELETE' }),
};
