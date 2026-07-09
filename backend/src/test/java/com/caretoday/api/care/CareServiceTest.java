package com.caretoday.api.care;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.caretoday.api.care.CareModels.CareSpace;
import com.caretoday.api.care.CareModels.NoteVisibility;
import com.caretoday.api.care.CareRequests.CreateNoteRequest;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class CareServiceTest {
  private static final UUID USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
  private static final UUID SPACE_ID = UUID.fromString("00000000-0000-0000-0000-000000000002");

  @Mock private CareRepository careRepository;
  private CareService careService;

  @BeforeEach
  void setUp() {
    careService = new CareService(careRepository);
    when(careRepository.findSpace(SPACE_ID))
        .thenReturn(Optional.of(new CareSpace(SPACE_ID, "今天", "患者甲", "", Instant.parse("2026-06-15T01:00:00Z"))));
    when(careRepository.isActiveMember(SPACE_ID, USER_ID)).thenReturn(true);
  }

  @Test
  void nonAdminListsOnlyMemberVisibleNotes() {
    when(careRepository.isAdmin(SPACE_ID, USER_ID)).thenReturn(false);

    careService.listNotes(USER_ID, SPACE_ID);

    verify(careRepository).listNotes(SPACE_ID, false);
  }

  @Test
  void nonAdminCannotCreatePatientAdminOnlyNote() {
    when(careRepository.isAdmin(SPACE_ID, USER_ID)).thenReturn(false);
    CreateNoteRequest request = new CreateNoteRequest("报告", "检查", "内容", NoteVisibility.PATIENT_ADMIN, null);

    assertThatThrownBy(() -> careService.createNote(USER_ID, SPACE_ID, request))
        .isInstanceOf(ResponseStatusException.class)
        .hasMessageContaining("403");
    verify(careRepository, never()).createNote(SPACE_ID, USER_ID, request);
  }
}
