package com.caretoday.api.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public final class AuthRequests {
  private AuthRequests() {}

  public record RegisterRequest(
      String phone,
      @Email String email,
      @NotBlank String nickname,
      @NotBlank String password) {}

  public record LoginRequest(
      String phone,
      @Email String email,
      @NotBlank String password) {}
}
