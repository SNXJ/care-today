package com.caretoday.api.auth;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AuthRepository {
  private final JdbcTemplate jdbcTemplate;

  public AuthRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  public UserRecord createUser(String phone, String email, String nickname, String passwordHash) {
    return jdbcTemplate.queryForObject(
        """
        INSERT INTO users (phone, email, nickname, password_hash)
        VALUES (?, ?, ?, ?)
        RETURNING id, phone, email, nickname, password_hash, created_at, last_login_at
        """,
        (rs, rowNum) -> mapUser(rs),
        blankToNull(phone),
        blankToNull(email),
        nickname,
        passwordHash);
  }

  public Optional<UserRecord> findByLogin(String phone, String email) {
    String normalizedPhone = blankToNull(phone);
    String normalizedEmail = blankToNull(email);
    if (normalizedPhone == null && normalizedEmail == null) {
      return Optional.empty();
    }
    return jdbcTemplate.query(
            """
            SELECT id, phone, email, nickname, password_hash, created_at, last_login_at
            FROM users
            WHERE deleted_at IS NULL
              AND ((? IS NOT NULL AND phone = ?) OR (? IS NOT NULL AND email = ?))
            LIMIT 1
            """,
            (rs, rowNum) -> mapUser(rs),
            normalizedPhone,
            normalizedPhone,
            normalizedEmail,
            normalizedEmail)
        .stream()
        .findFirst();
  }

  public Optional<UserRecord> findById(UUID id) {
    return jdbcTemplate.query(
            """
            SELECT id, phone, email, nickname, password_hash, created_at, last_login_at
            FROM users
            WHERE id = ? AND deleted_at IS NULL
            """,
            (rs, rowNum) -> mapUser(rs),
            id)
        .stream()
        .findFirst();
  }

  public void touchLastLogin(UUID userId) {
    jdbcTemplate.update("UPDATE users SET last_login_at = now() WHERE id = ?", userId);
  }

  private UserRecord mapUser(ResultSet rs) throws SQLException {
    return new UserRecord(
        rs.getObject("id", UUID.class),
        rs.getString("phone"),
        rs.getString("email"),
        rs.getString("nickname"),
        rs.getString("password_hash"),
        rs.getTimestamp("created_at").toInstant(),
        rs.getTimestamp("last_login_at") == null ? null : rs.getTimestamp("last_login_at").toInstant());
  }

  private String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }

  public record UserRecord(
      UUID id,
      String phone,
      String email,
      String nickname,
      String passwordHash,
      Instant createdAt,
      Instant lastLoginAt) {}
}
