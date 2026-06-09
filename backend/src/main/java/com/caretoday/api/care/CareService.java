package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.BodyRecord;
import com.caretoday.api.care.CareModels.CareEvent;
import com.caretoday.api.care.CareModels.CareNote;
import com.caretoday.api.care.CareModels.CareSpace;
import com.caretoday.api.care.CareModels.DoctorQuestion;
import com.caretoday.api.care.CareModels.HelpTask;
import com.caretoday.api.care.CareModels.HelpTaskStatus;
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
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CareService {
  private final CareRepository careRepository;
  private final List<CareEvent> events = new ArrayList<>();
  private final List<BodyRecord> bodyRecords = new ArrayList<>();
  private final List<DoctorQuestion> questions = new ArrayList<>();
  private final List<HelpTask> tasks = new ArrayList<>();
  private final List<SupportMessage> messages = new ArrayList<>();
  private final List<CareNote> notes = new ArrayList<>();

  public CareService(CareRepository careRepository) {
    this.careRepository = careRepository;
  }

  public List<CareSpace> listSpaces(UUID currentUserId) {
    return careRepository.listSpacesForUser(currentUserId);
  }

  public CareSpace createSpace(UUID currentUserId, CreateSpaceRequest request) {
    CareSpace space = careRepository.createSpace(currentUserId, request.name(), request.patientNickname(), request.description());
    careRepository.addMember(space.id(), currentUserId, request.patientNickname(), CareModels.MemberRole.PATIENT_ADMIN, MemberStatus.ACTIVE);
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
    return careRepository.addMember(spaceId, null, request.nickname(), request.role(), MemberStatus.PENDING);
  }

  public List<CareEvent> listEvents(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return events.stream().filter(event -> event.spaceId().equals(spaceId)).toList();
  }

  public CareEvent createEvent(UUID currentUserId, UUID spaceId, CreateEventRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareEvent event = new CareEvent(UUID.randomUUID(), spaceId, request.title(), request.scheduledAt(), request.location(), request.note(), request.needsCompanion(), Instant.now());
    events.add(event);
    return event;
  }

  public List<BodyRecord> listBodyRecords(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return bodyRecords.stream().filter(record -> record.spaceId().equals(spaceId)).toList();
  }

  public Map<String, Object> createBodyRecord(UUID currentUserId, UUID spaceId, CreateBodyRecordRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    BodyRecord record = new BodyRecord(
        UUID.randomUUID(),
        spaceId,
        request.painScore(),
        request.fatigueScore(),
        request.sleepScore(),
        request.moodScore(),
        request.appetiteScore(),
        request.temperature(),
        request.note(),
        request.recordDate(),
        Instant.now());
    bodyRecords.add(record);
    return Map.of(
        "record", record,
        "medicalBoundary", "This record is for review and appointment preparation only. It does not diagnose or assess treatment risk.");
  }

  public List<DoctorQuestion> listDoctorQuestions(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return questions.stream().filter(question -> question.spaceId().equals(spaceId)).toList();
  }

  public DoctorQuestion createDoctorQuestion(UUID currentUserId, UUID spaceId, CreateDoctorQuestionRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    DoctorQuestion question = new DoctorQuestion(UUID.randomUUID(), spaceId, request.question(), false, request.important(), null, Instant.now());
    questions.add(question);
    return question;
  }

  public DoctorQuestion updateDoctorQuestion(UUID currentUserId, UUID spaceId, UUID questionId, UpdateDoctorQuestionRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    DoctorQuestion current = questions.stream()
        .filter(question -> question.spaceId().equals(spaceId) && question.id().equals(questionId))
        .findFirst()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor question not found"));
    DoctorQuestion updated = new DoctorQuestion(
        current.id(),
        current.spaceId(),
        current.question(),
        request.asked() == null ? current.asked() : request.asked(),
        request.important() == null ? current.important() : request.important(),
        request.doctorAnswer() == null ? current.doctorAnswer() : request.doctorAnswer(),
        current.createdAt());
    questions.set(questions.indexOf(current), updated);
    return updated;
  }

  public List<HelpTask> listHelpTasks(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return tasks.stream().filter(task -> task.spaceId().equals(spaceId)).toList();
  }

  public HelpTask createHelpTask(UUID currentUserId, UUID spaceId, CreateHelpTaskRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    HelpTask task = new HelpTask(UUID.randomUUID(), spaceId, request.title(), request.type(), request.scheduledAt(), request.description(), HelpTaskStatus.PENDING, null, Instant.now());
    tasks.add(task);
    return task;
  }

  public HelpTask claimHelpTask(UUID currentUserId, UUID spaceId, UUID taskId) {
    ensureActiveMember(spaceId, currentUserId);
    HelpTask current = tasks.stream()
        .filter(task -> task.spaceId().equals(spaceId) && task.id().equals(taskId))
        .findFirst()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Help task not found"));
    HelpTask updated = new HelpTask(current.id(), current.spaceId(), current.title(), current.type(), current.scheduledAt(), current.description(), HelpTaskStatus.CLAIMED, "current-user", current.createdAt());
    tasks.set(tasks.indexOf(current), updated);
    return updated;
  }

  public List<SupportMessage> listMessages(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return messages.stream().filter(message -> message.spaceId().equals(spaceId)).toList();
  }

  public SupportMessage createMessage(UUID currentUserId, UUID spaceId, CreateMessageRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    SupportMessage message = new SupportMessage(UUID.randomUUID(), spaceId, request.text(), "current-user", Instant.now());
    messages.add(message);
    return message;
  }

  public List<CareNote> listNotes(UUID currentUserId, UUID spaceId) {
    ensureActiveMember(spaceId, currentUserId);
    return notes.stream().filter(note -> note.spaceId().equals(spaceId)).toList();
  }

  public CareNote createNote(UUID currentUserId, UUID spaceId, CreateNoteRequest request) {
    ensureActiveMember(spaceId, currentUserId);
    CareNote note = new CareNote(UUID.randomUUID(), spaceId, request.title(), request.type(), request.content(), request.visibility(), Instant.now());
    notes.add(note);
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
