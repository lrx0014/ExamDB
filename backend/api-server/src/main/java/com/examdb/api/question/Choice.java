package com.examdb.api.question;

import java.util.UUID;

public class Choice {
    private final UUID id;
    private final UUID questionId;
    private final String body;
    private final boolean isCorrect;

    public Choice(UUID id, UUID questionId, String body, boolean isCorrect) {
        this.id = id;
        this.questionId = questionId;
        this.body = body;
        this.isCorrect = isCorrect;
    }

    public UUID getId() {
        return id;
    }

    public UUID getQuestionId() {
        return questionId;
    }

    public String getBody() {
        return body;
    }

    public boolean isCorrect() {
        return isCorrect;
    }
}
