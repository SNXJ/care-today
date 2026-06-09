package com.caretoday.api.common;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class ApiExceptionHandler {
  @ExceptionHandler(ResponseStatusException.class)
  public ResponseEntity<Map<String, Object>> handleResponseStatusException(
      ResponseStatusException exception,
      HttpServletRequest request) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("timestamp", Instant.now().toString());
    payload.put("status", exception.getStatusCode().value());
    payload.put("error", exception.getStatusCode().toString());
    payload.put("reason", exception.getReason());
    payload.put("path", request.getRequestURI());
    return ResponseEntity.status(exception.getStatusCode()).body(payload);
  }
}
