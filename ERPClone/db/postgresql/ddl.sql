-- ============================================
-- MRP/WMS Database Schema
-- PostgreSQL 13+
-- 42 Tables (NO JSONB)
-- ============================================

-- Включаем расширение для UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. СПРАВОЧНИКИ И БЕЗОПАСНОСТЬ
-- ============================================

CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    conversion_factor DECIMAL(10,6) DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module VARCHAR(100) NOT NULL,
    action VARCHAR(20) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    login VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- ============================================
-- 2. НОМЕНКЛАТУРА
-- ============================================

CREATE TABLE nomenclature (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('PRODUCT', 'MATERIAL', 'SERVICE')),
    unit_id UUID REFERENCES units(id),
    barcode VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
    id UUID PRIMARY KEY REFERENCES nomenclature(id) ON DELETE CASCADE,
    sales_price DECIMAL(12,2),
    weight DECIMAL(10,3),
    product_group VARCHAR(100)
);

CREATE TABLE materials (
    id UUID PRIMARY KEY REFERENCES nomenclature(id) ON DELETE CASCADE,
    cost_price DECIMAL(12,2),
    default_supplier_id UUID,
    lead_time_days INTEGER DEFAULT 7,
    reorder_point DECIMAL(10,3) DEFAULT 0,
    safety_stock DECIMAL(10,3) DEFAULT 0
);

CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_number VARCHAR(50) UNIQUE NOT NULL,
    nomenclature_id UUID NOT NULL REFERENCES nomenclature(id),
    production_date DATE,
    expiration_date DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BLOCKED', 'EXPIRED', 'CONSUMED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_batches_nomenclature ON batches(nomenclature_id);
CREATE INDEX idx_batches_expiration ON batches(expiration_date);
CREATE INDEX idx_batches_status ON batches(status);

-- ============================================
-- 3. СКЛАД (WMS)
-- ============================================

CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    address TEXT,
    type VARCHAR(20) DEFAULT 'MAIN' CHECK (type IN ('MAIN', 'QUARANTINE', 'SCRAP')),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE storage_cells (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    cell_code VARCHAR(50) NOT NULL,
    zone_type VARCHAR(20) CHECK (zone_type IN ('RECEIVING', 'STORAGE', 'SHIPPING')),
    capacity DECIMAL(10,3),
    UNIQUE(warehouse_id, cell_code)
);

CREATE INDEX idx_storage_cells_warehouse ON storage_cells(warehouse_id);

CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('IN', 'OUT', 'ADJUST', 'RESERVE', 'RELEASE')),
    nomenclature_id UUID NOT NULL REFERENCES nomenclature(id),
    batch_id UUID REFERENCES batches(id),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    cell_id UUID REFERENCES storage_cells(id),
    quantity DECIMAL(10,3) NOT NULL,
    document_type VARCHAR(50),
    document_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    notes TEXT
);

CREATE INDEX idx_stock_movements_nomenclature ON stock_movements(nomenclature_id);
CREATE INDEX idx_stock_movements_batch ON stock_movements(batch_id);
CREATE INDEX idx_stock_movements_warehouse ON stock_movements(warehouse_id);
CREATE INDEX idx_stock_movements_created ON stock_movements(created_at DESC);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);

CREATE TABLE inventories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID REFERENCES warehouses(id),
    inventory_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PLANNED' CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    created_by UUID REFERENCES users(id),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE INDEX idx_inventories_warehouse ON inventories(warehouse_id);
CREATE INDEX idx_inventories_date ON inventories(inventory_date);
CREATE INDEX idx_inventories_status ON inventories(status);

CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id UUID NOT NULL REFERENCES inventories(id) ON DELETE CASCADE,
    nomenclature_id UUID NOT NULL REFERENCES nomenclature(id),
    batch_id UUID REFERENCES batches(id),
    book_quantity DECIMAL(10,3) NOT NULL,
    actual_quantity DECIMAL(10,3) NOT NULL,
    variance DECIMAL(10,3) GENERATED ALWAYS AS (actual_quantity - book_quantity) STORED,
    cell_id UUID REFERENCES storage_cells(id)
);

CREATE INDEX idx_inventory_items_inventory ON inventory_items(inventory_id);
CREATE INDEX idx_inventory_items_nomenclature ON inventory_items(nomenclature_id);

