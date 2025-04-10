import paho.mqtt.client as mqtt
import time
import random
import json

# MQTT-Broker-Einstellungen
broker = 'localhost'
port = 1883
topic = "sensor/daten"
username = "python"     # Entsprechend deiner Mosquitto-Konfiguration
password = "Zalter21@21"

index = 0

# MQTT-Client konfigurieren
client = mqtt.Client()
client.username_pw_set(username, password)

client.connect(broker, port)

# Endlosschleife: zufällige Daten erzeugen und senden
try:
    while True:
        temperatur = round(random.uniform(18.0, 30.0), 2)        # z. B. 22.75 °C
        luftfeuchtigkeit = round(random.uniform(30.0, 90.0), 2)  # z. B. 65.32 %

        daten = {
            "temperatur": temperatur,
            "luftfeuchtigkeit": luftfeuchtigkeit,
            "timestamp": f"{index}"
        }

        index += 1

        payload = json.dumps(daten)

        client.publish(topic, payload)
        print(f"Gesendet: {payload}")

        time.sleep(0.1)  # alle 5 Sekunden neue Daten

except KeyboardInterrupt:
    print("Datengenerator beendet")
    client.disconnect()
