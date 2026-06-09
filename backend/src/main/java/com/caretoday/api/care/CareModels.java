package com.caretoday.api.care;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public final class CareModels {
  private CareModels() {}

  public enum MemberRole {
    PATIENT_ADMIN,
    FAMILY,
    FRIEND,
    READONLY
  }

  public enum MemberStatus {
    PENDING,
    ACTIVE,
    REMOVED
  }

  public enum HelpTaskStatus {
    PENDING,
    CLAIMED,
    DONE,
    CANCELLED
  }

  public enum NoteVisibility {
    PATIENT_ADMIN,
    MEMBERS
  }

  public record CareSpace(
      UUID id,
      String name,
      String patientNickname,
      String description,
      Instant createdAt) {}

  public record SpaceMember(
      UUID id,
      UUID spaceId,
      String nickname,
      MemberRole role,
      MemberStatus status,
      Instant joinedAt) {}

  public record SpaceInvite(
      UUID token,
      UUID spaceId,
      String spaceName,
      String patientNickname,
      String nickname,
      MemberRole role,
      Instant expiresAt,
      Instant createdAt) {}

  public record CareEvent(
      UUID id,
      UUID spaceId,
      String title,
      Instant scheduledAt,
      String location,
      String note,
      boolean needsCompanion,
      Instant createdAt) {}

  public record BodyRecord(
      UUID id,
      UUID spaceId,
      int painScore,
      int fatigueScore,
      int sleepScore,
      int moodScore,
      int appetiteScore,
      double temperature,
      String note,
      LocalDate recordDate,
      Instant createdAt) {}

  public record DoctorQuestion(
      UUID id,
      UUID spaceId,
      String question,
      boolean asked,
      boolean important,
      String doctorAnswer,
      Instant createdAt) {}

  public record HelpTask(
      UUID id,
      UUID spaceId,
      String title,
      String type,
      Instant scheduledAt,
      String description,
      HelpTaskStatus status,
      String claimedBy,
      Instant createdAt) {}

  public record SupportMessage(
      UUID id,
      UUID spaceId,
      String text,
      String author,
      Instant createdAt) {}

  public record CareNote(
      UUID id,
      UUID spaceId,
      String title,
      String type,
      String content,
      NoteVisibility visibility,
      Instant createdAt) {}
}
