package com.caretoday.api.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
  private final SecretKey key;

  public JwtService(@Value("${care-today.jwt-secret}") String secret) {
    String normalized = secret.length() < 32 ? secret.repeat((32 / Math.max(secret.length(), 1)) + 1) : secret;
    this.key = Keys.hmacShaKeyFor(normalized.substring(0, Math.max(32, normalized.length())).getBytes(StandardCharsets.UTF_8));
  }

  public String createToken(AuthRepository.UserRecord user) {
    Instant now = Instant.now();
    return Jwts.builder()
        .subject(user.id().toString())
        .claim("nickname", user.nickname())
        .issuedAt(Date.from(now))
        .expiration(Date.from(now.plusSeconds(60L * 60L * 24L * 7L)))
        .signWith(key)
        .compact();
  }

  public CurrentUser parseToken(String token) {
    Claims claims = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    return new CurrentUser(UUID.fromString(claims.getSubject()), String.valueOf(claims.get("nickname")));
  }
}
