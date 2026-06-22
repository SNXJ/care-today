package com.caretoday.api.auth;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class AuthRateLimiter {
  private static final int MAX_FAILURES = 8;
  private static final Duration WINDOW = Duration.ofMinutes(15);

  private final Map<String, Attempt> attempts = new ConcurrentHashMap<>();

  public void check(String key) {
    Attempt attempt = attempts.get(key);
    if (attempt == null) {
      return;
    }
    Instant now = Instant.now();
    if (attempt.windowStarted.plus(WINDOW).isBefore(now)) {
      attempts.remove(key);
      return;
    }
    if (attempt.failures >= MAX_FAILURES) {
      throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "尝试次数过多，请稍后再试");
    }
  }

  public void recordFailure(String key) {
    Instant now = Instant.now();
    attempts.compute(key, (ignored, attempt) -> {
      if (attempt == null || attempt.windowStarted.plus(WINDOW).isBefore(now)) {
        return new Attempt(1, now);
      }
      return new Attempt(attempt.failures + 1, attempt.windowStarted);
    });
  }

  public void reset(String key) {
    attempts.remove(key);
  }

  private record Attempt(int failures, Instant windowStarted) {}
}
