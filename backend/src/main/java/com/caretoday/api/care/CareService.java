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
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
public class CareService {
  private final List<CareSpace> spaces = new ArrayList<>();
  private final List<SpaceMember> members = new ArrayList<>();
  private final List<CareEvent> events = new ArrayList<>();
  private final List<BodyRecord> bodyRecords = new ArrayList<>();
  private final List<DoctorQuestion> questions = new ArrayList<>();
  private final List<HelpTask> tasks = new ArrayList<>();
  private final List<SupportMessage> messages = new ArrayList<>();
  private final List<CareNote> notes = new ArrayList<>();

  public List<CareSpace> listSpaces() {
    return spaces;
  }

  public CareSpace createSpace(CreateSpaceRequest request) {
    Instant now = Instant.now();
    CareSpace space = new CareSpace(UUID.randomUUID(), request.name(), request.patientNickname(), request.description(), now);
    spaces.add(space);
    members.add(new SpaceMember(UUID.randomUUID(), space.id(), request.patientNickname(), CareModels.MemberRole.PATIENT_ADMIN, MemberStatus.ACTIVE, now));
    return space;
  }

  public Map<String, Object> getSpace(UUID spaceId) {
    CareSpace space = ensureSpace(spaceId);
    return Map.of(
        "space", space,
        "members", members.stream().filter(member -> member.spaceId().equals(spaceId)).toList());
  }

  public SpaceMember inviteMember(UUID spaceId, InviteMemberRequest request) {
    ensureSpace(spaceId);
    SpaceMember member = new SpaceMember(UUID.randomUUID(), spaceId, request.nickname(), request.role(), MemberStatus.PENDING, Instant.now());
    members.add(member);
    return member;
  }

  public List<CareEvent> listEvents(UUID spaceId) {
    ensureSpace(spaceId);
    return events.stream().filter(event -> event.spaceId().equals(spaceId)).toList();
  }

  public CareEvent createEvent(UUID spaceId, CreateEventRequest request) {
    ensureSpace(spaceId);
    CareEvent event = new CareEvent(UUID.randomUUID(), spaceId, request.title(), request.scheduledAt(), request.location(), request.note(), request.needsCompanion(), Instant.now());
    events.add(event);
    return event;
  }

  public List<BodyRecord> listBodyRecords(UUID spaceId) {
    ensureSpace(spaceId);
    return bodyRecords.stream().filter(record -> record.spaceId().equals(spaceId)).toList();
  }

  public Map<String, Object> createBodyRecord(UUID spaceId, CreateBodyRecordRequest request) {
    ensureSpace(spaceId);
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

  public List<DoctorQuestion> listDoctorQuestions(UUID spaceId) {
    ensureSpace(spaceId);
    return questions.stream().filter(question -> question.spaceId().equals(spaceId)).toList();
  }

  public DoctorQuestion createDoctorQuestion(UUID spaceId, CreateDoctorQuestionRequest request) {
    ensureSpace(spaceId);
    DoctorQuestion question = new DoctorQuestion(UUID.randomUUID(), spaceId, request.question(), false, request.important(), null, Instant.now());
    questions.add(question);
    return question;
  }

  public DoctorQuestion updateDoctorQuestion(UUID spaceId, UUID questionId, UpdateDoctorQuestionRequest request) {
    ensureSpace(spaceId);
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

  public List<HelpTask> listHelpTasks(UUID spaceId) {
    ensureSpace(spaceId);
    return tasks.stream().filter(task -> task.spaceId().equals(spaceId)).toList();
  }

  public HelpTask createHelpTask(UUID spaceId, CreateHelpTaskRequest request) {
    ensureSpace(spaceId);
    HelpTask task = new HelpTask(UUID.randomUUID(), spaceId, request.title(), request.type(), request.scheduledAt(), request.description(), HelpTaskStatus.PENDING, null, Instant.now());
    tasks.add(task);
    return task;
  }

  public HelpTask claimHelpTask(UUID spaceId, UUID taskId) {
    ensureSpace(spaceId);
    HelpTask current = tasks.stream()
        .filter(task -> task.spaceId().equals(spaceId) && task.id().equals(taskId))
        .findFirst()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Help task not found"));
    HelpTask updated = new HelpTask(current.id(), current.spaceId(), current.title(), current.type(), current.scheduledAt(), current.description(), HelpTaskStatus.CLAIMED, "current-user", current.createdAt());
    tasks.set(tasks.indexOf(current), updated);
    return updated;
  }

  public List<SupportMessage> listMessages(UUID spaceId) {
    ensureSpace(spaceId);
    return messages.stream().filter(message -> message.spaceId().equals(spaceId)).toList();
  }

  public SupportMessage createMessage(UUID spaceId, CreateMessageRequest request) {
    ensureSpace(spaceId);
    SupportMessage message = new SupportMessage(UUID.randomUUID(), spaceId, request.text(), "current-user", Instant.now());
    messages.add(message);
    return message;
  }

  public List<CareNote> listNotes(UUID spaceId) {
    ensureSpace(spaceId);
    return notes.stream().filter(note -> note.spaceId().equals(spaceId)).toList();
  }

  public CareNote createNote(UUID spaceId, CreateNoteRequest request) {
    ensureSpace(spaceId);
    CareNote note = new CareNote(UUID.randomUUID(), spaceId, request.title(), request.type(), request.content(), request.visibility(), Instant.now());
    notes.add(note);
    return note;
  }

  private CareSpace ensureSpace(UUID spaceId) {
    return spaces.stream()
        .filter(space -> space.id().equals(spaceId))
        .findFirst()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Care space not found"));
  }
}
