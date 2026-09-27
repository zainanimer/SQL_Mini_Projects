-- HR Employee Management Database

-- SCHEMA


DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Departments within the company
CREATE TABLE departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL,
    location        VARCHAR(50)
);

-- Job titles and their salary bands
CREATE TABLE jobs (
    job_id     SERIAL PRIMARY KEY,
    job_title  VARCHAR(50) NOT NULL,
    min_salary NUMERIC(10, 2),
    max_salary NUMERIC(10, 2)
);

-- Employees, with a self-referencing manager relationship
CREATE TABLE employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    hire_date     DATE NOT NULL,
    job_id        INT REFERENCES jobs(job_id),
    salary        NUMERIC(10, 2) NOT NULL,
    department_id INT REFERENCES departments(department_id),
    manager_id    INT REFERENCES employees(employee_id)
);

-- Projects run by the company
CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    start_date   DATE,
    end_date     DATE,
    budget       NUMERIC(12, 2)
);

-- Many-to-many: employees assigned to projects
CREATE TABLE employee_projects (
    employee_id INT REFERENCES employees(employee_id),
    project_id  INT REFERENCES projects(project_id),
    role        VARCHAR(50),
    PRIMARY KEY (employee_id, project_id)
);

-- SEED DATA

INSERT INTO departments (department_name, location) VALUES
('Engineering', 'Amman'),
('Sales',       'Dubai'),
('Marketing',   'Cairo'),
('Finance',     'Amman'),
('Human Resources', 'Remote');

INSERT INTO jobs (job_title, min_salary, max_salary) VALUES
('Software Engineer',  4000, 9000),
('Senior Engineer',    9000, 15000),
('Sales Rep',          2500, 6000),
('Sales Manager',      6000, 11000),
('Marketing Specialist', 3000, 7000),
('Accountant',         3500, 7500),
('HR Coordinator',     3000, 6500),
('VP',                12000, 20000);

-- Managers first (manager_id left NULL, updated later)
INSERT INTO employees (first_name, last_name, email, hire_date, job_id, salary, department_id, manager_id) VALUES
('Laila', 'Haddad',   'laila.haddad@example.com',   '2018-03-01', 8, 18500, 1, NULL), -- VP Engineering
('Omar',  'Nasser',   'omar.nasser@example.com',    '2018-06-15', 8, 17000, 2, NULL), -- VP Sales
('Sami',  'Khoury',   'sami.khoury@example.com',    '2019-01-10', 2, 12000, 1, 1),
('Dana',  'Odeh',     'dana.odeh@example.com',      '2019-04-22', 2, 11500, 1, 1),
('Rami',  'Saleh',    'rami.saleh@example.com',     '2020-02-11', 1, 7000,  1, 3),
('Nour',  'Khalil',   'nour.khalil@example.com',    '2020-07-19', 1, 6800,  1, 3),
('Yara',  'Mansour',  'yara.mansour@example.com',   '2021-01-05', 1, 6200,  1, 4),
('Hana',  'Saad',     'hana.saad@example.com',      '2021-09-13', 4, 9500,  2, 2),
('Karim', 'Aziz',     'karim.aziz@example.com',     '2019-11-01', 3, 4200,  2, 8),
('Lina',  'Fares',    'lina.fares@example.com',     '2022-03-08', 3, 4500,  2, 8),
('Tariq', 'Younes',   'tariq.younes@example.com',   '2020-05-17', 5, 5200,  3, NULL),
('Salma', 'Barakat',  'salma.barakat@example.com',  '2022-08-02', 5, 4800,  3, 11),
('Adel',  'Qasem',    'adel.qasem@example.com',     '2018-12-01', 6, 6500,  4, NULL),
('Rania', 'Sabbagh',  'rania.sabbagh@example.com',  '2021-06-21', 6, 5900,  4, 13),
('Fadi',  'Zaidan',   'fadi.zaidan@example.com',    '2019-09-09', 7, 4800,  5, NULL);

