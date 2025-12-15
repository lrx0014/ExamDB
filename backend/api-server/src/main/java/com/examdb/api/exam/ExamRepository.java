package com.examdb.api.exam;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class ExamRepository {
    private final JdbcTemplate jdbcTemplate;

    public ExamRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Exam create(UUID courseId, String title, OffsetDateTime start, OffsetDateTime end, boolean published) {
        UUID id = jdbcTemplate.queryForObject(
                "INSERT INTO exam.exams(course_id, title, start_time, end_time, is_published) VALUES (?,?,?,?,?) RETURNING id",
                UUID.class,
                courseId, title, start, end, published
        );
        return findById(id).orElseThrow();
    }

    public Optional<Exam> findById(UUID id) {
        List<Exam> result = jdbcTemplate.query(
                "SELECT id, course_id, title, start_time, end_time, is_published FROM exam.exams WHERE id = ? AND is_deleted = false",
                (rs, rowNum) -> new Exam(
                        rs.getObject("id", UUID.class),
                        rs.getObject("course_id", UUID.class),
                        rs.getString("title"),
                        rs.getObject("start_time", OffsetDateTime.class),
                        rs.getObject("end_time", OffsetDateTime.class),
                        rs.getBoolean("is_published")
                ),
                id
        );
        return result.stream().findFirst();
    }

    public List<Exam> list(UUID courseId) {
        if (courseId != null) {
            return jdbcTemplate.query(
                    "SELECT id, course_id, title, start_time, end_time, is_published FROM exam.exams WHERE is_deleted = false AND course_id = ? ORDER BY start_time",
                    (rs, rowNum) -> new Exam(
                            rs.getObject("id", UUID.class),
                            rs.getObject("course_id", UUID.class),
                            rs.getString("title"),
                            rs.getObject("start_time", OffsetDateTime.class),
                            rs.getObject("end_time", OffsetDateTime.class),
                            rs.getBoolean("is_published")
                    ),
                    courseId
            );
        }
        return jdbcTemplate.query(
                "SELECT id, course_id, title, start_time, end_time, is_published FROM exam.exams WHERE is_deleted = false ORDER BY start_time",
                (rs, rowNum) -> new Exam(
                        rs.getObject("id", UUID.class),
                        rs.getObject("course_id", UUID.class),
                        rs.getString("title"),
                        rs.getObject("start_time", OffsetDateTime.class),
                        rs.getObject("end_time", OffsetDateTime.class),
                        rs.getBoolean("is_published")
                )
        );
    }

    public void softDelete(UUID id) {
        jdbcTemplate.update("UPDATE exam.exams SET is_deleted = true WHERE id = ?", id);
    }
}
