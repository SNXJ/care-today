package com.caretoday.api.care;

import static org.assertj.core.api.Assertions.assertThat;

import com.caretoday.api.care.CareModels.MedicationLog;
import com.caretoday.api.care.CareModels.SymptomEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class DoctorSummaryTest {
  private static final ZoneId SH = ZoneId.of("Asia/Shanghai");

  private static Instant at(int month, int day) {
    return LocalDate.of(2026, month, day).atTime(9, 0).atZone(SH).toInstant();
  }

  private static SymptomEvent symptom(String tag, int month, int day) {
    return new SymptomEvent(UUID.randomUUID(), UUID.randomUUID(), tag, at(month, day), null, at(month, day));
  }

  private static MedicationLog med(String name, String dosage, int month, int day) {
    return new MedicationLog(UUID.randomUUID(), UUID.randomUUID(), name, dosage, at(month, day), null, at(month, day));
  }

  @Test
  void buildsSummaryWithRangesAndGroups() {
    List<SymptomEvent> symptoms = List.of(
        symptom("腹泻", 9, 24),
        symptom("发烧38°", 9, 30),
        symptom("便血", 9, 22),
        symptom("便血", 9, 23),
        symptom("便血", 9, 29),
        symptom("便血", 10, 8),
        symptom("便血", 10, 9));
    List<MedicationLog> meds = List.of(
        med("蒙脱石散", "2包", 9, 24),
        med("蒙脱石散", "2包", 9, 29),
        med("美林", "10ml", 9, 30));

    String text = DoctorSummary.build(symptoms, meds, LocalDate.of(2026, 9, 22), LocalDate.of(2026, 10, 9), SH);

    assertThat(text).isEqualTo(String.join("\n",
        "【不良反应 · 9/22–10/9】",
        "便血 9/22-9/23、9/29、10/8-10/9",
        "腹泻 9/24",
        "发烧38° 9/30",
        "",
        "【用药 · 9/22–10/9】",
        "蒙脱石散 2包 9/24、9/29",
        "美林 10ml 9/30"));
  }

  @Test
  void sameTagWithDifferentValuesStaySeparate() {
    String text = DoctorSummary.build(
        List.of(symptom("发烧38°", 10, 1), symptom("发烧39°", 10, 2)),
        List.of(), LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2), SH);
    assertThat(text).contains("发烧38° 10/1").contains("发烧39° 10/2");
  }

  @Test
  void emptySectionsShowNone() {
    String text = DoctorSummary.build(List.of(), List.of(),
        LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 7), SH);
    assertThat(text).isEqualTo(String.join("\n",
        "【不良反应 · 10/1–10/7】", "无", "", "【用药 · 10/1–10/7】", "无"));
  }

  @Test
  void excludesRecordsOutsideRange() {
    String text = DoctorSummary.build(
        List.of(symptom("腹泻", 9, 20), symptom("腹泻", 9, 25)),
        List.of(), LocalDate.of(2026, 9, 22), LocalDate.of(2026, 9, 30), SH);
    assertThat(text).contains("腹泻 9/25").doesNotContain("9/20");
  }

  @Test
  void medicationWithoutDosageOmitsIt() {
    String text = DoctorSummary.build(List.of(),
        List.of(med("维生素", null, 10, 3)),
        LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 7), SH);
    assertThat(text).contains("维生素 10/3").doesNotContain("维生素  ");
  }
}
