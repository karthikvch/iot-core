import json
from awscrt import mqtt
from awsiot import mqtt_connection_builder

# -----------------------------

# CONFIG

# -----------------------------

ENDPOINT = "a2rkzcx1pu628y-ats.iot.ap-northeast-1.amazonaws.com"
CLIENT_ID = "claim-client"

PATH_TO_CERT = "../certs/claim_certificate.pem.crt"
PATH_TO_KEY = "../certs/claim_private.pem.key"
PATH_TO_ROOT = "../certs/AmazonRootCA1.pem"

TEMPLATE_NAME = "fleet_template"
THING_NAME = "sensor-hyd-001"

# -----------------------------

# TOPICS

# -----------------------------

CREATE_CERT = "$aws/certificates/create/json"
CREATE_CERT_ACCEPTED = "$aws/certificates/create/json/accepted"
CREATE_CERT_REJECTED = "$aws/certificates/create/json/rejected"

PROVISION = f"$aws/provisioning-templates/{TEMPLATE_NAME}/provision/json"
PROVISION_ACCEPTED = f"{PROVISION}/accepted"
PROVISION_REJECTED = f"{PROVISION}/rejected"

# -----------------------------

# GLOBALS

# -----------------------------

certificate_ownership_token = None

# -----------------------------

# MQTT CONNECTION

# -----------------------------

mqtt_connection = mqtt_connection_builder.mtls_from_path(
endpoint=ENDPOINT,
cert_filepath=PATH_TO_CERT,
pri_key_filepath=PATH_TO_KEY,
ca_filepath=PATH_TO_ROOT,
client_id=CLIENT_ID,
clean_session=False,
keep_alive_secs=30,
)

# -----------------------------

# CALLBACKS

# -----------------------------

def on_create_cert_accepted(topic, payload, **kwargs):
    global certificate_ownership_token

    print("✅ Certificate created")

    data = json.loads(payload)

    certificate_ownership_token = data["certificateOwnershipToken"]
    device_cert = data["certificatePem"]
    device_key = data["privateKey"]

    # Save device credentials
    with open("device_cert.pem.crt", "w") as f:
        f.write(device_cert)

    with open("device_private.pem.key", "w") as f:
        f.write(device_key)

    print("Saved device certificate & key")

    # ✅ DEFINE request HERE
    request = {
        "certificateOwnershipToken": certificate_ownership_token,
        "parameters": {
            "ThingName": THING_NAME
        }
    }

    print("Sending provisioning request...")

    mqtt_connection.publish(
        topic=PROVISION,
        payload=json.dumps(request),
        qos=mqtt.QoS.AT_LEAST_ONCE
    )
    print("Sending provisioning request...")


def on_create_cert_rejected(topic, payload, **kwargs):
    print("❌ Certificate creation FAILED")
    print(payload)

def on_provision_accepted(topic, payload, **kwargs):
    print("🎉 Provisioning SUCCESS")
    print(payload)

def on_provision_rejected(topic, payload, **kwargs):
    print("❌ Provisioning FAILED")
    print(payload)

# -----------------------------

# MAIN FLOW

# -----------------------------

print("Connecting...")
mqtt_connection.connect().result()
print("Connected!")

# Subscribe FIRST

mqtt_connection.subscribe(CREATE_CERT_ACCEPTED, mqtt.QoS.AT_LEAST_ONCE, on_create_cert_accepted)
mqtt_connection.subscribe(CREATE_CERT_REJECTED, mqtt.QoS.AT_LEAST_ONCE, on_create_cert_rejected)

mqtt_connection.subscribe(PROVISION_ACCEPTED, mqtt.QoS.AT_LEAST_ONCE, on_provision_accepted)
mqtt_connection.subscribe(PROVISION_REJECTED, mqtt.QoS.AT_LEAST_ONCE, on_provision_rejected)

# Step 1: Create certificate

print("Creating certificate...")
mqtt_connection.publish(
topic=CREATE_CERT,
payload="{}",
qos=mqtt.QoS.AT_LEAST_ONCE
)

# Keep connection alive (wait for callbacks)

import time
time.sleep(10)

mqtt_connection.disconnect()
print("Disconnected")
