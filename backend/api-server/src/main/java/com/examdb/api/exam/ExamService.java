package com.examdb.api.exam;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class ExamService {
    private final ExamRepository repo;

    public ExamService(ExamRepository repo) {
        this.repo = repo;
    }

    public Exam create(CreateExamRequest req) {
        if (req.getEndTime().isBefore(req.getStartTime())) {
            throw new IllegalArgumentException("endTime must be after startTime");
        }
        return repo.create(req.getCourseId(), req.getTitle(), req.getStartTime(), req.getEndTime(), req.isPublished());
    }

    public Optional<Exam> get(UUID id) {
        return repo.findById(id);
    }

    public List<Exam> list(UUID courseId) {
        return repo.list(courseId);
    }

    public void softDelete(UUID id) {
        repo.softDelete(id);
    }
}
