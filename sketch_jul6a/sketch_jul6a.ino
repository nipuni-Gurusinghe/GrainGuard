#include <ESP8266Firebase.h>
#include <ESP8266WiFi.h>
#include "HX711.h"
#include <NTPClient.h>
#include <WiFiUdp.h>


#define WIFI_SSID "Nwifi"
#define WIFI_PASSWORD "nipuni12345"
#define REFERENCE_URL "https://smartjarcup-default-rtdb.firebaseio.com/"


const byte doutPin = 12;  
const byte sckPin = 13;  


Firebase firebase(REFERENCE_URL);
HX711 module;


WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 19800, 60000); 


const String UID = "n0RSwlrPUvNwGodSXhbgW1iwhEB2";
const String containerId = "001";
const String userPath = "users/" + UID + "/";
const String containerPath = "containers/" + containerId + "/";


float calibration = -1000.0;
float weight = 0;
float lastWeight = 0; 
const float SCALE_FACTOR = 3.12;
const float FULL_WEIGHT = 500.0;
const float REFILL_THRESHOLD = 100.0; 


const unsigned long HISTORY_UPDATE_INTERVAL = 60000;
unsigned long lastHistoryUpdate = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial);

  initializeLoadCell();
  connectToWiFi();
  initializeTimeClient();
  
  if (!verifyUidExists()) {
    Serial.println("Error: UID path does not exist in database");
    while (1);
  }
  
  testFirebaseConnection();
  initializeContainer();
  setStaticFullWeight();
}

void loop() {
  handleSerialInput();
  weight = getCurrentWeight();
  
  
  if (weight > lastWeight + REFILL_THRESHOLD) {
    updateFillDay();
  }
  lastWeight = weight;

  unsigned long currentMillis = millis();

   
  updateCurrentWeight(weight);
  
  
  if (currentMillis - lastHistoryUpdate >= HISTORY_UPDATE_INTERVAL) {
    updateUsageHistory(weight);
    lastHistoryUpdate = currentMillis;
  }
  
  delay(100);
}

void updateFillDay() {
  String currentDate = getFormattedDate();
  if (firebase.setString(containerPath + "fill_day", currentDate)) {
    Serial.print("Refill detected! Updated fill_day to: ");
    Serial.println(currentDate);
  } else {
    Serial.println("Failed to update fill_day");
  }
}

void setStaticFullWeight() {
  if (firebase.setFloat(containerPath + "full_weight", FULL_WEIGHT)) {
    Serial.print("Static full weight set to: ");
    Serial.println(FULL_WEIGHT);
  } else {
    Serial.println("Failed to set static full weight");
  }
}

bool verifyUidExists() {
  String testPath = userPath + ".uid_verify";
  if (firebase.setString(testPath, "test")) {
    firebase.deleteData(testPath);
    return true;
  }
  return false;
}

void initializeLoadCell() {
  pinMode(sckPin, OUTPUT);
  digitalWrite(sckPin, LOW);
  module.begin(doutPin, sckPin);
  module.power_down();
  delay(300);
  module.power_up();
  module.set_scale(calibration);
  module.tare(20);
  Serial.println("\nLoad Cell Initialized");
}

void connectToWiFi() {
  Serial.print("\nConnecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWiFi Connected");
}

void initializeTimeClient() {
  timeClient.begin();
  timeClient.forceUpdate();
}

void testFirebaseConnection() {
  String testPath = containerPath + "connection_test";
  if (firebase.setString(testPath, String(millis()))) {
    firebase.deleteData(testPath);
  }
}

void initializeContainer() {
  if (firebase.getString(containerPath + "name") == "") {
    if (firebase.setString(containerPath + "name", "Rice") &&
        firebase.setString(containerPath + "ownerId", UID) &&
        firebase.setString(containerPath + "fill_day", "N/A") &&
        firebase.setFloat(containerPath + "current_weight", 0) &&
        firebase.setFloat(containerPath + "full_weight", FULL_WEIGHT) &&
        firebase.setInt(userPath + "myContainers/" + containerId, 1)) {
      Serial.println("Container initialized");
    }
  }
}

void handleSerialInput() {
  if (Serial.available()) {
    char input = Serial.read();
    if (input == '+') calibration += 100;
    else if (input == '-') calibration -= 100;
    else if (input == 't') module.tare(20);
    else if (input == 'f') updateFillDay(); 
    module.set_scale(calibration);
  }
}

float getCurrentWeight() {
  float currentWeight = module.get_units(10) * SCALE_FACTOR;
  Serial.print("Weight: ");
  Serial.print(currentWeight);
  Serial.println("g");
  return currentWeight;
}

void updateCurrentWeight(float weight) {
  firebase.setFloat(containerPath + "current_weight", weight);
}

void updateUsageHistory(float weight) {
  String timestamp = getFormattedTimestamp();
  firebase.setFloat(containerPath + "usage_history/" + timestamp, weight);
}

String getFormattedDate() {
  timeClient.update();
  time_t rawtime = timeClient.getEpochTime();
  struct tm *ti = localtime(&rawtime);
  char buffer[11];
  sprintf(buffer, "%04d-%02d-%02d", ti->tm_year+1900, ti->tm_mon+1, ti->tm_mday);
  return String(buffer);
}

String getFormattedTimestamp() {
  timeClient.update();
  time_t rawtime = timeClient.getEpochTime();
  struct tm *ti = localtime(&rawtime);
  char buffer[20];
  sprintf(buffer, "%04d-%02d-%02dT%02d:%02d", ti->tm_year+1900, ti->tm_mon+1, ti->tm_mday, ti->tm_hour, ti->tm_min);
  return String(buffer);
}