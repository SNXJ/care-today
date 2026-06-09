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
      throw new Error(error.reason || error.message || error.error || `请求失败：${response.status}`);
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
    acceptMember: (spaceId, memberId) => request(`/spaces/${spaceId}/members/${memberId}/accept`, { method: 'PATCH' }),
    removeMember: (spaceId, memberId) => request(`/spaces/${spaceId}/members/${memberId}`, { method: 'DELETE' }),
    leaveSpace: (spaceId) => request(`/spaces/${spaceId}/leave`, { method: 'DELETE' }),
    deleteAccount: () => request('/account', { method: 'DELETE' }),
    listEvents: (spaceId) => request(`/spaces/${spaceId}/events`),
    createEvent: (spaceId, body) => request(`/spaces/${spaceId}/events`, { method: 'POST', body }),
    updateEvent: (spaceId, eventId, body) => request(`/spaces/${spaceId}/events/${eventId}`, { method: 'PATCH', body }),
    deleteEvent: (spaceId, eventId) => request(`/spaces/${spaceId}/events/${eventId}`, { method: 'DELETE' }),
    listBodyRecords: (spaceId) => request(`/spaces/${spaceId}/body-records`),
    createBodyRecord: (spaceId, body) => request(`/spaces/${spaceId}/body-records`, { method: 'POST', body }),
    updateBodyRecord: (spaceId, recordId, body) => request(`/spaces/${spaceId}/body-records/${recordId}`, { method: 'PATCH', body }),
    deleteBodyRecord: (spaceId, recordId) => request(`/spaces/${spaceId}/body-records/${recordId}`, { method: 'DELETE' }),
    listDoctorQuestions: (spaceId) => request(`/spaces/${spaceId}/doctor-questions`),
    createDoctorQuestion: (spaceId, body) => request(`/spaces/${spaceId}/doctor-questions`, { method: 'POST', body }),
    updateDoctorQuestion: (spaceId, questionId, body) =>
      request(`/spaces/${spaceId}/doctor-questions/${questionId}`, { method: 'PATCH', body }),
    deleteDoctorQuestion: (spaceId, questionId) => request(`/spaces/${spaceId}/doctor-questions/${questionId}`, { method: 'DELETE' }),
    listHelpTasks: (spaceId) => request(`/spaces/${spaceId}/help-tasks`),
    createHelpTask: (spaceId, body) => request(`/spaces/${spaceId}/help-tasks`, { method: 'POST', body }),
    updateHelpTask: (spaceId, taskId, body) => request(`/spaces/${spaceId}/help-tasks/${taskId}`, { method: 'PATCH', body }),
    deleteHelpTask: (spaceId, taskId) => request(`/spaces/${spaceId}/help-tasks/${taskId}`, { method: 'DELETE' }),
    claimHelpTask: (spaceId, taskId) => request(`/spaces/${spaceId}/help-tasks/${taskId}/claim`, { method: 'PATCH' }),
    listMessages: (spaceId) => request(`/spaces/${spaceId}/messages`),
    createMessage: (spaceId, body) => request(`/spaces/${spaceId}/messages`, { method: 'POST', body }),
    updateMessage: (spaceId, messageId, body) => request(`/spaces/${spaceId}/messages/${messageId}`, { method: 'PATCH', body }),
    deleteMessage: (spaceId, messageId) => request(`/spaces/${spaceId}/messages/${messageId}`, { method: 'DELETE' }),
    listNotes: (spaceId) => request(`/spaces/${spaceId}/notes`),
    createNote: (spaceId, body) => request(`/spaces/${spaceId}/notes`, { method: 'POST', body }),
    updateNote: (spaceId, noteId, body) => request(`/spaces/${spaceId}/notes/${noteId}`, { method: 'PATCH', body }),
    deleteNote: (spaceId, noteId) => request(`/spaces/${spaceId}/notes/${noteId}`, { method: 'DELETE' }),
  };
}
