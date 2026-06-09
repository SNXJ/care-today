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
import com.caretoday.api.care.CareRequests.UpdateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.UpdateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.UpdateEventRequest;
import com.caretoday.api.care.CareRequests.UpdateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.UpdateMessageRequest;
import com.caretoday.api.care.CareRequests.UpdateNoteRequest;
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

  public SpaceMember acceptMember(UUID currentUserId, UUID spaceId, UUID memberId) {
    careRepository.findSpace(spaceId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Care space not found"));
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
    ensureActiveMember(spaceId, currentUserId);
    SupportMessage message = careRepository.createMessage(spaceId, currentUserId, request.text());
    careRepository.audit(spaceId, currentUserId, "message.create", "message", message.id());
    return message;
  }

  public SupportMessage updateMessage(UUID currentUserId, UUID spaceId, UUID messageId, UpdateMessageRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    SupportMessage message = careRepository.updateMessage(spaceId, messageId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found"));
    careRepository.audit(spaceId, currentUserId, "message.update", "message", message.id());
    return message;
  }

  public void deleteMessage(UUID currentUserId, UUID spaceId, UUID messageId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteMessage(spaceId, messageId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found");
    }
    careRepository.audit(spaceId, currentUserId, "message.delete", "message", messageId);
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

  public CareNote updateNote(UUID currentUserId, UUID spaceId, UUID noteId, UpdateNoteRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareNote note = careRepository.updateNote(spaceId, noteId, request)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Note not found"));
    careRepository.audit(spaceId, currentUserId, "note.update", "note", note.id());
    return note;
  }

  public void deleteNote(UUID currentUserId, UUID spaceId, UUID noteId) {
    ensureActiveMember(spaceId, currentUserId);
    if (!careRepository.deleteNote(spaceId, noteId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Note not found");
    }
    careRepository.audit(spaceId, currentUserId, "note.delete", "note", noteId);
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
