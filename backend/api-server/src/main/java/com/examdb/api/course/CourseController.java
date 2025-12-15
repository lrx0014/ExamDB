package com.examdb.api.course;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/courses")
@io.swagger.v3.oas.annotations.security.SecurityRequirement(name = "bearerAuth")
public class CourseController {
    private final CourseService service;

    public CourseController(CourseService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody CreateCourseRequest req) {
        try {
            Course c = service.create(req);
            return ResponseEntity.ok(toResponse(c));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<CourseResponse> get(@PathVariable("id") UUID id) {
        return service.get(id)
                .map(c -> ResponseEntity.ok(toResponse(c)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<CourseResponse>> list() {
        List<CourseResponse> items = service.list().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(items);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> softDelete(@PathVariable("id") UUID id) {
        service.softDelete(id);
        return ResponseEntity.noContent().build();
    }

    private CourseResponse toResponse(Course c) {
        return new CourseResponse(c.getId(), c.getCode(), c.getTitle(), c.getOwnerId());
    }
}
