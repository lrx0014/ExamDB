package com.examdb.api.question;

import java.util.UUID;

public class ChoiceResponse {
    private final UUID id;
    private final String body;
    private final boolean correct;

    public ChoiceResponse(UUID id, String body, boolean correct) {
        this.id = id;
        this.body = body;
        this.correct = correct;
    }

    public UUID getId() {
        return id;
    }

    public String getBody() {
        return body;
    }

    public boolean isCorrect() {
        return correct;
    }
}
