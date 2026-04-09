from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

import logging
logging.basicConfig(level=logging.DEBUG)

client = AWSIoTMQTTClient("sensor-hyd-001")

client.configureEndpoint("a2rkzcx1pu628y-ats.iot.ap-northeast-1.amazonaws.com", 8883)
client.configureCredentials("certs/AmazonRootCA1.pem", "certs/private.pem.key", "certs/certificate.pem.crt")


client.configureConnectDisconnectTimeout(10)
client.configureMQTTOperationTimeout(5)

client.connect()

client.publish("test/topic", "Hello from device!", 0)

print("Message sent!")
