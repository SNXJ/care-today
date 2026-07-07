export function dateKey(value: Date | string = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  const offset = date.getTimezoneOffset() * 60000;
  return new Date(date.getTime() - offset).toISOString().slice(0, 10);
}

export function formatDate(value: string) {
  if (!value) return '待记录';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('zh-CN', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

/** 只显示时分，如 08:30 */
export function formatTime(value: string) {
  if (!value) return '';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '' : date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
}

/** 月/日，如 6/22 */
export function formatDay(value: string) {
  if (!value) return '待记录';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '待记录' : `${date.getMonth() + 1}/${date.getDate()}`;
}

/** 年月日 时分，用于「最新体温」等副标题 */
export function formatFull(value: string) {
  if (!value) return '还没记过';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '还没记过';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function showError(error: any) {
  uni.showToast({ title: error?.message || '操作没有完成', icon: 'none', duration: 2600 });
}
