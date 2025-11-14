/*
 * Swimming Stroke Tracker - ESP32 Firmware
 *
 * Hardware Connections:
 * - MPU6050: SDA -> GPIO21, SCL -> GPIO22
 * - SD Card Module: CS -> GPIO4, MOSI -> GPIO23, MISO -> GPIO19, SCK -> GPIO18
 * - Power: TP4056 charging circuit with 18650 battery
 *
 * Commands:
 * - "SS": Start recording stroke data to SD card
 * - "ST": Stop recording and send file via Bluetooth
 */

#include <Wire.h>
#include <MPU6050.h>
#include <SPI.h>
#include <SD.h>
#include <BluetoothSerial.h>

// Pin definitions
#define SD_CS_PIN 4
#define MPU_SDA 21
#define MPU_SCL 22

// Bluetooth
BluetoothSerial SerialBT;

// MPU6050
MPU6050 mpu;

// Recording state
bool isRecording = false;
File dataFile;
String currentFileName = "";
unsigned long recordingStartTime = 0;
unsigned long lastSampleTime = 0;
const unsigned long SAMPLE_INTERVAL = 20; // 50Hz sampling rate

// Data buffers
struct SensorData {
  unsigned long timestamp;
  int16_t ax, ay, az;
  int16_t gx, gy, gz;
};

void setup() {
  Serial.begin(115200);

  // Initialize I2C for MPU6050
  Wire.begin(MPU_SDA, MPU_SCL);

  // Initialize MPU6050
  Serial.println("Initializing MPU6050...");
  mpu.initialize();

  if (!mpu.testConnection()) {
    Serial.println("MPU6050 connection failed!");
    while (1) {
      delay(1000);
    }
  }
  Serial.println("MPU6050 connected successfully");

  // Configure MPU6050
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_4); // ±4g
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_500); // ±500°/s
  mpu.setDLPFMode(MPU6050_DLPF_BW_42); // Low pass filter 42Hz

  // Initialize SD card
  Serial.println("Initializing SD card...");
  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("SD card initialization failed!");
    while (1) {
      delay(1000);
    }
  }
  Serial.println("SD card initialized successfully");

  // Initialize Bluetooth
  if (!SerialBT.begin("SwimStrokeTracker")) {
    Serial.println("Bluetooth initialization failed!");
    while (1) {
      delay(1000);
    }
  }
  Serial.println("Bluetooth initialized - Device: SwimStrokeTracker");

  Serial.println("System ready!");
}

void loop() {
  // Check for Bluetooth commands
  if (SerialBT.available()) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    handleCommand(command);
  }

  // Record data if recording is active
  if (isRecording) {
    unsigned long currentTime = millis();

    if (currentTime - lastSampleTime >= SAMPLE_INTERVAL) {
      lastSampleTime = currentTime;
      recordSensorData();
    }
  }

  delay(1);
}

void handleCommand(String command) {
  Serial.println("Received command: " + command);

  if (command == "SS") {
    startRecording();
  } else if (command == "ST") {
    stopRecording();
    sendFileViaBluetooth();
  } else if (command == "STATUS") {
    sendStatus();
  } else if (command == "DELETE") {
    deleteLastFile();
  } else {
    SerialBT.println("ERROR:Unknown command");
  }
}

void startRecording() {
  if (isRecording) {
    SerialBT.println("ERROR:Already recording");
    return;
  }

  // Generate filename with timestamp
  currentFileName = "/swim_" + String(millis()) + ".csv";

  // Create and open file
  dataFile = SD.open(currentFileName, FILE_WRITE);

  if (!dataFile) {
    SerialBT.println("ERROR:Failed to create file");
    Serial.println("Failed to create file: " + currentFileName);
    return;
  }

  // Write CSV header
  dataFile.println("timestamp,ax,ay,az,gx,gy,gz");
  dataFile.flush();

  isRecording = true;
  recordingStartTime = millis();
  lastSampleTime = millis();

  SerialBT.println("OK:Recording started");
  Serial.println("Recording started: " + currentFileName);
}

