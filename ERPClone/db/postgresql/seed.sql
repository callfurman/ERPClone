-- ============================================
-- MRP/WMS Database Seed Script (FINAL FIXED)
-- PostgreSQL 13+
-- ============================================

-- ============================================
-- 1. СПРАВОЧНИКИ И БЕЗОПАСНОСТЬ
-- ============================================

-- Units (10 записей)
INSERT INTO units (code, name, conversion_factor) VALUES
('PCS', 'Штука', 1.0),
('KG', 'Килограмм', 1.0),
('M', 'Метр', 1.0),
('L', 'Литр', 1.0),
('M2', 'Квадратный метр', 1.0),
('M3', 'Кубический метр', 1.0),
('G', 'Грамм', 0.001),
('T', 'Тонна', 1000.0),
('MM', 'Миллиметр', 0.001),
('CM', 'Сантиметр', 0.01);

-- Roles (10 записей)
INSERT INTO roles (name, description) VALUES
('ADMIN', 'Администратор системы'),
('MANAGER', 'Менеджер производства'),
('WAREHOUSE_MANAGER', 'Заведующий складом'),
('PURCHASER', 'Менеджер по закупкам'),
('SALES_MANAGER', 'Менеджер по продажам'),
('ACCOUNTANT', 'Бухгалтер'),
('WORKER', 'Рабочий'),
('QC_INSPECTOR', 'Контролёр качества'),
('HR_MANAGER', 'Менеджер по кадрам'),
('GUEST', 'Гостевой доступ');

-- Permissions (10 записей)
INSERT INTO permissions (module, action, description) VALUES
('users', 'READ', 'Просмотр пользователей'),
('users', 'WRITE', 'Создание/редактирование пользователей'),
('orders', 'READ', 'Просмотр заказов'),
('orders', 'WRITE', 'Создание заказов'),
('warehouse', 'READ', 'Просмотр склада'),
('warehouse', 'WRITE', 'Операции со складом'),
('production', 'READ', 'Просмотр производства'),
('production', 'WRITE', 'Управление производством'),
('reports', 'READ', 'Просмотр отчётов'),
('admin', 'FULL', 'Полный доступ');

-- Users (10 записей)
INSERT INTO users (login, password_hash, is_active) VALUES
('admin', '$2b$12$hash123', TRUE),
('ivanov', '$2b$12$hash456', TRUE),
('petrov', '$2b$12$hash789', TRUE),
('sidorov', '$2b$12$hash012', TRUE),
('smirnova', '$2b$12$hash345', TRUE),
('kozlov', '$2b$12$hash678', TRUE),
('novikov', '$2b$12$hash901', TRUE),
('morozov', '$2b$12$hash234', TRUE),
('volkov', '$2b$12$hash567', TRUE),
('lebedev', '$2b$12$hash890', TRUE);

-- User Roles (10 записей)
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r 
WHERE u.login IN ('admin','ivanov','petrov','sidorov','smirnova','kozlov','novikov','morozov','volkov','lebedev')
AND r.name IN ('ADMIN','MANAGER','WAREHOUSE_MANAGER','PURCHASER','SALES_MANAGER','ACCOUNTANT','WORKER','QC_INSPECTOR','HR_MANAGER','GUEST')
LIMIT 10;

-- Role Permissions (10 записей)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name IN ('ADMIN','MANAGER','WAREHOUSE_MANAGER','PURCHASER','SALES_MANAGER','ACCOUNTANT','WORKER','QC_INSPECTOR','HR_MANAGER','GUEST')
AND p.action IN ('FULL','WRITE','READ')
LIMIT 10;

-- ============================================
-- 2. НОМЕНКЛАТУРА
-- ============================================

-- Nomenclature (10 УНИКАЛЬНЫХ записей)
INSERT INTO nomenclature (sku, name, type, unit_id, barcode, is_active) VALUES
('MAT-001', 'Сталь листовая 2мм', 'MATERIAL', (SELECT id FROM units WHERE code='KG'), '2000000000001', TRUE),
('MAT-002', 'Алюминий профильный', 'MATERIAL', (SELECT id FROM units WHERE code='M'), '2000000000002', TRUE),
('MAT-003', 'Краска порошковая', 'MATERIAL', (SELECT id FROM units WHERE code='KG'), '2000000000003', TRUE),
('MAT-004', 'Крепёж М8', 'MATERIAL', (SELECT id FROM units WHERE code='PCS'), '2000000000004', TRUE),
('MAT-005', 'Упаковка картон', 'MATERIAL', (SELECT id FROM units WHERE code='PCS'), '2000000000005', TRUE),
('PROD-001', 'Изделие А', 'PRODUCT', (SELECT id FROM units WHERE code='PCS'), '2000000000006', TRUE),
('PROD-002', 'Изделие Б', 'PRODUCT', (SELECT id FROM units WHERE code='PCS'), '2000000000007', TRUE),
('PROD-003', 'Изделие В', 'PRODUCT', (SELECT id FROM units WHERE code='PCS'), '2000000000008', TRUE),
('PROD-004', 'Изделие Г', 'PRODUCT', (SELECT id FROM units WHERE code='PCS'), '2000000000009', TRUE),
('PROD-005', 'Изделие Д', 'PRODUCT', (SELECT id FROM units WHERE code='PCS'), '2000000000010', TRUE);

