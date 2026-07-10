package com.caretoday.api.admin;

import com.caretoday.api.auth.AuthInterceptor;
import com.caretoday.api.auth.AuthRepository;
import com.caretoday.api.auth.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * 运营后台只读统计接口，全部要求登录且账号在 ADMIN_ACCOUNTS 白名单内。
 * 仅做 SELECT，不提供任何修改能力。
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {
  /** 内容表 -> 是否有 space_id 列（audit 之外的业务表都有）。 */
  private static final Map<String, String> CONTENT_TABLES = Map.of(
      "events", "日程",
      "messages", "分享",
      "notes", "资料",
      "body_records", "身体记录",
      "symptom_events", "症状",
      "medication_logs", "用药",
      "doctor_questions", "问医生",
      "care_notices", "注意事项");

  private final JdbcTemplate jdbc;
  private final AuthRepository authRepository;
  private final Set<String> adminAccounts;

  public AdminController(
      JdbcTemplate jdbc,
      AuthRepository authRepository,
      @Value("${care-today.admin-accounts:}") String adminAccounts) {
    this.jdbc = jdbc;
    this.authRepository = authRepository;
    this.adminAccounts = new HashSet<>(Arrays.stream(adminAccounts.split(","))
        .map(String::trim)
        .filter(value -> !value.isBlank())
        .map(String::toLowerCase)
        .toList());
  }

  /** 总览：各类数据总量 + 近 14 天新增趋势。 */
  @GetMapping("/overview")
  public Map<String, Object> overview(HttpServletRequest request) {
    requireAdmin(request);
    Map<String, Object> totals = new LinkedHashMap<>();
    totals.put("users", count("SELECT COUNT(*) FROM users WHERE deleted_at IS NULL"));
    totals.put("spaces", count("SELECT COUNT(*) FROM care_spaces WHERE deleted_at IS NULL"));
    totals.put("members", count("SELECT COUNT(*) FROM space_members WHERE status = 'active'"));
    totals.put("events", count("SELECT COUNT(*) FROM events WHERE deleted_at IS NULL"));
    totals.put("messages", count("SELECT COUNT(*) FROM messages WHERE deleted_at IS NULL"));
    totals.put("notes", count("SELECT COUNT(*) FROM notes WHERE deleted_at IS NULL"));
    totals.put("bodyRecords", count("SELECT COUNT(*) FROM body_records WHERE deleted_at IS NULL"));
    totals.put("symptoms", count("SELECT COUNT(*) FROM symptom_events WHERE deleted_at IS NULL"));
    totals.put("medications", count("SELECT COUNT(*) FROM medication_logs WHERE deleted_at IS NULL"));
    totals.put("questions", count("SELECT COUNT(*) FROM doctor_questions WHERE deleted_at IS NULL"));
    totals.put("notices", count("SELECT COUNT(*) FROM care_notices WHERE deleted_at IS NULL"));
    totals.put("files", count("SELECT COUNT(*) FROM uploaded_files WHERE deleted_at IS NULL"));
    totals.put("fileBytes", count("SELECT COALESCE(SUM(size_bytes),0) FROM uploaded_files WHERE deleted_at IS NULL"));

    // 近 14 天：每天新增用户数与新增记录数（所有内容表合并）
    StringBuilder union = new StringBuilder();
    for (String table : CONTENT_TABLES.keySet()) {
      if (union.length() > 0) union.append(" UNION ALL ");
      union.append("SELECT created_at FROM ").append(table).append(" WHERE deleted_at IS NULL");
    }
    List<Map<String, Object>> recordDaily = jdbc.queryForList(
        "SELECT DATE(created_at) AS day, COUNT(*) AS n FROM (" + union
            + ") t WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 13 DAY)"
            + " GROUP BY DATE(created_at) ORDER BY day");
    List<Map<String, Object>> userDaily = jdbc.queryForList(
        "SELECT DATE(created_at) AS day, COUNT(*) AS n FROM users"
            + " WHERE deleted_at IS NULL AND created_at >= DATE_SUB(CURDATE(), INTERVAL 13 DAY)"
            + " GROUP BY DATE(created_at) ORDER BY day");

    Map<String, Object> result = new LinkedHashMap<>();
    result.put("totals", totals);
    result.put("recordDaily", recordDaily);
    result.put("userDaily", userDaily);
    return result;
  }

  /** 用户列表：注册信息 + 参与空间数。 */
  @GetMapping("/users")
  public List<Map<String, Object>> users(HttpServletRequest request) {
    requireAdmin(request);
    return jdbc.queryForList("""
        SELECT u.id, u.nickname, u.email, u.phone, u.created_at AS createdAt,
               (SELECT COUNT(*) FROM space_members m WHERE m.user_id = u.id AND m.status = 'active') AS spaceCount
        FROM users u
        WHERE u.deleted_at IS NULL
        ORDER BY u.created_at DESC
        """);
  }

  /** 空间列表：成员数与各类记录数。 */
  @GetMapping("/spaces")
  public List<Map<String, Object>> spaces(HttpServletRequest request) {
    requireAdmin(request);
    return jdbc.queryForList("""
        SELECT s.id, s.name, s.patient_nickname AS patientNickname, s.created_at AS createdAt,
               (SELECT COUNT(*) FROM space_members m WHERE m.space_id = s.id AND m.status = 'active') AS memberCount,
               (SELECT COUNT(*) FROM events t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS events,
               (SELECT COUNT(*) FROM messages t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS messages,
               (SELECT COUNT(*) FROM notes t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS notes,
               (SELECT COUNT(*) FROM body_records t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS bodyRecords,
               (SELECT COUNT(*) FROM symptom_events t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS symptoms,
               (SELECT COUNT(*) FROM medication_logs t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS medications,
               (SELECT COUNT(*) FROM doctor_questions t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS questions,
               (SELECT COUNT(*) FROM care_notices t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS notices,
               (SELECT COUNT(*) FROM uploaded_files t WHERE t.space_id = s.id AND t.deleted_at IS NULL) AS files
        FROM care_spaces s
        WHERE s.deleted_at IS NULL
        ORDER BY s.created_at DESC
        """);
  }

  /** 单个空间的全部数据（含分享/资料的图片 id 列表）。 */
  @GetMapping("/spaces/{spaceId}")
  public Map<String, Object> spaceDetail(HttpServletRequest request, @PathVariable UUID spaceId) {
    requireAdmin(request);
    List<Map<String, Object>> space = jdbc.queryForList(
        "SELECT id, name, patient_nickname AS patientNickname, description, created_at AS createdAt"
            + " FROM care_spaces WHERE id = ? AND deleted_at IS NULL", spaceId.toString());
    if (space.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "空间不存在");
    }
    Map<String, Object> result = new LinkedHashMap<>();
    result.put("space", space.get(0));
    result.put("members", jdbc.queryForList(
        "SELECT m.nickname, m.role, m.status, m.joined_at AS joinedAt, u.email, u.phone"
            + " FROM space_members m LEFT JOIN users u ON u.id = m.user_id"
            + " WHERE m.space_id = ? ORDER BY m.joined_at", spaceId.toString()));
    result.put("events", jdbc.queryForList(
        "SELECT title, scheduled_at AS scheduledAt, location, note, needs_companion AS needsCompanion,"
            + " created_at AS createdAt FROM events WHERE space_id = ? AND deleted_at IS NULL"
            + " ORDER BY scheduled_at DESC", spaceId.toString()));
    result.put("messages", jdbc.queryForList(
        "SELECT m.text, m.photos, m.created_at AS createdAt, u.nickname AS author"
            + " FROM messages m LEFT JOIN users u ON u.id = m.user_id"
            + " WHERE m.space_id = ? AND m.deleted_at IS NULL ORDER BY m.created_at DESC", spaceId.toString()));
    result.put("notes", jdbc.queryForList(
        "SELECT title, type, content, photos, visibility, created_at AS createdAt"
            + " FROM notes WHERE space_id = ? AND deleted_at IS NULL ORDER BY created_at DESC", spaceId.toString()));
    result.put("bodyRecords", jdbc.queryForList(
        "SELECT record_date AS recordDate, temperature, weight, pain_score AS painScore,"
            + " fatigue_score AS fatigueScore, sleep_score AS sleepScore, mood_score AS moodScore,"
            + " appetite_score AS appetiteScore, note, measured_at AS measuredAt, created_at AS createdAt"
            + " FROM body_records WHERE space_id = ? AND deleted_at IS NULL"
            + " ORDER BY created_at DESC", spaceId.toString()));
    result.put("symptoms", jdbc.queryForList(
        "SELECT tag, note, happened_at AS happenedAt, created_at AS createdAt"
            + " FROM symptom_events WHERE space_id = ? AND deleted_at IS NULL"
            + " ORDER BY happened_at DESC", spaceId.toString()));
    result.put("medications", jdbc.queryForList(
        "SELECT name, dosage, taken_at AS takenAt, note, created_at AS createdAt"
            + " FROM medication_logs WHERE space_id = ? AND deleted_at IS NULL"
            + " ORDER BY taken_at DESC", spaceId.toString()));
    result.put("questions", jdbc.queryForList(
        "SELECT question, doctor_answer AS doctorAnswer, important, asked, created_at AS createdAt"
            + " FROM doctor_questions WHERE space_id = ? AND deleted_at IS NULL"
            + " ORDER BY created_at DESC", spaceId.toString()));
    result.put("notices", jdbc.queryForList(
        "SELECT content, detail, important, status, starts_on AS startsOn, ends_on AS endsOn,"
            + " created_at AS createdAt FROM care_notices WHERE space_id = ? AND deleted_at IS NULL"
            + " ORDER BY created_at DESC", spaceId.toString()));
    return result;
  }

  /** 全部图片（元数据，图片本体走 /api/files/{id}）。 */
  @GetMapping("/files")
  public List<Map<String, Object>> files(HttpServletRequest request) {
    requireAdmin(request);
    return jdbc.queryForList("""
        SELECT f.id, f.space_id AS spaceId, s.name AS spaceName, s.patient_nickname AS patientNickname,
               u.nickname AS uploader, f.content_type AS contentType, f.size_bytes AS sizeBytes,
               f.created_at AS createdAt
        FROM uploaded_files f
        LEFT JOIN care_spaces s ON s.id = f.space_id
        LEFT JOIN users u ON u.id = f.uploader_id
        WHERE f.deleted_at IS NULL
        ORDER BY f.created_at DESC
        """);
  }

  private long count(String sql) {
    Long value = jdbc.queryForObject(sql, Long.class);
    return value == null ? 0 : value;
  }

  private void requireAdmin(HttpServletRequest request) {
    CurrentUser current = (CurrentUser) request.getAttribute(AuthInterceptor.CURRENT_USER_ATTRIBUTE);
    if (current == null) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "未登录");
    }
    if (adminAccounts.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "未配置管理员账号");
    }
    var user = authRepository.findById(current.id())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "账号无效"));
    boolean isAdmin =
        (user.email() != null && adminAccounts.contains(user.email().toLowerCase()))
            || (user.phone() != null && adminAccounts.contains(user.phone().toLowerCase()));
    if (!isAdmin) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "没有管理权限");
    }
  }
}
