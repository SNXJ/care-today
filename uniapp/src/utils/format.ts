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

export function showError(error: any) {
  uni.showToast({ title: error?.message || '操作没有完成', icon: 'none', duration: 2600 });
}
