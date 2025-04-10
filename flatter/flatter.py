import paho.mqtt.client as mqtt
import json
import math

BROKER_URL = 'localhost'
BROKER_PORT = 1883
SUB_TOPIC = "sensor/daten"
PUB_TOPIC = "sensor/datenGlatt"
AVERAGE_COUNT = 50
username = "python"
password = "Zalter21@21"

temp_total = 0.0
humi_total = 0.0 
count = 0
timestamp = 0

def on_connect(client, userdata, flags, rc):
    print("Connected with result code", rc)
    client.subscribe(SUB_TOPIC)
    print("Subscribed to topic:", SUB_TOPIC)

def on_message(client, userdata, msg):
    global temp_total, humi_total, count, timestamp
    try:
        daten = json.loads(msg.payload.decode())
        temperatur = daten['temperatur']
        luftfeuchtigkeit = daten['luftfeuchtigkeit']
        temp_total += temperatur
        humi_total += luftfeuchtigkeit
        count += 1

        if count == AVERAGE_COUNT:
            avg1 = round(temp_total / count, 2)
            avg2 = round(humi_total / count,2)
            client.publish(PUB_TOPIC, json.dumps({"temperatur" : avg1, "luftfeuchtigkeit":avg2, "timestamp": timestamp}), qos=1)
            print(f"Sent: {avg1} , {avg2}")
            temp_total = 0.0
            humi_total = 0.0
            count = 0
            timestamp += 1
    except ValueError:
        print("Received invalid number:", msg.payload.decode())

def main():
    client = mqtt.Client()
    client.username_pw_set(username, password)
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(BROKER_URL, BROKER_PORT, 60)
    client.loop_forever()

if __name__ == "__main__":
    main()
