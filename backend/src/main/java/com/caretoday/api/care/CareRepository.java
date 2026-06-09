package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.CareSpace;
import com.caretoday.api.care.CareModels.MemberRole;
import com.caretoday.api.care.CareModels.MemberStatus;
import com.caretoday.api.care.CareModels.SpaceMember;
import java.sql.ResultSet;
import java.sql.SQLException;
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

  private Instant toInstant(ResultSet rs, String column) throws SQLException {
    return rs.getTimestamp(column).toInstant();
  }
}
