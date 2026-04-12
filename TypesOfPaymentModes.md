# Types of payments in your machines

Your machine may support:

1. 💵 Cash
2. 💳 Card (online / offline EMV)
3. 📱 UPI / QR (like Google Pay, PhonePe)



1. Payment system (bank side)
2. IoT system (AWS + data sync)


Case 1: Internet is DOWN
💳 UPI / QR (Google Pay / PhonePe)

❌ Will NOT work

👉 Why:

Needs bank server
No internet = no approval
💳 Card (normal swipe/tap)

❌ Will NOT work (in most cases)

👉 Because:

Machine must contact bank
💳 Card (offline mode — special)

🟡 MAY work (if enabled)

👉 What happens:

User taps card
Machine does NOT check bank
Machine says: “OK, I’ll trust this”
Stores transaction
Sends later when internet is back

👉 Risk:

Maybe no balance 😅
💵 Cash

✅ ALWAYS works

👉 No internet needed

🧠 What YOUR machine should do
✅ Simple logic
If internet is ON:
   Allow all payments

If internet is OFF:
   Allow cash
   Allow offline card (optional)
   Block UPI
🔄 What happens to data (IMPORTANT)

Even if internet is down:

👉 Machine still stores everything

Example:

{
  "txn_id": "TXN1001",
  "amount": 50,
  "status": "PENDING"
}
🔁 When internet comes back
Send all stored transactions → Cloud (AWS IoT Core)

👉 No data loss ✅

🧠 Very simple analogy
Internet down = shop WiFi gone
Shop still sells using cash
Writes in notebook
Later updates system
🎯 Final simple answer

👉 When internet is down:

UPI ❌
Online card ❌
Cash ✅
Offline card 🟡 (if enabled)

👉 Machine still:

Works
Stores data
Syncs later
⚡ Important point

👉 AWS IoT Core is only for:

Data sync
Monitoring

👉 It does NOT handle payment approval




# [10 Machines] → [1 Gateway] → [AWS IoT Core]

Machines ↔ Gateway (Mosquitto) ↔ AWS IoT Core


## Communication security
Machines → Gateway:
Local network (secure LAN)
Gateway → AWS:
TLS certificates
Encrypted MQTT

🧠 Full flow (step-by-step)
Ticket purchase

1. User buys ticket
2. Machine publishes txn → Mosquitto
3. Mosquitto stores + forwards
4. AWS receives data
5. Cloud sends ACK/command (optional)


[Machine 1] \
[Machine 2]  \
[Machine 3]   →  [LAN] → [Gateway (Mosquitto)] → Internet → AWS IoT Core
[Machine N]  /


OTA Process:

1. New software release is published to ORG from from Cloud
2. Station Broker machine received the request and download the new release
3. Now OTA request comes from cloud .stantion Broker sends the


🏭 🥇 Industry Standard OTA Architecture
Cloud (control + firmware store)
        ↓
Station Gateway (cache + distributor)
        ↓
Devices (machines pull & update)
🔑 Core principle

✅ Control plane = MQTT (commands)
✅ Data plane = HTTP/HTTPS (firmware download)
✅ Devices PULL updates, not pushed