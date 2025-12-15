package com.examdb.api.course;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class CourseRepository {
    private final JdbcTemplate jdbcTemplate;

    public CourseRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Course create(String code, String title, UUID ownerId) {
        UUID id = jdbcTemplate.queryForObject(
                "INSERT INTO exam.courses(code, title, owner_id) VALUES (?,?,?) RETURNING id",
                UUID.class,
                code, title, ownerId
        );
        return findById(id).orElseThrow();
    }

    public Optional<Course> findById(UUID id) {
        List<Course> result = jdbcTemplate.query(
                "SELECT id, code, title, owner_id FROM exam.courses WHERE id = ? AND is_deleted = false",
                (rs, rowNum) -> new Course(
                        rs.getObject("id", UUID.class),
                        rs.getString("code"),
                        rs.getString("title"),
                        rs.getObject("owner_id", UUID.class)
                ),
                id
        );
        return result.stream().findFirst();
    }

    public List<Course> list() {
        return jdbcTemplate.query(
                "SELECT id, code, title, owner_id FROM exam.courses WHERE is_deleted = false ORDER BY title",
                (rs, rowNum) -> new Course(
                        rs.getObject("id", UUID.class),
                        rs.getString("code"),
                        rs.getString("title"),
                        rs.getObject("owner_id", UUID.class)
                )
        );
    }

    public void softDelete(UUID id) {
        jdbcTemplate.update("UPDATE exam.courses SET is_deleted = true WHERE id = ?", id);
    }
}
