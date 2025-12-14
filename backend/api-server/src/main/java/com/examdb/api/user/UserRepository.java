package com.examdb.api.user;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public class UserRepository {
    private final JdbcTemplate jdbcTemplate;

    private static final RowMapper<User> MAPPER = (rs, rowNum) -> new User(
            rs.getObject("id", UUID.class),
            rs.getString("email"),
            rs.getString("full_name"),
            rs.getString("password_hash")
    );

    public UserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<User> findByEmail(String email) {
        return jdbcTemplate.query("SELECT id, email, full_name, password_hash FROM auth.users WHERE email = ? AND is_deleted = false", MAPPER, email)
                .stream().findFirst();
    }

    public User insert(String email, String fullName, String passwordHash) {
        UUID id = jdbcTemplate.queryForObject(
                "INSERT INTO auth.users(email, full_name, password_hash) VALUES (?,?,?) RETURNING id",
                UUID.class,
                email, fullName, passwordHash
        );
        return new User(id, email, fullName, passwordHash);
    }
}