-- ============================================
-- 3.1. Вложения (замена JSONB attachments)
-- ============================================

CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size INTEGER,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attachments_entity ON attachments(entity_type, entity_id);

-- ============================================
-- 3.2. QC Результаты (замена JSONB qc_results)
-- ============================================

CREATE TABLE qc_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_id UUID NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    test_value VARCHAR(255),
    expected_value VARCHAR(255),
    passed BOOLEAN,
    tested_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_qc_results_receipt ON qc_results(receipt_id);

-- ============================================
-- 3.3. Маршруты склада (замена JSONB route_json)
-- ============================================

CREATE TABLE warehouse_route_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL,
    sequence_number INTEGER NOT NULL,
    cell_id UUID REFERENCES storage_cells(id),
    action_type VARCHAR(20) CHECK (action_type IN ('STOP', 'PASS')),
    estimated_distance INTEGER
);

CREATE INDEX idx_route_points_task ON warehouse_route_points(task_id);

-- ============================================
-- 3.4. Receipts (без JSONB)
-- ============================================

CREATE TABLE receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_number VARCHAR(50) UNIQUE,
    purchase_order_id UUID,
    received_date TIMESTAMPTZ DEFAULT NOW(),
    supplier_id UUID,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'PARTIAL', 'REJECTED')),
    qc_status VARCHAR(20) DEFAULT 'PENDING' CHECK (qc_status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'PARTIAL')),
    qc_completed_at TIMESTAMPTZ,
    qc_accepted_qty DECIMAL(10,3),
    qc_rejected_qty DECIMAL(10,3),
    received_by UUID REFERENCES users(id),
    inspected_by UUID REFERENCES users(id)
);

CREATE INDEX idx_receipts_purchase_order ON receipts(purchase_order_id);
CREATE INDEX idx_receipts_supplier ON receipts(supplier_id);
CREATE INDEX idx_receipts_status ON receipts(status);
CREATE INDEX idx_receipts_received_date ON receipts(received_date);

-- ============================================
-- 3.5. Shipments
-- ============================================

CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_number VARCHAR(50) UNIQUE,
    sales_order_id UUID,
    shipped_date TIMESTAMPTZ DEFAULT NOW(),
    customer_id UUID,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    carrier VARCHAR(100),
    tracking_number VARCHAR(100),
    shipped_by UUID REFERENCES users(id)
);

CREATE INDEX idx_shipments_sales_order ON shipments(sales_order_id);
CREATE INDEX idx_shipments_customer ON shipments(customer_id);
CREATE INDEX idx_shipments_status ON shipments(status);

-- ============================================
-- 3.6. Warehouse Tasks (без JSONB)
-- ============================================

CREATE TABLE warehouse_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_type VARCHAR(20) NOT NULL CHECK (task_type IN ('PICKING', 'PUTAWAY', 'REPLENISHMENT', 'INVENTORY')),
    warehouse_id UUID REFERENCES warehouses(id),
    priority INTEGER DEFAULT 5,
    status VARCHAR(20) DEFAULT 'NEW' CHECK (status IN ('NEW', 'ASSIGNED', 'IN_PROGRESS', 'DONE', 'CANCELLED')),
    assigned_to UUID REFERENCES users(id),
    assigned_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_warehouse_tasks_warehouse ON warehouse_tasks(warehouse_id);
CREATE INDEX idx_warehouse_tasks_status ON warehouse_tasks(status);
CREATE INDEX idx_warehouse_tasks_assigned ON warehouse_tasks(assigned_to);
CREATE INDEX idx_warehouse_tasks_priority ON warehouse_tasks(priority DESC);

-- ============================================
-- 4. ПРОИЗВОДСТВО И ПЛАНИРОВАНИЕ
-- ============================================

CREATE TABLE production_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_number VARCHAR(50) UNIQUE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'APPROVED', 'ARCHIVED', 'CALCULATING')),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ
);

CREATE INDEX idx_production_plans_status ON production_plans(status);
CREATE INDEX idx_production_plans_period ON production_plans(period_start, period_end);

CREATE TABLE bom_specifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id),
    version VARCHAR(20) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, version)
);

CREATE INDEX idx_bom_specifications_product ON bom_specifications(product_id);
CREATE INDEX idx_bom_specifications_active ON bom_specifications(product_id, is_active) WHERE is_active = TRUE;

