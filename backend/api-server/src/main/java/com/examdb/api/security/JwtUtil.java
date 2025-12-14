package com.examdb.api.security;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
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

    private static String hmacSha256(String data, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] sig = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return B64_URL_ENCODER.encodeToString(sig);
    }
}
