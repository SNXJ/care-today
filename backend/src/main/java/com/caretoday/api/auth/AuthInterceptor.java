package com.caretoday.api.auth;

import com.caretoday.api.common.RequestAuditContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class AuthInterceptor implements HandlerInterceptor {
  public static final String CURRENT_USER_ATTRIBUTE = "currentUser";
  private final JwtService jwtService;
  private final AuthRepository authRepository;

  public AuthInterceptor(JwtService jwtService, AuthRepository authRepository) {
    this.jwtService = jwtService;
    this.authRepository = authRepository;
  }

  @Override
  public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
    if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
      return true;
    }
    String authorization = request.getHeader("Authorization");
    if (authorization == null || !authorization.startsWith("Bearer ")) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "missing bearer token");
    }
    CurrentUser tokenUser = jwtService.parseToken(authorization.substring("Bearer ".length()));
    authRepository.findById(tokenUser.id())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "account is not active"));
    RequestAuditContext.set(clientIp(request), request.getHeader("User-Agent"));
    request.setAttribute(CURRENT_USER_ATTRIBUTE, tokenUser);
    return true;
  }

  @Override
  public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
    RequestAuditContext.clear();
  }

  private String clientIp(HttpServletRequest request) {
    String forwardedFor = request.getHeader("X-Forwarded-For");
    if (forwardedFor != null && !forwardedFor.isBlank()) {
      return forwardedFor.split(",", 2)[0].trim();
    }
    return request.getRemoteAddr();
  }
}
