-- 1.Şirketin Genel Durumu

-- 1) Bugüne kadar çalışan toplam insan sayısı;
SELECT 
    dept_no, -- PowerBI da ilişki kurabilmek için tüm sorgularıma "dept_no" ekledim ve departments tablosu üzerinden one to many ilişki kurdum
    COUNT(DISTINCT emp_no) 
FROM dept_emp
GROUP BY dept_no WITH ROLLUP; -- 300.024 toplam çalışan
-- 2) Aktif çalışan toplam insan sayısı;
SELECT 
dept_emp.dept_no,
COUNT(DISTINCT dept_emp.emp_no) FROM dept_emp
WHERE dept_emp.to_date = '9999-01-01' -- 240.124 aktif kişi
GROUP BY dept_no;
-- 3) Turnover oranı;
SELECT 
    de.dept_no,
    COUNT(DISTINCT de.emp_no) AS total_employees, -- toplam çalışan sayısı
    COUNT(DISTINCT de.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END) AS left_employees, -- ayrılan çalışan sayısı
    ROUND(
        (COUNT(DISTINCT de.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END)) * 100.0 
        / COUNT(DISTINCT de.emp_no), 2
    ) AS turnover_rate_percentage -- turnover oranı %19.97
FROM dept_emp AS de
GROUP BY de.dept_no WITH ROLLUP; 

-- 2. Departman Bazlı Ayrılma Oranı
SELECT 
    d.dept_name, 
    de.dept_no,
    -- 1)  Departmandaki toplam net çalışan sayısı;
    COUNT(DISTINCT de.emp_no) AS total_employees,
    -- 2) Departmandan ayrılan net çalışan sayısı;
    COUNT(DISTINCT de.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END) AS left_employees,
    -- 3) Departman bazlı turnover oranı; 
    ROUND(
        (COUNT(DISTINCT de.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END)) * 100.0 
        / COUNT(DISTINCT de.emp_no), 2) 
    AS department_turnover_rate
FROM dept_emp AS de 
JOIN departments AS d ON d.dept_no = de.dept_no 
GROUP BY d.dept_name, de.dept_no
ORDER BY department_turnover_rate DESC;

-- 3. Unvan Bazlı Turnover Analizi (Terfi Edenleri Ayıklayarak)
SELECT 
    de.dept_no,
    t.title AS job_title,
    -- 1) Bu unvanda bulunmuş toplam net çalışan sayısı;
    COUNT(DISTINCT t.emp_no) AS total_employees,
    -- 2) Bu unvanda bulunmuş ama BUGÜN ŞİRKETTEN TAMAMEN AYRILMIŞ (Aktif tek bir kaydı bile olmayan) insan sayısı;
    COUNT(DISTINCT t.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN t.emp_no END) AS left_employees,
    -- 3) Unvan bazlı turnover oranı;
    ROUND(
        (COUNT(DISTINCT t.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END)) * 100.0 
        / COUNT(DISTINCT t.emp_no), 
        2
    ) AS title_turnover_rate
FROM titles AS t
JOIN dept_emp AS de ON t.emp_no = de.emp_no
GROUP BY de.dept_no, t.title
ORDER BY title_turnover_rate DESC;
        
-- 2 ve 3 Departman ve Unvan Çapraz Analizi 
SELECT 
    d.dept_name AS department_name,
    t.title AS job_title,
    -- O departmandaki o unvana sahip toplam çalışan;
    COUNT(DISTINCT t.emp_no) AS total_employees,
    -- O departmandaki o unvana sahip şirketten ayrılan net çalışan;
    COUNT(DISTINCT t.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END) AS left_employees,
    -- Çapraz turnover oranı;
    ROUND(
        (COUNT(DISTINCT t.emp_no) - COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END)) * 100.0 
        / COUNT(DISTINCT t.emp_no), 2)
    AS cross_turnover_rate
FROM titles AS t
JOIN dept_emp AS de ON t.emp_no = de.emp_no
JOIN departments AS d ON d.dept_no = de.dept_no
GROUP BY d.dept_name, t.title
ORDER BY cross_turnover_rate DESC;

