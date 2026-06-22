package com.caretoday.api.release;

import com.caretoday.api.auth.AuthInterceptor;
import com.caretoday.api.auth.AuthRepository;
import com.caretoday.api.auth.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

/**
 * App 版本检查与发布管理。
 * GET /api/app/version 公开（客户端检查更新）。
 * 其余接口需登录且账号在 ADMIN_ACCOUNTS 白名单内。
 */
@RestController
@RequestMapping("/api/app")
public class AppVersionController {
  private final AppReleaseStore store;
  private final AuthRepository authRepository;
  private final Set<String> adminAccounts;
  private final String apkBaseUrl;

  public AppVersionController(
      AppReleaseStore store,
      AuthRepository authRepository,
      @Value("${care-today.admin-accounts:}") String adminAccounts,
      @Value("${care-today.apk-base-url}") String apkBaseUrl) {
    this.store = store;
    this.authRepository = authRepository;
    this.adminAccounts = new HashSet<>(Arrays.stream(adminAccounts.split(","))
        .map(String::trim)
        .filter(value -> !value.isBlank())
        .map(String::toLowerCase)
        .toList());
    this.apkBaseUrl = apkBaseUrl.endsWith("/")
        ? apkBaseUrl.substring(0, apkBaseUrl.length() - 1)
        : apkBaseUrl;
  }

  /** 客户端检查更新：返回最新版本，无版本时 204。 */
  @GetMapping("/version")
  public ResponseEntity<Map<String, Object>> latest() {
    return store.latest()
        .<ResponseEntity<Map<String, Object>>>map(release -> ResponseEntity.ok(toManifest(release)))
        .orElseGet(() -> ResponseEntity.noContent().build());
  }

  @GetMapping("/versions")
  public Object listVersions(HttpServletRequest request) {
    requireAdmin(request);
    return store.list().stream().map(this::toManifest).toList();
  }

  @PostMapping("/versions")
  public ResponseEntity<Map<String, Object>> upload(
      HttpServletRequest request,
      @RequestParam("file") MultipartFile file,
      @RequestParam("versionCode") int versionCode,
      @RequestParam("versionName") String versionName,
      @RequestParam(value = "notes", required = false) String notes,
      @RequestParam(value = "forceUpdate", defaultValue = "false") boolean forceUpdate) {
    requireAdmin(request);
    if (file == null || file.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "APK 文件不能为空");
    }
    if (versionCode <= 0 || versionName == null || versionName.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "versionCode/versionName 不合法");
    }
    try {
      AppRelease release = store.add(
          versionCode, versionName.trim(), notes, forceUpdate, file, Instant.now().toString());
      return ResponseEntity.status(HttpStatus.CREATED).body(toManifest(release));
    } catch (IllegalArgumentException ex) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, ex.getMessage());
    }
  }

  @DeleteMapping("/versions/{id}")
  public ResponseEntity<Void> delete(HttpServletRequest request, @PathVariable String id) {
    requireAdmin(request);
    if (!store.delete(id)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "版本不存在");
    }
    return ResponseEntity.noContent().build();
  }

  private Map<String, Object> toManifest(AppRelease release) {
    Map<String, Object> manifest = new LinkedHashMap<>();
    manifest.put("id", release.id());
    manifest.put("versionCode", release.versionCode());
    manifest.put("versionName", release.versionName());
    manifest.put("notes", release.notes());
    manifest.put("forceUpdate", release.forceUpdate());
    manifest.put("fileSize", release.fileSize());
    manifest.put("publishedAt", release.publishedAt());
    manifest.put("apkUrl", apkBaseUrl + "/" + release.fileName());
    return manifest;
  }

  private void requireAdmin(HttpServletRequest request) {
    CurrentUser current = (CurrentUser) request.getAttribute(AuthInterceptor.CURRENT_USER_ATTRIBUTE);
    if (current == null) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "未登录");
    }
    if (adminAccounts.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "未配置管理员账号");
    }
    var user = authRepository.findById(current.id())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "账号无效"));
    boolean isAdmin =
        (user.email() != null && adminAccounts.contains(user.email().toLowerCase()))
            || (user.phone() != null && adminAccounts.contains(user.phone().toLowerCase()));
    if (!isAdmin) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "没有发布权限");
    }
  }
}