INSERT INTO projects (project_name, start_date, end_date, budget) VALUES
('Website Redesign',       '2023-01-15', '2023-06-30', 85000),
('Mobile App Launch',      '2023-03-01', '2023-12-01', 220000),
('CRM Migration',          '2022-11-01', '2023-04-15', 150000),
('Q3 Marketing Campaign',  '2023-07-01', '2023-09-30', 60000),
('Payroll System Upgrade', '2023-02-01', '2023-05-01', 40000);

INSERT INTO employee_projects (employee_id, project_id, role) VALUES
(3, 1, 'Lead Developer'),
(4, 1, 'Backend Developer'),
(5, 1, 'Frontend Developer'),
(3, 2, 'Technical Lead'),
(6, 2, 'Developer'),
(7, 2, 'Developer'),
(4, 3, 'Integration Lead'),
(9, 4, 'Campaign Coordinator'),
(10, 4, 'Content Specialist'),
(11, 4, 'Marketing Lead'),
(14, 5, 'Finance Analyst'),
(13, 5, 'Project Sponsor');

-- ------------------------------------------------------------
-- QUERIES + OUTPUT
-- ------------------------------------------------------------

-- 1. List all employees, most recently hired first
SELECT first_name, last_name, hire_date
FROM employees
ORDER BY hire_date DESC;
/* Output:
first_name | last_name | hire_date 
-----------+-----------+-----------
Salma      | Barakat   | 2022-08-02
Lina       | Fares     | 2022-03-08
Hana       | Saad      | 2021-09-13
Rania      | Sabbagh   | 2021-06-21
Yara       | Mansour   | 2021-01-05
Nour       | Khalil    | 2020-07-19
Tariq      | Younes    | 2020-05-17
Rami       | Saleh     | 2020-02-11
Karim      | Aziz      | 2019-11-01
Fadi       | Zaidan    | 2019-09-09
Dana       | Odeh      | 2019-04-22
Sami       | Khoury    | 2019-01-10
Adel       | Qasem     | 2018-12-01
Omar       | Nasser    | 2018-06-15
Laila      | Haddad    | 2018-03-01
(15 rows)
*/

-- 2. Employees earning more than 6000
SELECT first_name, last_name, salary
FROM employees
WHERE salary > 6000
ORDER BY salary DESC;
/* Output:
first_name | last_name | salary
-----------+-----------+-------
Laila      | Haddad    | 18500 
Omar       | Nasser    | 17000 
Sami       | Khoury    | 12000 
Dana       | Odeh      | 11500 
Hana       | Saad      | 9500  
Rami       | Saleh     | 7000  
Nour       | Khalil    | 6800  
Adel       | Qasem     | 6500  
Yara       | Mansour   | 6200  
(9 rows)
*/

-- 3. Employees hired in 2021
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date BETWEEN '2021-01-01' AND '2021-12-31';
/* Output:
first_name | last_name | hire_date 
-----------+-----------+-----------
Yara       | Mansour   | 2021-01-05
Hana       | Saad      | 2021-09-13
Rania      | Sabbagh   | 2021-06-21
(3 rows)
*/

-- 4. Full name + department name for every employee (INNER JOIN)
SELECT e.first_name || ' ' || e.last_name AS full_name,
       d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.department_name;
/* Output:
full_name     | department_name
--------------+----------------
Laila Haddad  | Engineering    
Sami Khoury   | Engineering    
Dana Odeh     | Engineering    
Rami Saleh    | Engineering    
Nour Khalil   | Engineering    
Yara Mansour  | Engineering    
Adel Qasem    | Finance        
Rania Sabbagh | Finance        
Fadi Zaidan   | Human Resources
Tariq Younes  | Marketing      
Salma Barakat | Marketing      
Omar Nasser   | Sales          
Hana Saad     | Sales          
Karim Aziz    | Sales          
Lina Fares    | Sales          
(15 rows)
*/

