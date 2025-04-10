package org.example;

import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import java.util.Random;

public class Main {

    private static final String BROKER_URL = "tcp://localhost:1883";
    private static final String CLIENT_ID = "SimulatorClientJava";
    private static final String TOPIC = "sensor/daten";
    private static final String USERNAME = "python";
    private static final String PASSWORD = "Zalter21@21";

    public static void main(String[] args) {
        MemoryPersistence persistence = new MemoryPersistence();
        try {
            MqttClient client = new MqttClient(BROKER_URL, CLIENT_ID, persistence);
            MqttConnectOptions connOpts = new MqttConnectOptions();
            connOpts.setUserName(USERNAME);
            connOpts.setPassword(PASSWORD.toCharArray());
            connOpts.setCleanSession(true);

            System.out.println("Connecting to broker: " + BROKER_URL);
            client.connect(connOpts);
            System.out.println("Connected");

            Random random = new Random();
            int index = 0;

            // Endless loop: generate and send random data
            while (true) {
                double temperatur = Math.round((18.0 + (30.0 - 18.0) * random.nextDouble()) * 100.0) / 100.0;
                double luftfeuchtigkeit = Math.round((30.0 + (90.0 - 30.0) * random.nextDouble()) * 100.0) / 100.0;

                // Build JSON payload (similar to the Python example)
                String payload = String.format(
                        "{\"temperatur\": %.2f, \"luftfeuchtigkeit\": %.2f, \"timestamp\": \"%d\"}",
                        temperatur, luftfeuchtigkeit, index
                );
                index++;

                MqttMessage message = new MqttMessage(payload.getBytes());
                message.setQos(1);
                client.publish(TOPIC, message);
                System.out.println("Gesendet: " + payload);

                Thread.sleep(10); // Sleep for 100 ms before sending new data
            }
        } catch (MqttException e) {
            System.err.println("MQTT Exception: " + e.getMessage());
            e.printStackTrace();
        } catch (InterruptedException e) {
            System.out.println("Simulator interrupted");
        }
    }
}