-- 4. Yıllara Göre İşten Ayrılan Sayısı
SELECT
    de.dept_no,
    YEAR(de.to_date) AS year_,
    COUNT(de.emp_no) AS left_employees,
    -- 1) O yıl o departmanda aktif olan çalışan sayısı
    (SELECT COUNT(DISTINCT sub.emp_no)
     FROM dept_emp AS sub
     WHERE sub.dept_no = de.dept_no
       AND YEAR(sub.from_date) <= YEAR(de.to_date) 
       AND (sub.to_date = '9999-01-01' OR YEAR(sub.to_date) >= YEAR(de.to_date))
    ) AS active_employees,
    -- 2) O yılki turnover oranı
    ROUND(
        COUNT(de.emp_no) * 100.0 /         
        (SELECT COUNT(DISTINCT sub.emp_no)
         FROM dept_emp AS sub
         WHERE sub.dept_no = de.dept_no -- Bu satırı ekledik!
           AND YEAR(sub.from_date) <= YEAR(de.to_date) 
           AND (sub.to_date = '9999-01-01' OR YEAR(sub.to_date) >= YEAR(de.to_date))
        ), 2
    ) AS turnover_rate_percentage
FROM dept_emp AS de
WHERE de.to_date <> '9999-01-01'
GROUP BY de.dept_no, YEAR(de.to_date)
ORDER BY year_;

-- 5. Departmanlara Göre Güncel Maaşlar
SELECT
      d.dept_name,
      de.dept_no,
      ROUND(AVG(s.salary),2) AS average_salary,
      COUNT(DISTINCT de.emp_no) AS active_employees
FROM dept_emp AS de
JOIN departments AS d ON de.dept_no = d.dept_no
JOIN salaries AS s ON de.emp_no = s.emp_no
WHERE de.to_date = '9999-01-01' AND s.to_date = '9999-01-01'
GROUP BY d.dept_name, de.dept_no
ORDER BY average_salary DESC; -- Salaries tablosunda her çalışanın verisi yok bunun sonucu örneklem veriden ortalama maaş bulunmuştur

-- 6. Cinsiyete Göre Maaş Ortalaması 

SELECT 
    de.dept_no,
    e.gender,
    -- 1) Aktif kadın ve erkek çalışan sayısı;
    COUNT(DISTINCT e.emp_no) AS active_employees,
    -- 2) Ortalama güncel maaşları;
    ROUND(AVG(CAST(s.salary AS DECIMAL (18,2))), 2) AS average_salary,
    -- 3) En düşük maaşlar;
    MIN(s.salary) AS min_salary,
    -- 4) En yüksek maaşlar;
    MAX(s.salary) AS max_salary
FROM employees AS e
JOIN dept_emp AS de ON e.emp_no = de.emp_no
JOIN salaries AS s ON e.emp_no = s.emp_no
-- Sadece şu an aktif çalışanları ve güncel maaşları alıyoruz (geriye dönükleri eledik!)
WHERE de.to_date = '9999-01-01' 
  AND s.to_date = '9999-01-01'
GROUP BY de.dept_no, e.gender; -- Bu da salaries tablosundan alınan ortalama maaş verisi

-- 7. Ayrılan Çalışanların Çalışma Yılına Göre Ayrılma Analizi
SELECT 
    de.dept_no,
    CASE 
        WHEN DATEDIFF(YEAR, e.hire_date, de.to_date) < 2 THEN '0-2 Year (New Hire)'
        WHEN DATEDIFF(YEAR, e.hire_date, de.to_date) BETWEEN 2 AND 5 THEN '2-5 Years (Experienced)'
        WHEN DATEDIFF(YEAR, e.hire_date, de.to_date) BETWEEN 5 AND 7 THEN '5-7 Years (Senior)'
        ELSE '7+ Years (Loyal Employee)'
    END AS seniority_range,
    COUNT(DISTINCT de.emp_no) AS left_employees_count,
    ROUND(
        COUNT(DISTINCT de.emp_no) * 100.0 / 
        SUM(COUNT(DISTINCT de.emp_no)) OVER(), 2
    ) AS percentage_rate
FROM dept_emp de
JOIN employees e ON de.emp_no = e.emp_no
WHERE de.to_date <> '9999-01-01' 
  AND de.emp_no NOT IN (SELECT emp_no FROM dept_emp WHERE to_date = '9999-01-01')
GROUP BY 
    de.dept_no,
    CASE 
        WHEN DATEDIFF(YEAR, e.hire_date, de.to_date) < 2 THEN '0-2 Year (New Hire)'
        WHEN DATEDIFF(YEAR, e.hire_date, de.to_date) BETWEEN 2 AND 5 THEN '2-5 Years (Experienced)'
        WHEN DATEDIFF(YEAR, e.hire_date, de.to_date) BETWEEN 5 AND 7 THEN '5-7 Years (Senior)'
        ELSE '7+ Years (Loyal Employee)'
    END
ORDER BY percentage_rate DESC;