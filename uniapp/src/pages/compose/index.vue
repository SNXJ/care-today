<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { api } from '../../api/client';
import { refreshCurrentSpace, useSession } from '../../state/session';
import { dateKey, showError } from '../../utils/format';

const session = useSession();
const submitting = ref(false);
const selectedType = ref('');
const today = dateKey();
const form = reactive({ title: '', content: '', note: '', date: today, time: '09:00', value: '', tag: '', important: false, needsCompanion: false, painScore: 0, fatigueScore: 0, sleepScore: 5, moodScore: 5, appetiteScore: 5 });
const actions = [
  { id: 'message', label: '说说此刻', desc: '发布给家人看', patient: true },
  { id: 'event', label: '加日程', desc: '复诊、检查、提醒' },
  { id: 'body', label: '记身体状态', desc: '五项 0–10 分评分' },
  { id: 'temperature', label: '记体温', desc: '测量时间和数值' },
  { id: 'weight', label: '记体重', desc: '日期和数值' },
  { id: 'symptom', label: '记症状', desc: '症状和发生时间' },
  { id: 'medication', label: '记用药', desc: '吃了什么药、何时吃' },
  { id: 'notice', label: '记注意事项', desc: '有效期内提醒' },
  { id: 'question', label: '问医生的问题', desc: '复诊前确认' },
  { id: 'note', label: '存一条资料', desc: '报告、用药、医嘱' },
];
const availableActions = computed(() => actions.filter((x) => !x.patient || session.isPatient.value));
const current = computed(() => actions.find((x) => x.id === selectedType.value));
const needsDate = computed(() => ['event', 'body', 'temperature', 'weight', 'symptom', 'medication', 'notice'].includes(selectedType.value));
const needsDateTime = computed(() => ['event', 'temperature', 'symptom', 'medication'].includes(selectedType.value));
const recentMedNames = computed(() => {
  const names: string[] = [];
  for (const item of session.data.medications) {
    if (item.name && !names.includes(item.name)) names.push(item.name);
    if (names.length >= 6) break;
  }
  return names;
});
const scoreFields = [
  { key: 'painScore', label: '疼痛' },
  { key: 'fatigueScore', label: '乏力' },
  { key: 'sleepScore', label: '睡眠' },
  { key: 'moodScore', label: '心情' },
  { key: 'appetiteScore', label: '食欲' },
] as const;

onLoad(async (query) => {
  try { await session.boot(); } catch (error) { showError(error); }
  const requested = String(query?.type || '');
  if (requested === 'body') selectedType.value = '';
  else if (requested) selectedType.value = requested;
});

function isoDateTime() { return new Date(`${form.date}T${form.time}:00`).toISOString(); }
function requireValue(value: string, message: string) { if (value.trim()) return true; uni.showToast({ title: message, icon: 'none' }); return false; }
function setScore(key: typeof scoreFields[number]['key'], event: any) { form[key] = Number(event.detail.value); }

async function submit() {
  if (!session.data.space?.id || !selectedType.value) return;
  const id = session.data.space.id;
  submitting.value = true;
  try {
    switch (selectedType.value) {
      case 'message':
        if (!requireValue(form.content, '请写下想分享的内容')) return;
        await api.createMessage(id, { text: form.content.trim() }); break;
      case 'event':
        if (!requireValue(form.title, '请填写日程标题')) return;
        await api.createEvent(id, { title: form.title.trim(), scheduledAt: isoDateTime(), location: form.content.trim() || undefined, note: form.note.trim() || undefined, needsCompanion: form.needsCompanion }); break;
      case 'body':
        await api.createBody(id, { painScore: form.painScore, fatigueScore: form.fatigueScore, sleepScore: form.sleepScore, moodScore: form.moodScore, appetiteScore: form.appetiteScore, note: form.note.trim() || undefined, recordDate: form.date }); break;
      case 'temperature':
        if (!form.value || Number(form.value) < 34 || Number(form.value) > 42) throw new Error('体温需在 34–42℃ 之间');
        await api.createBody(id, { temperature: Number(form.value), measuredAt: isoDateTime(), note: form.note.trim() || undefined, recordDate: form.date }); break;
      case 'weight':
        if (!form.value || Number(form.value) < 20 || Number(form.value) > 300) throw new Error('体重需在 20–300kg 之间');
        await api.createBody(id, { weight: Number(form.value), note: form.note.trim() || undefined, recordDate: form.date }); break;
      case 'symptom':
        if (!requireValue(form.tag, '请选择或填写症状')) return;
        await api.createSymptom(id, { tag: form.tag.trim(), happenedAt: isoDateTime(), note: form.note.trim() || undefined }); break;
      case 'medication':
        if (!requireValue(form.tag, '请选择或填写药名')) return;
        await api.createMedication(id, { name: form.tag.trim(), dosage: form.value.trim() || undefined, takenAt: isoDateTime(), note: form.note.trim() || undefined }); break;
      case 'notice':
        if (!requireValue(form.content, '请填写注意事项')) return;
        await api.createNotice(id, { content: form.content.trim(), detail: form.note.trim() || undefined, important: form.important, startsOn: form.date, endsOn: form.value || undefined }); break;
      case 'question':
        if (!requireValue(form.content, '请填写想问的问题')) return;
        await api.createQuestion(id, { question: form.content.trim(), important: form.important }); break;
      case 'note':
        if (!requireValue(form.title, '请填写资料标题')) return;
        await api.createNote(id, { title: form.title.trim(), type: '文本资料', content: form.content.trim(), visibility: 'PATIENT_ADMIN' }); break;
    }
    await refreshCurrentSpace();
    uni.showToast({ title: '已经记下了' });
    setTimeout(() => uni.navigateBack(), 500);
  } catch (error) { showError(error); } finally { submitting.value = false; }
}
</script>

