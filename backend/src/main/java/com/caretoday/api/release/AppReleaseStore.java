package com.caretoday.api.release;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

/** 基于文件系统的版本仓库：APK 存到 release 目录，元数据存到 releases.json。 */
@Component
public class AppReleaseStore {
  private final Path dir;
  private final ObjectMapper mapper = new ObjectMapper();
  private final List<AppRelease> releases = new ArrayList<>();

  public AppReleaseStore(@Value("${care-today.release-dir}") String releaseDir) {
    this.dir = Path.of(releaseDir).toAbsolutePath().normalize();
  }

  @PostConstruct
  synchronized void load() {
    try {
      Files.createDirectories(dir);
      Path manifest = manifestPath();
      if (Files.exists(manifest)) {
        AppRelease[] loaded = mapper.readValue(Files.readAllBytes(manifest), AppRelease[].class);
        releases.clear();
        for (AppRelease release : loaded) {
          releases.add(release);
        }
      }
    } catch (IOException ex) {
      throw new UncheckedIOException("failed to load releases", ex);
    }
  }

  private Path manifestPath() {
    return dir.resolve("releases.json");
  }

  /** 按 versionCode 倒序返回全部版本。 */
  public synchronized List<AppRelease> list() {
    List<AppRelease> copy = new ArrayList<>(releases);
    copy.sort(Comparator.comparingInt(AppRelease::versionCode).reversed());
    return copy;
  }

  public synchronized Optional<AppRelease> latest() {
    return list().stream().findFirst();
  }

  public synchronized AppRelease add(
      int versionCode,
      String versionName,
      String notes,
      boolean forceUpdate,
      MultipartFile file,
      String publishedAt) {
    if (releases.stream().anyMatch(r -> r.versionCode() == versionCode)) {
      throw new IllegalArgumentException("versionCode " + versionCode + " 已存在");
    }
    String safeName = ("care-today-" + versionName + "-" + versionCode + ".apk")
        .replaceAll("[^A-Za-z0-9._+-]", "_");
    try {
      Path target = dir.resolve(safeName);
      file.transferTo(target.toFile());
      AppRelease release = new AppRelease(
          java.util.UUID.randomUUID().toString(),
          versionCode,
          versionName,
          notes == null ? "" : notes,
          safeName,
          Files.size(target),
          forceUpdate,
          publishedAt);
      releases.add(release);
      persist();
      return release;
    } catch (IOException ex) {
      throw new UncheckedIOException("failed to store apk", ex);
    }
  }

  public synchronized boolean delete(String id) {
    Optional<AppRelease> found = releases.stream().filter(r -> r.id().equals(id)).findFirst();
    if (found.isEmpty()) {
      return false;
    }
    AppRelease release = found.get();
    releases.remove(release);
    try {
      Files.deleteIfExists(dir.resolve(release.fileName()));
      persist();
    } catch (IOException ex) {
      throw new UncheckedIOException("failed to delete apk", ex);
    }
    return true;
  }

  private void persist() {
    try {
      Files.write(manifestPath(),
          mapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(list()));
    } catch (IOException ex) {
      throw new UncheckedIOException("failed to persist releases", ex);
    }
  }
}
