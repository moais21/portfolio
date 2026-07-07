-- ============================================
-- SQL-запросы для системы учета фотостудии
-- Проект для резюме системного аналитика
-- ============================================

-- ============================================
-- БАЗОВЫЕ ЗАПРОСЫ
-- ============================================

-- Запрос 1: Получить все активные залы
SELECT name, area, base_price 
FROM halls 
WHERE is_active = TRUE
ORDER BY base_price ASC;

-- Запрос 2: Найти бронирования конкретного пользователя (ID=1)
SELECT b.id, h.name, b.start_time, b.end_time, b.status, b.total_price
FROM bookings b
JOIN halls h ON b.hall_id = h.id
WHERE b.user_id = 1
ORDER BY b.start_time DESC;

-- Запрос 3: Получить всех клиентов
SELECT first_name, last_name, email, phone
FROM users
WHERE role = 'client'
ORDER BY last_name;

-- ============================================
-- АГРЕГАТНЫЕ ФУНКЦИИ (COUNT, SUM, AVG)
-- ============================================

-- Запрос 4: Количество бронирований по статусам
SELECT status, COUNT(*) as booking_count
FROM bookings
GROUP BY status
ORDER BY booking_count DESC;

-- Запрос 5: Общая выручка по каждому залу
SELECT h.name, SUM(b.total_price) as total_revenue, COUNT(b.id) as bookings_count
FROM halls h
LEFT JOIN bookings b ON h.id = b.hall_id
WHERE b.status = 'completed'
GROUP BY h.name
ORDER BY total_revenue DESC;

-- Запрос 6: Средняя оценка каждого зала
SELECT h.name, AVG(r.rating) as avg_rating, COUNT(r.id) as reviews_count
FROM halls h
LEFT JOIN reviews r ON h.id = r.hall_id
GROUP BY h.name
ORDER BY avg_rating DESC;

-- ============================================
-- ЗАПРОСЫ С JOIN (СОЕДИНЕНИЕ ТАБЛИЦ)
-- ============================================

-- Запрос 7: Все бронирования с информацией о клиенте и зале
SELECT 
    b.id as booking_id,
    u.first_name || ' ' || u.last_name as client_name,
    h.name as hall_name,
    b.start_time,
    b.end_time,
    b.status,
    b.total_price
FROM bookings b
JOIN users u ON b.user_id = u.id
JOIN halls h ON b.hall_id = h.id
ORDER BY b.start_time DESC;

-- Запрос 8: Клиенты, которые сделали больше 2 бронирований
SELECT 
    u.first_name, 
    u.last_name, 
    COUNT(b.id) as booking_count,
    SUM(b.total_price) as total_spent
FROM users u
JOIN bookings b ON u.id = b.user_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY u.id, u.first_name, u.last_name
HAVING COUNT(b.id) > 2
ORDER BY total_spent DESC;

-- ============================================
-- ЗАПРОСЫ С ПОДЗАПРОСАМИ
-- ============================================

-- Запрос 9: Залы, которые дороже среднего
SELECT name, base_price
FROM halls
WHERE base_price > (SELECT AVG(base_price) FROM halls)
ORDER BY base_price DESC;

-- Запрос 10: Пользователи, которые не делали бронирований
SELECT first_name, last_name, email
FROM users
WHERE id NOT IN (
    SELECT DISTINCT user_id 
    FROM bookings 
    WHERE user_id IS NOT NULL
)
AND role = 'client';

-- ============================================
-- ОКОННЫЕ ФУНКЦИИ (ПРОДВИНУТЫЙ УРОВЕНЬ)
-- ============================================

-- Запрос 11: Рейтинг клиентов по сумме потраченных денег
SELECT 
    first_name,
    last_name,
    SUM(total_price) as total_spent,
    RANK() OVER (ORDER BY SUM(total_price) DESC) as spending_rank
FROM users u
JOIN bookings b ON u.id = b.user_id
WHERE b.status = 'completed'
GROUP BY u.id, first_name, last_name
ORDER BY spending_rank;

-- Запрос 12: Загруженность залов по месяцам
SELECT 
    h.name,
    EXTRACT(MONTH FROM b.start_time) as month,
    COUNT(b.id) as bookings_count,
    SUM(EXTRACT(EPOCH FROM (b.end_time - b.start_time))/3600) as total_hours
FROM halls h
JOIN bookings b ON h.id = b.hall_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY h.name, EXTRACT(MONTH FROM b.start_time)
ORDER BY h.name, month;

-- ============================================
-- АНАЛИТИЧЕСКИЕ ЗАПРОСЫ ДЛЯ БИЗНЕСА
-- ============================================

-- Запрос 13: Конверсия бронирований
SELECT 
    COUNT(*) as total_bookings,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled,
    ROUND(COUNT(CASE WHEN status IN ('confirmed', 'completed') THEN 1 END) * 100.0 / COUNT(*), 2) as conversion_rate
FROM bookings;

-- Запрос 14: Топ-3 самых популярных зала
SELECT 
    h.name,
    COUNT(b.id) as booking_count,
    SUM(b.total_price) as revenue
FROM halls h
JOIN bookings b ON h.id = b.hall_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY h.id, h.name
ORDER BY booking_count DESC
LIMIT 3;

-- Запрос 15: Выручка по месяцам с нарастающим итогом
SELECT 
    EXTRACT(YEAR FROM start_time) as year,
    EXTRACT(MONTH FROM start_time) as month,
    SUM(total_price) as monthly_revenue,
    SUM(SUM(total_price)) OVER (ORDER BY EXTRACT(YEAR FROM start_time), EXTRACT(MONTH FROM start_time)) as cumulative_revenue
FROM bookings
WHERE status = 'completed'
GROUP BY EXTRACT(YEAR FROM start_time), EXTRACT(MONTH FROM start_time)
ORDER BY year, month;