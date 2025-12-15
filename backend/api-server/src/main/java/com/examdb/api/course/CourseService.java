package com.examdb.api.course;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class CourseService {
    private final CourseRepository repo;

    public CourseService(CourseRepository repo) {
        this.repo = repo;
    }

    public Course create(CreateCourseRequest req) {
        try {
            return repo.create(req.getCode(), req.getTitle(), req.getOwnerId());
        } catch (DuplicateKeyException e) {
            throw new IllegalArgumentException("Course code already exists");
        }
    }

    public Optional<Course> get(UUID id) {
        return repo.findById(id);
    }

    public List<Course> list() {
        return repo.list();
    }

    public void softDelete(UUID id) {
        repo.softDelete(id);
    }
}