-- Products (5 записей)
INSERT INTO products (id, sales_price, weight, product_group)
SELECT id, 
       CASE sku 
           WHEN 'PROD-001' THEN 1500.00 
           WHEN 'PROD-002' THEN 2500.00 
           WHEN 'PROD-003' THEN 3500.00 
           WHEN 'PROD-004' THEN 4500.00 
           WHEN 'PROD-005' THEN 5500.00 
       END,
       CASE sku 
           WHEN 'PROD-001' THEN 5.5 
           WHEN 'PROD-002' THEN 8.2 
           WHEN 'PROD-003' THEN 12.0 
           WHEN 'PROD-004' THEN 15.5 
           WHEN 'PROD-005' THEN 20.0 
       END,
       'Металлоконструкции'
FROM nomenclature 
WHERE type = 'PRODUCT';

-- Materials (5 записей)
INSERT INTO materials (id, cost_price, lead_time_days, reorder_point, safety_stock)
SELECT id,
       CASE sku 
           WHEN 'MAT-001' THEN 150.00 
           WHEN 'MAT-002' THEN 250.00 
           WHEN 'MAT-003' THEN 350.00 
           WHEN 'MAT-004' THEN 50.00 
           WHEN 'MAT-005' THEN 100.00 
       END,
       7, 100.0, 50.0
FROM nomenclature 
WHERE type = 'MATERIAL';

-- Batches (10 записей)
INSERT INTO batches (batch_number, nomenclature_id, production_date, expiration_date, status)
SELECT 
    'BATCH-2024-00' || n,
    (SELECT id FROM nomenclature ORDER BY id LIMIT 1 OFFSET (n-1)),
    DATE '2024-01-01' + (n * 7),
    NULL,
    'ACTIVE'
FROM generate_series(1, 10) AS n;

-- ============================================
-- 3. СКЛАД (WMS)
-- ============================================

-- Warehouses (10 записей)
INSERT INTO warehouses (name, address, type, is_active)
SELECT 
    'Склад #' || n,
    'г. Москва, ул. Промышленная ' || n,
    CASE WHEN n <= 7 THEN 'MAIN' WHEN n = 8 THEN 'QUARANTINE' ELSE 'SCRAP' END,
    TRUE
FROM generate_series(1, 10) AS n;

-- Storage Cells (10 записей)
INSERT INTO storage_cells (warehouse_id, cell_code, zone_type, capacity)
SELECT 
    (SELECT id FROM warehouses ORDER BY id LIMIT 1),
    'CELL-' || LPAD(n::text, 3, '0'),
    CASE WHEN n <= 3 THEN 'RECEIVING' WHEN n <= 7 THEN 'STORAGE' ELSE 'SHIPPING' END,
    100.0 * n
FROM generate_series(1, 10) AS n;

