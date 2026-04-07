// Создаем новую базу данных и коллекции
db = db.getSiblingDB("mrp_database");

print("📊 Создание базы данных mrp_database и коллекций...");

// 1. audit_logs
db.createCollection("audit_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "actionType", "entityType", "timestamp"],
      properties: {
        userId: { bsonType: "string" },
        actionType: { enum: ["CREATE", "UPDATE", "DELETE"] },
        entityType: { bsonType: "string" },
        entityId: { bsonType: "string" },
        oldValue: { bsonType: ["object", "null"] },
        newValue: { bsonType: ["object", "null"] },
        ipAddress: { bsonType: "string" },
        partition: { bsonType: "int" },
        timestamp: { bsonType: "date" }
      }
    }
  }
});

db.audit_logs.createIndex({ timestamp: -1 });
db.audit_logs.createIndex({ userId: 1, timestamp: -1 });
db.audit_logs.createIndex({ entityType: 1, entityId: 1 });

print("✅ audit_logs создана");

// 2. integration_logs
db.createCollection("integration_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["direction", "payload", "createdAt"],
      properties: {
        direction: { enum: ["IN", "OUT"] },
        payload: { bsonType: "object" },
        processedAt: { bsonType: ["date", "null"] },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

db.integration_logs.createIndex({ createdAt: -1 });
db.integration_logs.createIndex({ direction: 1 });
db.integration_logs.createIndex({ processedAt: 1 });

print("✅ integration_logs создана");

// 3. mrp_results
db.createCollection("mrp_results", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["planId", "calculatedAt", "status"],
      properties: {
        planId: { bsonType: "string" },
        calculatedAt: { bsonType: "date" },
        horizonDays: { bsonType: ["int", "null"] },
        status: { enum: ["COMPLETED", "PENDING", "FAILED"] },
        totalMaterials: { bsonType: ["int", "null"] },
        totalDeficit: { bsonType: ["double", "int", "null"] },
        urgentCount: { bsonType: ["int", "null"] },
        mongodbDocumentId: { bsonType: ["string", "null"] }
      }
    }
  }
});

db.mrp_results.createIndex({ planId: 1 });
db.mrp_results.createIndex({ calculatedAt: -1 });
db.mrp_results.createIndex({ status: 1, calculatedAt: -1 });

print("✅ mrp_results создана");

// 4. mrp_result_items (ИСПРАВЛЕНО - добавлен int)
db.createCollection("mrp_result_items", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["resultId", "materialId", "deficit"],
      properties: {
        resultId: { bsonType: "string" },
        materialId: { bsonType: "string" },
        materialName: { bsonType: ["string", "null"] },
        requiredQty: { bsonType: ["double", "int", "null"] },
        availableQty: { bsonType: ["double", "int", "null"] },
        deficit: { bsonType: ["double", "int"] },
        recommendedDate: { bsonType: ["date", "null"] }
      }
    }
  }
});

db.mrp_result_items.createIndex({ resultId: 1 });
db.mrp_result_items.createIndex({ materialId: 1, deficit: 1 });
db.mrp_result_items.createIndex({ recommendedDate: 1 });
db.mrp_result_items.createIndex({ materialId: 1, recommendedDate: 1 });

print("✅ mrp_result_items создана");

// 5. stock_forecasts
db.createCollection("stock_forecasts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["materialId", "forecastDate", "projectedQty"],
      properties: {
        materialId: { bsonType: "string" },
        materialName: { bsonType: ["string", "null"] },
        warehouseId: { bsonType: ["string", "null"] },
        warehouseName: { bsonType: ["string", "null"] },
        forecastDate: { bsonType: "date" },
        projectedQty: { bsonType: ["double", "int"] },
        sourceEvents: { bsonType: ["array", "null"] }
      }
    }
  }
});

db.stock_forecasts.createIndex({ materialId: 1, forecastDate: 1 });
db.stock_forecasts.createIndex({ warehouseId: 1 });
db.stock_forecasts.createIndex({ forecastDate: -1 });

print("✅ stock_forecasts создана");

