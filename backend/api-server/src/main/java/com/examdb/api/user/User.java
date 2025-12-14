package com.examdb.api.user;

import java.util.UUID;

public class User {
    private final UUID id;
    private final String email;
    private final String fullName;
    private final String passwordHash;

    public User(UUID id, String email, String fullName, String passwordHash) {
        this.id = id;
        this.email = email;
        this.fullName = fullName;
        this.passwordHash = passwordHash;
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getFullName() {
        return fullName;
    }

    public String getPasswordHash() {
        return passwordHash;
    }
}
