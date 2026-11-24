# FRA271 Lab 2: Actuators (กลุ่ม B06)

ไฟล์ประกอบรายงาน Lab 2 วิชา FRA271 ครอบคลุม DC Motor, Stepper Motor และ BLDC Motor
บอร์ดที่ใช้คือ NUCLEO-G474RE กับชุดทดลอง MotorXploer สำหรับ DC และ Stepper ส่วน BLDC ใช้ X-NUCLEO-IHM08M1

## โครงสร้าง

| ที่อยู่ | เนื้อหา |
|---|---|
| `MotorXploer.slx`, `motorxplorer.bin` | โมเดล Simulink และเฟิร์มแวร์จาก repo ของวิชา ใช้กับ DC Motor และ Stepper |
| `MATLAB/` | สคริปต์วิเคราะห์ข้อมูลทุกการทดลอง ดูวิธีใช้ใน `MATLAB/README.md` |
| `Stepper/MotorXploer_stepper.slx` | สำเนาโมเดลที่ตั้ง EN = 0 และ Stepper Frequency = 200 Hz ไว้แล้ว |
| `Stepper/stepper_speed_data.csv` | ความเร็วเฉลี่ยจาก Encoder เทียบทฤษฎี (Full, Half และ 1/4 Step รอบละ 3 ครั้ง) |
| `BLDC/BLDC_Explorer.bin`, `BLDC/BLDC_Explorer.stwb6` | เฟิร์มแวร์และโปรเจกต์ MC Workbench จาก repo ของวิชา |
| `BLDC/Oscilloscope/` | ภาพหน้าจอ Oscilloscope (CH1 = U, CH2 = V, CH3 = W) ชื่อไฟล์บอกความเร็วและค่าที่วัด |
| `BLDC/bldc_speed_from_bemf.csv` | คาบทางไฟฟ้าและความเร็วที่คำนวณจาก rpm = 60 fe / 7 |
| `BLDC/bldc_phase_U_segments_1000rpm.csv` | ช่วง Floating และ Conducting ของเฟส U ที่ 1000 rpm |
| `Setup/` | รูปถ่ายชุดทดลอง |

## หมายเหตุ
- รายงานฉบับเต็มจะเพิ่มเป็น PDF ไว้ที่ชั้นนอกสุดเมื่อเขียนเสร็จ
- ผลการทดลอง DC Motor และ Stepper ส่วนที่เหลือจะเพิ่มเมื่อเก็บข้อมูลครบ