void stopRecording() {
  if (!isRecording) {
    SerialBT.println("ERROR:Not recording");
    return;
  }

  isRecording = false;

  if (dataFile) {
    dataFile.close();
  }

  unsigned long duration = (millis() - recordingStartTime) / 1000;
  SerialBT.println("OK:Recording stopped - Duration: " + String(duration) + "s");
  Serial.println("Recording stopped - Duration: " + String(duration) + "s");
}

void recordSensorData() {
  if (!dataFile) {
    return;
  }

  // Read sensor data
  int16_t ax, ay, az;
  int16_t gx, gy, gz;

  mpu.getAcceleration(&ax, &ay, &az);
  mpu.getRotation(&gx, &gy, &gz);

  // Write to SD card in CSV format
  unsigned long timestamp = millis() - recordingStartTime;

  dataFile.print(timestamp);
  dataFile.print(",");
  dataFile.print(ax);
  dataFile.print(",");
  dataFile.print(ay);
  dataFile.print(",");
  dataFile.print(az);
  dataFile.print(",");
  dataFile.print(gx);
  dataFile.print(",");
  dataFile.print(gy);
  dataFile.print(",");
  dataFile.println(gz);

  // Flush every 100 samples (2 seconds at 50Hz)
  static int sampleCount = 0;
  sampleCount++;
  if (sampleCount >= 100) {
    dataFile.flush();
    sampleCount = 0;
  }
}

void sendFileViaBluetooth() {
  if (currentFileName == "") {
    SerialBT.println("ERROR:No file to send");
    return;
  }

  File file = SD.open(currentFileName, FILE_READ);

  if (!file) {
    SerialBT.println("ERROR:Failed to open file");
    return;
  }

  // Get file size
  unsigned long fileSize = file.size();

  // Send file header
  SerialBT.println("FILE_START");
  SerialBT.println("SIZE:" + String(fileSize));
  SerialBT.println("NAME:" + currentFileName);

  delay(100); // Give receiver time to prepare

  // Send file data in chunks
  const int CHUNK_SIZE = 512;
  byte buffer[CHUNK_SIZE];
  unsigned long bytesSent = 0;

  Serial.println("Sending file: " + currentFileName + " (" + String(fileSize) + " bytes)");

  while (file.available()) {
    int bytesRead = file.read(buffer, CHUNK_SIZE);
    SerialBT.write(buffer, bytesRead);
    bytesSent += bytesRead;

    // Send progress every 10KB
    if (bytesSent % 10240 == 0) {
      Serial.println("Progress: " + String(bytesSent) + "/" + String(fileSize) + " bytes");
    }

    delay(10); // Small delay to prevent buffer overflow
  }

  file.close();

  // Send end marker
  delay(100);
  SerialBT.println("FILE_END");

  Serial.println("File sent successfully: " + String(bytesSent) + " bytes");
}

void sendStatus() {
  String status = "STATUS:";
  status += isRecording ? "RECORDING" : "IDLE";

  if (isRecording) {
    unsigned long duration = (millis() - recordingStartTime) / 1000;
    status += ",Duration:" + String(duration) + "s";
  }

  // SD card info
  unsigned long cardSize = SD.cardSize() / (1024 * 1024);
  unsigned long usedSize = SD.usedBytes() / (1024 * 1024);
  status += ",SD:" + String(usedSize) + "MB/" + String(cardSize) + "MB";

  SerialBT.println(status);
}

void deleteLastFile() {
  if (currentFileName == "") {
    SerialBT.println("ERROR:No file to delete");
    return;
  }

  if (isRecording) {
    SerialBT.println("ERROR:Cannot delete while recording");
    return;
  }

  if (SD.remove(currentFileName)) {
    SerialBT.println("OK:File deleted");
    currentFileName = "";
  } else {
    SerialBT.println("ERROR:Failed to delete file");
  }
}
