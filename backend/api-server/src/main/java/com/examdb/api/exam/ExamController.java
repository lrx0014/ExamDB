package com.examdb.api.exam;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/exams")
public class ExamController {
    private final ExamService service;

    public ExamController(ExamService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody CreateExamRequest req) {
        try {
            Exam exam = service.create(req);
            return ResponseEntity.ok(toResponse(exam));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ExamResponse> get(@PathVariable("id") UUID id) {
        return service.get(id)
                .map(ex -> ResponseEntity.ok(toResponse(ex)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<ExamResponse>> list(@RequestParam(value = "courseId", required = false) UUID courseId) {
        List<ExamResponse> items = service.list(courseId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(items);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> softDelete(@PathVariable("id") UUID id) {
        service.softDelete(id);
        return ResponseEntity.noContent().build();
    }

    private ExamResponse toResponse(Exam exam) {
        return new ExamResponse(exam.getId(), exam.getCourseId(), exam.getTitle(), exam.getStartTime(), exam.getEndTime(), exam.isPublished());
    }
}
