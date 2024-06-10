import os
import requests
import json
import psycopg2
import select
import xml.etree.ElementTree as ET  # Импортируем модуль для работы с XML

def send_post_request(payload):
    url = 'http://localhost:5000/update'
    headers = {'Content-Type': 'application/xml'}
    try:
        response = requests.post(url, data=payload, headers=headers)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        print(f"HTTP error occurred: {e}")
        print(f"Response content: {response.content}")
    except Exception as e:
        print(f"Other error occurred: {e}")

def generate_xml(payload):
    # Создаем корневой элемент XML
    root = ET.Element('root', xmlns="http://example.com/public")
    
    # Добавляем атрибут xsi:schemaLocation для указания местоположения схемы
    xsi_namespace = 'http://www.w3.org/2001/XMLSchema-instance'
    root.set(f'{{{xsi_namespace}}}schemaLocation', 'http://example.com/public public.xsd')

    # Добавляем элементы в зависимости от таблицы
    if payload['table'] == 'users':
        user_elem = ET.SubElement(root, 'user')  # Создаем элемент <user>
        new_data = payload['new']  # Получаем данные новой записи из payload

        # Добавляем каждый ключ и его значение в XML
        if 'id' in new_data:
            ET.SubElement(user_elem, 'id').text = str(new_data['id'])
        if 'username' in new_data:
            ET.SubElement(user_elem, 'username').text = new_data['username']
        if 'email' in new_data:
            ET.SubElement(user_elem, 'email').text = new_data['email']
        if 'password_hash' in new_data:
            ET.SubElement(user_elem, 'password_hash').text = new_data['password_hash']
        if 'created_at' in new_data:
            ET.SubElement(user_elem, 'created_at').text = new_data['created_at']
        if 'updated_at' in new_data and new_data['updated_at'] is not None:
            ET.SubElement(user_elem, 'updated_at').text = new_data['updated_at']
        if 'deleted_at' in new_data and new_data['deleted_at'] is not None:
            ET.SubElement(user_elem, 'deleted_at').text = new_data['deleted_at']
        if 'transmitted_at' in new_data and new_data['transmitted_at'] is not None:
            ET.SubElement(user_elem, 'transmitted_at').text = new_data['transmitted_at']

    elif payload['table'] == 'addresses':
        address_elem = ET.SubElement(root, 'address')  # Создаем элемент <address>
        new_data = payload['new']

        # Добавляем каждый ключ и его значение в XML
        if 'id' in new_data:
            ET.SubElement(address_elem, 'id').text = str(new_data['id'])
        if 'user_id' in new_data:
            ET.SubElement(address_elem, 'user_id').text = str(new_data['user_id'])
        if 'street' in new_data:
            ET.SubElement(address_elem, 'street').text = new_data['street']
        if 'city' in new_data:
            ET.SubElement(address_elem, 'city').text = new_data['city']
        if 'state' in new_data:
            ET.SubElement(address_elem, 'state').text = new_data['state']
        if 'postal_code' in new_data:
            ET.SubElement(address_elem, 'postal_code').text = new_data['postal_code']
        if 'created_at' in new_data:
            ET.SubElement(address_elem, 'created_at').text = new_data['created_at']
        if 'updated_at' in new_data and new_data['updated_at'] is not None:
            ET.SubElement(address_elem, 'updated_at').text = new_data['updated_at']
        if 'deleted_at' in new_data and new_data['deleted_at'] is not None:
            ET.SubElement(address_elem, 'deleted_at').text = new_data['deleted_at']
        if 'transmitted_at' in new_data and new_data['transmitted_at'] is not None:
            ET.SubElement(address_elem, 'transmitted_at').text = new_data['transmitted_at']

    elif payload['table'] == 'orders':
        order_elem = ET.SubElement(root, 'order')  # Создаем элемент <order>
        new_data = payload['new']

        # Добавляем каждый ключ и его значение в XML
        if 'id' in new_data:
            ET.SubElement(order_elem, 'id').text = str(new_data['id'])
        if 'user_id' in new_data:
            ET.SubElement(order_elem, 'user_id').text = str(new_data['user_id'])
        if 'order_date' in new_data:
            ET.SubElement(order_elem, 'order_date').text = new_data['order_date']
        if 'total_amount' in new_data:
            ET.SubElement(order_elem, 'total_amount').text = str(new_data['total_amount'])
        if 'created_at' in new_data:
            ET.SubElement(order_elem, 'created_at').text = new_data['created_at']
        if 'updated_at' in new_data and new_data['updated_at'] is not None:
            ET.SubElement(order_elem, 'updated_at').text = new_data['updated_at']
        if 'deleted_at' in new_data and new_data['deleted_at'] is not None:
            ET.SubElement(order_elem, 'deleted_at').text = new_data['deleted_at']
        if 'transmitted_at' in new_data and new_data['transmitted_at'] is not None:
            ET.SubElement(order_elem, 'transmitted_at').text = new_data['transmitted_at']

    else:
        return None  # Если таблица не соответствует ожидаемым, возвращаем None

    # Преобразуем XML-документ в строку
    xml_str = ET.tostring(root, encoding='unicode')
    return xml_str

def source():
    conn = psycopg2.connect(
        dbname="source_db",
        user="user",
        password="123!@#",
        host="localhost",
        port="6543"
    )
    conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()
    cur.execute("LISTEN table_changes;")

    print("Waiting for notifications on channel 'table_changes'")
    while True:
        if select.select([conn], [], [], 5) == ([], [], []):
            print("Timeout")
        else:
            conn.poll()
            while conn.notifies:
                notify = conn.notifies.pop(0)
                payload = json.loads(notify.payload)
                print(f"Got NOTIFY: {payload}")

                # Генерируем XML из payload
                xml_data = generate_xml(payload)
                if xml_data is not None:
                    send_post_request(xml_data)

if __name__ == "__main__":
    source()
