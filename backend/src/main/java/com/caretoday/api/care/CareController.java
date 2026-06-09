package com.caretoday.api.care;

import com.caretoday.api.auth.AuthInterceptor;
import com.caretoday.api.auth.CurrentUser;
import com.caretoday.api.care.CareRequests.CreateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.CreateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.CreateEventRequest;
import com.caretoday.api.care.CareRequests.CreateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.CreateMessageRequest;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import com.caretoday.api.care.CareRequests.CreateSpaceRequest;
import com.caretoday.api.care.CareRequests.InviteMemberRequest;
import com.caretoday.api.care.CareRequests.UpdateDoctorQuestionRequest;
import jakarta.servlet.http.HttpServletRequest;
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
  public Object listSpaces(HttpServletRequest httpRequest) {
    return careService.listSpaces(currentUser(httpRequest).id());
  }

  @PostMapping("/spaces")
  public Object createSpace(HttpServletRequest httpRequest, @Valid @RequestBody CreateSpaceRequest request) {
    return careService.createSpace(currentUser(httpRequest).id(), request);
  }

  @GetMapping("/spaces/{spaceId}")
  public Object getSpace(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.getSpace(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/members")
  public Object inviteMember(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody InviteMemberRequest request) {
    return careService.inviteMember(currentUser(httpRequest).id(), spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/events")
  public Object listEvents(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listEvents(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/events")
  public Object createEvent(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateEventRequest request) {
    return careService.createEvent(currentUser(httpRequest).id(), spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/body-records")
  public Object listBodyRecords(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listBodyRecords(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/body-records")
  public Object createBodyRecord(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateBodyRecordRequest request) {
    return careService.createBodyRecord(currentUser(httpRequest).id(), spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/doctor-questions")
  public Object listDoctorQuestions(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listDoctorQuestions(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/doctor-questions")
  public Object createDoctorQuestion(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateDoctorQuestionRequest request) {
    return careService.createDoctorQuestion(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/doctor-questions/{questionId}")
  public Object updateDoctorQuestion(
      HttpServletRequest httpRequest,
      @PathVariable UUID spaceId,
      @PathVariable UUID questionId,
      @Valid @RequestBody UpdateDoctorQuestionRequest request) {
    return careService.updateDoctorQuestion(currentUser(httpRequest).id(), spaceId, questionId, request);
  }

  @GetMapping("/spaces/{spaceId}/help-tasks")
  public Object listHelpTasks(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listHelpTasks(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/help-tasks")
  public Object createHelpTask(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateHelpTaskRequest request) {
    return careService.createHelpTask(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/help-tasks/{taskId}/claim")
  public Object claimHelpTask(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID taskId) {
    return careService.claimHelpTask(currentUser(httpRequest).id(), spaceId, taskId);
  }

  @GetMapping("/spaces/{spaceId}/messages")
  public Object listMessages(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listMessages(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/messages")
  public Object createMessage(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateMessageRequest request) {
    return careService.createMessage(currentUser(httpRequest).id(), spaceId, request);
  }

  @GetMapping("/spaces/{spaceId}/notes")
  public Object listNotes(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listNotes(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/notes")
  public Object createNote(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateNoteRequest request) {
    return careService.createNote(currentUser(httpRequest).id(), spaceId, request);
  }

  private CurrentUser currentUser(HttpServletRequest request) {
    return (CurrentUser) request.getAttribute(AuthInterceptor.CURRENT_USER_ATTRIBUTE);
  }
}
