import { Injectable, NotFoundException } from '@nestjs/common';
import {
  CreateBodyRecordDto,
  CreateDoctorQuestionDto,
  CreateEventDto,
  CreateHelpTaskDto,
  CreateMessageDto,
  CreateNoteDto,
  CreateSpaceDto,
  InviteMemberDto,
  UpdateDoctorQuestionDto,
} from './care.dto';
import { BodyRecord, CareEvent, CareNote, CareSpace, DoctorQuestion, HelpTask, SpaceMember, SupportMessage } from './care.types';

@Injectable()
export class CareService {
  private spaces: CareSpace[] = [];
  private members: SpaceMember[] = [];
  private events: CareEvent[] = [];
  private bodyRecords: BodyRecord[] = [];
  private questions: DoctorQuestion[] = [];
  private tasks: HelpTask[] = [];
  private messages: SupportMessage[] = [];
  private notes: CareNote[] = [];

  createSpace(dto: CreateSpaceDto) {
    const now = new Date().toISOString();
    const space: CareSpace = {
      id: crypto.randomUUID(),
      name: dto.name,
      patientNickname: dto.patientNickname,
      description: dto.description,
      createdAt: now,
    };
    this.spaces.push(space);
    this.members.push({
      id: crypto.randomUUID(),
      spaceId: space.id,
      nickname: dto.patientNickname,
      role: 'patient_admin',
      status: 'active',
      joinedAt: now,
    });
    return space;
  }

  listSpaces() {
    return this.spaces;
  }

  getSpace(spaceId: string) {
    const space = this.spaces.find((item) => item.id === spaceId);
    if (!space) {
      throw new NotFoundException('Care space not found');
    }
    return {
      ...space,
      members: this.members.filter((item) => item.spaceId === spaceId),
    };
  }

  inviteMember(spaceId: string, dto: InviteMemberDto) {
    this.ensureSpace(spaceId);
    const member: SpaceMember = {
      id: crypto.randomUUID(),
      spaceId,
      nickname: dto.nickname,
      role: dto.role,
      status: 'pending',
      joinedAt: new Date().toISOString(),
    };
    this.members.push(member);
    return member;
  }

  listEvents(spaceId: string) {
    this.ensureSpace(spaceId);
    return this.events.filter((item) => item.spaceId === spaceId);
  }

  createEvent(spaceId: string, dto: CreateEventDto) {
    this.ensureSpace(spaceId);
    const event: CareEvent = {
      id: crypto.randomUUID(),
      spaceId,
      title: dto.title,
      scheduledAt: dto.scheduledAt,
      location: dto.location,
      note: dto.note,
      needsCompanion: dto.needsCompanion ?? false,
      createdAt: new Date().toISOString(),
    };
    this.events.push(event);
    return event;
  }

  listBodyRecords(spaceId: string) {
    this.ensureSpace(spaceId);
    return this.bodyRecords.filter((item) => item.spaceId === spaceId);
  }

  createBodyRecord(spaceId: string, dto: CreateBodyRecordDto) {
    this.ensureSpace(spaceId);
    const record: BodyRecord = {
      id: crypto.randomUUID(),
      spaceId,
      ...dto,
      createdAt: new Date().toISOString(),
    };
    this.bodyRecords.push(record);
    return {
      ...record,
      medicalBoundary: 'This record is for review and appointment preparation only. It does not diagnose or assess treatment risk.',
    };
  }

  listDoctorQuestions(spaceId: string) {
    this.ensureSpace(spaceId);
    return this.questions.filter((item) => item.spaceId === spaceId);
  }

  createDoctorQuestion(spaceId: string, dto: CreateDoctorQuestionDto) {
    this.ensureSpace(spaceId);
    const question: DoctorQuestion = {
      id: crypto.randomUUID(),
      spaceId,
      question: dto.question,
      asked: false,
      important: dto.important ?? false,
      createdAt: new Date().toISOString(),
    };
    this.questions.push(question);
    return question;
  }

  updateDoctorQuestion(spaceId: string, questionId: string, dto: UpdateDoctorQuestionDto) {
    this.ensureSpace(spaceId);
    const question = this.questions.find((item) => item.spaceId === spaceId && item.id === questionId);
    if (!question) {
      throw new NotFoundException('Doctor question not found');
    }
    Object.assign(question, dto);
    return question;
  }

  listHelpTasks(spaceId: string) {
    this.ensureSpace(spaceId);
    return this.tasks.filter((item) => item.spaceId === spaceId);
  }

  createHelpTask(spaceId: string, dto: CreateHelpTaskDto) {
    this.ensureSpace(spaceId);
    const task: HelpTask = {
      id: crypto.randomUUID(),
      spaceId,
      title: dto.title,
      type: dto.type,
      scheduledAt: dto.scheduledAt,
      description: dto.description,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    this.tasks.push(task);
    return task;
  }

  claimHelpTask(spaceId: string, taskId: string) {
    this.ensureSpace(spaceId);
    const task = this.tasks.find((item) => item.spaceId === spaceId && item.id === taskId);
    if (!task) {
      throw new NotFoundException('Help task not found');
    }
    task.status = 'claimed';
    task.claimedBy = 'current-user';
    return task;
  }

  listMessages(spaceId: string) {
    this.ensureSpace(spaceId);
    return this.messages.filter((item) => item.spaceId === spaceId);
  }

  createMessage(spaceId: string, dto: CreateMessageDto) {
    this.ensureSpace(spaceId);
    const message: SupportMessage = {
      id: crypto.randomUUID(),
      spaceId,
      text: dto.text,
      author: 'current-user',
      createdAt: new Date().toISOString(),
    };
    this.messages.push(message);
    return message;
  }

  listNotes(spaceId: string) {
    this.ensureSpace(spaceId);
    return this.notes.filter((item) => item.spaceId === spaceId);
  }

  createNote(spaceId: string, dto: CreateNoteDto) {
    this.ensureSpace(spaceId);
    const note: CareNote = {
      id: crypto.randomUUID(),
      spaceId,
      ...dto,
      createdAt: new Date().toISOString(),
    };
    this.notes.push(note);
    return note;
  }

  private ensureSpace(spaceId: string) {
    if (!this.spaces.some((item) => item.id === spaceId)) {
      throw new NotFoundException('Care space not found');
    }
  }
}
