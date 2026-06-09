package com.caretoday.api.auth;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.caretoday.api.common.ApiExceptionHandler;
import com.caretoday.api.common.CorsConfig;
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
}
