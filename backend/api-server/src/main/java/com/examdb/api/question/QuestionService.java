package com.examdb.api.question;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class QuestionService {
    private final QuestionRepository repo;

    public QuestionService(QuestionRepository repo) {
        this.repo = repo;
    }

    public Question create(CreateQuestionRequest req) {
        if ("mcq".equalsIgnoreCase(req.getQtype())) {
            if (req.getChoices() == null || req.getChoices().isEmpty()) {
                throw new IllegalArgumentException("MCQ requires choices");
            }
            boolean hasCorrect = req.getChoices().stream().anyMatch(ChoiceRequest::isCorrect);
            if (!hasCorrect) {
                throw new IllegalArgumentException("At least one choice must be correct");
            }
        }
        return repo.create(req.getExamId(), req.getQtype(), req.getBody(), req.getPoints(), req.getPosition(), req.getChoices());
    }

    public Optional<Question> get(UUID id) {
        return repo.findById(id);
    }

    public List<Question> listByExam(UUID examId) {
        return repo.listByExam(examId);
    }

    public void softDelete(UUID id) {
        repo.softDelete(id);
    }
}
