package com.caretoday.api.common;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class ApiExceptionHandler {
  @ExceptionHandler(ResponseStatusException.class)
  public ResponseEntity<Map<String, Object>> handleResponseStatusException(
      ResponseStatusException exception,
      HttpServletRequest request) {
    return build(exception.getStatusCode().value(), exception.getStatusCode().toString(),
        exception.getReason(), request);
  }

  /** 请求体字段校验失败（@NotBlank/@Size 等）→ 返回 400 与具体提示，而非默认 400 空壳。 */
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<Map<String, Object>> handleValidation(
      MethodArgumentNotValidException exception,
      HttpServletRequest request) {
    String reason = exception.getBindingResult().getFieldErrors().stream()
        .findFirst()
        .map(error -> {
          String message = error.getDefaultMessage();
          return message == null || message.isBlank() ? error.getField() + " 不合法" : message;
        })
        .orElse("请求参数不合法");
    return build(HttpStatus.BAD_REQUEST.value(), HttpStatus.BAD_REQUEST.toString(), reason, request);
  }

  /** 数据库约束冲突（如内容超长）→ 返回 400，避免暴露为 500。 */
  @ExceptionHandler(DataIntegrityViolationException.class)
  public ResponseEntity<Map<String, Object>> handleDataIntegrity(
      DataIntegrityViolationException exception,
      HttpServletRequest request) {
    return build(HttpStatus.BAD_REQUEST.value(), HttpStatus.BAD_REQUEST.toString(),
        "内容过长或格式不正确，请缩短后重试", request);
  }

  private ResponseEntity<Map<String, Object>> build(
      int status, String error, String reason, HttpServletRequest request) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("timestamp", Instant.now().toString());
    payload.put("status", status);
    payload.put("error", error);
    payload.put("reason", reason);
    payload.put("path", request.getRequestURI());
    return ResponseEntity.status(status).body(payload);
  }
}
