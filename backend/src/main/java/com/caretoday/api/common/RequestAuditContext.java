package com.caretoday.api.common;

public final class RequestAuditContext {
  private static final ThreadLocal<AuditRequest> CURRENT = new ThreadLocal<>();

  private RequestAuditContext() {}

  public static void set(String ipAddress, String userAgent) {
    CURRENT.set(new AuditRequest(ipAddress, userAgent));
  }

  public static String ipAddress() {
    AuditRequest request = CURRENT.get();
    return request == null ? null : request.ipAddress();
  }

  public static String userAgent() {
    AuditRequest request = CURRENT.get();
    return request == null ? null : request.userAgent();
  }

  public static void clear() {
    CURRENT.remove();
  }

  private record AuditRequest(String ipAddress, String userAgent) {}
}
