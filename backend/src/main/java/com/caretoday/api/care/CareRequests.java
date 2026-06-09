package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.MemberRole;
import com.caretoday.api.care.CareModels.HelpTaskStatus;
import com.caretoday.api.care.CareModels.NoteVisibility;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public final class CareRequests {
  private CareRequests() {}

  public record CreateSpaceRequest(
      @NotBlank String name,
      @NotBlank String patientNickname,
      String description) {}

  public record InviteMemberRequest(
      @NotBlank String nickname,
      @NotNull MemberRole role) {}

  public record AcceptInviteRequest(String nickname) {}

  public record CreateEventRequest(
      @NotBlank String title,
      @NotNull Instant scheduledAt,
      String location,
      String note,
      boolean needsCompanion) {}

  public record UpdateEventRequest(
      String title,
      Instant scheduledAt,
      String location,
      String note,
      Boolean needsCompanion) {}

  public record CreateBodyRecordRequest(
      @Min(0) @Max(10) int painScore,
      @Min(0) @Max(10) int fatigueScore,
      @Min(0) @Max(10) int sleepScore,
      @Min(0) @Max(10) int moodScore,
      @Min(0) @Max(10) int appetiteScore,
      @DecimalMin("34.0") @DecimalMax("42.0") double temperature,
      String note,
      @NotNull LocalDate recordDate) {}

  public record UpdateBodyRecordRequest(
      @Min(0) @Max(10) Integer painScore,
      @Min(0) @Max(10) Integer fatigueScore,
      @Min(0) @Max(10) Integer sleepScore,
      @Min(0) @Max(10) Integer moodScore,
      @Min(0) @Max(10) Integer appetiteScore,
      @DecimalMin("34.0") @DecimalMax("42.0") Double temperature,
      String note,
      LocalDate recordDate) {}

  public record CreateDoctorQuestionRequest(
      @NotBlank String question,
      boolean important) {}

  public record UpdateDoctorQuestionRequest(
      String question,
      Boolean asked,
      String doctorAnswer,
      Boolean important) {}

  public record CreateHelpTaskRequest(
      @NotBlank String title,
      @NotBlank String type,
      Instant scheduledAt,
      String description) {}

  public record UpdateHelpTaskRequest(
      String title,
      String type,
      Instant scheduledAt,
      String description,
      HelpTaskStatus status) {}

  public record CreateMessageRequest(@NotBlank String text) {}

  public record UpdateMessageRequest(String text) {}

  public record CreateNoteRequest(
      @NotBlank String title,
      @NotBlank String type,
      String content,
      @NotNull NoteVisibility visibility) {}

  public record UpdateNoteRequest(
      String title,
      String type,
      String content,
      NoteVisibility visibility) {}
}
