package com.examdb.api.question;

import com.examdb.api.security.CryptoService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class QuestionRepository {
    private final JdbcTemplate jdbcTemplate;
    private final CryptoService crypto;

    public QuestionRepository(JdbcTemplate jdbcTemplate, CryptoService crypto) {
        this.jdbcTemplate = jdbcTemplate;
        this.crypto = crypto;
    }

    public Question create(UUID examId, String qtype, String body, BigDecimal points, int position, List<ChoiceRequest> choicesReq) {
        String cipherBody = crypto.encrypt(body);
        UUID id = jdbcTemplate.queryForObject(
                "INSERT INTO exam.questions(exam_id, qtype, body, points, position) VALUES (?,?,?,?,?) RETURNING id",
                UUID.class,
                examId, qtype, cipherBody, points, position
        );
        if ("mcq".equalsIgnoreCase(qtype) && choicesReq != null) {
            for (ChoiceRequest c : choicesReq) {
                String cipherChoice = crypto.encrypt(c.getBody());
                jdbcTemplate.update(
                        "INSERT INTO exam.choices(question_id, body, is_correct) VALUES (?,?,?)",
                        id, cipherChoice, c.isCorrect()
                );
            }
        }
        return findById(id).orElseThrow();
    }

    public Optional<Question> findById(UUID id) {
        List<Question> result = jdbcTemplate.query(
                "SELECT id, exam_id, qtype, body, points, position FROM exam.questions WHERE id = ? AND is_deleted = false",
                (rs, rowNum) -> mapQuestion(
                        rs.getObject("id", UUID.class),
                        rs.getObject("exam_id", UUID.class),
                        rs.getString("qtype"),
                        crypto.decrypt(rs.getString("body")),
                        rs.getBigDecimal("points"),
                        rs.getInt("position")
                ),
                id
        );
        return result.stream().findFirst();
    }

    public List<Question> listByExam(UUID examId) {
        return jdbcTemplate.query(
                "SELECT id, exam_id, qtype, body, points, position FROM exam.questions WHERE exam_id = ? AND is_deleted = false ORDER BY position",
                (rs, rowNum) -> mapQuestion(
                        rs.getObject("id", UUID.class),
                        rs.getObject("exam_id", UUID.class),
                        rs.getString("qtype"),
                        crypto.decrypt(rs.getString("body")),
                        rs.getBigDecimal("points"),
                        rs.getInt("position")
                ),
                examId
        );
    }

    public void softDelete(UUID id) {
        jdbcTemplate.update("UPDATE exam.questions SET is_deleted = true WHERE id = ?", id);
        jdbcTemplate.update("UPDATE exam.choices SET is_deleted = true WHERE question_id = ?", id);
    }

    private Question mapQuestion(UUID id, UUID examId, String qtype, String body, BigDecimal points, int position) {
        List<Choice> choices = new ArrayList<>();
        if ("mcq".equalsIgnoreCase(qtype)) {
            choices = jdbcTemplate.query(
                    "SELECT id, question_id, body, is_correct FROM exam.choices WHERE question_id = ? AND is_deleted = false",
                    (rs, rowNum) -> new Choice(
                            rs.getObject("id", UUID.class),
                            rs.getObject("question_id", UUID.class),
                            crypto.decrypt(rs.getString("body")),
                            rs.getBoolean("is_correct")
                    ),
                    id
            );
        }
        return new Question(id, examId, qtype, body, points, position, choices);
    }
}