// 6. reservations
db.createCollection("reservations", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["salesOrderId", "materialId", "quantity", "expiresAt", "status"],
      properties: {
        salesOrderId: { bsonType: "string" },
        salesOrderNumber: { bsonType: ["string", "null"] },
        materialId: { bsonType: "string" },
        materialName: { bsonType: ["string", "null"] },
        batchId: { bsonType: ["string", "null"] },
        quantity: { bsonType: ["double", "int"] },
        expiresAt: { bsonType: "date" },
        status: { enum: ["ACTIVE", "CONFIRMED", "EXPIRED", "CANCELLED"] },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

db.reservations.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
db.reservations.createIndex({ salesOrderId: 1 });
db.reservations.createIndex({ materialId: 1, status: 1 });
db.reservations.createIndex({ status: 1, expiresAt: 1 });
db.reservations.createIndex({ createdAt: -1 });

print("✅ reservations создана");

// 7. warehouse_routes
db.createCollection("warehouse_routes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["warehouseId", "routeName", "routeType", "isActive"],
      properties: {
        warehouseId: { bsonType: "string" },
        routeName: { bsonType: "string" },
        routeType: { enum: ["PICKING", "PUTAWAY", "REPLENISHMENT", "INVENTORY"] },
        isActive: { bsonType: "bool" },
        waypoints: { bsonType: ["array", "null"] },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

db.warehouse_routes.createIndex({ warehouseId: 1 });
db.warehouse_routes.createIndex({ isActive: 1 });
db.warehouse_routes.createIndex({ routeType: 1 });

print("✅ warehouse_routes создана");

// Показываем все коллекции
print("\n📋 Все коллекции:");
print(db.getCollectionNames());

// Вставляем тестовые данные
print("\n🧪 Вставка тестовых данных...");

db.audit_logs.insertOne({
  userId: "user-001",
  actionType: "CREATE",
  entityType: "Reservation",
  entityId: "res-001",
  oldValue: null,
  newValue: { quantity: 100 },
  ipAddress: "192.168.1.100",
  partition: 202604,
  timestamp: new Date()
});

db.mrp_results.insertOne({
  planId: "plan-001",
  calculatedAt: new Date(),
  horizonDays: 30,
  status: "COMPLETED",
  totalMaterials: 50,
  totalDeficit: 1000.50,
  urgentCount: 5
});

db.mrp_result_items.insertOne({
  resultId: "mrp-001",
  materialId: "mat-001",
  materialName: "Сталь листовая 2мм",
  requiredQty: 1000,
  availableQty: 300,
  deficit: 700,
  recommendedDate: new Date("2026-04-10")
});

db.reservations.insertOne({
  salesOrderId: "so-001",
  salesOrderNumber: "SO-12345",
  materialId: "mat-001",
  materialName: "Сталь листовая 2мм",
  batchId: "batch-001",
  quantity: 100,
  expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
  status: "ACTIVE",
  createdAt: new Date()
});

db.stock_forecasts.insertOne({
  materialId: "mat-001",
  materialName: "Сталь листовая 2мм",
  warehouseId: "wh-001",
  warehouseName: "Основной склад",
  forecastDate: new Date("2026-04-15"),
  projectedQty: 500,
  sourceEvents: ["PO-123", "SO-456"]
});

db.warehouse_routes.insertOne({
  warehouseId: "wh-001",
  routeName: "Маршрут отбора Zone A",
  routeType: "PICKING",
  isActive: true,
  waypoints: [
    { cellCode: "A-01", sequenceNumber: 1, actionType: "STOP", estimatedDistance: 5 },
    { cellCode: "A-02", sequenceNumber: 2, actionType: "STOP", estimatedDistance: 10 },
    { cellCode: "B-01", sequenceNumber: 3, actionType: "PASS", estimatedDistance: 15 }
  ],
  createdAt: new Date(),
  updatedAt: new Date()
});

db.integration_logs.insertOne({
  direction: "IN",
  payload: { event: "test", data: "sample" },
  processedAt: new Date(),
  createdAt: new Date()
});

print("✅ Тестовые данные вставлены");

// Финальная статистика
print("\n========================================");
print("✅ MongoDB инициализирована успешно!");
print("========================================");
print("База данных: mrp_database");
print("Коллекций: 7");
print("Тестовых документов: 6");
print("========================================");