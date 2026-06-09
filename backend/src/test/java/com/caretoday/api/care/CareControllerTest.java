package com.caretoday.api.care;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.caretoday.api.auth.AuthInterceptor;
import com.caretoday.api.auth.AuthRepository;
import com.caretoday.api.auth.CurrentUser;
import com.caretoday.api.auth.JwtService;
import com.caretoday.api.common.CorsConfig;
import com.caretoday.api.care.CareModels.CareEvent;
import com.caretoday.api.care.CareModels.MemberRole;
import com.caretoday.api.care.CareModels.MemberStatus;
import com.caretoday.api.care.CareModels.SpaceMember;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

@WebMvcTest(CareController.class)
@Import(CorsConfig.class)
class CareControllerTest {
  private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
  private static final UUID SPACE_ID = UUID.fromString("00000000-0000-0000-0000-000000000002");
  private static final UUID EVENT_ID = UUID.fromString("00000000-0000-0000-0000-000000000003");
  private static final UUID MEMBER_ID = UUID.fromString("00000000-0000-0000-0000-000000000004");

  @Autowired private MockMvc mockMvc;
  @MockBean private CareService careService;
  @MockBean private JwtService jwtService;
  @MockBean private AuthRepository authRepository;

  @BeforeEach
  void setUpAuth() {
    when(jwtService.parseToken("test-token")).thenReturn(new CurrentUser(USER_ID, "测试用户"));
    when(authRepository.findById(USER_ID))
        .thenReturn(Optional.of(new AuthRepository.UserRecord(USER_ID, null, "test@example.com", "测试用户", "hash", Instant.parse("2026-06-09T02:00:00Z"), null)));
  }

  @Test
  void updateEventReturnsUpdatedResource() throws Exception {
    when(careService.updateEvent(eq(USER_ID), eq(SPACE_ID), eq(EVENT_ID), any()))
        .thenReturn(new CareEvent(EVENT_ID, SPACE_ID, "复诊", Instant.parse("2026-06-10T02:00:00Z"), "门诊楼", "带报告", true, Instant.parse("2026-06-09T02:00:00Z")));

    mockMvc.perform(patch("/api/spaces/{spaceId}/events/{eventId}", SPACE_ID, EVENT_ID)
            .with(currentUser())
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"title\":\"复诊\",\"location\":\"门诊楼\",\"note\":\"带报告\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(EVENT_ID.toString()))
        .andExpect(jsonPath("$.title").value("复诊"));
  }

  @Test
  void deleteEventReturnsNoContent() throws Exception {
    doNothing().when(careService).deleteEvent(USER_ID, SPACE_ID, EVENT_ID);

    mockMvc.perform(delete("/api/spaces/{spaceId}/events/{eventId}", SPACE_ID, EVENT_ID).with(currentUser()))
        .andExpect(status().isNoContent());

    verify(careService).deleteEvent(USER_ID, SPACE_ID, EVENT_ID);
  }

  @Test
  void acceptMemberReturnsMember() throws Exception {
    when(careService.acceptMember(USER_ID, SPACE_ID, MEMBER_ID))
        .thenReturn(new SpaceMember(MEMBER_ID, SPACE_ID, "家人", MemberRole.FAMILY, MemberStatus.ACTIVE, Instant.parse("2026-06-09T02:00:00Z")));

    mockMvc.perform(patch("/api/spaces/{spaceId}/members/{memberId}/accept", SPACE_ID, MEMBER_ID).with(currentUser()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.id").value(MEMBER_ID.toString()))
        .andExpect(jsonPath("$.status").value("ACTIVE"));
  }

  @Test
  void leaveSpaceReturnsNoContent() throws Exception {
    mockMvc.perform(delete("/api/spaces/{spaceId}/leave", SPACE_ID).with(currentUser()))
        .andExpect(status().isNoContent());

    verify(careService).leaveSpace(USER_ID, SPACE_ID);
  }

  @Test
  void optionsPreflightDoesNotRequireBearerToken() throws Exception {
    mockMvc.perform(options("/api/spaces/{spaceId}/events", SPACE_ID)
            .header("Origin", "https://localhost:8443")
            .header("Access-Control-Request-Method", "POST")
            .header("Access-Control-Request-Headers", "content-type,authorization"))
        .andExpect(status().isOk());
  }

  @Test
  void invalidHelpTaskStatusReturnsBadRequest() throws Exception {
    mockMvc.perform(patch("/api/spaces/{spaceId}/help-tasks/{taskId}", SPACE_ID, EVENT_ID)
            .with(currentUser())
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"status\":\"not_a_status\"}"))
        .andExpect(status().isBadRequest());
  }

  private RequestPostProcessor currentUser() {
    return request -> {
      request.addHeader("Authorization", "Bearer test-token");
      return request;
    };
  }
}
