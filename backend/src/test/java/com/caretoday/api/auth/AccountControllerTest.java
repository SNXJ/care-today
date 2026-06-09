package com.caretoday.api.auth;

import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.caretoday.api.care.CareRepository;
import com.caretoday.api.common.CorsConfig;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AccountController.class)
@Import(CorsConfig.class)
class AccountControllerTest {
  private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Autowired private MockMvc mockMvc;
  @MockBean private AuthService authService;
  @MockBean private CareRepository careRepository;
  @MockBean private JwtService jwtService;
  @MockBean private AuthRepository authRepository;

  @BeforeEach
  void setUpAuth() {
    org.mockito.Mockito.when(jwtService.parseToken("test-token")).thenReturn(new CurrentUser(USER_ID, "测试用户"));
    org.mockito.Mockito.when(authRepository.findById(USER_ID))
        .thenReturn(Optional.of(new AuthRepository.UserRecord(USER_ID, null, "test@example.com", "测试用户", "hash", Instant.parse("2026-06-09T02:00:00Z"), null)));
  }

  @Test
  void deleteAccountSoftDeletesUserAndRemovesMemberships() throws Exception {
    mockMvc.perform(delete("/api/account").header("Authorization", "Bearer test-token"))
        .andExpect(status().isNoContent());

    verify(careRepository).removeUserFromActiveSpaces(USER_ID);
    verify(authService).deleteAccount(USER_ID);
  }
}
