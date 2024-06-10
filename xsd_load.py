from lxml import etree

def load_schema(file_path):
    with open(file_path, 'rb') as f:
        schema_doc = etree.parse(f)
        return etree.XMLSchema(schema_doc)

try:
    schema_users = load_schema('/home/fsrcodefsr/Desktop/projects/pgsql-data-pipeline/schemas/users.xsd')
    print("Users schema loaded successfully")
    
    schema_addresses = load_schema('/home/fsrcodefsr/Desktop/projects/pgsql-data-pipeline/schemas/addresses.xsd')
    print("Addresses schema loaded successfully")
    
    schema_orders = load_schema('/home/fsrcodefsr/Desktop/projects/pgsql-data-pipeline/schemas/orders.xsd')
    print("Orders schema loaded successfully")
    
    schema_root = load_schema('/home/fsrcodefsr/Desktop/projects/pgsql-data-pipeline/schemas/root.xsd')
    print("Root schema loaded successfully")
    
except etree.XMLSchemaParseError as e:
    print(f"Schema parse error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
