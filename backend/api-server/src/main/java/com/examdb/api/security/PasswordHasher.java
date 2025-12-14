package com.examdb.api.security;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.util.HexFormat;

public class PasswordHasher {
    private static final int SALT_BYTES = 16;
    private static final int ITERATIONS = 65_536;
    private static final int KEY_LENGTH = 256;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final HexFormat HEX = HexFormat.of();

    public static String newSalt() {
        byte[] salt = new byte[SALT_BYTES];
        RANDOM.nextBytes(salt);
        return HEX.formatHex(salt);
    }

    public static String hash(String password, String saltHex) {
        try {
            byte[] salt = HEX.parseHex(saltHex);
            PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, ITERATIONS, KEY_LENGTH);
            SecretKeyFactory skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            byte[] hash = skf.generateSecret(spec).getEncoded();
            return HEX.formatHex(hash);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to hash password", e);
        }
    }
}
