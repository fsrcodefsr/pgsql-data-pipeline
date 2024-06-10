Data pipeline between 2 pgsql dbs via self written service on fastapi

###                                    --- helpful commands (scripts) in postgresql databases ---

### Создание таблиц:

-- Таблица пользователей
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255)
);

-- Таблица адресов
CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20)
);

-- Таблица заказов
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    order_date DATE,
    total_amount NUMERIC(10, 2)
);

### Добавим столбцы для меток времени в каждую таблицу (users, addresses, orders).

-- Обновление структуры таблицы users
ALTER TABLE users
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP,
ADD COLUMN deleted_at TIMESTAMP,
ADD COLUMN transmitted_at TIMESTAMP;

-- Обновление структуры таблицы addresses
ALTER TABLE addresses
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP,
ADD COLUMN deleted_at TIMESTAMP,
ADD COLUMN transmitted_at TIMESTAMP;

-- Обновление структуры таблицы orders
ALTER TABLE orders
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP,
ADD COLUMN deleted_at TIMESTAMP,
ADD COLUMN transmitted_at TIMESTAMP;


### Вставим тестовые данные в каждую таблицу:

-- Вставка данных в таблицу users
INSERT INTO users (username, email, password_hash) VALUES
('user1', 'user1@example.com', 'hashed_password_1'),
('user2', 'user2@example.com', 'hashed_password_2');

-- Вставка данных в таблицу addresses
INSERT INTO addresses (user_id, street, city, state, postal_code) VALUES
(1, '123 Main St', 'Anytown', 'CA', '12345'),
(2, '456 Elm St', 'Othertown', 'NY', '67890');

-- Вставка данных в таблицу orders
INSERT INTO orders (user_id, order_date, total_amount) VALUES
(1, '2024-06-01', 100.00),
(1, '2024-06-02', 150.00),
(2, '2024-06-03', 200.00);


### Очистка базы данных source_db и dest_db:

TRUNCATE TABLE users, addresses, orders RESTART IDENTITY CASCADE;

### Команды для удаления триггеров для каждой из таблиц:

DROP TRIGGER IF EXISTS user_changes ON users;
DROP TRIGGER IF EXISTS address_changes ON addresses;
DROP TRIGGER IF EXISTS order_changes ON orders;


### Триггеры на изменения в таблицах

-- Функция для отправки уведомлений и обновления меток времени для users
CREATE OR REPLACE FUNCTION notify_user_changes()
RETURNS trigger AS $$
DECLARE
    payload JSON;
BEGIN
    IF (TG_OP = 'DELETE-- Вставка данных в таблицу users
INSERT INTO users (username, email, password_hash) VALUES
('user3', 'user3@example.com', 'hashed_password_3'),
('user4', 'user4@example.com', 'hashed_password_4');

-- Вставка данных в таблицу addresses
INSERT INTO addresses (user_id, street, city, state, postal_code) VALUES
(1, '123 Main St', 'Anytown', 'CA', '12345'),
(2, '456 Elm St', 'Othertown', 'NY', '67890');

-- Вставка данных в таблицу orders
INSERT INTO orders (user_id, order_date, total_amount) VALUES
(1, '2024-06-01', 100.00),
(1, '2024-06-02', 150.00),
(2, '2024-06-03', 200.00);') THEN
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'old', row_to_json(OLD)
        );
        OLD.deleted_at := CURRENT_TIMESTAMP;
        RETURN OLD;
    ELSE
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'new', row_to_json(NEW)
        );
        IF (TG_OP = 'INSERT') THEN
            NEW.created_at := CURRENT_TIMESTAMP;
        ELSE
            NEW.updated_at := CURRENT_TIMESTAMP;
        END IF;
        PERFORM pg_notify('table_changes', payload::text);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера для таблицы users
CREATE TRIGGER user_changes
BEFORE INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION notify_user_changes();



### дампирование, переброска, заливка

docker exec -ti source-db pg_dump -U user source_db > $HOME/Desktop/projects/pgsql-data-pipeline/source_db_dump.sql
docker cp ./source_db_dump.sql dest-db:/dump/source_db_dump.sql
docker exec -it dest-db psql -U user -d dest_db -f /source_db_dump.sql

### удаление предудущей версии базы, очистка перед новой заливкой
psql -U your_username -d postgres
DROP DATABASE dest_db;
CREATE DATABASE dest_db;
