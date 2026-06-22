package com.caretoday.api.auth;

import com.caretoday.api.auth.AuthRequests.LoginRequest;
import com.caretoday.api.auth.AuthRequests.RegisterRequest;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
  private final AuthRepository authRepository;
  private final JwtService jwtService;
  private final AuthRateLimiter rateLimiter;
  private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

  public AuthService(AuthRepository authRepository, JwtService jwtService, AuthRateLimiter rateLimiter) {
    this.authRepository = authRepository;
    this.jwtService = jwtService;
    this.rateLimiter = rateLimiter;
  }

  public Map<String, Object> register(RegisterRequest request) {
    if (isBlank(request.phone()) && isBlank(request.email())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请填写手机号或邮箱");
    }
    String key = rateLimitKey("register", request.phone(), request.email());
    rateLimiter.check(key);
    authRepository.findByLogin(request.phone(), request.email()).ifPresent(user -> {
      rateLimiter.recordFailure(key);
      throw new ResponseStatusException(HttpStatus.CONFLICT, "账号已存在，请直接登录");
    });
    AuthRepository.UserRecord user = authRepository.createUser(
        request.phone(),
        request.email(),
        resolveNickname(request),
        passwordEncoder.encode(request.password()));
    rateLimiter.reset(key);
    return response(user);
  }

  public Map<String, Object> login(LoginRequest request) {
    String key = rateLimitKey("login", request.phone(), request.email());
    rateLimiter.check(key);
    AuthRepository.UserRecord user = authRepository.findByLogin(request.phone(), request.email())
        .orElseThrow(() -> {
          rateLimiter.recordFailure(key);
          return new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid credentials");
        });
    if (!passwordEncoder.matches(request.password(), user.passwordHash())) {
      rateLimiter.recordFailure(key);
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid credentials");
    }
    authRepository.touchLastLogin(user.id());
    rateLimiter.reset(key);
    return response(user);
  }

  public Map<String, Object> refresh(UUID currentUserId) {
    AuthRepository.UserRecord user = authRepository.findById(currentUserId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "account is not active"));
    return response(user);
  }

  public void deleteAccount(UUID currentUserId) {
    authRepository.softDelete(currentUserId);
  }

  private Map<String, Object> response(AuthRepository.UserRecord user) {
    Map<String, Object> userPayload = new LinkedHashMap<>();
    userPayload.put("id", user.id());
    userPayload.put("phone", user.phone());
    userPayload.put("email", user.email());
    userPayload.put("nickname", user.nickname());

    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("token", jwtService.createToken(user));
    payload.put("user", userPayload);
    return payload;
  }

  private boolean isBlank(String value) {
    return value == null || value.isBlank();
  }

  private String resolveNickname(RegisterRequest request) {
    if (!isBlank(request.nickname())) {
      return request.nickname().trim();
    }
    if (!isBlank(request.email())) {
      return request.email().trim().split("@", 2)[0];
    }
    return request.phone().trim();
  }

  private String rateLimitKey(String action, String phone, String email) {
    String identifier = !isBlank(email) ? email.trim().toLowerCase() : phone == null ? "" : phone.trim();
    return action + ":" + identifier;
  }
}