CREATE TABLE bom_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bom_id UUID NOT NULL REFERENCES bom_specifications(id) ON DELETE CASCADE,
    component_id UUID NOT NULL REFERENCES materials(id),
    quantity DECIMAL(10,3) NOT NULL,
    unit_id UUID REFERENCES units(id),
    loss_percent DECIMAL(5,2) DEFAULT 0,
    sequence_number INTEGER DEFAULT 1,
    UNIQUE(bom_id, component_id)
);

CREATE INDEX idx_bom_items_bom ON bom_items(bom_id);
CREATE INDEX idx_bom_items_component ON bom_items(component_id);

-- ============================================
-- 4. ПРОИЗВОДСТВО И ПЛАНИРОВАНИЕ (Исправлено)
-- ============================================

CREATE TABLE mrp_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES production_plans(id),
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    horizon_days INTEGER,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')),
    
    -- Только агрегированная статистика для быстрого отображения в списке
    total_materials INTEGER,      -- Сколько всего материалов считали
    total_deficit DECIMAL(12,2),  -- Общий дефицит (сумма)
    urgent_count INTEGER,         -- Сколько срочных заказов
    has_errors BOOLEAN DEFAULT FALSE, -- Флаг ошибок расчёта
    
    calculated_by UUID REFERENCES users(id),
    
    -- Ссылка на документ в MongoDB (опционально)
    mongodb_document_id VARCHAR(24) 
);

CREATE INDEX idx_mrp_calculations_plan ON mrp_calculations(plan_id);
CREATE INDEX idx_mrp_calculations_status ON mrp_calculations(status);
CREATE INDEX idx_mrp_calculations_date ON mrp_calculations(calculated_at DESC);

CREATE TABLE purchase_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mrp_calculation_id UUID REFERENCES mrp_calculations(id),
    material_id UUID NOT NULL REFERENCES materials(id),
    required_qty DECIMAL(10,3) NOT NULL,
    required_date DATE NOT NULL,
    priority VARCHAR(10) DEFAULT 'MEDIUM' CHECK (priority IN ('HIGH', 'MEDIUM', 'LOW')),
    status VARCHAR(20) DEFAULT 'NEW' CHECK (status IN ('NEW', 'ORDERED', 'CLOSED', 'CANCELLED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_purchase_requests_material ON purchase_requests(material_id);
CREATE INDEX idx_purchase_requests_required_date ON purchase_requests(required_date);
CREATE INDEX idx_purchase_requests_status ON purchase_requests(status);

CREATE TABLE production_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE,
    plan_id UUID REFERENCES production_plans(id),
    mrp_calculation_id UUID REFERENCES mrp_calculations(id),
    product_id UUID NOT NULL REFERENCES products(id),
    planned_quantity DECIMAL(10,3) NOT NULL,
    produced_quantity DECIMAL(10,3) DEFAULT 0,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'PLANNED' CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_production_orders_plan ON production_orders(plan_id);
CREATE INDEX idx_production_orders_product ON production_orders(product_id);
CREATE INDEX idx_production_orders_status ON production_orders(status);

CREATE TABLE production_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    production_order_id UUID NOT NULL REFERENCES production_orders(id) ON DELETE CASCADE,
    nomenclature_id UUID NOT NULL REFERENCES nomenclature(id),
    planned_qty DECIMAL(10,3) NOT NULL,
    produced_qty DECIMAL(10,3) DEFAULT 0,
    scrap_qty DECIMAL(10,3) DEFAULT 0,
    unit_id UUID REFERENCES units(id)
);

CREATE INDEX idx_production_order_items_order ON production_order_items(production_order_id);

CREATE TABLE production_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    production_order_id UUID NOT NULL REFERENCES production_orders(id) ON DELETE CASCADE,
    operation_name VARCHAR(100) NOT NULL,
    sequence_number INTEGER NOT NULL,
    work_center_id UUID,
    planned_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'PENDING'
);

CREATE INDEX idx_production_operations_order ON production_operations(production_order_id);
CREATE INDEX idx_production_operations_sequence ON production_operations(sequence_number);

CREATE TABLE work_centers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    warehouse_id UUID REFERENCES warehouses(id),
    capacity_per_shift DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_work_centers_warehouse ON work_centers(warehouse_id);

