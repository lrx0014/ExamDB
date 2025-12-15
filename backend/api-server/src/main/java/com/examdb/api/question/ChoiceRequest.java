package com.examdb.api.question;

import jakarta.validation.constraints.NotBlank;

public class ChoiceRequest {
    @NotBlank
    private String body;
    private boolean isCorrect;

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public boolean isCorrect() {
        return isCorrect;
    }

    public void setCorrect(boolean correct) {
        isCorrect = correct;
    }
}
