package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.BodyRecord;
import com.caretoday.api.care.CareModels.CareEvent;
import com.caretoday.api.care.CareModels.CareNote;
import com.caretoday.api.care.CareModels.CareNotice;
import com.caretoday.api.care.CareModels.CareSpace;
import com.caretoday.api.care.CareModels.DoctorQuestion;
import com.caretoday.api.care.CareModels.HelpTask;
import com.caretoday.api.care.CareModels.MemberStatus;
import com.caretoday.api.care.CareModels.SpaceInvite;
import com.caretoday.api.care.CareModels.SpaceMember;
import com.caretoday.api.care.CareModels.SupportMessage;
import com.caretoday.api.care.CareModels.MedicationLog;
import com.caretoday.api.care.CareModels.SymptomEvent;
import com.caretoday.api.care.CareRequests.CreateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.CreateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.CreateEventRequest;
import com.caretoday.api.care.CareRequests.CreateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.CreateMessageRequest;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import com.caretoday.api.care.CareRequests.CreateNoticeRequest;
import com.caretoday.api.care.CareRequests.CreateMedicationLogRequest;
import com.caretoday.api.care.CareRequests.CreateSymptomEventRequest;
import com.caretoday.api.care.CareRequests.CreateSpaceRequest;
import com.caretoday.api.care.CareRequests.AcceptInviteRequest;
import com.caretoday.api.care.CareRequests.InviteMemberRequest;
import com.caretoday.api.care.CareRequests.UpdateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.UpdateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.UpdateEventRequest;
import com.caretoday.api.care.CareRequests.UpdateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.UpdateMessageRequest;
import com.caretoday.api.care.CareRequests.UpdateNoteRequest;
import com.caretoday.api.care.CareRequests.UpdateNoticeRequest;
import com.caretoday.api.care.CareRequests.UpdateMedicationLogRequest;
import com.caretoday.api.care.CareRequests.UpdateSymptomEventRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CareService {
  private final CareRepository careRepository;

  public CareService(CareRepository careRepository) {
    this.careRepository = careRepository;
  }

  public List<CareSpace> listSpaces(UUID currentUserId) {
    return careRepository.listSpacesForUser(currentUserId);
  }

  public CareSpace createSpace(UUID currentUserId, CreateSpaceRequest request) {
    CareSpace space = careRepository.createSpace(currentUserId, request.name(), request.patientNickname(), request.description());
    careRepository.addMember(space.id(), currentUserId, request.patientNickname(), CareModels.MemberRole.PATIENT_ADMIN, MemberStatus.ACTIVE);
    careRepository.audit(space.id(), currentUserId, "space.create", "care_space", space.id());
    return space;
  }

  public Map<String, Object> getSpace(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    CareSpace space = careRepository.findSpace(spaceId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Care space not found"));
    String currentRole = careRepository.findMembership(spaceId, currentUserId)
        .map(member -> member.role().name())
        .orElse("");
    return Map.of(
        "space", space,
        "members", careRepository.listMembers(spaceId),
        "currentRole", currentRole);
  }

  public SpaceMember inviteMember(UUID currentUserId, UUID spaceId, InviteMemberRequest request) {
    ensureAdmin(spaceId, currentUserId);
    SpaceMember member = careRepository.addMember(spaceId, null, request.nickname(), request.role(), MemberStatus.PENDING);
    careRepository.audit(spaceId, currentUserId, "member.invite", "space_member", member.id());
    return member;
  }

  public SpaceInvite createInvite(UUID currentUserId, UUID spaceId, InviteMemberRequest request) {
    ensureAdmin(spaceId, currentUserId);
    if (request.role() == CareModels.MemberRole.PATIENT_ADMIN) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "邀请不能授予患者/管理员权限");
    }
    SpaceInvite invite = careRepository.createInvite(spaceId, currentUserId, request.nickname(), request.role());
    careRepository.audit(spaceId, currentUserId, "member.invite.create", "space_invite", invite.token());
    return invite;
  }

  public Map<String, Object> getInvite(UUID token) {
    SpaceInvite invite = careRepository.findInvite(token)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "邀请链接无效或已过期"));
    return Map.of(
        "token", invite.token(),
        "nickname", invite.nickname(),
        "role", invite.role(),
        "expiresAt", invite.expiresAt());
  }

  public SpaceMember acceptInvite(UUID currentUserId, UUID token, AcceptInviteRequest request) {
    SpaceInvite invite = careRepository.findInvite(token)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "邀请链接无效或已过期"));
    SpaceMember member = careRepository.acceptInvite(token, currentUserId, request == null ? null : request.nickname())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "邀请链接无效或已过期"));
    careRepository.audit(invite.spaceId(), currentUserId, "member.invite.accept", "space_invite", token);
    return member;
  }

  public SpaceMember acceptMember(UUID currentUserId, UUID spaceId, UUID memberId) {
    careRepository.findSpace(spaceId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Care space not found"));
    if (careRepository.isActiveMember(spaceId, currentUserId)) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "already joined this care space");
    }
    SpaceMember member = careRepository.acceptMember(spaceId, memberId, currentUserId, null)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pending member not found"));
    careRepository.audit(spaceId, currentUserId, "member.accept", "space_member", member.id());
    return member;
  }

  public void removeMember(UUID currentUserId, UUID spaceId, UUID memberId) {
    SpaceMember target = careRepository.findMemberInSpace(spaceId, memberId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Member not found"));
    SpaceMember current = careRepository.findMembership(spaceId, currentUserId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "no access to this care space"));
    boolean self = current.id().equals(memberId);
    if (!self) {
      ensureAdmin(spaceId, currentUserId);
    }
    if (target.role() == CareModels.MemberRole.PATIENT_ADMIN && !self) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "cannot remove another admin");
    }
    if (target.role() == CareModels.MemberRole.PATIENT_ADMIN && careRepository.countActiveAdmins(spaceId) <= 1) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "cannot remove the last admin");
    }
    if (!careRepository.removeMember(spaceId, memberId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Member not found");
    }
    careRepository.audit(spaceId, currentUserId, self ? "member.leave" : "member.remove", "space_member", memberId);
  }

  public void leaveSpace(UUID currentUserId, UUID spaceId) {
    SpaceMember member = careRepository.findMembership(spaceId, currentUserId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Membership not found"));
    removeMember(currentUserId, spaceId, member.id());
  }

  public List<CareEvent> listEvents(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listEvents(spaceId);
  }

  public CareEvent createEvent(UUID currentUserId, UUID spaceId, CreateEventRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareEvent event = careRepository.createEvent(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "event.create", "event", event.id());
    return event;
  }

  public CareEvent updateEvent(UUID currentUserId, UUID spaceId, UUID eventId, UpdateEventRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareEvent event = careRepository.updateEvent(spaceId, eventId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Event not found"));
    careRepository.audit(spaceId, currentUserId, "event.update", "event", event.id());
    return event;
  }

  public void deleteEvent(UUID currentUserId, UUID spaceId, UUID eventId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteEvent(spaceId, eventId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Event not found");
    }
    careRepository.audit(spaceId, currentUserId, "event.delete", "event", eventId);
  }

  public List<BodyRecord> listBodyRecords(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listBodyRecords(spaceId);
  }

  public Map<String, Object> createBodyRecord(UUID currentUserId, UUID spaceId, CreateBodyRecordRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    BodyRecord record = careRepository.createBodyRecord(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "body_record.create", "body_record", record.id());
    return Map.of(
        "record", record,
        "medicalBoundary", "This record is for review and appointment preparation only. It does not diagnose or assess treatment risk.");
  }

  public BodyRecord updateBodyRecord(UUID currentUserId, UUID spaceId, UUID recordId, UpdateBodyRecordRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    BodyRecord record = careRepository.updateBodyRecord(spaceId, recordId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Body record not found"));
    careRepository.audit(spaceId, currentUserId, "body_record.update", "body_record", record.id());
    return record;
  }

  public void deleteBodyRecord(UUID currentUserId, UUID spaceId, UUID recordId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteBodyRecord(spaceId, recordId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Body record not found");
    }
    careRepository.audit(spaceId, currentUserId, "body_record.delete", "body_record", recordId);
  }

  public List<DoctorQuestion> listDoctorQuestions(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listDoctorQuestions(spaceId);
  }

  public DoctorQuestion createDoctorQuestion(UUID currentUserId, UUID spaceId, CreateDoctorQuestionRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    DoctorQuestion question = careRepository.createDoctorQuestion(spaceId, currentUserId, request.question(), request.important());
    careRepository.audit(spaceId, currentUserId, "doctor_question.create", "doctor_question", question.id());
    return question;
  }

  public DoctorQuestion updateDoctorQuestion(UUID currentUserId, UUID spaceId, UUID questionId, UpdateDoctorQuestionRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    DoctorQuestion question = careRepository.updateDoctorQuestion(
            spaceId,
            questionId,
            request.question(),
            request.asked(),
            request.doctorAnswer(),
            request.important())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor question not found"));
    careRepository.audit(spaceId, currentUserId, "doctor_question.update", "doctor_question", question.id());
    return question;
  }

  public void deleteDoctorQuestion(UUID currentUserId, UUID spaceId, UUID questionId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteDoctorQuestion(spaceId, questionId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor question not found");
    }
    careRepository.audit(spaceId, currentUserId, "doctor_question.delete", "doctor_question", questionId);
  }

  public List<HelpTask> listHelpTasks(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listHelpTasks(spaceId);
  }

  public HelpTask createHelpTask(UUID currentUserId, UUID spaceId, CreateHelpTaskRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    HelpTask task = careRepository.createHelpTask(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "help_task.create", "help_task", task.id());
    return task;
  }

  public HelpTask claimHelpTask(UUID currentUserId, UUID spaceId, UUID taskId) {
    ensureActiveMember(spaceId, currentUserId);
    HelpTask task = careRepository.claimHelpTask(spaceId, taskId, currentUserId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Help task not found or already claimed"));
    careRepository.audit(spaceId, currentUserId, "help_task.claim", "help_task", task.id());
    return task;
  }

  public HelpTask updateHelpTask(UUID currentUserId, UUID spaceId, UUID taskId, UpdateHelpTaskRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    HelpTask task = careRepository.updateHelpTask(spaceId, taskId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Help task not found"));
    careRepository.audit(spaceId, currentUserId, "help_task.update", "help_task", task.id());
    return task;
  }

  public void deleteHelpTask(UUID currentUserId, UUID spaceId, UUID taskId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteHelpTask(spaceId, taskId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Help task not found");
    }
    careRepository.audit(spaceId, currentUserId, "help_task.delete", "help_task", taskId);
  }

  public List<SupportMessage> listMessages(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listMessages(spaceId);
  }

  public SupportMessage createMessage(UUID currentUserId, UUID spaceId, CreateMessageRequest request) {
    // 陪伴协作：所有活跃成员都可以在「分享」里发动态（编辑/删除仍限管理员）。
    ensureActiveMember(spaceId, currentUserId);
    SupportMessage message =
        careRepository.createMessage(spaceId, currentUserId, request.text(), request.photos());
    careRepository.audit(spaceId, currentUserId, "message.create", "message", message.id());
    return message;
  }

  // —— 图片附件 ——
  public UUID uploadFile(UUID currentUserId, UUID spaceId, String contentType, byte[] data) {
    ensureActiveMember(spaceId, currentUserId);
    if (contentType == null || !contentType.toLowerCase().startsWith("image/")) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "只支持上传图片");
    }
    if (data.length == 0 || data.length > 8 * 1024 * 1024) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "图片大小需在 8MB 以内");
    }
    UUID fileId = careRepository.createFile(spaceId, currentUserId, contentType, data);
    careRepository.audit(spaceId, currentUserId, "file.upload", "uploaded_file", fileId);
    return fileId;
  }

  public CareModels.UploadedFile getFile(UUID fileId) {
    return careRepository.findFile(fileId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found"));
  }

  public SupportMessage updateMessage(UUID currentUserId, UUID spaceId, UUID messageId, UpdateMessageRequest request) {
    ensureAdmin(spaceId, currentUserId);
    SupportMessage message = careRepository.updateMessage(spaceId, messageId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found"));
    careRepository.audit(spaceId, currentUserId, "message.update", "message", message.id());
    return message;
  }

  public void deleteMessage(UUID currentUserId, UUID spaceId, UUID messageId) {
    ensureAdmin(spaceId, currentUserId);
    if (!careRepository.deleteMessage(spaceId, messageId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found");
    }
    careRepository.audit(spaceId, currentUserId, "message.delete", "message", messageId);
  }

  public List<CareNote> listNotes(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listNotes(spaceId, careRepository.isAdmin(spaceId, currentUserId));
  }

  public CareNote createNote(UUID currentUserId, UUID spaceId, CreateNoteRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    if (request.visibility() == CareModels.NoteVisibility.PATIENT_ADMIN && !careRepository.isAdmin(spaceId, currentUserId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有患者/管理员可以保存私密资料");
    }
    CareNote note = careRepository.createNote(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "note.create", "note", note.id());
    return note;
  }

  public CareNote updateNote(UUID currentUserId, UUID spaceId, UUID noteId, UpdateNoteRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    ensureNoteWritable(spaceId, currentUserId, noteId, request.visibility());
    CareNote note = careRepository.updateNote(spaceId, noteId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Note not found"));
    careRepository.audit(spaceId, currentUserId, "note.update", "note", note.id());
    return note;
  }

  public void deleteNote(UUID currentUserId, UUID spaceId, UUID noteId) {
    ensureActiveMember(spaceId, currentUserId);
    ensureNoteWritable(spaceId, currentUserId, noteId, null);
    if (!careRepository.deleteNote(spaceId, noteId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Note not found");
    }
    careRepository.audit(spaceId, currentUserId, "note.delete", "note", noteId);
  }

  public List<CareNotice> listNotices(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listNotices(spaceId);
  }

  public CareNotice createNotice(UUID currentUserId, UUID spaceId, CreateNoticeRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareNotice notice = careRepository.createNotice(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "notice.create", "care_notice", notice.id());
    return notice;
  }

  public CareNotice updateNotice(UUID currentUserId, UUID spaceId, UUID noticeId, UpdateNoticeRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareNotice notice = careRepository.updateNotice(spaceId, noticeId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Notice not found"));
    careRepository.audit(spaceId, currentUserId, "notice.update", "care_notice", notice.id());
    return notice;
  }

  public void deleteNotice(UUID currentUserId, UUID spaceId, UUID noticeId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteNotice(spaceId, noticeId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Notice not found");
    }
    careRepository.audit(spaceId, currentUserId, "notice.delete", "care_notice", noticeId);
  }

  public List<SymptomEvent> listSymptomEvents(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listSymptomEvents(spaceId);
  }

  public SymptomEvent createSymptomEvent(UUID currentUserId, UUID spaceId, CreateSymptomEventRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    SymptomEvent symptom = careRepository.createSymptomEvent(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "symptom.create", "symptom_event", symptom.id());
    return symptom;
  }

  public SymptomEvent updateSymptomEvent(UUID currentUserId, UUID spaceId, UUID symptomId, UpdateSymptomEventRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    SymptomEvent symptom = careRepository.updateSymptomEvent(spaceId, symptomId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Symptom event not found"));
    careRepository.audit(spaceId, currentUserId, "symptom.update", "symptom_event", symptom.id());
    return symptom;
  }

  public void deleteSymptomEvent(UUID currentUserId, UUID spaceId, UUID symptomId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteSymptomEvent(spaceId, symptomId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Symptom event not found");
    }
    careRepository.audit(spaceId, currentUserId, "symptom.delete", "symptom_event", symptomId);
  }

  public List<MedicationLog> listMedicationLogs(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listMedicationLogs(spaceId);
  }

  public MedicationLog createMedicationLog(UUID currentUserId, UUID spaceId, CreateMedicationLogRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    MedicationLog log = careRepository.createMedicationLog(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "medication.create", "medication_log", log.id());
    return log;
  }

  public MedicationLog updateMedicationLog(UUID currentUserId, UUID spaceId, UUID logId, UpdateMedicationLogRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    MedicationLog log = careRepository.updateMedicationLog(spaceId, logId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Medication log not found"));
    careRepository.audit(spaceId, currentUserId, "medication.update", "medication_log", log.id());
    return log;
  }

  public void deleteMedicationLog(UUID currentUserId, UUID spaceId, UUID logId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteMedicationLog(spaceId, logId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Medication log not found");
    }
    careRepository.audit(spaceId, currentUserId, "medication.delete", "medication_log", logId);
  }

  private void ensureActiveMember(UUID spaceId, UUID currentUserId) {
    careRepository.findSpace(spaceId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Care space not found"));
    if (!careRepository.isActiveMember(spaceId, currentUserId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "no access to this care space");
    }
  }

  private void ensureAdmin(UUID spaceId, UUID currentUserId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.isAdmin(spaceId, currentUserId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有患者/管理员可以操作");
    }
  }

  private void ensureNoteWritable(UUID spaceId, UUID currentUserId, UUID noteId, CareModels.NoteVisibility nextVisibility) {
    CareNote note = careRepository.findNote(noteId)
        .filter(candidate -> candidate.spaceId().equals(spaceId))
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Note not found"));
    boolean admin = careRepository.isAdmin(spaceId, currentUserId);
    if (!admin && (note.visibility() == CareModels.NoteVisibility.PATIENT_ADMIN || nextVisibility == CareModels.NoteVisibility.PATIENT_ADMIN)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有患者/管理员可以操作私密资料");
    }
  }
}