-- ============================================
-- 5. ЗАКУПКИ
-- ============================================

CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    inn VARCHAR(20),
    contact_email VARCHAR(200),
    contact_phone VARCHAR(50),
    rating INTEGER DEFAULT 0,
    lead_time_days INTEGER DEFAULT 7,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_suppliers_name ON suppliers(name);
CREATE INDEX idx_suppliers_active ON suppliers(is_active);

CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    order_date DATE NOT NULL,
    expected_delivery DATE,
    total_amount DECIMAL(14,2),
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'SENT', 'PARTIAL', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_purchase_orders_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_orders_date ON purchase_orders(order_date DESC);

CREATE TABLE purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES materials(id),
    quantity DECIMAL(10,3) NOT NULL,
    unit_price DECIMAL(12,2),
    total_price DECIMAL(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    expected_date DATE,
    received_qty DECIMAL(10,3) DEFAULT 0
);

CREATE INDEX idx_purchase_order_items_order ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_purchase_order_items_material ON purchase_order_items(material_id);

-- ============================================
-- 5.1. Quality Inspections (без JSONB)
-- ============================================

CREATE TABLE quality_inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_id UUID NOT NULL REFERENCES receipts(id),
    purchase_order_id UUID REFERENCES purchase_orders(id),
    supplier_id UUID REFERENCES suppliers(id),
    inspection_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'PARTIAL')),
    total_qty_received DECIMAL(10,3),
    total_qty_rejected DECIMAL(10,3),
    accepted_qty DECIMAL(10,3),
    inspector_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quality_inspections_receipt ON quality_inspections(receipt_id);
CREATE INDEX idx_quality_inspections_supplier ON quality_inspections(supplier_id);
CREATE INDEX idx_quality_inspections_date ON quality_inspections(inspection_date DESC);

