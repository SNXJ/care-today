import { computed, reactive } from 'vue';
import { api } from '../api/client';

const data = reactive({
  ready: false,
  loading: false,
  token: uni.getStorageSync('care-today-token') || '',
  user: uni.getStorageSync('care-today-user') || null as any,
  spaces: [] as any[],
  space: null as any,
  members: [] as any[],
  currentRole: '',
  events: [] as any[],
  body: [] as any[],
  questions: [] as any[],
  messages: [] as any[],
  symptoms: [] as any[],
  notices: [] as any[],
  notes: [] as any[],
});

let bootPromise: Promise<void> | null = null;

function persistSession(result: any) {
  data.token = result.token;
  data.user = result.user;
  uni.setStorageSync('care-today-token', result.token);
  uni.setStorageSync('care-today-user', result.user);
}

async function selectSpace(id: string) {
  uni.setStorageSync('care-today-space-id', id);
  const detail = await api.getSpace(id);
  data.space = detail.space;
  data.members = detail.members || [];
  data.currentRole = detail.currentRole || '';
  const results = await Promise.all([
    api.listEvents(id), api.listBody(id), api.listQuestions(id), api.listMessages(id),
    api.listSymptoms(id), api.listNotices(id), api.listNotes(id),
  ]);
  [data.events, data.body, data.questions, data.messages, data.symptoms, data.notices, data.notes] = results;
}

async function load() {
  if (!data.token) {
    data.ready = true;
    return;
  }
  data.loading = true;
  try {
    data.spaces = await api.listSpaces();
    const remembered = uni.getStorageSync('care-today-space-id');
    const chosen = data.spaces.find((item) => item.id === remembered) || data.spaces[0];
    if (chosen) await selectSpace(chosen.id);
  } catch (error: any) {
    if (!uni.getStorageSync('care-today-token')) logout(false);
    throw error;
  } finally {
    data.loading = false;
    data.ready = true;
  }
}

function boot(force = false) {
  if (!bootPromise || force) bootPromise = load().finally(() => { bootPromise = null; });
  return bootPromise;
}

async function authenticate(mode: 'login' | 'register', form: any) {
  const result = mode === 'login' ? await api.login(form) : await api.register(form);
  persistSession(result);
  await boot(true);
}

async function createSpace(form: any) {
  const space = await api.createSpace(form) as any;
  await selectSpace(space.id);
  data.spaces = await api.listSpaces();
}

function logout(relaunch = true) {
  Object.assign(data, { token: '', user: null, spaces: [], space: null, members: [], currentRole: '', events: [], body: [], questions: [], messages: [], symptoms: [], notices: [], notes: [], ready: true });
  ['care-today-token', 'care-today-user', 'care-today-space-id'].forEach((key) => uni.removeStorageSync(key));
  if (relaunch) uni.reLaunch({ url: '/pages/index/index' });
}

export function useSession() {
  return {
    data,
    isAuthed: computed(() => Boolean(data.token)),
    hasSpace: computed(() => Boolean(data.space)),
    isPatient: computed(() => data.currentRole === 'PATIENT_ADMIN'),
    boot,
    authenticate,
    createSpace,
    selectSpace,
    logout,
  };
}

export async function refreshCurrentSpace() {
  if (data.space?.id) await selectSpace(data.space.id);
}
