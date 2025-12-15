package com.examdb.api.course;

import java.util.UUID;

public class Course {
    private final UUID id;
    private final String code;
    private final String title;
    private final UUID ownerId;

    public Course(UUID id, String code, String title, UUID ownerId) {
        this.id = id;
        this.code = code;
        this.title = title;
        this.ownerId = ownerId;
    }

    public UUID getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public String getTitle() {
        return title;
    }

    public UUID getOwnerId() {
        return ownerId;
    }
}