-- 5. Employees with their job title and salary band (JOIN across 2 tables)
SELECT e.first_name, e.last_name, j.job_title, e.salary, j.min_salary, j.max_salary
FROM employees e
JOIN jobs j ON e.job_id = j.job_id;
/* Output:
first_name | last_name | job_title            | salary | min_salary | max_salary
-----------+-----------+----------------------+--------+------------+-----------
Laila      | Haddad    | VP                   | 18500  | 12000      | 20000     
Omar       | Nasser    | VP                   | 17000  | 12000      | 20000     
Sami       | Khoury    | Senior Engineer      | 12000  | 9000       | 15000     
Dana       | Odeh      | Senior Engineer      | 11500  | 9000       | 15000     
Rami       | Saleh     | Software Engineer    | 7000   | 4000       | 9000      
Nour       | Khalil    | Software Engineer    | 6800   | 4000       | 9000      
Yara       | Mansour   | Software Engineer    | 6200   | 4000       | 9000      
Hana       | Saad      | Sales Manager        | 9500   | 6000       | 11000     
Karim      | Aziz      | Sales Rep            | 4200   | 2500       | 6000      
Lina       | Fares     | Sales Rep            | 4500   | 2500       | 6000      
Tariq      | Younes    | Marketing Specialist | 5200   | 3000       | 7000      
Salma      | Barakat   | Marketing Specialist | 4800   | 3000       | 7000      
Adel       | Qasem     | Accountant           | 6500   | 3500       | 7500      
Rania      | Sabbagh   | Accountant           | 5900   | 3500       | 7500      
Fadi       | Zaidan    | HR Coordinator       | 4800   | 3000       | 6500      
(15 rows)
*/

-- 6. Each employee with their manager's name (self JOIN)
SELECT e.first_name || ' ' || e.last_name AS employee,
       m.first_name || ' ' || m.last_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY manager;
/* Output:
employee      | manager     
--------------+-------------
Laila Haddad  | NULL        
Omar Nasser   | NULL        
Tariq Younes  | NULL        
Adel Qasem    | NULL        
Fadi Zaidan   | NULL        
Rania Sabbagh | Adel Qasem  
Yara Mansour  | Dana Odeh   
Karim Aziz    | Hana Saad   
Lina Fares    | Hana Saad   
Sami Khoury   | Laila Haddad
Dana Odeh     | Laila Haddad
Hana Saad     | Omar Nasser 
Rami Saleh    | Sami Khoury 
Nour Khalil   | Sami Khoury 
Salma Barakat | Tariq Younes
(15 rows)
*/

-- 7. Headcount per department
SELECT d.department_name, COUNT(e.employee_id) AS headcount
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY headcount DESC;
/* Output:
department_name | headcount
----------------+----------
Engineering     | 6        
Sales           | 4        
Marketing       | 2        
Finance         | 2        
Human Resources | 1        
(5 rows)
*/

-- 8. Average salary per department
SELECT d.department_name, ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY avg_salary DESC;
/* Output:
department_name | avg_salary
----------------+-----------
Engineering     | 10333.33  
Sales           | 8800      
Finance         | 6200      
Marketing       | 5000      
Human Resources | 4800      
(5 rows)
*/

-- 9. Departments with more than 2 employees (GROUP BY + HAVING)
SELECT d.department_name, COUNT(*) AS headcount
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
HAVING COUNT(*) > 2;
/* Output:
department_name | headcount
----------------+----------
Engineering     | 6        
Sales           | 4        
(2 rows)
*/

