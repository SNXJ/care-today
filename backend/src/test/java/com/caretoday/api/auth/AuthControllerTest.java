package com.caretoday.api.auth;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.caretoday.api.common.ApiExceptionHandler;
import com.caretoday.api.common.CorsConfig;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

@WebMvcTest(AuthController.class)
@Import({CorsConfig.class, ApiExceptionHandler.class})
class AuthControllerTest {
  private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Autowired private MockMvc mockMvc;
  @MockBean private AuthService authService;
  @MockBean private JwtService jwtService;
  @MockBean private AuthRepository authRepository;

  @Test
  void duplicateRegisterReturnsReadableConflictReason() throws Exception {
    when(authService.register(any()))
        .thenThrow(new ResponseStatusException(HttpStatus.CONFLICT, "账号已存在，请直接登录"));

    mockMvc.perform(post("/api/auth/register")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"email\":\"927990956@qq.com\",\"password\":\"secret123\"}"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.reason").value("账号已存在，请直接登录"));
  }

  @Test
  void refreshRequiresValidSessionAndReturnsNewToken() throws Exception {
    when(jwtService.parseToken("old-token")).thenReturn(new CurrentUser(USER_ID, "测试用户"));
    when(authRepository.findById(USER_ID)).thenReturn(Optional.of(new AuthRepository.UserRecord(
        USER_ID,
        null,
        "test@example.com",
        "测试用户",
        "hash",
        Instant.parse("2026-06-15T01:00:00Z"),
        null)));
    when(authService.refresh(USER_ID)).thenReturn(Map.of(
        "token", "new-token",
        "user", Map.of("id", USER_ID, "nickname", "测试用户")));

    mockMvc.perform(post("/api/auth/refresh")
            .header("Authorization", "Bearer old-token"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.token").value("new-token"))
        .andExpect(jsonPath("$.user.nickname").value("测试用户"));
  }
}
