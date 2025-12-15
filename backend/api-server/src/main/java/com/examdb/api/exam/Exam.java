package com.examdb.api.exam;

import java.time.OffsetDateTime;
import java.util.UUID;

public class Exam {
    private final UUID id;
    private final UUID courseId;
    private final String title;
    private final OffsetDateTime startTime;
    private final OffsetDateTime endTime;
    private final boolean isPublished;

    public Exam(UUID id, UUID courseId, String title, OffsetDateTime startTime, OffsetDateTime endTime, boolean isPublished) {
        this.id = id;
        this.courseId = courseId;
        this.title = title;
        this.startTime = startTime;
        this.endTime = endTime;
        this.isPublished = isPublished;
    }

    public UUID getId() {
        return id;
    }

    public UUID getCourseId() {
        return courseId;
    }

    public String getTitle() {
        return title;
    }

    public OffsetDateTime getStartTime() {
        return startTime;
    }

    public OffsetDateTime getEndTime() {
        return endTime;
    }

    public boolean isPublished() {
        return isPublished;
    }
}
