const API_BASE = import.meta.env.VITE_API_BASE || '/api';

export function createApi(getToken) {
  async function request(path, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    };
    const token = getToken();
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }
    const response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined,
    });
    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || error.error || `请求失败：${response.status}`);
    }
    if (response.status === 204) {
      return null;
    }
    return response.json();
  }

  return {
    register: (body) => request('/auth/register', { method: 'POST', body }),
    login: (body) => request('/auth/login', { method: 'POST', body }),
    listSpaces: () => request('/spaces'),
    createSpace: (body) => request('/spaces', { method: 'POST', body }),
    getSpace: (spaceId) => request(`/spaces/${spaceId}`),
    inviteMember: (spaceId, body) => request(`/spaces/${spaceId}/members`, { method: 'POST', body }),
    listEvents: (spaceId) => request(`/spaces/${spaceId}/events`),
    createEvent: (spaceId, body) => request(`/spaces/${spaceId}/events`, { method: 'POST', body }),
    listBodyRecords: (spaceId) => request(`/spaces/${spaceId}/body-records`),
    createBodyRecord: (spaceId, body) => request(`/spaces/${spaceId}/body-records`, { method: 'POST', body }),
    listDoctorQuestions: (spaceId) => request(`/spaces/${spaceId}/doctor-questions`),
    createDoctorQuestion: (spaceId, body) => request(`/spaces/${spaceId}/doctor-questions`, { method: 'POST', body }),
    updateDoctorQuestion: (spaceId, questionId, body) =>
      request(`/spaces/${spaceId}/doctor-questions/${questionId}`, { method: 'PATCH', body }),
    listHelpTasks: (spaceId) => request(`/spaces/${spaceId}/help-tasks`),
    createHelpTask: (spaceId, body) => request(`/spaces/${spaceId}/help-tasks`, { method: 'POST', body }),
    claimHelpTask: (spaceId, taskId) => request(`/spaces/${spaceId}/help-tasks/${taskId}/claim`, { method: 'PATCH' }),
    listMessages: (spaceId) => request(`/spaces/${spaceId}/messages`),
    createMessage: (spaceId, body) => request(`/spaces/${spaceId}/messages`, { method: 'POST', body }),
    listNotes: (spaceId) => request(`/spaces/${spaceId}/notes`),
    createNote: (spaceId, body) => request(`/spaces/${spaceId}/notes`, { method: 'POST', body }),
  };
}
