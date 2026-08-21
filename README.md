# 📺 ESP32 HDMI-CEC TV Autostart

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PlatformIO](https://img.shields.io/badge/PlatformIO-Supported-orange.svg)](https://platformio.org)
[![Arduino IDE](https://img.shields.io/badge/Arduino%20IDE-Compatible-00979C.svg)](https://www.arduino.cc/en/software)
[![Hardware](https://img.shields.io/badge/Hardware-ESP32%20%7C%20DS3231-green.svg)](#hardware-bill-of-materials-bom)

**A standalone, plug-and-play hardware solution that turns your Google TV / Smart TV on and activates the HDMI input automatically after a power outage — no WiFi, no manual intervention.**

[English Documentation](#-english-documentation) • [النسخة العربية (Arabic Documentation)](#-النسخة-العربية)

</div>

---

# 🇬🇧 English Documentation

## Overview

When power is restored following an electrical blackout, most modern Smart TVs (Google TV, Android TV, Samsung Tizen, LG webOS, Sony Bravia) enter a passive **Standby mode** and remain turned off.

**ESP32 HDMI-CEC TV Autostart** is a self-contained device that plugs directly into any HDMI port on your TV:
1. Powered directly via the HDMI connector's **Pin 18 (+5V)** and **Pin 17 (GND)**.
2. Reads current time from a battery-backed **DS3231 RTC Module** and computes the exact **outage duration**.
3. Waits for a configurable startup delay (`WAIT_SECONDS = 15s`) to allow the TV's power supply and standby controller to boot up.
4. Transmits standard **HDMI-CEC** commands:
   - `<Image View On>` (`0x04`): Wakes the TV screen from Standby.
   - `<Active Source>` (`0x82`): Selects and displays the active HDMI port.
5. Saves the new boot timestamp to non-volatile storage (AT24C32 EEPROM / NVS) for future outage diagnostics.

---

## Hardware Bill of Materials (BOM)

| Component | Description / Specification | Quantity | Purpose | Purchase Search Links |
| :--- | :--- | :---: | :--- | :--- |
| **ESP32 Board** | ESP32-C3 Super Mini *(Recommended)* or ESP32 DevKit v1 | 1 | Microcontroller running the CEC engine | [AliExpress](https://www.aliexpress.com/wholesale?SearchText=esp32-c3+super+mini) / [Amazon](https://www.amazon.com/s?k=esp32-c3+super+mini) |
| **DS3231 RTC Module** | High-precision Real Time Clock with I2C + AT24C32 | 1 | Time retention during blackouts & outage logging | [AliExpress](https://www.aliexpress.com/wholesale?SearchText=DS3231+RTC+module) / [Amazon](https://www.amazon.com/s?k=DS3231+RTC+module) |
| **CR2032 Coin Battery** | 3V Lithium Cell | 1 | Powers the DS3231 clock during power outages | [Amazon](https://www.amazon.com/s?k=CR2032+battery) |
| **HDMI Male Breakout** | HDMI Male Plug with solder pads or screw terminals | 1 | Plugs into TV HDMI port for power & CEC line | [AliExpress](https://www.aliexpress.com/wholesale?SearchText=HDMI+male+breakout+board) / [Amazon](https://www.amazon.com/s?k=HDMI+male+breakout) |
| **Resistor** | 2.7kΩ (1/4W Through-hole or SMD) | 1 | Current limiting & signal damping on CEC line | [Amazon](https://www.amazon.com/s?k=2.7k+ohm+resistor) |
| **Capacitor (Optional)** | 100µF to 220µF, 10V/16V Electrolytic | 1 | Buffers in-rush current on HDMI 5V rail | [Amazon](https://www.amazon.com/s?k=100uf+electrolytic+capacitor) |

---

## Wiring Diagram & Pinout Matrix

![Wiring Diagram](diagrams/wiring.svg)

### Pinout Connections

| HDMI Male Pin | Signal Name | ESP32 DevKit (WROOM) | ESP32-C3 Super Mini | Notes |
| :---: | :---: | :---: | :---: | :--- |
| **Pin 18** | +5V Power | `VIN` / `5V` | `5V` / `VIN` | Draws power from TV HDMI port |
| **Pin 17** | DDC / CEC GND | `GND` | `GND` | Common ground reference |
| **Pin 13** | CEC Line | `GPIO 4` *(via 2.7kΩ)* | `GPIO 3` *(via 2.7kΩ)* | Bidirectional 3.3V open-drain bus |

### DS3231 RTC Connections

| DS3231 Pin | ESP32 DevKit Pin | ESP32-C3 Super Mini Pin | Description |
| :---: | :---: | :---: | :--- |
| **VCC** | `3.3V` | `3.3V` | Power supply |
| **GND** | `GND` | `GND` | Ground |
| **SDA** | `GPIO 21` | `GPIO 8` | I2C Serial Data |
| **SCL** | `GPIO 22` | `GPIO 9` | I2C Serial Clock |

---

## Assembly Steps

1. **Prepare the HDMI Connector**: Solder wires to **Pin 18 (+5V)**, **Pin 17 (GND)**, and **Pin 13 (CEC)** on the HDMI male breakout board.
2. **Add 2.7kΩ Resistor**: Solder the 2.7kΩ resistor in series between HDMI Pin 13 and the selected ESP32 CEC GPIO pin.
3. **Wire the DS3231 RTC**: Connect `VCC`, `GND`, `SDA`, and `SCL` between the ESP32 and DS3231 module. Ensure the CR2032 coin battery is installed.
4. **Buffer Capacitor (Recommended)**: Solder a 100µF capacitor across `5V` and `GND` near the ESP32 input to absorb any sudden voltage dips.
5. **Enclosure**: Insulate exposed joints with heat-shrink tubing or house the project in a 3D-printed compact dongle case.

---

## Installation & Flashing

### Option A: Using PlatformIO (Recommended)

1. Install [VS Code](https://code.visualstudio.com/) and the [PlatformIO IDE Extension](https://platformio.org/).
2. Clone this repository:
   ```bash
   git clone https://github.com/<YOUR_USERNAME>/esp32-hdmi-cec-tv-autostart.git
   cd esp32-hdmi-cec-tv-autostart
   ```
3. Open the folder in PlatformIO.
4. Build and upload:
   - For **ESP32 DevKit**:
     ```bash
     pio run -e esp32dev -t upload
     ```
   - For **ESP32-C3 Super Mini**:
     ```bash
     pio run -e esp32c3 -t upload
     ```
5. Open the serial monitor (`115200 baud`):
   ```bash
   pio device monitor -b 115200
   ```

### Option B: Using Arduino IDE

1. Open Arduino IDE (v2.x or later).
2. Add ESP32 board support in **Settings** > **Additional Boards Manager URLs**:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Install **RTClib** via **Library Manager** (`Sketch` > `Include Library` > `Manage Libraries...` > Search for `RTClib` by Adafruit).
4. Select your board (e.g. *ESP32 Dev Module* or *ESP32C3 Dev Module*).
5. Open `src/main.cpp` (or rename to `.ino`), compile, and upload!

---

## Troubleshooting Guide

### 1. TV Not Responding to Wake-Up Commands
- **Enable HDMI-CEC in TV Settings**: Different brands use proprietary trade names for HDMI-CEC. Ensure it is enabled in your TV menu:
  - **Google TV / Android TV**: *Settings → Display & Sounds → HDMI-CEC → Enable CEC Control & Device Auto Power On*.
  - **LG (webOS)**: *Settings → All Settings → General → Devices → HDMI Settings → SIMPLINK (HDMI-CEC)*.
  - **Samsung (Tizen)**: *Settings → General → External Device Manager → Anynet+ (HDMI-CEC)*.
  - **Sony (Bravia)**: *Settings → Watching TV → External inputs → BRAVIA Sync settings*.
- **Adjust Startup Delay (`WAIT_SECONDS`)**: If the TV power supply takes longer to initialize its CEC receiver, increase `WAIT_SECONDS` in `include/config.h` (e.g., from `15` to `20` or `25`).
- **Physical Address Match**: If your device is plugged into HDMI 2, adjust `HDMI_PHYSICAL_ADDRESS` in `include/config.h` to `0x2000` (Port 1 = `0x1000`, Port 2 = `0x2000`, Port 3 = `0x3000`).

### 2. RTC Not Retaining Time Across Outages
- **CR2032 Coin Cell**: Verify that the CR2032 battery measures at least 2.9V - 3.2V with a multimeter.
- **ZS-042 Module Modification**: Some generic blue "ZS-042" DS3231 modules include an aggressive trickle-charging circuit designed for rechargeable LIR2032 cells. If using a standard non-rechargeable CR2032, desolder the 200Ω resistor or charging diode (marked `D1` / `R5`) to prevent overcharging.

### 3. Power Stability & HDMI Pin 18 Current Limitation
- **Specification Limit**: HDMI 1.4/2.0 specifications require TV ports to supply at least **55mA at +5V** on Pin 18. While many TVs supply 100mA–300mA, some strictly limit current.
- **Brownout Prevention**:
  - Use the **ESP32-C3 Super Mini** which consumes significantly less current (~25mA active, <15mA idle with WiFi disabled) than classic dual-core ESP32 chips.
  - Solder a **100µF - 220µF low-ESR electrolytic capacitor** across the `5V` and `GND` pins to buffer current during transmission peaks.
  - If a specific TV model cuts 5V power entirely in Standby mode, you can optionally connect the ESP32's 5V input to a nearby TV USB port (which provides 500mA) while keeping HDMI Pin 13 (CEC) and Pin 17 (GND) connected to the HDMI port.

---

# 🇸🇦 النسخة العربية

## نظرة عامة على المشروع

عند انقطاع التيار الكهربائي وعودته، تدخل معظم شاشات التلفزيون الذكية الحديثة (Google TV، Android TV، سامسونج، LG، سوني) تلقائياً في **وضع الاستعداد (Standby)** وتبقى مطفأة ولا تعمل إلا بالضغط يدوياً على زر التشغيل في جهاز التحكم (الريموت).

مشروع **ESP32 HDMI-CEC TV Autostart** هو جهاز صغير ومستقل يتم توصيله مباشرة بمنفذ HDMI في الشاشة:
1. يستمد طاقته مباشرة من منفذ الـ HDMI عبر **السن 18 (جهد 5 فولت)** و**السن 17 (الأرضي GND)**.
2. يقرأ الوقت الفعلي من موديول التوقيت **DS3231 RTC** المزود ببطارية مدمجة، ويحسب بدقة **مدة انقطاع الكهرباء**.
3. ينتظر مهلة زمنية قابلة للتعديل (`WAIT_SECONDS = 15 ثانية`) للسماح للوحة الأم للشاشة ومتحكم وضع الاستعداد بالإقلاع والجاهزية.
4. يرسل أوامر **HDMI-CEC** القياسية عبر بروتوكول التحكم بالأجهزة الإلكترونية:
   - أمر تشغيل الشاشة (`<Image View On>` - Opcode `0x04`).
   - أمر تفعيل منفذ الدخل (`<Active Source>` - Opcode `0x82`).
5. يحفظ وقت الإقلاع الحالي في الذاكرة غير المتطايرة (AT24C32 EEPROM / NVS) لحساب فترات الانقطاع القادمة بدقة.

---

## جدول المكونات والقطع المطلوبة (BOM)

| المكون | المواصفات / الوصف | الكمية | الغرض |
| :--- | :--- | :---: | :--- |
| **متحكم ESP32** | ESP32-C3 Super Mini *(موصى به)* أو ESP32 DevKit v1 | 1 | تنفيذ بروتوكول CEC ومعالجة حسابات الوقت |
| **موديول ساعة DS3231 RTC** | موديول توقيت عالي الدقة مزود بشريحة ذاكرة AT24C32 | 1 | حفظ الوقت أثناء انقطاع الكهرباء |
| **بطارية قرصية CR2032** | بطارية ليثيوم 3 فولت | 1 | تشغيل شريحة الـ RTC أثناء انقطاع التيار |
| **وصلة ذكر HDMI Breakout** | قابس HDMI ذكر مزود بنقاط لحام أو مسامير | 1 | التوصيل بمنفذ HDMI للشاشة لنقل الطاقة وإشارة CEC |
| **مقاومة كهربائية** | 2.7 كيلو أوم (2.7kΩ) | 1 | حماية المنفذ وضبط إشارة خط الـ CEC |
| **مكثف كيميائي (اختياري)** | 100 ميكروفاراد إلى 220 ميكروفاراد (10V/16V) | 1 | تثبيت جهد الـ 5 فولت ومنع هبوط الجهد عند الإقلاع |

---

## جدول التوصيلات والأسلاك

### 1. توصيل منفذ HDMI مع الـ ESP32

| سن الـ HDMI | اسم الإشارة | طرف ESP32 DevKit | طرف ESP32-C3 Super Mini | ملاحظات |
| :---: | :---: | :---: | :---: | :--- |
| **السن 18** | +5V Power | `VIN` أو `5V` | `5V` أو `VIN` | تزويد المتحكم بالطاقة من منفذ الشاشة |
| **السن 17** | Ground | `GND` | `GND` | الأرضي المشترك |
| **السن 13** | CEC Line | `GPIO 4` *(عبر مقاومة 2.7kΩ)* | `GPIO 3` *(عبر مقاومة 2.7kΩ)* | خط البيانات الأحادي لبروتوكول CEC |

### 2. توصيل موديول الساعة DS3231 مع الـ ESP32

| طرف DS3231 | طرف ESP32 DevKit | طرف ESP32-C3 Super Mini | الوصف |
| :---: | :---: | :---: | :--- |
| **VCC** | `3.3V` | `3.3V` | التغذية الكهربائية |
| **GND** | `GND` | `GND` | الخط الأرضي |
| **SDA** | `GPIO 21` | `GPIO 8` | خط بيانات I2C |
| **SCL** | `GPIO 22` | `GPIO 9` | خط نبضات I2C |

---

## خطوات التجميع والتركيب

1. **تجهيز موصل الـ HDMI**: قم بلحام ثلاثة أسلاك بالسنون **18 (+5V)**، **17 (GND)**، و**13 (CEC)** على لوحة التوصيل الذكر.
2. **تركيب مقاومة الـ CEC**: صِل المقاومة 2.7kΩ على التوالي بين السن رقم 13 وطرف الـ GPIO المحدد في كود الـ ESP32.
3. **توصيل موديول التوقيت DS3231**: صِل خطوط `VCC` و `GND` و `SDA` و `SCL` بـ ESP32، وتأكد من تركيب بطارية CR2032.
4. **تركيب مكثف التنعيم**: يُفضل لحام مكثف 100µF بين طرفي `5V` و `GND` لامتصاص أي هبوط مفاجئ في الجهد.
5. **العزل والتغليف**: اعزل نقاط اللحام باستخدام أنابيب الانكماش الحراري (Heat Shrink) أو ضع الجهاز داخل مجسم مطبوع ثلاثي الأبعاد (3D Case).

---

## خطوات البرمجة ورفع الكود

### باستخدام PlatformIO (الطريقة الموصى بها)

1. قم بتثبيت برنامج [VS Code](https://code.visualstudio.com/) وإضافة [PlatformIO IDE](https://platformio.org/).
2. استنسخ المشروع من GitHub:
   ```bash
   git clone https://github.com/<YOUR_USERNAME>/esp32-hdmi-cec-tv-autostart.git
   cd esp32-hdmi-cec-tv-autostart
   ```
3. افتح المجلد داخل PlatformIO.
4. ارفع الكود للجهاز:
   - لشريحة **ESP32 DevKit**:
     ```bash
     pio run -e esp32dev -t upload
     ```
   - لشريحة **ESP32-C3 Super Mini**:
     ```bash
     pio run -e esp32c3 -t upload
     ```
5. افتح شاشة المراقبة التسلسلية (Serial Monitor):
   ```bash
   pio device monitor -b 115200
   ```

### باستخدام Arduino IDE

1. افتح برنامج Arduino IDE (الإصدار 2 أو أحدث).
2. أضف دعم شرائح ESP32 من خلال **Settings** > **Additional Boards Manager URLs**:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. قم بتثبيت مكتبة **RTClib** من خلال مدير المكتبات (Library Manager).
4. اختر نوع اللوحة المناسب (مثل *ESP32 Dev Module* أو *ESP32C3 Dev Module*).
5. افتح ملف `src/main.cpp` واضغط على زر الرفع (**Upload**).

---

## دليل استكشاف الأخطاء وإصلاحها (Troubleshooting)

### 1. الشاشة لا تستجيب لأمر التشغيل
- **تفعيل خاصية HDMI-CEC في إعدادات الشاشة**: تختلف التسمية التجارية لخاصية HDMI-CEC باختلاف الشركة المصنعة:
  - **Google TV / Android TV**: *الإعدادات ← الشاشة والصوت ← HDMI-CEC ← تفعيل التحكم وتفعيل التشغيل التلقائي*.
  - **LG (webOS)**: *الإعدادات ← عام ← الأجهزة ← إعدادات HDMI ← SIMPLINK (HDMI-CEC)*.
  - **Samsung (Tizen)**: *الإعدادات ← عام ← إدارة الأجهزة الخارجية ← Anynet+ (HDMI-CEC)*.
  - **Sony (Bravia)**: *الإعدادات ← مدخلات خارجية ← إعدادات BRAVIA Sync*.
- **زيادة مهلة الانتظار (`WAIT_SECONDS`)**: بعض الشاشات تتأخر لوحتها الأم في الإقلاع؛ جرب زيادة `WAIT_SECONDS` في ملف `include/config.h` من 15 إلى 20 أو 25 ثانية.
- **تطابق العنوان الفيزيائي لمنفذ HDMI**: إذا قمت بتوصيل الجهاز في منفذ HDMI 2، عدل `HDMI_PHYSICAL_ADDRESS` في `config.h` إلى `0x2000`.

### 2. موديول الساعة DS3231 يفقد التوقيت
- **فحص بطارية CR2032**: تأكد من أن قياس جهد البطارية لا يقل عن 2.9 إلى 3.2 فولت باستخدام الملتيميتر.
- **تعديل دائرة الشحن في موديولات ZS-042**: تحتوي بعض موديولات DS3231 التجارية الرخيصة على دائرة شحن مصممة لبطاريات LIR2032 القابلة للشحن، والتي قد تؤدي إلى إتلاف بطاريات CR2032 العادية؛ يُنصح بإزالة المقاومة 200Ω أو الدايود (المحدد بـ `D1` أو `R5`) لتعطيل دائرة الشحن عند استخدام بطارية CR2032 عادية.

### 3. ثبات الطاقة وحدود التيار لمنفذ السن 18 في HDMI
- **الحد الأقصى للتيار في مواصفات HDMI**: تنص معايير HDMI 1.4/2.0 على توفير تيار 55 مللي أمبير كحد أدنى بجهد 5 فولت على السن رقم 18.
- **حلول الحفاظ على استقرار المتحكم**:
  - استخدم شريحة **ESP32-C3 Super Mini** لأنها تستهلك طاقة أقل بكثير (~25mA) مقارنة بشرائح ESP32 ثنائية النواة الكلاسيكية.
  - صِل **مكثف 100µF إلى 220µF** بين خط الـ 5V والـ GND لامتصاص ذروات سحب التيار أثناء البث.
  - في حال كانت الشاشة تقطع الطاقة تماماً عن منافذ HDMI في وضع الاستعداد، يمكن تغذية الـ ESP32 من منفذ USB قريب في الشاشة (5V/GND) مع إبقاء خط الـ CEC (السن 13) والأرضي (السن 17) متصلين بمنفذ الـ HDMI.

---

## License

This project is licensed under the [MIT License](LICENSE).
