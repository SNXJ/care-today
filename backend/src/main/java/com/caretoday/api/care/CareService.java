package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.BodyRecord;
import com.caretoday.api.care.CareModels.CareEvent;
import com.caretoday.api.care.CareModels.CareNote;
import com.caretoday.api.care.CareModels.CareSpace;
import com.caretoday.api.care.CareModels.DoctorQuestion;
import com.caretoday.api.care.CareModels.HelpTask;
import com.caretoday.api.care.CareModels.MemberStatus;
import com.caretoday.api.care.CareModels.SpaceMember;
import com.caretoday.api.care.CareModels.SupportMessage;
import com.caretoday.api.care.CareRequests.CreateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.CreateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.CreateEventRequest;
import com.caretoday.api.care.CareRequests.CreateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.CreateMessageRequest;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import com.caretoday.api.care.CareRequests.CreateSpaceRequest;
import com.caretoday.api.care.CareRequests.InviteMemberRequest;
import com.caretoday.api.care.CareRequests.UpdateDoctorQuestionRequest;
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
    return Map.of(
        "space", space,
        "members", careRepository.listMembers(spaceId));
  }

  public SpaceMember inviteMember(UUID currentUserId, UUID spaceId, InviteMemberRequest request) {
    ensureAdmin(spaceId, currentUserId);
    SpaceMember member = careRepository.addMember(spaceId, null, request.nickname(), request.role(), MemberStatus.PENDING);
    careRepository.audit(spaceId, currentUserId, "member.invite", "space_member", member.id());
    return member;
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
            request.asked(),
            request.doctorAnswer(),
            request.important())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor question not found"));
    careRepository.audit(spaceId, currentUserId, "doctor_question.update", "doctor_question", question.id());
    return question;
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

  public List<SupportMessage> listMessages(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listMessages(spaceId);
  }

  public SupportMessage createMessage(UUID currentUserId, UUID spaceId, CreateMessageRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    SupportMessage message = careRepository.createMessage(spaceId, currentUserId, request.text());
    careRepository.audit(spaceId, currentUserId, "message.create", "message", message.id());
    return message;
  }

  public List<CareNote> listNotes(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return careRepository.listNotes(spaceId);
  }

  public CareNote createNote(UUID currentUserId, UUID spaceId, CreateNoteRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareNote note = careRepository.createNote(spaceId, currentUserId, request);
    careRepository.audit(spaceId, currentUserId, "note.create", "note", note.id());
    return note;
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
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "admin permission required");
    }
  }
}
