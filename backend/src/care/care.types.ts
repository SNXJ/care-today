export type MemberRole = 'patient_admin' | 'family' | 'friend' | 'readonly';
export type MemberStatus = 'active' | 'pending' | 'removed';
export type HelpTaskStatus = 'pending' | 'claimed' | 'done' | 'cancelled';

export interface CareSpace {
  id: string;
  name: string;
  patientNickname: string;
  description?: string;
  createdAt: string;
}

export interface SpaceMember {
  id: string;
  spaceId: string;
  nickname: string;
  role: MemberRole;
  status: MemberStatus;
  joinedAt: string;
}

export interface CareEvent {
  id: string;
  spaceId: string;
  title: string;
  scheduledAt: string;
  location?: string;
  note?: string;
  needsCompanion: boolean;
  createdAt: string;
}

export interface BodyRecord {
  id: string;
  spaceId: string;
  painScore: number;
  fatigueScore: number;
  sleepScore: number;
  moodScore: number;
  appetiteScore: number;
  temperature: number;
  note?: string;
  recordDate: string;
  createdAt: string;
}

export interface DoctorQuestion {
  id: string;
  spaceId: string;
  question: string;
  asked: boolean;
  important: boolean;
  doctorAnswer?: string;
  createdAt: string;
}

export interface HelpTask {
  id: string;
  spaceId: string;
  title: string;
  type: string;
  scheduledAt?: string;
  description?: string;
  status: HelpTaskStatus;
  claimedBy?: string;
  createdAt: string;
}

export interface SupportMessage {
  id: string;
  spaceId: string;
  text: string;
  author: string;
  createdAt: string;
}

export interface CareNote {
  id: string;
  spaceId: string;
  title: string;
  type: string;
  content?: string;
  visibility: 'patient_admin' | 'members';
  createdAt: string;
}
