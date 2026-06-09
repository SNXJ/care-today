package com.caretoday.api.auth;

import com.caretoday.api.care.CareRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/account")
public class AccountController {
  private final AuthService authService;
  private final CareRepository careRepository;

  public AccountController(AuthService authService, CareRepository careRepository) {
    this.authService = authService;
    this.careRepository = careRepository;
  }

  @DeleteMapping
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteAccount(HttpServletRequest request) {
    CurrentUser currentUser = (CurrentUser) request.getAttribute(AuthInterceptor.CURRENT_USER_ATTRIBUTE);
    careRepository.removeUserFromActiveSpaces(currentUser.id());
    careRepository.audit(null, currentUser.id(), "account.delete", "user", currentUser.id(), clientIp(request), request.getHeader("User-Agent"));
    authService.deleteAccount(currentUser.id());
  }

  private String clientIp(HttpServletRequest request) {
    String forwardedFor = request.getHeader("X-Forwarded-For");
    if (forwardedFor != null && !forwardedFor.isBlank()) {
      return forwardedFor.split(",", 2)[0].trim();
    }
    return request.getRemoteAddr();
  }
}