-- ============================================
-- 6. ПРОДАЖИ
-- ============================================

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    inn VARCHAR(20),
    contact_email VARCHAR(200),
    contact_phone VARCHAR(50),
    category VARCHAR(50),
    credit_limit DECIMAL(14,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_active ON customers(is_active);

CREATE TABLE sales_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL,
    delivery_date DATE,
    total_amount DECIMAL(14,2),
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'CONFIRMED', 'RESERVED', 'SHIPPED', 'PAID', 'CANCELLED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_sales_orders_customer ON sales_orders(customer_id);
CREATE INDEX idx_sales_orders_status ON sales_orders(status);
CREATE INDEX idx_sales_orders_date ON sales_orders(order_date DESC);

CREATE TABLE sales_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
    nomenclature_id UUID NOT NULL REFERENCES nomenclature(id),
    quantity DECIMAL(10,3) NOT NULL,
    unit_price DECIMAL(12,2),
    total_price DECIMAL(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    reserved_qty DECIMAL(10,3) DEFAULT 0,
    shipped_qty DECIMAL(10,3) DEFAULT 0
);

CREATE INDEX idx_sales_order_items_order ON sales_order_items(sales_order_id);
CREATE INDEX idx_sales_order_items_nomenclature ON sales_order_items(nomenclature_id);

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE,
    sales_order_id UUID REFERENCES sales_orders(id),
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    total_amount DECIMAL(14,2) NOT NULL,
    paid_amount DECIMAL(14,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'UNPAID' CHECK (status IN ('UNPAID', 'PARTIAL', 'PAID', 'OVERDUE', 'CANCELLED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_invoices_sales_order ON invoices(sales_order_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- ============================================
-- 7. КАДРЫ
-- ============================================

CREATE TABLE positions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    default_role_id UUID REFERENCES roles(id),
    hourly_rate DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position_id UUID REFERENCES positions(id),
    work_center_id UUID REFERENCES work_centers(id),
    hire_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_employees_position ON employees(position_id);
CREATE INDEX idx_employees_work_center ON employees(work_center_id);
CREATE INDEX idx_employees_active ON employees(is_active);

CREATE TABLE shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    work_center_id UUID REFERENCES work_centers(id),
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    planned_hours DECIMAL(4,2),
    actual_hours DECIMAL(4,2),
    status VARCHAR(20) DEFAULT 'PLANNED'
);

CREATE INDEX idx_shifts_employee ON shifts(employee_id);
CREATE INDEX idx_shifts_date ON shifts(shift_date);

CREATE TABLE timesheets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    shift_id UUID REFERENCES shifts(id),
    work_date DATE NOT NULL,
    work_type VARCHAR(20),
    hours DECIMAL(4,2),
    production_order_id UUID REFERENCES production_orders(id),
    output_qty DECIMAL(10,3),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_timesheets_employee ON timesheets(employee_id);
CREATE INDEX idx_timesheets_date ON timesheets(work_date);
CREATE INDEX idx_timesheets_production_order ON timesheets(production_order_id);

-- ============================================
-- 8. ФИНАНСЫ
-- ============================================

CREATE TABLE cost_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('DIRECT', 'INDIRECT', 'OVERHEAD')),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE batch_costs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES batches(id),
    cost_item_id UUID NOT NULL REFERENCES cost_items(id),
    amount DECIMAL(14,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RUB',
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

CREATE INDEX idx_batch_costs_batch ON batch_costs(batch_id);
CREATE INDEX idx_batch_costs_item ON batch_costs(cost_item_id);

CREATE TABLE production_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_number VARCHAR(50) UNIQUE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    cost_item_id UUID REFERENCES cost_items(id),
    planned_amount DECIMAL(14,2),
    actual_amount DECIMAL(14,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_production_budgets_period ON production_budgets(period_start, period_end);
CREATE INDEX idx_production_budgets_item ON production_budgets(cost_item_id);

-- ============================================
-- 9. ТЕХНИЧЕСКИЕ ТАБЛИЦЫ
-- ============================================

CREATE TABLE mrp_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    safety_stock_days INTEGER DEFAULT 7,
    include_safety_stock BOOLEAN DEFAULT TRUE,
    planning_horizon_days INTEGER DEFAULT 30,
    is_default BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9.1. Outbox (без JSONB - используем TEXT)
-- ============================================

CREATE TABLE outbox_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    last_error TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_outbox_events_unprocessed ON outbox_events(next_retry_at, processed_at) WHERE processed_at IS NULL;
CREATE INDEX idx_outbox_events_aggregate ON outbox_events(aggregate_type, aggregate_id);
CREATE INDEX idx_outbox_events_created ON outbox_events(created_at DESC);

-- ============================================
-- 10. ДОПОЛНИТЕЛЬНЫЕ ВНЕШНИЕ КЛЮЧИ
-- ============================================

ALTER TABLE materials ADD CONSTRAINT fk_materials_default_supplier 
    FOREIGN KEY (default_supplier_id) REFERENCES suppliers(id);

ALTER TABLE receipts ADD CONSTRAINT fk_receipts_purchase_order 
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id);

ALTER TABLE receipts ADD CONSTRAINT fk_receipts_supplier 
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE shipments ADD CONSTRAINT fk_shipments_sales_order 
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id);

ALTER TABLE shipments ADD CONSTRAINT fk_shipments_customer 
    FOREIGN KEY (customer_id) REFERENCES customers(id);

ALTER TABLE quality_inspections ADD CONSTRAINT fk_quality_inspections_purchase_order 
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id);

ALTER TABLE quality_inspections ADD CONSTRAINT fk_quality_inspections_supplier 
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE production_operations ADD CONSTRAINT fk_production_operations_work_center 
    FOREIGN KEY (work_center_id) REFERENCES work_centers(id);

-- ============================================
-- 11. МАТЕРИАЛИЗОВАННОЕ ПРЕДСТАВЛЕНИЕ (Остатки)
-- ============================================

CREATE MATERIALIZED VIEW current_stock AS
SELECT 
    nomenclature_id,
    batch_id,
    warehouse_id,
    cell_id,
    SUM(CASE 
        WHEN movement_type IN ('IN', 'RELEASE') THEN quantity 
        WHEN movement_type IN ('OUT', 'RESERVE') THEN -quantity 
        ELSE 0 
    END) AS quantity
FROM stock_movements
GROUP BY nomenclature_id, batch_id, warehouse_id, cell_id;

CREATE UNIQUE INDEX idx_current_stock_unique ON current_stock(nomenclature_id, batch_id, warehouse_id, cell_id);

-- ============================================
-- 12. ТРИГГЕРЫ (автообновление updated_at)
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_nomenclature_updated_at
    BEFORE UPDATE ON nomenclature
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- КОНЕЦ СКРИПТА
-- ============================================
