SELECT
  title,
  release_date AS release,
  count_stars As stars
FROM movies
WHERE release_date > '01-01-2000'
      AND count_stars = 1;
