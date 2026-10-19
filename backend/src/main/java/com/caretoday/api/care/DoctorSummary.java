package com.caretoday.api.care;

import com.caretoday.api.care.CareModels.MedicationLog;
import com.caretoday.api.care.CareModels.SymptomEvent;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.TreeSet;

/**
 * 复诊汇总：把某区间内的不良反应（症状）与用药拼成一段给医生的文本。
 *
 * <p>纯函数，无框架依赖，便于单元测试。规则见
 * docs/superpowers/specs/2026-10-19-doctor-visit-summary-design.md。
 */
public final class DoctorSummary {
  private DoctorSummary() {}

  /** 生成汇总文本。{@code from}/{@code to} 为本地日期闭区间。 */
  public static String build(
      List<SymptomEvent> symptoms,
      List<MedicationLog> medications,
      LocalDate from,
      LocalDate to,
      ZoneId zone) {
    String range = md(from) + "–" + md(to);

    // 症状：按完整 tag 分组，收集去重日期。
    LinkedHashMap<String, TreeSet<LocalDate>> symptomGroups = new LinkedHashMap<>();
    for (SymptomEvent s : symptoms) {
      LocalDate day = localDate(s.happenedAt(), zone);
      if (!inRange(day, from, to)) {
        continue;
      }
      symptomGroups
          .computeIfAbsent(s.tag() == null ? "" : s.tag(), key -> new TreeSet<>())
          .add(day);
    }

    // 用药：按 (名称 + 剂量) 分组。
    LinkedHashMap<String, MedGroup> medGroups = new LinkedHashMap<>();
    for (MedicationLog m : medications) {
      LocalDate day = localDate(m.takenAt(), zone);
      if (!inRange(day, from, to)) {
        continue;
      }
      String name = m.name() == null ? "" : m.name();
      String dosage = m.dosage() == null ? "" : m.dosage().trim();
      medGroups
          .computeIfAbsent(name + '\u0000' + dosage, key -> new MedGroup(name, dosage))
          .dates
          .add(day);
    }

    List<Line> symptomLines = new ArrayList<>();
    symptomGroups.forEach((tag, dates) ->
        symptomLines.add(new Line(dates.first(), tag + ' ' + joinDates(dates))));

    List<Line> medLines = new ArrayList<>();
    medGroups.values().forEach(group -> {
      String head = group.dosage.isBlank() ? group.name : group.name + ' ' + group.dosage;
      medLines.add(new Line(group.dates.first(), head + ' ' + joinDates(group.dates)));
    });

    StringBuilder sb = new StringBuilder();
    sb.append("【不良反应 · ").append(range).append("】\n");
    appendSection(sb, symptomLines);
    sb.append('\n');
    sb.append("【用药 · ").append(range).append("】\n");
    appendSection(sb, medLines);
    return sb.toString().stripTrailing();
  }

  private static void appendSection(StringBuilder sb, List<Line> lines) {
    if (lines.isEmpty()) {
      sb.append("无\n");
      return;
    }
    lines.sort(Comparator.comparing((Line l) -> l.firstDate).thenComparing(l -> l.text));
    for (Line line : lines) {
      sb.append(line.text).append('\n');
    }
  }

  /** 把一组升序去重日期按连续区间合并：9/22-9/23、9/29、10/8-10/9。 */
  static String joinDates(TreeSet<LocalDate> dates) {
    List<LocalDate> sorted = new ArrayList<>(dates);
    StringBuilder sb = new StringBuilder();
    int i = 0;
    while (i < sorted.size()) {
      LocalDate start = sorted.get(i);
      LocalDate end = start;
      while (i + 1 < sorted.size() && sorted.get(i + 1).equals(end.plusDays(1))) {
        end = sorted.get(i + 1);
        i++;
      }
      if (sb.length() > 0) {
        sb.append('、');
      }
      sb.append(start.equals(end) ? md(start) : md(start) + '-' + md(end));
      i++;
    }
    return sb.toString();
  }

  private static boolean inRange(LocalDate day, LocalDate from, LocalDate to) {
    return day != null && !day.isBefore(from) && !day.isAfter(to);
  }

  private static LocalDate localDate(Instant instant, ZoneId zone) {
    return instant == null ? null : instant.atZone(zone).toLocalDate();
  }

  /** M/D，无前导零。 */
  private static String md(LocalDate date) {
    return date.getMonthValue() + "/" + date.getDayOfMonth();
  }

  private record Line(LocalDate firstDate, String text) {}

  private static final class MedGroup {
    final String name;
    final String dosage;
    final TreeSet<LocalDate> dates = new TreeSet<>();

    MedGroup(String name, String dosage) {
      this.name = name;
      this.dosage = dosage;
    }
  }
}
