package com.examdb.api.security;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.StringJoiner;

public class JwtUtil {
    private static final Base64.Encoder B64_URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64_URL_DECODER = Base64.getUrlDecoder();

    public static String sign(Map<String, Object> claims, String secret, long ttlSeconds) {
        try {
            String headerJson = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
            long exp = Instant.now().getEpochSecond() + ttlSeconds;
            StringJoiner payloadJoiner = new StringJoiner(",", "{", "}");
            claims.forEach((k, v) -> payloadJoiner.add("\"" + k + "\":\"" + v + "\""));
            payloadJoiner.add("\"exp\":" + exp);
            String header = B64_URL_ENCODER.encodeToString(headerJson.getBytes(StandardCharsets.UTF_8));
            String payload = B64_URL_ENCODER.encodeToString(payloadJoiner.toString().getBytes(StandardCharsets.UTF_8));
            String signingInput = header + "." + payload;
            String signature = hmacSha256(signingInput, secret);
            return signingInput + "." + signature;
        } catch (Exception e) {
            throw new IllegalStateException("Failed to sign JWT", e);
        }
    }

    public static Map<String, Object> verify(String token, String secret) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new IllegalArgumentException("Invalid token format");
            }
            String signingInput = parts[0] + "." + parts[1];
            String expectedSig = hmacSha256(signingInput, secret);
            if (!MessageDigest.isEqual(expectedSig.getBytes(StandardCharsets.UTF_8), parts[2].getBytes(StandardCharsets.UTF_8))) {
                throw new IllegalArgumentException("Invalid signature");
            }
            String payloadJson = new String(B64_URL_DECODER.decode(parts[1]), StandardCharsets.UTF_8);
            Map<String, Object> claims = parseClaims(payloadJson);
            Object expObj = claims.get("exp");
            if (expObj instanceof Number) {
                long exp = ((Number) expObj).longValue();
                if (Instant.now().getEpochSecond() > exp) {
                    throw new IllegalArgumentException("Token expired");
                }
            }
            return claims;
        } catch (Exception e) {
            throw new IllegalArgumentException("JWT verification failed: " + e.getMessage(), e);
        }
    }

    private static Map<String, Object> parseClaims(String json) {
        Map<String, Object> claims = new HashMap<>();
        String trimmed = json.trim();
        if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
            trimmed = trimmed.substring(1, trimmed.length() - 1);
            if (!trimmed.isEmpty()) {
                for (String part : trimmed.split(",")) {
                    String[] kv = part.split(":", 2);
                    if (kv.length == 2) {
                        String key = kv[0].trim().replaceAll("^\"|\"$", "");
                        String valRaw = kv[1].trim();
                        if (valRaw.matches("^\".*\"$")) {
                            claims.put(key, valRaw.replaceAll("^\"|\"$", ""));
                        } else if (valRaw.matches("^-?\\d+$")) {
                            claims.put(key, Long.parseLong(valRaw));
                        } else {
                            claims.put(key, valRaw);
                        }
                    }
                }
            }
        }
        return claims;
    }

    private static String hmacSha256(String data, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] sig = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return B64_URL_ENCODER.encodeToString(sig);
    }
}
