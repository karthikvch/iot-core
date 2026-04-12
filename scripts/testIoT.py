import json

from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

import logging
logging.basicConfig(level=logging.DEBUG)

client = AWSIoTMQTTClient("sensor-hyd-002")

client.configureEndpoint("a2rkzcx1pu628y-ats.iot.ap-northeast-1.amazonaws.com", 8883)
client.configureCredentials("certs/AmazonRootCA1.pem", "certs/private.pem.key", "certs/certificate.pem.crt")


client.configureConnectDisconnectTimeout(10)
client.configureMQTTOperationTimeout(5)

client.connect()
payload = {
    "device": "sensor-hyd-002",
    "temperature": 28.4,
    "status": "OK"
}


client.publish("test/topic", json.dumps(payload), 0)
client.disconnect()

print("Message sent!"+ json.dumps(payload))
