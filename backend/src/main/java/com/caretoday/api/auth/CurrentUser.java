package com.caretoday.api.auth;

import java.util.UUID;

public record CurrentUser(UUID id, String nickname) {}
