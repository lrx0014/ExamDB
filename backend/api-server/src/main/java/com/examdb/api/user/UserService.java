package com.examdb.api.user;

import com.examdb.api.security.PasswordHasher;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {
    private final UserRepository repo;

    @Value("${app.auth.jwt-secret:change-me-secret}")
    private String jwtSecret;

    public UserService(UserRepository repo) {
        this.repo = repo;
    }

    public User register(String email, String fullName, String password) {
        if (repo.findByEmail(email.toLowerCase()).isPresent()) {
            throw new IllegalArgumentException("Email already registered");
        }
        String salt = PasswordHasher.newSalt();
        String hash = PasswordHasher.hash(password, salt);
        String stored = salt + ":" + hash;
        return repo.insert(email.toLowerCase(), fullName, stored);
    }

    public Optional<User> authenticate(String email, String password) {
        User user = repo.findByEmail(email.toLowerCase()).orElse(null);
        if (user == null) {
            return Optional.empty();
        }
        String[] parts = user.getPasswordHash().split(":", 2);
        if (parts.length != 2) return Optional.empty();
        String salt = parts[0];
        String candidate = PasswordHasher.hash(password, salt);
        if (!candidate.equals(parts[1])) return Optional.empty();
        return Optional.of(user);
    }
}
