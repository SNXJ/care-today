package com.caretoday.api.auth;

import com.caretoday.api.auth.AuthRequests.LoginRequest;
import com.caretoday.api.auth.AuthRequests.RegisterRequest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
  private final AuthRepository authRepository;
  private final JwtService jwtService;
  private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

  public AuthService(AuthRepository authRepository, JwtService jwtService) {
    this.authRepository = authRepository;
    this.jwtService = jwtService;
  }

  public Map<String, Object> register(RegisterRequest request) {
    if (isBlank(request.phone()) && isBlank(request.email())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请填写手机号或邮箱");
    }
    authRepository.findByLogin(request.phone(), request.email()).ifPresent(user -> {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "账号已存在，请直接登录");
    });
    AuthRepository.UserRecord user = authRepository.createUser(
        request.phone(),
        request.email(),
        resolveNickname(request),
        passwordEncoder.encode(request.password()));
    return response(user);
  }

  public Map<String, Object> login(LoginRequest request) {
    AuthRepository.UserRecord user = authRepository.findByLogin(request.phone(), request.email())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid credentials"));
    if (!passwordEncoder.matches(request.password(), user.passwordHash())) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid credentials");
    }
    authRepository.touchLastLogin(user.id());
    return response(user);
  }

  public void deleteAccount(java.util.UUID currentUserId) {
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
}