-- Stock Movements (10 записей)
INSERT INTO stock_movements (movement_type, nomenclature_id, batch_id, warehouse_id, cell_id, quantity, document_type, created_by)
SELECT 
    CASE WHEN n % 2 = 0 THEN 'IN' ELSE 'OUT' END,
    (SELECT id FROM nomenclature WHERE type = 'MATERIAL' ORDER BY id LIMIT 1 OFFSET (n % 5)),
    (SELECT id FROM batches ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM warehouses ORDER BY id LIMIT 1),
    (SELECT id FROM storage_cells ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE WHEN n % 2 = 0 THEN 100.0 * n ELSE -50.0 * n END,
    CASE WHEN n % 2 = 0 THEN 'receipt' ELSE 'production' END,
    (SELECT id FROM users WHERE login = 'petrov')
FROM generate_series(1, 10) AS n;

-- Inventories (10 записей)
INSERT INTO inventories (warehouse_id, inventory_date, status, created_by, completed_at)
SELECT 
    (SELECT id FROM warehouses ORDER BY id LIMIT 1),
    DATE '2024-01-01' + (n * 30),
    CASE WHEN n <= 5 THEN 'COMPLETED' WHEN n <= 8 THEN 'IN_PROGRESS' ELSE 'PLANNED' END,
    (SELECT id FROM users WHERE login = 'petrov'),
    CASE WHEN n <= 5 THEN DATE '2024-01-01' + (n * 30) + 1 ELSE NULL END
FROM generate_series(1, 10) AS n;

-- Inventory Items (10 записей)
INSERT INTO inventory_items (inventory_id, nomenclature_id, batch_id, book_quantity, actual_quantity, cell_id)
SELECT 
    (SELECT id FROM inventories ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM nomenclature ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM batches ORDER BY id LIMIT 1 OFFSET (n % 10)),
    100.0 + n * 10,
    98.0 + n * 10,
    (SELECT id FROM storage_cells ORDER BY id LIMIT 1 OFFSET (n % 10))
FROM generate_series(1, 10) AS n;

-- ============================================
-- 4. КОНТРАГЕНТЫ
-- ============================================

-- Suppliers (10 записей)
INSERT INTO suppliers (name, inn, contact_email, contact_phone, rating, lead_time_days, is_active)
SELECT 
    'Поставщик #' || n,
    '770' || LPAD(n::text, 7, '0'),
    'supplier' || n || '@example.com',
    '+7-495-' || LPAD((100 + n)::text, 7, '0'),
    (n % 5) + 1,
    5 + (n % 10),
    TRUE
FROM generate_series(1, 10) AS n;

-- Customers (10 записей)
INSERT INTO customers (name, inn, contact_email, contact_phone, category, credit_limit, is_active)
SELECT 
    'Клиент #' || n,
    '771' || LPAD(n::text, 7, '0'),
    'customer' || n || '@example.com',
    '+7-495-' || LPAD((200 + n)::text, 7, '0'),
    CASE WHEN n <= 3 THEN 'KEY' WHEN n <= 7 THEN 'OPT' ELSE 'RETAIL' END,
    100000.00 * n,
    TRUE
FROM generate_series(1, 10) AS n;

-- ============================================
-- 5. ПРОИЗВОДСТВО И ПЛАНИРОВАНИЕ
-- ============================================

-- Production Plans (10 записей)
INSERT INTO production_plans (plan_number, period_start, period_end, status, created_by)
SELECT 
    'PLAN-2024-' || LPAD(n::text, 2, '0'),
    DATE '2024-01-01' + ((n-1) * 30),
    DATE '2024-01-01' + (n * 30) - 1,
    CASE WHEN n <= 3 THEN 'ARCHIVED' WHEN n <= 5 THEN 'APPROVED' ELSE 'DRAFT' END,
    (SELECT id FROM users WHERE login = 'ivanov')
FROM generate_series(1, 10) AS n;

-- BOM Specifications (10 записей)
INSERT INTO bom_specifications (product_id, version, valid_from, valid_to, is_active)
SELECT 
    (SELECT id FROM products ORDER BY id LIMIT 1 OFFSET (n % 5)),
    '1.' || (n % 3),
    DATE '2024-01-01' + ((n-1) * 30),
    NULL,
    TRUE
FROM generate_series(1, 10) AS n;

-- BOM Items (10 записей)
INSERT INTO bom_items (bom_id, component_id, quantity, unit_id, loss_percent, sequence_number)
SELECT 
    (SELECT id FROM bom_specifications ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM materials ORDER BY id LIMIT 1 OFFSET (n % 5)),
    10.0 + n * 2,
    (SELECT id FROM units WHERE code = 'PCS'),
    1.0 + (n % 3) * 0.5,
    n
FROM generate_series(1, 10) AS n;

-- MRP Calculations (10 записей)
INSERT INTO mrp_calculations (plan_id, horizon_days, status, total_materials, total_deficit, urgent_count, calculated_by, mongodb_document_id)
SELECT 
    (SELECT id FROM production_plans ORDER BY id LIMIT 1 OFFSET (n-1)),
    30,
    CASE WHEN n <= 5 THEN 'COMPLETED' ELSE 'PENDING' END,
    CASE WHEN n <= 5 THEN 50 ELSE NULL END,
    CASE WHEN n <= 5 THEN 10000.00 + n * 1000 ELSE NULL END,
    CASE WHEN n <= 5 THEN 5 ELSE NULL END,
    (SELECT id FROM users WHERE login = 'ivanov'),
    CASE WHEN n <= 5 THEN '507f1f77bcf86cd79943900' || n ELSE NULL END
FROM generate_series(1, 10) AS n;

-- Purchase Requests (10 записей)
INSERT INTO purchase_requests (mrp_calculation_id, material_id, required_qty, required_date, priority, status)
SELECT 
    (SELECT id FROM mrp_calculations WHERE status = 'COMPLETED' ORDER BY id LIMIT 1 OFFSET (n % 5)),
    (SELECT id FROM materials ORDER BY id LIMIT 1 OFFSET (n % 5)),
    100.0 + n * 50,
    DATE '2024-04-01' + (n * 5),
    CASE WHEN n <= 3 THEN 'HIGH' WHEN n <= 7 THEN 'MEDIUM' ELSE 'LOW' END,
    'NEW'
FROM generate_series(1, 10) AS n;

-- Production Orders (10 записей)
INSERT INTO production_orders (order_number, plan_id, product_id, planned_quantity, produced_quantity, start_date, end_date, status)
SELECT 
    'WO-2024-' || LPAD(n::text, 3, '0'),
    (SELECT id FROM production_plans ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM products ORDER BY id LIMIT 1 OFFSET (n % 5)),
    50.0 - n * 3,
    CASE WHEN n <= 3 THEN 50.0 - n * 3 WHEN n <= 6 THEN 25.0 ELSE 0 END,
    DATE '2024-04-01' + (n * 3),
    DATE '2024-04-01' + (n * 3) + 10,
    CASE WHEN n <= 3 THEN 'COMPLETED' WHEN n <= 6 THEN 'IN_PROGRESS' ELSE 'PLANNED' END
FROM generate_series(1, 10) AS n;

-- Production Order Items (10 записей)
INSERT INTO production_order_items (production_order_id, nomenclature_id, planned_qty, produced_qty, scrap_qty, unit_id)
SELECT 
    (SELECT id FROM production_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM nomenclature WHERE type = 'PRODUCT' ORDER BY id LIMIT 1 OFFSET (n % 5)),
    50.0 - n * 3,
    CASE WHEN n <= 6 THEN 50.0 - n * 3 ELSE 0 END,
    CASE WHEN n > 6 THEN 1.0 ELSE 0 END,
    (SELECT id FROM units WHERE code = 'PCS')
FROM generate_series(1, 10) AS n;

-- Work Centers (10 записей)
INSERT INTO work_centers (name, warehouse_id, capacity_per_shift, is_active)
SELECT 
    'Цех #' || n,
    (SELECT id FROM warehouses ORDER BY id LIMIT 1),
    50.0 + n * 10,
    TRUE
FROM generate_series(1, 10) AS n;

-- Production Operations (10 записей)
INSERT INTO production_operations (production_order_id, operation_name, sequence_number, work_center_id, planned_duration_minutes, actual_duration_minutes, started_at, completed_at, status)
SELECT 
    (SELECT id FROM production_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE n % 5 
        WHEN 0 THEN 'Раскрой' 
        WHEN 1 THEN 'Сварка' 
        WHEN 2 THEN 'Покраска' 
        WHEN 3 THEN 'Сборка' 
        ELSE 'Упаковка' 
    END,
    n,
    (SELECT id FROM work_centers ORDER BY id LIMIT 1 OFFSET (n % 10)),
    60 + n * 10,
    CASE WHEN n <= 5 THEN 60 + n * 10 + (n % 5) ELSE NULL END,
    CASE WHEN n <= 5 THEN TIMESTAMP '2024-04-01 08:00:00' + (n * 24) * INTERVAL '1 hour' ELSE NULL END,
    CASE WHEN n <= 3 THEN TIMESTAMP '2024-04-01 08:00:00' + (n * 24) * INTERVAL '1 hour' + (60 + n * 10) * INTERVAL '1 minute' ELSE NULL END,
    CASE WHEN n <= 3 THEN 'COMPLETED' WHEN n <= 5 THEN 'IN_PROGRESS' ELSE 'PENDING' END
FROM generate_series(1, 10) AS n;

-- ============================================
-- 6. ЗАКУПКИ
-- ============================================

-- Purchase Orders (10 записей)
INSERT INTO purchase_orders (order_number, supplier_id, order_date, expected_delivery, total_amount, status, created_by)
SELECT 
    'PO-2024-' || LPAD(n::text, 3, '0'),
    (SELECT id FROM suppliers ORDER BY id LIMIT 1 OFFSET (n % 10)),
    DATE '2024-03-01' + (n * 3),
    DATE '2024-03-01' + (n * 3) + 7,
    50000.00 + n * 5000,
    CASE WHEN n <= 3 THEN 'COMPLETED' WHEN n <= 6 THEN 'SENT' ELSE 'DRAFT' END,
    (SELECT id FROM users WHERE login = 'sidorov')
FROM generate_series(1, 10) AS n;

-- Purchase Order Items (10 записей)
INSERT INTO purchase_order_items (purchase_order_id, material_id, quantity, unit_price, expected_date, received_qty)
SELECT 
    (SELECT id FROM purchase_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM materials ORDER BY id LIMIT 1 OFFSET (n % 5)),
    100.0 + n * 50,
    100.00 + n * 10,
    DATE '2024-03-01' + (n * 3) + 7,
    CASE WHEN n <= 3 THEN 100.0 + n * 50 ELSE 0 END
FROM generate_series(1, 10) AS n;

-- Receipts (10 записей)
INSERT INTO receipts (receipt_number, purchase_order_id, received_date, supplier_id, status, qc_status, qc_accepted_qty, qc_rejected_qty, received_by, inspected_by)
SELECT 
    'RCV-2024-' || LPAD(n::text, 3, '0'),
    (SELECT id FROM purchase_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    TIMESTAMP '2024-03-01 00:00:00' + (n * 3) * INTERVAL '1 day',
    (SELECT id FROM suppliers ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE WHEN n <= 3 THEN 'COMPLETED' WHEN n <= 6 THEN 'PARTIAL' ELSE 'PENDING' END,
    CASE WHEN n <= 3 THEN 'ACCEPTED' WHEN n <= 6 THEN 'PENDING' ELSE 'PENDING' END,
    CASE WHEN n <= 3 THEN 100.0 + n * 50 ELSE 0 END,
    0,
    CASE WHEN n <= 6 THEN (SELECT id FROM users WHERE login = 'petrov') ELSE NULL END,
    CASE WHEN n <= 3 THEN (SELECT id FROM users WHERE login = 'morozov') ELSE NULL END
FROM generate_series(1, 10) AS n;

-- Quality Inspections (10 записей)
INSERT INTO quality_inspections (receipt_id, purchase_order_id, supplier_id, inspection_date, status, total_qty_received, total_qty_rejected, accepted_qty, inspector_id)
SELECT 
    (SELECT id FROM receipts ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM purchase_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM suppliers ORDER BY id LIMIT 1 OFFSET (n % 10)),
    TIMESTAMP '2024-03-01 00:00:00' + (n * 3) * INTERVAL '1 day',
    CASE WHEN n <= 3 THEN 'ACCEPTED' ELSE 'PENDING' END,
    CASE WHEN n <= 3 THEN 100.0 + n * 50 ELSE 0 END,
    0,
    CASE WHEN n <= 3 THEN 100.0 + n * 50 ELSE 0 END,
    CASE WHEN n <= 3 THEN (SELECT id FROM users WHERE login = 'morozov') ELSE NULL END
FROM generate_series(1, 10) AS n;

-- QC Results (10 записей)
INSERT INTO qc_results (receipt_id, test_name, test_value, expected_value, passed, tested_at)
SELECT 
    (SELECT id FROM receipts ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE n % 4 
        WHEN 0 THEN 'Толщина' 
        WHEN 1 THEN 'Твёрдость' 
        WHEN 2 THEN 'Длина' 
        ELSE 'Вес' 
    END,
    CASE n % 4 
        WHEN 0 THEN '2.0мм' 
        WHEN 1 THEN '150 HB' 
        WHEN 2 THEN '6.0м' 
        ELSE '5.5кг/м' 
    END,
    CASE n % 4 
        WHEN 0 THEN '2.0±0.1мм' 
        WHEN 1 THEN '140-160 HB' 
        WHEN 2 THEN '6.0±0.05м' 
        ELSE '5.5±0.2кг/м' 
    END,
    TRUE,
    TIMESTAMP '2024-03-01 10:00:00' + (n * 30) * INTERVAL '1 minute'
FROM generate_series(1, 10) AS n;

-- ============================================
-- 7. ПРОДАЖИ
-- ============================================

-- Sales Orders (10 записей)
INSERT INTO sales_orders (order_number, customer_id, order_date, delivery_date, total_amount, status, created_by)
SELECT 
    'SO-2024-' || LPAD(n::text, 3, '0'),
    (SELECT id FROM customers ORDER BY id LIMIT 1 OFFSET (n % 10)),
    DATE '2024-03-01' + (n * 3),
    DATE '2024-03-01' + (n * 3) + 14,
    30000.00 + n * 10000,
    CASE WHEN n <= 3 THEN 'SHIPPED' WHEN n <= 6 THEN 'RESERVED' WHEN n <= 8 THEN 'CONFIRMED' ELSE 'DRAFT' END,
    (SELECT id FROM users WHERE login = 'smirnova')
FROM generate_series(1, 10) AS n;

-- Sales Order Items (10 записей)
INSERT INTO sales_order_items (sales_order_id, nomenclature_id, quantity, unit_price, reserved_qty, shipped_qty)
SELECT 
    (SELECT id FROM sales_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM nomenclature WHERE type = 'PRODUCT' ORDER BY id LIMIT 1 OFFSET (n % 5)),
    20.0 + n * 5,
    1500.00 + n * 500,
    CASE WHEN n <= 6 THEN 20.0 + n * 5 ELSE 0 END,
    CASE WHEN n <= 3 THEN 20.0 + n * 5 ELSE 0 END
FROM generate_series(1, 10) AS n;

-- Shipments (10 записей)
INSERT INTO shipments (shipment_number, sales_order_id, shipped_date, customer_id, status, carrier, tracking_number, shipped_by)
SELECT 
    'SHP-2024-' || LPAD(n::text, 3, '0'),
    (SELECT id FROM sales_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE WHEN n <= 7 THEN DATE '2024-03-01' + (n * 3) + 13 ELSE NULL END,
    (SELECT id FROM customers ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE WHEN n <= 3 THEN 'DELIVERED' WHEN n <= 7 THEN 'SHIPPED' ELSE 'PENDING' END,
    CASE n % 3 WHEN 0 THEN 'Деловые Линии' WHEN 1 THEN 'ПЭК' ELSE 'СДЭК' END,
    CASE WHEN n <= 7 THEN 'TRK' || LPAD(n::text, 9, '0') ELSE NULL END,
    CASE WHEN n <= 7 THEN (SELECT id FROM users WHERE login = 'petrov') ELSE NULL END
FROM generate_series(1, 10) AS n;

-- Invoices (10 записей)
INSERT INTO invoices (invoice_number, sales_order_id, issue_date, due_date, total_amount, paid_amount, status)
SELECT 
    'INV-2024-' || LPAD(n::text, 3, '0'),
    (SELECT id FROM sales_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    DATE '2024-03-01' + (n * 3),
    DATE '2024-03-01' + (n * 3) + 30,
    30000.00 + n * 10000,
    CASE WHEN n <= 3 THEN 30000.00 + n * 10000 ELSE 0 END,
    CASE WHEN n <= 3 THEN 'PAID' ELSE 'UNPAID' END
FROM generate_series(1, 10) AS n;

-- ============================================
-- 8. КАДРЫ
-- ============================================

-- Positions (10 записей)
INSERT INTO positions (name, department, default_role_id, hourly_rate, is_active)
SELECT 
    CASE n 
        WHEN 1 THEN 'Генеральный директор'
        WHEN 2 THEN 'Начальник производства'
        WHEN 3 THEN 'Заведующий складом'
        WHEN 4 THEN 'Менеджер по закупкам'
        WHEN 5 THEN 'Менеджер по продажам'
        WHEN 6 THEN 'Бухгалтер'
        WHEN 7 THEN 'Рабочий'
        WHEN 8 THEN 'Контролёр ОТК'
        WHEN 9 THEN 'Менеджер по кадрам'
        ELSE 'Стажёр'
    END,
    CASE WHEN n <= 2 THEN 'Руководство' WHEN n <= 5 THEN 'Производство' WHEN n = 6 THEN 'Финансы' WHEN n <= 8 THEN 'Склад' ELSE 'Кадры' END,
    (SELECT id FROM roles ORDER BY id LIMIT 1 OFFSET (n % 10)),
    5000.00 - n * 400,
    TRUE
FROM generate_series(1, 10) AS n;

-- Employees (10 записей)
INSERT INTO employees (user_id, first_name, last_name, position_id, work_center_id, hire_date, is_active)
SELECT 
    (SELECT id FROM users ORDER BY id LIMIT 1 OFFSET (n-1)),
    'Имя' || n,
    'Фамилия' || n,
    (SELECT id FROM positions ORDER BY id LIMIT 1 OFFSET (n-1)),
    CASE WHEN n <= 7 THEN (SELECT id FROM work_centers ORDER BY id LIMIT 1 OFFSET (n % 10)) ELSE NULL END,
    DATE '2020-01-01' + (n * 90),
    TRUE
FROM generate_series(1, 10) AS n;

-- Shifts (10 записей)
INSERT INTO shifts (employee_id, work_center_id, shift_date, start_time, end_time, planned_hours, actual_hours, status)
SELECT 
    (SELECT id FROM employees ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE WHEN n <= 7 THEN (SELECT id FROM work_centers ORDER BY id LIMIT 1 OFFSET (n % 10)) ELSE NULL END,
    DATE '2024-04-01' + (n - 1),
    TIME '08:00:00',
    TIME '17:00:00',
    8.0,
    CASE WHEN n <= 5 THEN 8.0 + (n % 3) * 0.5 ELSE NULL END,
    CASE WHEN n <= 5 THEN 'COMPLETED' ELSE 'PLANNED' END
FROM generate_series(1, 10) AS n;

-- Timesheets (10 записей)
INSERT INTO timesheets (employee_id, shift_id, work_date, work_type, hours, production_order_id, output_qty, notes)
SELECT 
    (SELECT id FROM employees ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM shifts ORDER BY id LIMIT 1 OFFSET (n % 10)),
    DATE '2024-04-01' + (n - 1),
    'WORK',
    CASE WHEN n <= 5 THEN 8.0 + (n % 3) * 0.5 ELSE 8.0 END,
    CASE WHEN n <= 5 THEN (SELECT id FROM production_orders ORDER BY id LIMIT 1 OFFSET (n % 10)) ELSE NULL END,
    CASE WHEN n <= 5 THEN 50.0 - n * 5 ELSE NULL END,
    CASE WHEN n <= 3 THEN 'План выполнен' WHEN n <= 5 THEN 'В процессе' ELSE 'Рабочий день' END
FROM generate_series(1, 10) AS n;

-- ============================================
-- 9. ФИНАНСЫ
-- ============================================

-- Cost Items (10 записей)
INSERT INTO cost_items (code, name, type, is_active)
SELECT 
    CASE n 
        WHEN 1 THEN 'MAT' WHEN 2 THEN 'LAB' WHEN 3 THEN 'OVH' WHEN 4 THEN 'UTIL'
        WHEN 5 THEN 'RENT' WHEN 6 THEN 'DEPR' WHEN 7 THEN 'TRANS' WHEN 8 THEN 'MAINT'
        WHEN 9 THEN 'ADMIN' ELSE 'OTHER'
    END,
    CASE n 
        WHEN 1 THEN 'Материалы' WHEN 2 THEN 'Оплата труда' WHEN 3 THEN 'Накладные расходы'
        WHEN 4 THEN 'Коммунальные услуги' WHEN 5 THEN 'Аренда' WHEN 6 THEN 'Амортизация'
        WHEN 7 THEN 'Транспорт' WHEN 8 THEN 'Обслуживание' WHEN 9 THEN 'Административные'
        ELSE 'Прочие'
    END,
    CASE WHEN n <= 2 THEN 'DIRECT' WHEN n <= 6 THEN 'INDIRECT' ELSE 'OVERHEAD' END,
    TRUE
FROM generate_series(1, 10) AS n;

-- Batch Costs (10 записей)
INSERT INTO batch_costs (batch_id, cost_item_id, amount, currency, notes)
SELECT 
    (SELECT id FROM batches ORDER BY id LIMIT 1 OFFSET (n % 10)),
    (SELECT id FROM cost_items ORDER BY id LIMIT 1 OFFSET (n % 10)),
    50000.00 + n * 5000,
    'RUB',
    'Затраты на партию #' || n
FROM generate_series(1, 10) AS n;

-- Production Budgets (10 записей) - ИСПРАВЛЕНО
INSERT INTO production_budgets (budget_number, period_start, period_end, cost_item_id, planned_amount, actual_amount, status)
SELECT 
    'BUD-2024-' || LPAD(n::text, 2, '0'),
    DATE '2024-01-01' + ((n-1) * 30),
    DATE '2024-01-01' + (n * 30) - 1,
    (SELECT id FROM cost_items ORDER BY id LIMIT 1 OFFSET (n % 10)),
    500000.00 + n * 50000,
    CASE WHEN n <= 3 THEN 500000.00 + n * 50000 - 10000 ELSE 0 END,
    CASE WHEN n <= 3 THEN 'COMPLETED' WHEN n <= 6 THEN 'IN_PROGRESS' ELSE 'DRAFT' END
FROM generate_series(1, 10) AS n;

-- ============================================
-- 10. ТЕХНИЧЕСКИЕ ТАБЛИЦЫ
-- ============================================

-- MRP Profiles (10 записей)
INSERT INTO mrp_profiles (name, safety_stock_days, include_safety_stock, planning_horizon_days, is_default, created_by)
SELECT 
    CASE n 
        WHEN 1 THEN 'Стандартный' WHEN 2 THEN 'Быстрый' WHEN 3 THEN 'Долгосрочный'
        WHEN 4 THEN 'Экономный' WHEN 5 THEN 'Срочный' WHEN 6 THEN 'Сезонный'
        WHEN 7 THEN 'Экспортный' WHEN 8 THEN 'Тестовый' WHEN 9 THEN 'Резервный'
        ELSE 'Кастомный'
    END,
    CASE n WHEN 5 THEN 1 WHEN 8 THEN 0 ELSE 7 + (n % 7) END,
    n != 2 AND n != 5 AND n != 8,
    CASE n WHEN 2 THEN 7 WHEN 5 THEN 7 WHEN 3 THEN 90 WHEN 6 THEN 45 WHEN 7 THEN 120 ELSE 30 END,
    n = 1,
    (SELECT id FROM users WHERE login = 'ivanov')
FROM generate_series(1, 10) AS n;

-- Attachments (10 записей)
INSERT INTO attachments (entity_type, entity_id, file_name, file_path, file_type, file_size, uploaded_by)
SELECT 
    CASE n % 4 WHEN 0 THEN 'purchase_order' WHEN 1 THEN 'sales_order' WHEN 2 THEN 'employee' ELSE 'quality_inspection' END,
    (SELECT id FROM purchase_orders ORDER BY id LIMIT 1 OFFSET (n % 10)),
    'doc_' || n || '.pdf',
    '/files/docs/doc_' || n || '.pdf',
    'application/pdf',
    500000 + n * 100000,
    (SELECT id FROM users WHERE login IN ('sidorov', 'smirnova', 'volkov', 'morozov') ORDER BY id LIMIT 1 OFFSET (n % 4))
FROM generate_series(1, 10) AS n;

-- Warehouse Tasks (10 записей)
INSERT INTO warehouse_tasks (task_type, warehouse_id, priority, status, assigned_to, assigned_at, completed_at)
SELECT 
    CASE n % 4 WHEN 0 THEN 'PICKING' WHEN 1 THEN 'PUTAWAY' WHEN 2 THEN 'REPLENISHMENT' ELSE 'INVENTORY' END,
    (SELECT id FROM warehouses ORDER BY id LIMIT 1),
    n,
    CASE WHEN n <= 3 THEN 'DONE' WHEN n <= 6 THEN 'IN_PROGRESS' WHEN n <= 8 THEN 'ASSIGNED' ELSE 'NEW' END,
    CASE WHEN n <= 8 THEN (SELECT id FROM users WHERE login = 'petrov') ELSE NULL END,
    CASE WHEN n <= 8 THEN TIMESTAMP '2024-04-01 08:00:00' + (n-1) * INTERVAL '1 hour' ELSE NULL END,
    CASE WHEN n <= 3 THEN TIMESTAMP '2024-04-01 10:00:00' + (n-1) * INTERVAL '1 hour' ELSE NULL END
FROM generate_series(1, 10) AS n;

-- Warehouse Route Points (10 записей)
INSERT INTO warehouse_route_points (task_id, sequence_number, cell_id, action_type, estimated_distance)
SELECT 
    (SELECT id FROM warehouse_tasks ORDER BY id LIMIT 1 OFFSET (n % 10)),
    n,
    (SELECT id FROM storage_cells ORDER BY id LIMIT 1 OFFSET (n % 10)),
    CASE WHEN n % 3 = 0 THEN 'PASS' ELSE 'STOP' END,
    n * 5
FROM generate_series(1, 10) AS n;

-- Outbox Events (10 записей)
INSERT INTO outbox_events (aggregate_type, aggregate_id, event_type, payload, retry_count, max_retries)
SELECT 
    CASE n % 5 
        WHEN 0 THEN 'MRPCalculation' 
        WHEN 1 THEN 'SalesOrder' 
        WHEN 2 THEN 'PurchaseOrder' 
        WHEN 3 THEN 'ProductionOrder' 
        ELSE 'StockMovement' 
    END,
    gen_random_uuid(),
    CASE n % 4 WHEN 0 THEN 'CREATED' WHEN 1 THEN 'UPDATED' WHEN 2 THEN 'COMPLETED' ELSE 'DELETED' END,
    '{"test": "data", "index": ' || n || '}',
    0,
    3
FROM generate_series(1, 10) AS n;

-- ============================================
-- КОНЕЦ СКРИПТА
-- ============================================