package com.caretoday.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class JwtServiceTest {
  @Test
  void rejectsDefaultSecret() {
    assertThatThrownBy(() -> new JwtService("replace-with-a-long-random-secret"))
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("JWT_SECRET");
  }

  @Test
  void createsAndParsesTokenWithStrongSecret() {
    JwtService jwtService = new JwtService("0123456789abcdef0123456789abcdef");
    UUID userId = UUID.fromString("00000000-0000-0000-0000-000000000001");

    String token = jwtService.createToken(new AuthRepository.UserRecord(
        userId,
        null,
        "test@example.com",
        "测试用户",
        "hash",
        Instant.parse("2026-06-15T01:00:00Z"),
        null));

    CurrentUser user = jwtService.parseToken(token);
    assertThat(user.id()).isEqualTo(userId);
    assertThat(user.nickname()).isEqualTo("测试用户");
  }
}
