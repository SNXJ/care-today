import { IsBoolean, IsDateString, IsIn, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateSpaceDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  patientNickname: string;

  @IsString()
  @IsOptional()
  description?: string;
}

export class InviteMemberDto {
  @IsString()
  @IsNotEmpty()
  nickname: string;

  @IsIn(['family', 'friend', 'readonly'])
  role: 'family' | 'friend' | 'readonly';
}

export class CreateEventDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsDateString()
  scheduledAt: string;

  @IsString()
  @IsOptional()
  location?: string;

  @IsString()
  @IsOptional()
  note?: string;

  @IsBoolean()
  @IsOptional()
  needsCompanion?: boolean;
}

export class CreateBodyRecordDto {
  @IsInt()
  @Min(0)
  @Max(10)
  painScore: number;

  @IsInt()
  @Min(0)
  @Max(10)
  fatigueScore: number;

  @IsInt()
  @Min(0)
  @Max(10)
  sleepScore: number;

  @IsInt()
  @Min(0)
  @Max(10)
  moodScore: number;

  @IsInt()
  @Min(0)
  @Max(10)
  appetiteScore: number;

  @IsNumber()
  @Min(34)
  @Max(42)
  temperature: number;

  @IsString()
  @IsOptional()
  note?: string;

  @IsDateString()
  recordDate: string;
}

export class CreateDoctorQuestionDto {
  @IsString()
  @IsNotEmpty()
  question: string;

  @IsBoolean()
  @IsOptional()
  important?: boolean;
}

export class UpdateDoctorQuestionDto {
  @IsBoolean()
  @IsOptional()
  asked?: boolean;

  @IsString()
  @IsOptional()
  doctorAnswer?: string;

  @IsBoolean()
  @IsOptional()
  important?: boolean;
}

export class CreateHelpTaskDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsIn(['陪诊', '做饭', '接送', '买药', '整理报告', '照顾家人', '其他'])
  type: string;

  @IsDateString()
  @IsOptional()
  scheduledAt?: string;

  @IsString()
  @IsOptional()
  description?: string;
}

export class CreateMessageDto {
  @IsString()
  @IsNotEmpty()
  text: string;
}

export class CreateNoteDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsIn(['报告名称记录', '用药记录', '医嘱备注', '文本资料'])
  type: string;

  @IsString()
  @IsOptional()
  content?: string;

  @IsIn(['patient_admin', 'members'])
  visibility: 'patient_admin' | 'members';
}
