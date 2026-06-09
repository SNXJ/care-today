package com.caretoday.api.care;

import com.caretoday.api.care.CareRequests.CreateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.CreateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.CreateEventRequest;
import com.caretoday.api.care.CareRequests.CreateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.CreateMessageRequest;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import com.caretoday.api.care.CareRequests.CreateSpaceRequest;
import com.caretoday.api.care.CareRequests.InviteMemberRequest;
import com.caretoday.api.care.CareRequests.UpdateDoctorQuestionRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class CareController {
  private final CareService careService;

  public CareController(CareService careService) {
    this.careService = careService;
  }

  @GetMapping("/spaces")
  public Object listSpaces() {
    return careService.listSpaces();
  }

  @PostMapping("/spaces")
  public Object createSpace(@Valid @RequestBody CreateSpaceRequest request) {
    return careService.createSpace(request);
  }

  @GetMapping("/spaces/{spaceId}")
  public Object getSpace(@PathVariable UUID spaceId) {
    return careService.getSpace(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/members")
  public Object inviteMember(@PathVariable UUID spaceId, @Valid @RequestBody InviteMemberRequest request) {
    return careService.inviteMember(spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/events")
  public Object listEvents(@PathVariable UUID spaceId) {
    return careService.listEvents(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/events")
  public Object createEvent(@PathVariable UUID spaceId, @Valid @RequestBody CreateEventRequest request) {
    return careService.createEvent(spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/body-records")
  public Object listBodyRecords(@PathVariable UUID spaceId) {
    return careService.listBodyRecords(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/body-records")
  public Object createBodyRecord(@PathVariable UUID spaceId, @Valid @RequestBody CreateBodyRecordRequest request) {
    return careService.createBodyRecord(spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/doctor-questions")
  public Object listDoctorQuestions(@PathVariable UUID spaceId) {
    return careService.listDoctorQuestions(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/doctor-questions")
  public Object createDoctorQuestion(@PathVariable UUID spaceId, @Valid @RequestBody CreateDoctorQuestionRequest request) {
    return careService.createDoctorQuestion(spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/doctor-questions/{questionId}")
  public Object updateDoctorQuestion(
      @PathVariable UUID spaceId,
      @PathVariable UUID questionId,
      @Valid @RequestBody UpdateDoctorQuestionRequest request) {
    return careService.updateDoctorQuestion(spaceId, questionId, request);
  }

  @GetMapping("/spaces/{spaceId}/help-tasks")
  public Object listHelpTasks(@PathVariable UUID spaceId) {
    return careService.listHelpTasks(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/help-tasks")
  public Object createHelpTask(@PathVariable UUID spaceId, @Valid @RequestBody CreateHelpTaskRequest request) {
    return careService.createHelpTask(spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/help-tasks/{taskId}/claim")
  public Object claimHelpTask(@PathVariable UUID spaceId, @PathVariable UUID taskId) {
    return careService.claimHelpTask(spaceId, taskId);
  }

  @GetMapping("/spaces/{spaceId}/messages")
  public Object listMessages(@PathVariable UUID spaceId) {
    return careService.listMessages(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/messages")
  public Object createMessage(@PathVariable UUID spaceId, @Valid @RequestBody CreateMessageRequest request) {
    return careService.createMessage(spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/notes")
  public Object listNotes(@PathVariable UUID spaceId) {
    return careService.listNotes(spaceId);
  }

  @PostMapping("/spaces/{spaceId}/notes")
  public Object createNote(@PathVariable UUID spaceId, @Valid @RequestBody CreateNoteRequest request) {
    return careService.createNote(spaceId, request);
  }
}
