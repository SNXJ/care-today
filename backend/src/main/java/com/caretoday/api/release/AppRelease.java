package com.caretoday.api.release;

/** 一个 App 发布版本的元数据，持久化在 release 目录的 releases.json 中。 */
public record AppRelease(
    String id,
    int versionCode,
    String versionName,
    String notes,
    String fileName,
    long fileSize,
    boolean forceUpdate,
    String publishedAt) {}