<template><view class="page" style="padding-top:32rpx">
  <view v-if="!selectedType" class="card"><view class="card-title"><text>现在想记下哪件事？</text><text class="tag">统一发布</text></view><button v-for="item in availableActions" :key="item.id" class="action" @click="selectedType = item.id"><view><text class="row-title">{{ item.label }}</text><text class="row-meta">{{ item.desc }}</text></view><text class="arrow">›</text></button></view>
  <view v-else class="card"><view class="card-title"><text>{{ current?.label }}</text><text class="tag" @click="selectedType = ''">换一种</text></view>
    <view v-if="['event','note'].includes(selectedType)" class="field"><text class="label">标题</text><input v-model="form.title" class="input" placeholder="简短说清楚这件事" /></view>
    <view v-if="['message','notice','question','note'].includes(selectedType)" class="field"><text class="label">{{ selectedType === 'question' ? '问题' : selectedType === 'message' ? '想说的话' : '内容' }}</text><textarea v-model="form.content" class="textarea" placeholder="写在这里" /></view>
    <view v-if="selectedType === 'event'" class="field"><text class="label">地点</text><input v-model="form.content" class="input" placeholder="可选" /></view>
    <view v-if="['temperature','weight'].includes(selectedType)" class="field"><text class="label">{{ selectedType === 'temperature' ? '体温（℃）' : '体重（kg）' }}</text><input v-model="form.value" class="input" type="digit" placeholder="请输入数值" /></view>
    <view v-if="selectedType === 'symptom'" class="field"><text class="label">症状</text><view class="chips"><text v-for="tag in ['大便','腹泻','发烧','乏力','疼痛','手脚发麻']" :key="tag" class="chip" :class="{ active: form.tag === tag }" @click="form.tag = tag">{{ tag }}</text></view><input v-model="form.tag" class="input" placeholder="也可以自己填写" /></view>
    <view v-if="selectedType === 'medication'" class="field"><text class="label">药名</text><view v-if="recentMedNames.length" class="chips"><text v-for="name in recentMedNames" :key="name" class="chip" :class="{ active: form.tag === name }" @click="form.tag = name">{{ name }}</text></view><input v-model="form.tag" class="input" placeholder="例如：布洛芬" /></view>
    <view v-if="selectedType === 'medication'" class="field"><text class="label">剂量（可选）</text><input v-model="form.value" class="input" placeholder="例如：1 片 / 200mg" /></view>
    <template v-if="selectedType === 'body'"><view v-for="field in scoreFields" :key="field.key" class="score"><view><text>{{ field.label }}</text><text class="tag">{{ form[field.key] }}</text></view><slider :value="form[field.key]" min="0" max="10" activeColor="#b85f55" block-size="20" @change="setScore(field.key, $event)" /></view></template>
    <view v-if="needsDate" class="date-grid"><view class="field"><text class="label">{{ selectedType === 'notice' ? '开始日期' : '日期' }}</text><picker mode="date" :value="form.date" @change="form.date = $event.detail.value"><view class="picker">{{ form.date }}</view></picker></view><view v-if="needsDateTime" class="field"><text class="label">时间</text><picker mode="time" :value="form.time" @change="form.time = $event.detail.value"><view class="picker">{{ form.time }}</view></picker></view><view v-if="selectedType === 'notice'" class="field"><text class="label">结束日期（可选）</text><picker mode="date" :value="form.value || form.date" @change="form.value = $event.detail.value"><view class="picker">{{ form.value || '长期有效' }}</view></picker></view></view>
    <view v-if="!['message','question','note'].includes(selectedType)" class="field"><text class="label">补充说明</text><textarea v-model="form.note" class="textarea" placeholder="可选" /></view>
    <label v-if="['notice','question'].includes(selectedType)" class="check"><checkbox :checked="form.important" color="#b85f55" @click="form.important = !form.important" /> 标记为重要</label>
    <label v-if="selectedType === 'event'" class="check"><checkbox :checked="form.needsCompanion" color="#b85f55" @click="form.needsCompanion = !form.needsCompanion" /> 需要家人陪同</label>
    <view class="form-actions"><button class="primary" :loading="submitting" @click="submit()">记下来</button><button class="secondary" @click="selectedType = ''">返回选择</button></view>
  </view>
</view></template>

<style scoped lang="scss">
.action { display:flex; align-items:center; justify-content:space-between; width:100%; padding:24rpx 4rpx; border-top:1px solid #f0e5d8; background:transparent; text-align:left; line-height:1.4; }
.action:first-of-type { border-top:0; }.arrow { color:#b85f55; font-size:44rpx; }.chips { display:flex; flex-wrap:wrap; gap:12rpx; margin-bottom:16rpx; }.chip { padding:12rpx 18rpx; border:1px solid #eadbca; border-radius:999rpx; background:#fff; color:#766b62; font-size:24rpx; }.chip.active { border-color:#b85f55; background:#fde8e1; color:#b85f55; }.date-grid { display:grid; grid-template-columns:1fr 1fr; gap:18rpx; }.score { margin-bottom:24rpx; }.score > view { display:flex; justify-content:space-between; align-items:center; font-size:27rpx; font-weight:700; }.check { display:flex; align-items:center; margin:20rpx 0; color:#766b62; font-size:26rpx; }
</style>