-- 10. Highest-paid employee in each department (subquery)
SELECT d.department_name, e.first_name, e.last_name, e.salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.salary = (
    SELECT MAX(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);
/* Output:
department_name | first_name | last_name | salary
----------------+------------+-----------+-------
Engineering     | Laila      | Haddad    | 18500 
Sales           | Omar       | Nasser    | 17000 
Marketing       | Tariq      | Younes    | 5200  
Finance         | Adel       | Qasem     | 6500  
Human Resources | Fadi       | Zaidan    | 4800  
(5 rows)
*/

-- 11. Employees who are NOT assigned to any project (LEFT JOIN + IS NULL)
SELECT e.first_name, e.last_name
FROM employees e
LEFT JOIN employee_projects ep ON e.employee_id = ep.employee_id
WHERE ep.project_id IS NULL;
/* Output:
first_name | last_name
-----------+----------
Laila      | Haddad   
Omar       | Nasser   
Hana       | Saad     
Salma      | Barakat  
Fadi       | Zaidan   
(5 rows)
*/

-- 12. Project roster: project name + everyone working on it
SELECT p.project_name, e.first_name, e.last_name, ep.role
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
JOIN employees e ON ep.employee_id = e.employee_id
ORDER BY p.project_name;
/* Output:
project_name           | first_name | last_name | role                
-----------------------+------------+-----------+---------------------
CRM Migration          | Dana       | Odeh      | Integration Lead    
Mobile App Launch      | Sami       | Khoury    | Technical Lead      
Mobile App Launch      | Nour       | Khalil    | Developer           
Mobile App Launch      | Yara       | Mansour   | Developer           
Payroll System Upgrade | Rania      | Sabbagh   | Finance Analyst     
Payroll System Upgrade | Adel       | Qasem     | Project Sponsor     
Q3 Marketing Campaign  | Karim      | Aziz      | Campaign Coordinator
Q3 Marketing Campaign  | Lina       | Fares     | Content Specialist  
Q3 Marketing Campaign  | Tariq      | Younes    | Marketing Lead      
Website Redesign       | Sami       | Khoury    | Lead Developer      
Website Redesign       | Dana       | Odeh      | Backend Developer   
Website Redesign       | Rami       | Saleh     | Frontend Developer  
(12 rows)
*/

-- 13. Number of employees per project
SELECT p.project_name, COUNT(ep.employee_id) AS team_size
FROM projects p
LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
GROUP BY p.project_name
ORDER BY team_size DESC;
/* Output:
project_name           | team_size
-----------------------+----------
Website Redesign       | 3        
Q3 Marketing Campaign  | 3        
Mobile App Launch      | 3        
Payroll System Upgrade | 2        
CRM Migration          | 1        
(5 rows)
*/

-- 14. Total project budget by department (multi-table JOIN)
SELECT d.department_name, SUM(p.budget) AS total_budget
FROM departments d
JOIN employees e ON d.department_id = e.department_id
JOIN employee_projects ep ON e.employee_id = ep.employee_id
JOIN projects p ON ep.project_id = p.project_id
GROUP BY d.department_name
ORDER BY total_budget DESC;
/* Output:
department_name | total_budget
----------------+-------------
Engineering     | 1065000     
Sales           | 120000      
Finance         | 80000       
Marketing       | 60000       
(4 rows)
*/

-- 15. Employees earning above their job's midpoint salary
SELECT e.first_name, e.last_name, e.salary, j.job_title,
       (j.min_salary + j.max_salary) / 2 AS midpoint_salary
FROM employees e
JOIN jobs j ON e.job_id = j.job_id
WHERE e.salary > (j.min_salary + j.max_salary) / 2;
/* Output:
first_name | last_name | salary | job_title            | midpoint_salary
-----------+-----------+--------+----------------------+----------------
Laila      | Haddad    | 18500  | VP                   | 16000          
Omar       | Nasser    | 17000  | VP                   | 16000          
Rami       | Saleh     | 7000   | Software Engineer    | 6500           
Nour       | Khalil    | 6800   | Software Engineer    | 6500           
Hana       | Saad      | 9500   | Sales Manager        | 8500           
Lina       | Fares     | 4500   | Sales Rep            | 4250           
Tariq      | Younes    | 5200   | Marketing Specialist | 5000           
Adel       | Qasem     | 6500   | Accountant           | 5500           
Rania      | Sabbagh   | 5900   | Accountant           | 5500           
Fadi       | Zaidan    | 4800   | HR Coordinator       | 4750           
(10 rows)
*/
