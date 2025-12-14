package com.examdb.api.auth;

import com.examdb.api.security.JwtUtil;
import com.examdb.api.user.User;
import com.examdb.api.user.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserService userService;

    @Value("${app.auth.jwt-secret:change-me-secret}")
    private String jwtSecret;

    @Value("${app.auth.jwt-ttl-seconds:900}")
    private long jwtTtlSeconds;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody AuthRequest req) {
        try {
            User user = userService.register(req.getEmail(), req.getFullName(), req.getPassword());
            String token = tokenFor(user);
            return ResponseEntity.ok(new AuthResponse(token));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(409).body(new ErrorResponse("Email already registered"));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest req) {
        return userService.authenticate(req.getEmail(), req.getPassword())
                .map(u -> ResponseEntity.ok(new AuthResponse(tokenFor(u))))
                .orElseGet(() -> ResponseEntity.status(401).build());
    }

    private String tokenFor(User user) {
        return JwtUtil.sign(
                Map.of("sub", user.getEmail(), "uid", user.getId().toString()),
                jwtSecret,
                jwtTtlSeconds
        );
    }
}
