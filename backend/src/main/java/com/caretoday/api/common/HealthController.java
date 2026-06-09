package com.caretoday.api.common;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HealthController {
  private final String medicalBoundary;

  public HealthController(@Value("${care-today.medical-boundary}") String medicalBoundary) {
    this.medicalBoundary = medicalBoundary;
  }

  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of(
        "status", "ok",
        "service", "care-today-backend",
        "medicalBoundary", medicalBoundary);
  }
}
