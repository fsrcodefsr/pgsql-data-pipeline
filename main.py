from fastapi import FastAPI, HTTPException, Request
import asyncpg
from lxml import etree
from config import Config
from contextlib import asynccontextmanager
from datetime import datetime

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.source_conn = await asyncpg.connect(**Config.SOURCE_DB)
    app.state.dest_conn = await asyncpg.connect(**Config.DEST_DB)

    # Load XSD schemas from string
    def load_schema(file_path):
        with open(file_path, 'rb') as f:
            schema_doc = etree.parse(f)
            return etree.XMLSchema(schema_doc)

    schema_public = load_schema('schemas/public.xsd')
    print("Public schema loaded successfully")

    app.state.schemas = {
        'http://example.com/public': schema_public,
    }

    yield

    # Shutdown
    await app.state.source_conn.close()
    await app.state.dest_conn.close()

app = FastAPI(lifespan=lifespan)

async def process_user(user, conn):
    nsmap = {'public': 'http://example.com/public'}  # Используем правильное пространство имен
    user_id = user.findtext('public:id', namespaces=nsmap)
    username = user.findtext('public:username', namespaces=nsmap)
    email = user.findtext('public:email', namespaces=nsmap)
    password_hash = user.findtext('public:password_hash', namespaces=nsmap)
    created_at_str = user.findtext('public:created_at', namespaces=nsmap)
    updated_at_str = user.findtext('public:updated_at', namespaces=nsmap)
    deleted_at_str = user.findtext('public:deleted_at', namespaces=nsmap)

    if not all([user_id, username, email, password_hash]):
        raise ValueError("Missing user data")

    created_at = datetime.fromisoformat(created_at_str) if created_at_str else None
    updated_at = datetime.fromisoformat(updated_at_str) if updated_at_str else None
    deleted_at = datetime.fromisoformat(deleted_at_str) if deleted_at_str else None

    await conn.execute('''
        INSERT INTO users (id, username, email, password_hash, created_at, updated_at, deleted_at, transmitted_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
        ON CONFLICT (id) DO UPDATE
        SET username = EXCLUDED.username,
            email = EXCLUDED.email,
            password_hash = EXCLUDED.password_hash,
            created_at = EXCLUDED.created_at,
            updated_at = EXCLUDED.updated_at,
            deleted_at = EXCLUDED.deleted_at,
            transmitted_at = CURRENT_TIMESTAMP
    ''', int(user_id), username, email, password_hash, created_at, updated_at, deleted_at)

# Пример функции обработки адресов с метками времени
async def process_address(address, conn):
    nsmap = {'public': 'http://example.com/public'}  # Используем правильное пространство имен
    address_id = address.findtext('public:id', namespaces=nsmap)
    user_id = address.findtext('public:user_id', namespaces=nsmap)
    street = address.findtext('public:street', namespaces=nsmap)
    city = address.findtext('public:city', namespaces=nsmap)
    state = address.findtext('public:state', namespaces=nsmap)
    postal_code = address.findtext('public:postal_code', namespaces=nsmap)
    created_at_str = address.findtext('public:created_at', namespaces=nsmap)
    updated_at_str = address.findtext('public:updated_at', namespaces=nsmap)
    deleted_at_str = address.findtext('public:deleted_at', namespaces=nsmap)

    if not all([address_id, user_id, street, city, state, postal_code]):
        raise ValueError("Missing address data")

    created_at = datetime.fromisoformat(created_at_str) if created_at_str else None
    updated_at = datetime.fromisoformat(updated_at_str) if updated_at_str else None
    deleted_at = datetime.fromisoformat(deleted_at_str) if deleted_at_str else None

    await conn.execute('''
        INSERT INTO addresses (id, user_id, street, city, state, postal_code, created_at, updated_at, deleted_at, transmitted_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
        ON CONFLICT (id) DO UPDATE
        SET user_id = EXCLUDED.user_id,
            street = EXCLUDED.street,
            city = EXCLUDED.city,
            state = EXCLUDED.state,
            postal_code = EXCLUDED.postal_code,
            created_at = EXCLUDED.created_at,
            updated_at = EXCLUDED.updated_at,
            deleted_at = EXCLUDED.deleted_at,
            transmitted_at = CURRENT_TIMESTAMP
    ''', int(address_id), int(user_id), street, city, state, postal_code, created_at, updated_at, deleted_at)

