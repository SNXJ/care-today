package com.caretoday.api.care;

import com.caretoday.api.auth.AuthInterceptor;
import com.caretoday.api.auth.CurrentUser;
import com.caretoday.api.care.CareRequests.CreateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.CreateDoctorQuestionRequest;
import com.caretoday.api.care.CareRequests.CreateEventRequest;
import com.caretoday.api.care.CareRequests.CreateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.CreateMessageRequest;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import com.caretoday.api.care.CareRequests.CreateNoticeRequest;
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
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
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

  @PostMapping("/spaces/{spaceId}/member-invites")
  public Object createInvite(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody InviteMemberRequest request) {
    return careService.createInvite(currentUser(httpRequest).id(), spaceId, request);
  }

  @GetMapping("/member-invites/{token}")
  public Object getInvite(@PathVariable UUID token) {
    return careService.getInvite(token);
  }

  @PatchMapping("/member-invites/{token}/accept")
  public Object acceptInvite(HttpServletRequest httpRequest, @PathVariable UUID token, @RequestBody(required = false) AcceptInviteRequest request) {
    return careService.acceptInvite(currentUser(httpRequest).id(), token, request);
  }

  @PatchMapping("/spaces/{spaceId}/members/{memberId}/accept")
  public Object acceptMember(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID memberId) {
    return careService.acceptMember(currentUser(httpRequest).id(), spaceId, memberId);
  }

  @DeleteMapping("/spaces/{spaceId}/members/{memberId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void removeMember(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID memberId) {
    careService.removeMember(currentUser(httpRequest).id(), spaceId, memberId);
  }

  @DeleteMapping("/spaces/{spaceId}/leave")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void leaveSpace(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    careService.leaveSpace(currentUser(httpRequest).id(), spaceId);
  }

  @GetMapping("/spaces/{spaceId}/events")
  public Object listEvents(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listEvents(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/events")
  public Object createEvent(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateEventRequest request) {
    return careService.createEvent(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/events/{eventId}")
  public Object updateEvent(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID eventId, @Valid @RequestBody UpdateEventRequest request) {
    return careService.updateEvent(currentUser(httpRequest).id(), spaceId, eventId, request);
  }

  @DeleteMapping("/spaces/{spaceId}/events/{eventId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteEvent(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID eventId) {
    careService.deleteEvent(currentUser(httpRequest).id(), spaceId, eventId);
  }

  @GetMapping("/spaces/{spaceId}/body-records")
  public Object listBodyRecords(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listBodyRecords(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/body-records")
  public Object createBodyRecord(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateBodyRecordRequest request) {
    return careService.createBodyRecord(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/body-records/{recordId}")
  public Object updateBodyRecord(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID recordId, @Valid @RequestBody UpdateBodyRecordRequest request) {
    return careService.updateBodyRecord(currentUser(httpRequest).id(), spaceId, recordId, request);
  }

  @DeleteMapping("/spaces/{spaceId}/body-records/{recordId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteBodyRecord(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID recordId) {
    careService.deleteBodyRecord(currentUser(httpRequest).id(), spaceId, recordId);
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

  @DeleteMapping("/spaces/{spaceId}/doctor-questions/{questionId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteDoctorQuestion(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID questionId) {
    careService.deleteDoctorQuestion(currentUser(httpRequest).id(), spaceId, questionId);
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

  @PatchMapping("/spaces/{spaceId}/help-tasks/{taskId}")
  public Object updateHelpTask(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID taskId, @Valid @RequestBody UpdateHelpTaskRequest request) {
    return careService.updateHelpTask(currentUser(httpRequest).id(), spaceId, taskId, request);
  }

  @DeleteMapping("/spaces/{spaceId}/help-tasks/{taskId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteHelpTask(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID taskId) {
    careService.deleteHelpTask(currentUser(httpRequest).id(), spaceId, taskId);
  }

  @GetMapping("/spaces/{spaceId}/messages")
  public Object listMessages(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listMessages(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/messages")
  public Object createMessage(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateMessageRequest request) {
    return careService.createMessage(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/messages/{messageId}")
  public Object updateMessage(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID messageId, @Valid @RequestBody UpdateMessageRequest request) {
    return careService.updateMessage(currentUser(httpRequest).id(), spaceId, messageId, request);
  }

  @DeleteMapping("/spaces/{spaceId}/messages/{messageId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteMessage(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID messageId) {
    careService.deleteMessage(currentUser(httpRequest).id(), spaceId, messageId);
  }

  @GetMapping("/spaces/{spaceId}/notes")
  public Object listNotes(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listNotes(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/notes")
  public Object createNote(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateNoteRequest request) {
    return careService.createNote(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/notes/{noteId}")
  public Object updateNote(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID noteId, @Valid @RequestBody UpdateNoteRequest request) {
    return careService.updateNote(currentUser(httpRequest).id(), spaceId, noteId, request);
  }

  @DeleteMapping("/spaces/{spaceId}/notes/{noteId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteNote(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID noteId) {
    careService.deleteNote(currentUser(httpRequest).id(), spaceId, noteId);
  }

  @GetMapping("/spaces/{spaceId}/notices")
  public Object listNotices(HttpServletRequest httpRequest, @PathVariable UUID spaceId) {
    return careService.listNotices(currentUser(httpRequest).id(), spaceId);
  }

  @PostMapping("/spaces/{spaceId}/notices")
  public Object createNotice(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @Valid @RequestBody CreateNoticeRequest request) {
    return careService.createNotice(currentUser(httpRequest).id(), spaceId, request);
  }

  @PatchMapping("/spaces/{spaceId}/notices/{noticeId}")
  public Object updateNotice(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID noticeId, @Valid @RequestBody UpdateNoticeRequest request) {
    return careService.updateNotice(currentUser(httpRequest).id(), spaceId, noticeId, request);
  }

  @DeleteMapping("/spaces/{spaceId}/notices/{noticeId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteNotice(HttpServletRequest httpRequest, @PathVariable UUID spaceId, @PathVariable UUID noticeId) {
    careService.deleteNotice(currentUser(httpRequest).id(), spaceId, noticeId);
  }

  private CurrentUser currentUser(HttpServletRequest request) {
    return (CurrentUser) request.getAttribute(AuthInterceptor.CURRENT_USER_ATTRIBUTE);
  }
}
