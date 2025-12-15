package com.examdb.api.question;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class QuestionResponse {
    private final UUID id;
    private final UUID examId;
    private final String qtype;
    private final String body;
    private final BigDecimal points;
    private final int position;
    private final List<ChoiceResponse> choices;

    public QuestionResponse(UUID id, UUID examId, String qtype, String body, BigDecimal points, int position, List<ChoiceResponse> choices) {
        this.id = id;
        this.examId = examId;
        this.qtype = qtype;
        this.body = body;
        this.points = points;
        this.position = position;
        this.choices = choices;
    }

    public UUID getId() {
        return id;
    }

    public UUID getExamId() {
        return examId;
    }

    public String getQtype() {
        return qtype;
    }

    public String getBody() {
        return body;
    }

    public BigDecimal getPoints() {
        return points;
    }

    public int getPosition() {
        return position;
    }

    public List<ChoiceResponse> getChoices() {
        return choices;
    }
}
