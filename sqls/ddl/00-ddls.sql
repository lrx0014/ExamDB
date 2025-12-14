-- Ensure target DB exists when running manually (psql-only)
SELECT 'CREATE DATABASE exam_sys'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'exam_sys') \gexec

\connect exam_sys

-- ============================================================
--  Common Trigger: auto-update mtime
-- ============================================================
CREATE OR REPLACE FUNCTION set_mtime()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.mtime = now();
    RETURN NEW;
END;
$$;

-- ============================================================
--  Schema: auth
-- ============================================================
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE auth.users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         CITEXT UNIQUE NOT NULL,
    password_hash TEXT          NOT NULL,
    full_name     TEXT          NOT NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,

    -- metadata
    is_deleted    BOOLEAN       NOT NULL DEFAULT FALSE,
    ctime         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    mtime         TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_active ON auth.users (is_active) WHERE is_active = true;

CREATE TRIGGER trg_users_mtime
BEFORE UPDATE ON auth.users
FOR EACH ROW
EXECUTE PROCEDURE set_mtime();

--------------------------------------------------------------

CREATE TABLE auth.roles (
    id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code   TEXT UNIQUE NOT NULL
);

CREATE TABLE auth.user_roles (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES auth.roles(id) ON DELETE RESTRICT,
    ctime   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_role ON auth.user_roles(role_id, user_id);

-- ============================================================
--  Schema: exam
-- ============================================================
CREATE SCHEMA IF NOT EXISTS exam;

-- ------------------------------------------------------------
-- Courses
-- ------------------------------------------------------------
CREATE TABLE exam.courses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        TEXT NOT NULL,
    title       TEXT NOT NULL,
    owner_id    UUID NOT NULL REFERENCES auth.users(id),

    -- unified
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    ctime       TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- unique course code (active only)
CREATE UNIQUE INDEX ux_courses_code_active
    ON exam.courses(code)
    WHERE is_deleted = false;

CREATE INDEX idx_courses_owner ON exam.courses(owner_id);
CREATE INDEX idx_courses_title_trgm ON exam.courses USING GIN (title gin_trgm_ops);

CREATE TRIGGER trg_courses_mtime
BEFORE UPDATE ON exam.courses
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Exams
-- ------------------------------------------------------------
CREATE TABLE exam.exams (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id    UUID NOT NULL REFERENCES exam.courses(id) ON DELETE CASCADE,
    title        TEXT NOT NULL,
    start_time   TIMESTAMPTZ NOT NULL,
    end_time     TIMESTAMPTZ NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,

    is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
    ctime        TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (end_time > start_time)
);

CREATE INDEX idx_exams_course_time ON exam.exams(course_id, start_time, end_time);
CREATE INDEX idx_exams_published ON exam.exams(is_published) WHERE is_published = true;
CREATE INDEX idx_exams_title_trgm ON exam.exams USING GIN (title gin_trgm_ops);

CREATE TRIGGER trg_exams_mtime
BEFORE UPDATE ON exam.exams
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Questions
-- ------------------------------------------------------------
CREATE TABLE exam.questions (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id   UUID NOT NULL REFERENCES exam.exams(id) ON DELETE CASCADE,
    qtype     TEXT NOT NULL CHECK (qtype IN ('mcq','text','code')),
    body      TEXT NOT NULL,
    points    NUMERIC(6,2) NOT NULL DEFAULT 1.0,
    position  INT NOT NULL,

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    ctime      TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (exam_id, position)
);

CREATE INDEX idx_questions_exam ON exam.questions(exam_id);

CREATE TRIGGER trg_questions_mtime
BEFORE UPDATE ON exam.questions
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Choices
-- ------------------------------------------------------------
CREATE TABLE exam.choices (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES exam.questions(id) ON DELETE CASCADE,
    body        TEXT NOT NULL,
    is_correct  BOOLEAN NOT NULL DEFAULT FALSE,

    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    ctime       TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_choices_question ON exam.choices(question_id);

CREATE TRIGGER trg_choices_mtime
BEFORE UPDATE ON exam.choices
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Exam Assignments (who can take which exam)
-- ------------------------------------------------------------
CREATE TABLE exam.exam_assignments (
    exam_id     UUID NOT NULL REFERENCES exam.exams(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    ctime       TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime       TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (exam_id, user_id)
);

CREATE INDEX idx_exam_assignments_user ON exam.exam_assignments(user_id, exam_id);

CREATE TRIGGER trg_exam_assignments_mtime
BEFORE UPDATE ON exam.exam_assignments
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Submissions
-- ------------------------------------------------------------
CREATE TABLE exam.submissions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id     UUID NOT NULL REFERENCES exam.exams(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status      TEXT NOT NULL CHECK (status IN ('draft','submitted','graded')),

    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    ctime       TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime       TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- one active submission per user per exam
    UNIQUE (exam_id, user_id, is_deleted)
);

CREATE INDEX idx_submissions_user_active
    ON exam.submissions(user_id, exam_id)
    WHERE is_deleted = false;

CREATE TRIGGER trg_submissions_mtime
BEFORE UPDATE ON exam.submissions
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Answers
-- ------------------------------------------------------------
CREATE TABLE exam.answers (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id  UUID NOT NULL REFERENCES exam.submissions(id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES exam.questions(id)   ON DELETE CASCADE,
    choice_id      UUID REFERENCES exam.choices(id),
    text_answer    TEXT,

    is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    ctime          TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (submission_id, question_id),

    CHECK (
        (choice_id IS NOT NULL AND text_answer IS NULL)
        OR (choice_id IS NULL AND text_answer IS NOT NULL)
    )
);

CREATE INDEX idx_answers_submission ON exam.answers(submission_id)
    WHERE is_deleted = false;

CREATE INDEX idx_answers_question ON exam.answers(question_id);

CREATE TRIGGER trg_answers_mtime
BEFORE UPDATE ON exam.answers
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ============================================================
--  Schema: grading
-- ============================================================
CREATE SCHEMA IF NOT EXISTS grading;

-- ------------------------------------------------------------
-- Answer Grades
-- ------------------------------------------------------------
CREATE TABLE grading.answer_grades (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    answer_id   UUID NOT NULL REFERENCES exam.answers(id) ON DELETE CASCADE,
    grader_id   UUID NOT NULL REFERENCES auth.users(id),
    score       NUMERIC(6,2) NOT NULL,
    feedback    TEXT,

    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    ctime       TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime       TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (answer_id)
);

CREATE INDEX idx_answer_grades_grader ON grading.answer_grades(grader_id);

CREATE TRIGGER trg_answer_grades_mtime
BEFORE UPDATE ON grading.answer_grades
FOR EACH ROW EXECUTE PROCEDURE set_mtime();

-- ------------------------------------------------------------
-- Submission Grades
-- ------------------------------------------------------------
CREATE TABLE grading.submission_grades (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id  UUID NOT NULL REFERENCES exam.submissions(id) ON DELETE CASCADE,
    total_score    NUMERIC(8,2) NOT NULL,
    finalized_by   UUID REFERENCES auth.users(id),
    finalized_at   TIMESTAMPTZ,

    is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    ctime          TIMESTAMPTZ NOT NULL DEFAULT now(),
    mtime          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (submission_id)
);

CREATE INDEX idx_submission_grades_total ON grading.submission_grades(total_score);

CREATE TRIGGER trg_submission_grades_mtime
BEFORE UPDATE ON grading.submission_grades
FOR EACH ROW EXECUTE PROCEDURE set_mtime();
