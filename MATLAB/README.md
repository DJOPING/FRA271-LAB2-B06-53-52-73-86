# MATLAB scripts สำหรับ Lab 2

**วิธีใช้**
- ทุกสคริปต์ตั้ง `USE_DEMO = true` ไว้ จึงรันได้ทันทีด้วยข้อมูลจำลอง เพื่อดูหน้าตากราฟก่อนมีบอร์ด
- พอได้ข้อมูลจริง ให้ใส่ค่าในส่วน `INPUT` แล้วเปลี่ยนเป็น `USE_DEMO = false`
- รูปทั้งหมดถูกบันทึกเป็น PNG 300 dpi ลงโฟลเดอร์ `figures/` พร้อมใส่รายงาน

## ลำดับการรัน

| ลำดับ | ไฟล์ | ใช้กับ criteria |
|---|---|---|
| 0 | `lab2_config.m` | ค่าคงที่ทั้งหมด เช่น ADC, ความยาวก้าน L, step angle, pole pairs **(ค่าที่มี TODO ต้องวัดเอง)** |
| 1 | `dc_calibration.m` | Signal Conditioning: ADC → A (WCS1700) และ ADC → N (Load Cell) เสร็จแล้วให้วางค่าที่พิมพ์ออกมาลงใน config |
| 2 | `dc_kt_stall.m` | Kt (ความชันของ τ–I พร้อมค่าแยกแต่ละ trial ± SD) และ Stall Torque |
| 3 | `dc_characteristic.m` | กราฟ Speed, Current, Power และ Efficiency เทียบกับ Torque ที่หลายระดับ PWM และจุด η สูงสุดที่ 12V |
| 4 | `dc_pwm_sweep.m` | ผลของ Duty × Frequency ต่อความเร็ว กระแส และ η ให้รันแยกต่อ `MODE` เพื่อเทียบ Sign-Magnitude กับ Locked Anti-Phase |
| 5 | `dc_fft_lpf.m` | FFT ของความเร็วที่ PWM ต่าง ๆ, ออกแบบ LPF, Bode, ก่อน/หลังกรอง |
| 6 | `stepper_analysis.m` | ความถี่ → ความเร็วในแต่ละ mode เทียบทฤษฎี, หาจุด Loss Step, ผลของความเร่ง |
| 7 | `bldc_bemf_speed.m` | rpm = 60·f_e/7 จากคาบที่วัดบนสโคป, phase shift, ลำดับเฟส, รูป BEMF ideal |

## ฟังก์ชันช่วย
- `getSig`: อ่านตัวแปรที่ export จาก Data Inspector ได้ทุกรูปแบบ ทั้ง `.time/.data`, timeseries และ `[t y]`
- `steadyMean(sig, t1, t2)`: หาค่าเฉลี่ยและ SD ของช่วงที่สัญญาณนิ่ง ใช้แปลงข้อมูล 1 รอบการรันเป็น 1 จุดในตาราง
- `linfit`: linear fit พร้อมคืนค่า R²
- `saveFig`: บันทึกรูปลง `figures/`

## สิ่งที่ต้องใช้
- MATLAB R2019b ขึ้นไป (สคริปต์ใช้ `tiledlayout`, `xline`/`yline` และ local functions)
- ไม่จำเป็นต้องมี toolbox เพิ่ม
- ถ้ามี Signal Processing Toolbox:
  - `dc_fft_lpf.m` จะใช้ Butterworth กับ `filtfilt`
  - ถ้าไม่มี จะใช้ IIR อันดับ 1 แทน

## หมายเหตุ
- **ทำซ้ำอย่างน้อย 3 ครั้ง:** เป็น criteria ข้อ "การทำซ้ำ" ของทุกแลป สคริปต์รองรับ mean ± SD และ error bar
- **อยากได้ไฟล์ .mlx:** คู่มือแนะนำ Live Script ให้เปิดไฟล์ .m ใน MATLAB แล้วคลิกขวา → Open as Live Script หรือใช้ Save As `.mlx`
- **สถานะการทดสอบ:** สคริปต์ยังไม่เคยรันจริง เพราะเครื่องนี้ยังไม่มี MATLAB ผมตรวจได้แค่ว่าวงเล็บและ block สมดุลกัน ให้รันโหมด demo ทุกไฟล์ก่อนครั้งแรกเพื่อเช็ค
