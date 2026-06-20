const API_BASE = import.meta.env.VITE_API_BASE || 'https://your-domain.example/api';

type RequestOptions = { method?: UniApp.RequestOptions['method']; data?: any };

async function request<T = any>(path: string, options: RequestOptions = {}): Promise<T> {
  const token = uni.getStorageSync('care-today-token');
  return new Promise((resolve, reject) => {
    uni.request({
      url: `${API_BASE}${path}`,
      method: options.method || 'GET',
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

export const api = {
  register: (data: any) => request('/auth/register', { method: 'POST', data }),
  login: (data: any) => request('/auth/login', { method: 'POST', data }),
  listSpaces: () => request<any[]>('/spaces'),
  createSpace: (data: any) => request('/spaces', { method: 'POST', data }),
  getSpace: (id: string) => request<any>(`/spaces/${id}`),
  createInvite: (id: string, data: any) => request<any>(`/spaces/${id}/member-invites`, { method: 'POST', data }),
  listEvents: (id: string) => request<any[]>(`/spaces/${id}/events`),
  createEvent: (id: string, data: any) => request(`/spaces/${id}/events`, { method: 'POST', data }),
  listBody: (id: string) => request<any[]>(`/spaces/${id}/body-records`),
  createBody: (id: string, data: any) => request(`/spaces/${id}/body-records`, { method: 'POST', data }),
  listQuestions: (id: string) => request<any[]>(`/spaces/${id}/doctor-questions`),
  createQuestion: (id: string, data: any) => request(`/spaces/${id}/doctor-questions`, { method: 'POST', data }),
  listMessages: (id: string) => request<any[]>(`/spaces/${id}/messages`),
  createMessage: (id: string, data: any) => request(`/spaces/${id}/messages`, { method: 'POST', data }),
  listSymptoms: (id: string) => request<any[]>(`/spaces/${id}/symptoms`),
  createSymptom: (id: string, data: any) => request(`/spaces/${id}/symptoms`, { method: 'POST', data }),
  listNotices: (id: string) => request<any[]>(`/spaces/${id}/notices`),
  createNotice: (id: string, data: any) => request(`/spaces/${id}/notices`, { method: 'POST', data }),
  listNotes: (id: string) => request<any[]>(`/spaces/${id}/notes`),
  createNote: (id: string, data: any) => request(`/spaces/${id}/notes`, { method: 'POST', data }),
};
