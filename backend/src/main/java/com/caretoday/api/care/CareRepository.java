package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.BodyRecord;
import com.caretoday.api.care.CareModels.CareEvent;
import com.caretoday.api.care.CareModels.CareNote;
import com.caretoday.api.care.CareModels.CareSpace;
import com.caretoday.api.care.CareModels.DoctorQuestion;
import com.caretoday.api.care.CareModels.HelpTask;
import com.caretoday.api.care.CareModels.HelpTaskStatus;
import com.caretoday.api.care.CareModels.MemberRole;
import com.caretoday.api.care.CareModels.MemberStatus;
import com.caretoday.api.care.CareModels.NoteVisibility;
import com.caretoday.api.care.CareModels.SpaceMember;
import com.caretoday.api.care.CareModels.SupportMessage;
import com.caretoday.api.care.CareRequests.CreateBodyRecordRequest;
import com.caretoday.api.care.CareRequests.CreateEventRequest;
import com.caretoday.api.care.CareRequests.CreateHelpTaskRequest;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class CareRepository {
  private final JdbcTemplate jdbcTemplate;

  public CareRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  public List<CareSpace> listSpacesForUser(UUID userId) {
    return jdbcTemplate.query(
        """
        SELECT s.id, s.name, s.patient_nickname, s.description, s.created_at
        FROM care_spaces s
        JOIN space_members m ON m.space_id = s.id
        WHERE m.user_id = ?
          AND m.status = 'active'
          AND s.deleted_at IS NULL
        ORDER BY s.created_at DESC
        """,
        (rs, rowNum) -> mapSpace(rs),
        id(userId));
  }

  public CareSpace createSpace(UUID userId, String name, String patientNickname, String description) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO care_spaces (id, name, patient_user_id, patient_nickname, description)
        VALUES (?, ?, ?, ?, ?)
        """,
        id(id),
        name,
        id(userId),
        patientNickname,
        description);
    return findSpace(id).orElseThrow();
  }

  public SpaceMember addMember(UUID spaceId, UUID userId, String nickname, MemberRole role, MemberStatus status) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO space_members (id, space_id, user_id, nickname, role, status)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        id(userId),
        nickname,
        role.name().toLowerCase(),
        status.name().toLowerCase());
    return findMember(id).orElseThrow();
  }

  public Optional<CareSpace> findSpace(UUID spaceId) {
    return jdbcTemplate.query(
            """
            SELECT id, name, patient_nickname, description, created_at
            FROM care_spaces
            WHERE id = ? AND deleted_at IS NULL
            """,
            (rs, rowNum) -> mapSpace(rs),
            id(spaceId))
        .stream()
        .findFirst();
  }

  public List<SpaceMember> listMembers(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT id, space_id, nickname, role, status, joined_at
        FROM space_members
        WHERE space_id = ? AND status <> 'removed'
        ORDER BY joined_at ASC
        """,
        (rs, rowNum) -> mapMember(rs),
        id(spaceId));
  }

  public Optional<SpaceMember> findMember(UUID memberId) {
    return jdbcTemplate.query(
            """
            SELECT id, space_id, nickname, role, status, joined_at
            FROM space_members
            WHERE id = ?
            """,
            (rs, rowNum) -> mapMember(rs),
            id(memberId))
        .stream()
        .findFirst();
  }

  public boolean isActiveMember(UUID spaceId, UUID userId) {
    Boolean exists = jdbcTemplate.queryForObject(
        """
        SELECT EXISTS (
          SELECT 1 FROM space_members
          WHERE space_id = ? AND user_id = ? AND status = 'active'
        )
        """,
        Boolean.class,
        id(spaceId),
        id(userId));
    return Boolean.TRUE.equals(exists);
  }

  public boolean isAdmin(UUID spaceId, UUID userId) {
    Boolean exists = jdbcTemplate.queryForObject(
        """
        SELECT EXISTS (
          SELECT 1 FROM space_members
          WHERE space_id = ? AND user_id = ? AND status = 'active' AND role = 'patient_admin'
        )
        """,
        Boolean.class,
        id(spaceId),
        id(userId));
    return Boolean.TRUE.equals(exists);
  }

  public List<CareEvent> listEvents(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT id, space_id, title, scheduled_at, location, note, needs_companion, created_at
        FROM events
        WHERE space_id = ? AND deleted_at IS NULL
        ORDER BY scheduled_at ASC
        """,
        (rs, rowNum) -> mapEvent(rs),
        id(spaceId));
  }

  public Optional<CareEvent> findEvent(UUID eventId) {
    return jdbcTemplate.query(
            """
            SELECT id, space_id, title, scheduled_at, location, note, needs_companion, created_at
            FROM events
            WHERE id = ? AND deleted_at IS NULL
            """,
            (rs, rowNum) -> mapEvent(rs),
            id(eventId))
        .stream()
        .findFirst();
  }

  public CareEvent createEvent(UUID spaceId, UUID userId, CreateEventRequest request) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO events (id, space_id, title, scheduled_at, location, note, needs_companion, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        request.title(),
        Timestamp.from(request.scheduledAt()),
        request.location(),
        request.note(),
        request.needsCompanion(),
        id(userId));
    return findEvent(id).orElseThrow();
  }

  public List<BodyRecord> listBodyRecords(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT id, space_id, pain_score, fatigue_score, sleep_score, mood_score, appetite_score, temperature, note, record_date, created_at
        FROM body_records
        WHERE space_id = ?
        ORDER BY record_date DESC, created_at DESC
        """,
        (rs, rowNum) -> mapBodyRecord(rs),
        id(spaceId));
  }

  public Optional<BodyRecord> findBodyRecord(UUID recordId) {
    return jdbcTemplate.query(
            """
            SELECT id, space_id, pain_score, fatigue_score, sleep_score, mood_score, appetite_score, temperature, note, record_date, created_at
            FROM body_records
            WHERE id = ?
            """,
            (rs, rowNum) -> mapBodyRecord(rs),
            id(recordId))
        .stream()
        .findFirst();
  }

  public BodyRecord createBodyRecord(UUID spaceId, UUID userId, CreateBodyRecordRequest request) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO body_records (
          id, space_id, user_id, pain_score, fatigue_score, sleep_score, mood_score, appetite_score, temperature, note, record_date
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        id(userId),
        request.painScore(),
        request.fatigueScore(),
        request.sleepScore(),
        request.moodScore(),
        request.appetiteScore(),
        request.temperature(),
        request.note(),
        request.recordDate());
    return findBodyRecord(id).orElseThrow();
  }

  public List<DoctorQuestion> listDoctorQuestions(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT id, space_id, question, asked, important, doctor_answer, created_at
        FROM doctor_questions
        WHERE space_id = ? AND deleted_at IS NULL
        ORDER BY important DESC, created_at DESC
        """,
        (rs, rowNum) -> mapDoctorQuestion(rs),
        id(spaceId));
  }

  public Optional<DoctorQuestion> findDoctorQuestion(UUID questionId) {
    return jdbcTemplate.query(
            """
            SELECT id, space_id, question, asked, important, doctor_answer, created_at
            FROM doctor_questions
            WHERE id = ? AND deleted_at IS NULL
            """,
            (rs, rowNum) -> mapDoctorQuestion(rs),
            id(questionId))
        .stream()
        .findFirst();
  }

  public DoctorQuestion createDoctorQuestion(UUID spaceId, UUID userId, String question, boolean important) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO doctor_questions (id, space_id, question, important, created_by)
        VALUES (?, ?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        question,
        important,
        id(userId));
    return findDoctorQuestion(id).orElseThrow();
  }

  public Optional<DoctorQuestion> updateDoctorQuestion(UUID spaceId, UUID questionId, Boolean asked, String doctorAnswer, Boolean important) {
    int updated = jdbcTemplate.update(
            """
            UPDATE doctor_questions
            SET asked = COALESCE(?, asked),
                doctor_answer = COALESCE(?, doctor_answer),
                important = COALESCE(?, important),
                updated_at = CURRENT_TIMESTAMP(3)
            WHERE id = ? AND space_id = ? AND deleted_at IS NULL
            """,
            asked,
            doctorAnswer,
            important,
            id(questionId),
            id(spaceId));
    return updated == 0 ? Optional.empty() : findDoctorQuestion(questionId);
  }

  public List<HelpTask> listHelpTasks(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT t.id, t.space_id, t.title, t.type, t.scheduled_at, t.description, t.status, u.nickname AS claimed_by, t.created_at
        FROM help_tasks t
        LEFT JOIN users u ON u.id = t.claimed_by
        WHERE t.space_id = ? AND t.deleted_at IS NULL
        ORDER BY t.status ASC, t.scheduled_at IS NULL ASC, t.scheduled_at ASC, t.created_at DESC
        """,
        (rs, rowNum) -> mapHelpTask(rs),
        id(spaceId));
  }

  public Optional<HelpTask> findHelpTask(UUID taskId) {
    return jdbcTemplate.query(
            """
            SELECT t.id, t.space_id, t.title, t.type, t.scheduled_at, t.description, t.status, u.nickname AS claimed_by, t.created_at
            FROM help_tasks t
            LEFT JOIN users u ON u.id = t.claimed_by
            WHERE t.id = ? AND t.deleted_at IS NULL
            """,
            (rs, rowNum) -> mapHelpTask(rs),
            id(taskId))
        .stream()
        .findFirst();
  }

  public HelpTask createHelpTask(UUID spaceId, UUID userId, CreateHelpTaskRequest request) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO help_tasks (id, space_id, title, type, scheduled_at, description, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        request.title(),
        request.type(),
        request.scheduledAt() == null ? null : Timestamp.from(request.scheduledAt()),
        request.description(),
        id(userId));
    return findHelpTask(id).orElseThrow();
  }

  public Optional<HelpTask> claimHelpTask(UUID spaceId, UUID taskId, UUID userId) {
    int updated = jdbcTemplate.update(
            """
            UPDATE help_tasks
            SET claimed_by = ?, status = 'claimed', updated_at = CURRENT_TIMESTAMP(3)
            WHERE id = ? AND space_id = ? AND deleted_at IS NULL AND status = 'pending' 
            """,
            id(userId),
            id(taskId),
            id(spaceId));
    return updated == 0 ? Optional.empty() : findHelpTask(taskId);
  }

  public List<SupportMessage> listMessages(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT m.id, m.space_id, m.text, COALESCE(u.nickname, '成员') AS author, m.created_at
        FROM messages m
        LEFT JOIN users u ON u.id = m.user_id
        WHERE m.space_id = ? AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC
        """,
        (rs, rowNum) -> mapMessage(rs),
        id(spaceId));
  }

  public Optional<SupportMessage> findMessage(UUID messageId) {
    return jdbcTemplate.query(
            """
            SELECT m.id, m.space_id, m.text, COALESCE(u.nickname, '成员') AS author, m.created_at
            FROM messages m
            LEFT JOIN users u ON u.id = m.user_id
            WHERE m.id = ? AND m.deleted_at IS NULL
            """,
            (rs, rowNum) -> mapMessage(rs),
            id(messageId))
        .stream()
        .findFirst();
  }

  public SupportMessage createMessage(UUID spaceId, UUID userId, String text) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO messages (id, space_id, user_id, text)
        VALUES (?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        id(userId),
        text);
    return findMessage(id).orElseThrow();
  }

  public List<CareNote> listNotes(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT id, space_id, title, type, content, visibility, created_at
        FROM notes
        WHERE space_id = ? AND deleted_at IS NULL
        ORDER BY created_at DESC
        """,
        (rs, rowNum) -> mapNote(rs),
        id(spaceId));
  }

  public Optional<CareNote> findNote(UUID noteId) {
    return jdbcTemplate.query(
            """
            SELECT id, space_id, title, type, content, visibility, created_at
            FROM notes
            WHERE id = ? AND deleted_at IS NULL
            """,
            (rs, rowNum) -> mapNote(rs),
            id(noteId))
        .stream()
        .findFirst();
  }

  public CareNote createNote(UUID spaceId, UUID userId, CreateNoteRequest request) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        """
        INSERT INTO notes (id, space_id, title, type, content, visibility, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        id(id),
        id(spaceId),
        request.title(),
        request.type(),
        request.content(),
        request.visibility().name().toLowerCase(),
        id(userId));
    return findNote(id).orElseThrow();
  }

  public void audit(UUID spaceId, UUID userId, String action, String targetType, UUID targetId) {
    jdbcTemplate.update(
        """
        INSERT INTO audit_logs (space_id, user_id, action, target_type, target_id)
        VALUES (?, ?, ?, ?, ?)
        """,
        id(spaceId),
        id(userId),
        action,
        targetType,
        id(targetId));
  }

  private CareSpace mapSpace(ResultSet rs) throws SQLException {
    return new CareSpace(
        uuid(rs, "id"),
        rs.getString("name"),
        rs.getString("patient_nickname"),
        rs.getString("description"),
        toInstant(rs, "created_at"));
  }

  private SpaceMember mapMember(ResultSet rs) throws SQLException {
    return new SpaceMember(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getString("nickname"),
        MemberRole.valueOf(rs.getString("role").toUpperCase()),
        MemberStatus.valueOf(rs.getString("status").toUpperCase()),
        toInstant(rs, "joined_at"));
  }

  private CareEvent mapEvent(ResultSet rs) throws SQLException {
    return new CareEvent(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getString("title"),
        toInstant(rs, "scheduled_at"),
        rs.getString("location"),
        rs.getString("note"),
        rs.getBoolean("needs_companion"),
        toInstant(rs, "created_at"));
  }

  private BodyRecord mapBodyRecord(ResultSet rs) throws SQLException {
    return new BodyRecord(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getInt("pain_score"),
        rs.getInt("fatigue_score"),
        rs.getInt("sleep_score"),
        rs.getInt("mood_score"),
        rs.getInt("appetite_score"),
        rs.getDouble("temperature"),
        rs.getString("note"),
        rs.getDate("record_date").toLocalDate(),
        toInstant(rs, "created_at"));
  }

  private DoctorQuestion mapDoctorQuestion(ResultSet rs) throws SQLException {
    return new DoctorQuestion(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getString("question"),
        rs.getBoolean("asked"),
        rs.getBoolean("important"),
        rs.getString("doctor_answer"),
        toInstant(rs, "created_at"));
  }

  private HelpTask mapHelpTask(ResultSet rs) throws SQLException {
    return new HelpTask(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getString("title"),
        rs.getString("type"),
        rs.getTimestamp("scheduled_at") == null ? null : rs.getTimestamp("scheduled_at").toInstant(),
        rs.getString("description"),
        HelpTaskStatus.valueOf(rs.getString("status").toUpperCase()),
        rs.getString("claimed_by"),
        toInstant(rs, "created_at"));
  }

  private SupportMessage mapMessage(ResultSet rs) throws SQLException {
    return new SupportMessage(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getString("text"),
        rs.getString("author"),
        toInstant(rs, "created_at"));
  }

  private CareNote mapNote(ResultSet rs) throws SQLException {
    return new CareNote(
        uuid(rs, "id"),
        uuid(rs, "space_id"),
        rs.getString("title"),
        rs.getString("type"),
        rs.getString("content"),
        NoteVisibility.valueOf(rs.getString("visibility").toUpperCase()),
        toInstant(rs, "created_at"));
  }

  private Instant toInstant(ResultSet rs, String column) throws SQLException {
    return rs.getTimestamp(column).toInstant();
  }

  private UUID uuid(ResultSet rs, String column) throws SQLException {
    return UUID.fromString(rs.getString(column));
  }

  private String id(UUID value) {
    return value == null ? null : value.toString();
  }
}
