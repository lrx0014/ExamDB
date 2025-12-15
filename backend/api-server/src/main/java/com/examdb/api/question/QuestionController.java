package com.examdb.api.question;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/questions")
@io.swagger.v3.oas.annotations.security.SecurityRequirement(name = "bearerAuth")
public class QuestionController {
    private final QuestionService service;

    public QuestionController(QuestionService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody CreateQuestionRequest req) {
        try {
            Question q = service.create(req);
            return ResponseEntity.ok(toResponse(q));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<QuestionResponse> get(@PathVariable("id") UUID id) {
        return service.get(id)
                .map(q -> ResponseEntity.ok(toResponse(q)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<QuestionResponse>> list(@RequestParam("examId") UUID examId) {
        List<QuestionResponse> items = service.listByExam(examId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(items);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> softDelete(@PathVariable("id") UUID id) {
        service.softDelete(id);
        return ResponseEntity.noContent().build();
    }

    private QuestionResponse toResponse(Question q) {
        List<ChoiceResponse> choiceResponses = null;
        if (q.getChoices() != null) {
            choiceResponses = q.getChoices().stream()
                    .map(c -> new ChoiceResponse(c.getId(), c.getBody(), c.isCorrect()))
                    .collect(Collectors.toList());
        }
        return new QuestionResponse(q.getId(), q.getExamId(), q.getQtype(), q.getBody(), q.getPoints(), q.getPosition(), choiceResponses);
    }
}
