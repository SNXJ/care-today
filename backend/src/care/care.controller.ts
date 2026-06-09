import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
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
import { CareService } from './care.service';

@Controller()
export class CareController {
  constructor(private readonly careService: CareService) {}

  @Get('spaces')
  listSpaces() {
    return this.careService.listSpaces();
  }

  @Post('spaces')
  createSpace(@Body() dto: CreateSpaceDto) {
    return this.careService.createSpace(dto);
  }

  @Get('spaces/:spaceId')
  getSpace(@Param('spaceId') spaceId: string) {
    return this.careService.getSpace(spaceId);
  }

  @Post('spaces/:spaceId/members')
  inviteMember(@Param('spaceId') spaceId: string, @Body() dto: InviteMemberDto) {
    return this.careService.inviteMember(spaceId, dto);
  }

  @Get('spaces/:spaceId/events')
  listEvents(@Param('spaceId') spaceId: string) {
    return this.careService.listEvents(spaceId);
  }

  @Post('spaces/:spaceId/events')
  createEvent(@Param('spaceId') spaceId: string, @Body() dto: CreateEventDto) {
    return this.careService.createEvent(spaceId, dto);
  }

  @Get('spaces/:spaceId/body-records')
  listBodyRecords(@Param('spaceId') spaceId: string) {
    return this.careService.listBodyRecords(spaceId);
  }

  @Post('spaces/:spaceId/body-records')
  createBodyRecord(@Param('spaceId') spaceId: string, @Body() dto: CreateBodyRecordDto) {
    return this.careService.createBodyRecord(spaceId, dto);
  }

  @Get('spaces/:spaceId/doctor-questions')
  listDoctorQuestions(@Param('spaceId') spaceId: string) {
    return this.careService.listDoctorQuestions(spaceId);
  }

  @Post('spaces/:spaceId/doctor-questions')
  createDoctorQuestion(@Param('spaceId') spaceId: string, @Body() dto: CreateDoctorQuestionDto) {
    return this.careService.createDoctorQuestion(spaceId, dto);
  }

  @Patch('spaces/:spaceId/doctor-questions/:questionId')
  updateDoctorQuestion(
    @Param('spaceId') spaceId: string,
    @Param('questionId') questionId: string,
    @Body() dto: UpdateDoctorQuestionDto,
  ) {
    return this.careService.updateDoctorQuestion(spaceId, questionId, dto);
  }

  @Get('spaces/:spaceId/help-tasks')
  listHelpTasks(@Param('spaceId') spaceId: string) {
    return this.careService.listHelpTasks(spaceId);
  }

  @Post('spaces/:spaceId/help-tasks')
  createHelpTask(@Param('spaceId') spaceId: string, @Body() dto: CreateHelpTaskDto) {
    return this.careService.createHelpTask(spaceId, dto);
  }

  @Patch('spaces/:spaceId/help-tasks/:taskId/claim')
  claimHelpTask(@Param('spaceId') spaceId: string, @Param('taskId') taskId: string) {
    return this.careService.claimHelpTask(spaceId, taskId);
  }

  @Get('spaces/:spaceId/messages')
  listMessages(@Param('spaceId') spaceId: string) {
    return this.careService.listMessages(spaceId);
  }

  @Post('spaces/:spaceId/messages')
  createMessage(@Param('spaceId') spaceId: string, @Body() dto: CreateMessageDto) {
    return this.careService.createMessage(spaceId, dto);
  }

  @Get('spaces/:spaceId/notes')
  listNotes(@Param('spaceId') spaceId: string) {
    return this.careService.listNotes(spaceId);
  }

  @Post('spaces/:spaceId/notes')
  createNote(@Param('spaceId') spaceId: string, @Body() dto: CreateNoteDto) {
    return this.careService.createNote(spaceId, dto);
  }
}
