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
        userId);
  }

  public CareSpace createSpace(UUID userId, String name, String patientNickname, String description) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO care_spaces (name, patient_user_id, patient_nickname, description)
        VALUES (?, ?, ?, ?)
        RETURNING id, name, patient_nickname, description, created_at
        """,
        (rs, rowNum) -> mapSpace(rs),
        name,
        userId,
        patientNickname,
        description);
  }

  public SpaceMember addMember(UUID spaceId, UUID userId, String nickname, MemberRole role, MemberStatus status) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO space_members (space_id, user_id, nickname, role, status)
        VALUES (?, ?, ?, ?::member_role, ?::member_status)
        RETURNING id, space_id, nickname, role, status, joined_at
        """,
        (rs, rowNum) -> mapMember(rs),
        spaceId,
        userId,
        nickname,
        role.name().toLowerCase(),
        status.name().toLowerCase());
  }

  public Optional<CareSpace> findSpace(UUID spaceId) {
    return jdbcTemplate.query(
            """
            SELECT id, name, patient_nickname, description, created_at
            FROM care_spaces
            WHERE id = ? AND deleted_at IS NULL
            """,
            (rs, rowNum) -> mapSpace(rs),
            spaceId)
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
        spaceId);
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
        spaceId,
        userId);
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
        spaceId,
        userId);
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
        spaceId);
  }

  public CareEvent createEvent(UUID spaceId, UUID userId, CreateEventRequest request) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO events (space_id, title, scheduled_at, location, note, needs_companion, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        RETURNING id, space_id, title, scheduled_at, location, note, needs_companion, created_at
        """,
        (rs, rowNum) -> mapEvent(rs),
        spaceId,
        request.title(),
        Timestamp.from(request.scheduledAt()),
        request.location(),
        request.note(),
        request.needsCompanion(),
        userId);
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
        spaceId);
  }

  public BodyRecord createBodyRecord(UUID spaceId, UUID userId, CreateBodyRecordRequest request) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO body_records (
          space_id, user_id, pain_score, fatigue_score, sleep_score, mood_score, appetite_score, temperature, note, record_date
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING id, space_id, pain_score, fatigue_score, sleep_score, mood_score, appetite_score, temperature, note, record_date, created_at
        """,
        (rs, rowNum) -> mapBodyRecord(rs),
        spaceId,
        userId,
        request.painScore(),
        request.fatigueScore(),
        request.sleepScore(),
        request.moodScore(),
        request.appetiteScore(),
        request.temperature(),
        request.note(),
        request.recordDate());
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
        spaceId);
  }

  public DoctorQuestion createDoctorQuestion(UUID spaceId, UUID userId, String question, boolean important) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO doctor_questions (space_id, question, important, created_by)
        VALUES (?, ?, ?, ?)
        RETURNING id, space_id, question, asked, important, doctor_answer, created_at
        """,
        (rs, rowNum) -> mapDoctorQuestion(rs),
        spaceId,
        question,
        important,
        userId);
  }

  public Optional<DoctorQuestion> updateDoctorQuestion(UUID spaceId, UUID questionId, Boolean asked, String doctorAnswer, Boolean important) {
    return jdbcTemplate.query(
            """
            UPDATE doctor_questions
            SET asked = COALESCE(?, asked),
                doctor_answer = COALESCE(?, doctor_answer),
                important = COALESCE(?, important),
                updated_at = now()
            WHERE id = ? AND space_id = ? AND deleted_at IS NULL
            RETURNING id, space_id, question, asked, important, doctor_answer, created_at
            """,
            (rs, rowNum) -> mapDoctorQuestion(rs),
            asked,
            doctorAnswer,
            important,
            questionId,
            spaceId)
        .stream()
        .findFirst();
  }

  public List<HelpTask> listHelpTasks(UUID spaceId) {
    return jdbcTemplate.query(
        """
        SELECT t.id, t.space_id, t.title, t.type, t.scheduled_at, t.description, t.status, u.nickname AS claimed_by, t.created_at
        FROM help_tasks t
        LEFT JOIN users u ON u.id = t.claimed_by
        WHERE t.space_id = ? AND t.deleted_at IS NULL
        ORDER BY t.status ASC, t.scheduled_at ASC NULLS LAST, t.created_at DESC
        """,
        (rs, rowNum) -> mapHelpTask(rs),
        spaceId);
  }

  public HelpTask createHelpTask(UUID spaceId, UUID userId, CreateHelpTaskRequest request) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO help_tasks (space_id, title, type, scheduled_at, description, created_by)
        VALUES (?, ?, ?, ?, ?, ?)
        RETURNING id, space_id, title, type, scheduled_at, description, status, NULL::text AS claimed_by, created_at
        """,
        (rs, rowNum) -> mapHelpTask(rs),
        spaceId,
        request.title(),
        request.type(),
        request.scheduledAt() == null ? null : Timestamp.from(request.scheduledAt()),
        request.description(),
        userId);
  }

  public Optional<HelpTask> claimHelpTask(UUID spaceId, UUID taskId, UUID userId) {
    return jdbcTemplate.query(
            """
            UPDATE help_tasks
            SET claimed_by = ?, status = 'claimed', updated_at = now()
            WHERE id = ? AND space_id = ? AND deleted_at IS NULL AND status = 'pending'
            RETURNING id, space_id, title, type, scheduled_at, description, status, 'current-user'::text AS claimed_by, created_at
            """,
            (rs, rowNum) -> mapHelpTask(rs),
            userId,
            taskId,
            spaceId)
        .stream()
        .findFirst();
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
        spaceId);
  }

  public SupportMessage createMessage(UUID spaceId, UUID userId, String text) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO messages (space_id, user_id, text)
        VALUES (?, ?, ?)
        RETURNING id, space_id, text, 'current-user'::text AS author, created_at
        """,
        (rs, rowNum) -> mapMessage(rs),
        spaceId,
        userId,
        text);
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
        spaceId);
  }

  public CareNote createNote(UUID spaceId, UUID userId, CreateNoteRequest request) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO notes (space_id, title, type, content, visibility, created_by)
        VALUES (?, ?, ?, ?, ?::note_visibility, ?)
        RETURNING id, space_id, title, type, content, visibility, created_at
        """,
        (rs, rowNum) -> mapNote(rs),
        spaceId,
        request.title(),
        request.type(),
        request.content(),
        request.visibility().name().toLowerCase(),
        userId);
  }

  public void audit(UUID spaceId, UUID userId, String action, String targetType, UUID targetId) {
    jdbcTemplate.update(
        """
        INSERT INTO audit_logs (space_id, user_id, action, target_type, target_id)
        VALUES (?, ?, ?, ?, ?)
        """,
        spaceId,
        userId,
        action,
        targetType,
        targetId);
  }

  private CareSpace mapSpace(ResultSet rs) throws SQLException {
    return new CareSpace(
        rs.getObject("id", UUID.class),
        rs.getString("name"),
        rs.getString("patient_nickname"),
        rs.getString("description"),
        toInstant(rs, "created_at"));
  }

  private SpaceMember mapMember(ResultSet rs) throws SQLException {
    return new SpaceMember(
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
        rs.getString("nickname"),
        MemberRole.valueOf(rs.getString("role").toUpperCase()),
        MemberStatus.valueOf(rs.getString("status").toUpperCase()),
        toInstant(rs, "joined_at"));
  }

  private CareEvent mapEvent(ResultSet rs) throws SQLException {
    return new CareEvent(
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
        rs.getString("title"),
        toInstant(rs, "scheduled_at"),
        rs.getString("location"),
        rs.getString("note"),
        rs.getBoolean("needs_companion"),
        toInstant(rs, "created_at"));
  }

  private BodyRecord mapBodyRecord(ResultSet rs) throws SQLException {
    return new BodyRecord(
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
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
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
        rs.getString("question"),
        rs.getBoolean("asked"),
        rs.getBoolean("important"),
        rs.getString("doctor_answer"),
        toInstant(rs, "created_at"));
  }

  private HelpTask mapHelpTask(ResultSet rs) throws SQLException {
    return new HelpTask(
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
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
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
        rs.getString("text"),
        rs.getString("author"),
        toInstant(rs, "created_at"));
  }

  private CareNote mapNote(ResultSet rs) throws SQLException {
    return new CareNote(
        rs.getObject("id", UUID.class),
        rs.getObject("space_id", UUID.class),
        rs.getString("title"),
        rs.getString("type"),
        rs.getString("content"),
        NoteVisibility.valueOf(rs.getString("visibility").toUpperCase()),
        toInstant(rs, "created_at"));
  }

  private Instant toInstant(ResultSet rs, String column) throws SQLException {
    return rs.getTimestamp(column).toInstant();
  }
}
