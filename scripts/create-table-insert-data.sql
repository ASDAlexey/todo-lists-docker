CREATE TABLE directors (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(200)
);

CREATE TABLE movies (
  id           SERIAL PRIMARY KEY,
  title        VARCHAR(100) NOT NULL,
  release_date DATE,
  count_stars  INTEGER,
  director_id  INTEGER
);

INSERT INTO directors (name) VALUES ('Alexey'), ('Sasha');

INSERT INTO movies (title, release_date, count_stars, director_id) VALUES (
  'Kill Bill',
  '10-10-2003',
  1,
  1
), (
  'Funny people',
  '07-20-2009',
  5,
  2
);

SELECT * FROM directors;
SELECT * FROM movies;


