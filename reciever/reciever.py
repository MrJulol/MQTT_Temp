import paho.mqtt.client as mqtt
import tkinter as tk
import json
import threading
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

# MQTT-Broker-Konfiguration
broker = 'localhost'
port = 1883
topic = "sensor/datenGlatt"
username = "python"
password = "Zalter21@21"

# Daten speichern
timestamps = []
temperatures = []
humidity = []

# Callback-Funktion bei empfangener Nachricht
def on_message(client, userdata, msg):
    try:
        daten = json.loads(msg.payload.decode())
        temperatur = daten['temperatur']
        luftfeuchtigkeit = daten['luftfeuchtigkeit']
        timestamp = daten['timestamp']

        # Update der GUI mit den empfangenen Daten
        update_gui(temperatur, luftfeuchtigkeit, timestamp)

        # Daten für das Diagramm speichern
        timestamps.append(timestamp)
        temperatures.append(temperatur)
        humidity.append(luftfeuchtigkeit)

        # Diagramm aktualisieren
        update_chart()

    except Exception as e:
        print("Fehler beim Verarbeiten der Nachricht:", e)

# Funktion zur Aktualisierung der GUI
def update_gui(temperatur, luftfeuchtigkeit, timestamp):
    temperatur_label.config(text=f"Temperatur: {temperatur}°C")
    luftfeuchtigkeit_label.config(text=f"Luftfeuchtigkeit: {luftfeuchtigkeit}%")
    timestamp_label.config(text=f"Zeit: {timestamp}")

# Funktion zur Aktualisierung des Diagramms
def update_chart():
    ax.clear()  # Diagramm löschen
    ax.plot(timestamps, temperatures, label='Temperatur (°C)', color='red')
    ax.plot(timestamps, humidity, label='Luftfeuchtigkeit (%)', color='blue')
    
    ax.set_xlabel('Zeit')
    ax.set_ylabel('Werte')
    ax.set_title('Sensor-Daten')
    ax.legend()

    canvas.draw()  # Diagramm neu zeichnen

# Funktion für den Listener-Thread
def start_mqtt_listener():
    client = mqtt.Client()
    client.username_pw_set(username, password)
    client.on_message = on_message

    client.connect(broker, port)
    client.subscribe(topic)

    print("MQTT Listener gestartet...")

    client.loop_forever()  # Dauerschleife

# GUI erstellen
def create_gui():
    global temperatur_label, luftfeuchtigkeit_label, timestamp_label, ax, canvas

    root = tk.Tk()
    root.title("Sensor-Daten")

    # Label für Temperatur
    temperatur_label = tk.Label(root, text="Temperatur: 0°C", font=("Helvetica", 14))
    temperatur_label.pack(pady=10)

    # Label für Luftfeuchtigkeit
    luftfeuchtigkeit_label = tk.Label(root, text="Luftfeuchtigkeit: 0%", font=("Helvetica", 14))
    luftfeuchtigkeit_label.pack(pady=10)

    # Label für Timestamp
    timestamp_label = tk.Label(root, text="Zeit: -", font=("Helvetica", 14))
    timestamp_label.pack(pady=10)

    # Erstellen des Diagramms
    fig, ax = plt.subplots(figsize=(6, 4))  # Erstelle ein Diagramm
    ax.set_xlabel('Zeit')
    ax.set_ylabel('Werte')
    ax.set_title('Sensor-Daten')

    # Canvas für das Diagramm
    canvas = FigureCanvasTkAgg(fig, master=root)  
    canvas.get_tk_widget().pack(pady=20)

    # Starten des MQTT-Listener-Threads
    listener_thread = threading.Thread(target=start_mqtt_listener)
    listener_thread.daemon = True
    listener_thread.start()

    root.mainloop()  # Start der GUI-Hauptschleife

# Hauptprogramm
if __name__ == "__main__":
    create_gui()
