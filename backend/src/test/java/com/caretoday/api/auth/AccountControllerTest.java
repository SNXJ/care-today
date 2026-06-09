package com.caretoday.api.auth;

import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.caretoday.api.care.CareRepository;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AccountController.class)
class AccountControllerTest {
  private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Autowired private MockMvc mockMvc;
  @MockBean private AuthService authService;
  @MockBean private CareRepository careRepository;
  @MockBean private JwtService jwtService;
  @MockBean private AuthRepository authRepository;

  @Test
  void deleteAccountSoftDeletesUserAndRemovesMemberships() throws Exception {
    mockMvc.perform(delete("/api/account").requestAttr(AuthInterceptor.CURRENT_USER_ATTRIBUTE, new CurrentUser(USER_ID, "测试用户")))
        .andExpect(status().isNoContent());

    verify(careRepository).removeUserFromActiveSpaces(USER_ID);
    verify(authService).deleteAccount(USER_ID);
  }
}
