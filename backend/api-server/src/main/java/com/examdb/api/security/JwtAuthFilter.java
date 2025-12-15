package com.examdb.api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.Set;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    @Value("${app.auth.jwt-secret}")
    private String jwtSecret;

    private static final Set<String> OPEN_PATHS = Set.of(
            "/api/auth/register",
            "/api/auth/login"
    );

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = request.getRequestURI();
        if (isOpenPath(path) || "OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String auth = request.getHeader("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            unauthorized(response, "Missing Bearer token");
            return;
        }
        String token = auth.substring("Bearer ".length()).trim();
        try {
            Map<String, Object> claims = JwtUtil.verify(token, jwtSecret);
            request.setAttribute("jwtClaims", claims);
            filterChain.doFilter(request, response);
        } catch (IllegalArgumentException e) {
            unauthorized(response, e.getMessage());
        }
    }

    private boolean isOpenPath(String path) {
        return OPEN_PATHS.contains(path);
    }

    private void unauthorized(HttpServletResponse response, String msg) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write("{\"message\":\"" + msg.replace("\"", "") + "\"}");
    }
}