# Пример функции обработки заказов с метками времени
async def process_order(order, conn):
    nsmap = {'public': 'http://example.com/public'}  # Используем правильное пространство имен
    order_id = order.findtext('public:id', namespaces=nsmap)
    user_id = order.findtext('public:user_id', namespaces=nsmap)
    order_date_str = order.findtext('public:order_date', namespaces=nsmap)
    total_amount = order.findtext('public:total_amount', namespaces=nsmap)
    created_at_str = order.findtext('public:created_at', namespaces=nsmap)
    updated_at_str = order.findtext('public:updated_at', namespaces=nsmap)
    deleted_at_str = order.findtext('public:deleted_at', namespaces=nsmap)

    if not all([order_id, user_id, order_date_str, total_amount]):
        raise ValueError("Missing order data")

    order_date = datetime.strptime(order_date_str, "%Y-%m-%d")
    created_at = datetime.fromisoformat(created_at_str) if created_at_str else None
    updated_at = datetime.fromisoformat(updated_at_str) if updated_at_str else None
    deleted_at = datetime.fromisoformat(deleted_at_str) if deleted_at_str else None

    await conn.execute('''
        INSERT INTO orders (id, user_id, order_date, total_amount, created_at, updated_at, deleted_at, transmitted_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
        ON CONFLICT (id) DO UPDATE
        SET user_id = EXCLUDED.user_id,
            order_date = EXCLUDED.order_date,
            total_amount = EXCLUDED.total_amount,
            created_at = EXCLUDED.created_at,
            updated_at = EXCLUDED.updated_at,
            deleted_at = EXCLUDED.deleted_at,
            transmitted_at = CURRENT_TIMESTAMP
    ''', int(order_id), int(user_id), order_date, float(total_amount), created_at, updated_at, deleted_at)


@app.post("/update")
async def update_data(request: Request):
    try:
        # Получение XML данных из запроса
        xml_data = await request.body()
        print(f"Received XML: {xml_data}")

        # Парсинг XML данных
        xml_doc = etree.fromstring(xml_data)

        # Валидация XML данных
        schema_location = xml_doc.get('{http://www.w3.org/2001/XMLSchema-instance}schemaLocation')

        if not schema_location:
            raise HTTPException(status_code=400, detail="Missing schemaLocation attribute")

        print(f"schemaLocation found: {schema_location}")

        schema_locations = schema_location.split()
        schema_dict = dict(zip(schema_locations[::2], schema_locations[1::2]))

        # Проверка схемы для корневого элемента
        root_ns = xml_doc.nsmap[xml_doc.prefix]
        schema_file = schema_dict.get(root_ns)

        if not schema_file:
            raise HTTPException(status_code=400, detail=f"No schema found for namespace: {root_ns}")

        schema = app.state.schemas.get(root_ns)

        if schema is None:
            raise HTTPException(status_code=400, detail=f"No schema found for given namespace: {root_ns}")

        schema.assertValid(xml_doc)

        # Обработка данных и обновление базы данных
        async with app.state.dest_conn.transaction():
            for user in xml_doc.findall('.//public:user', namespaces={'public': 'http://example.com/public'}):
                await process_user(user, app.state.dest_conn)
            for address in xml_doc.findall('.//public:address', namespaces={'public': 'http://example.com/public'}):
                await process_address(address, app.state.dest_conn)
            for order in xml_doc.findall('.//public:order', namespaces={'public': 'http://example.com/public'}):
                await process_order(order, app.state.dest_conn)

        return {"message": "Data successfully updated"}

    except etree.XMLSyntaxError as e:
        raise HTTPException(status_code=400, detail=f"XML Syntax Error: {e}")
    except etree.DocumentInvalid as e:
        raise HTTPException(status_code=400, detail=f"Document Invalid: {e}")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Value Error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {e}")

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=5000)
