#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
 تطبيق حرق السوفتوير لشريحة ESP32 - نظام تشغيل التلفزيون التلقائي HDMI-CEC
 ESP32 HDMI-CEC TV Autostart - Windows Graphical Flasher Tool
=============================================================================
"""

import sys
import os
import subprocess
import threading
import time
import tkinter as tk
from tkinter import ttk, messagebox, filedialog

try:
    import serial.tools.list_ports
except ImportError:
    serial = None


class Esp32FlasherApp:
    def __init__(self, root):
        self.root = root
        self.root.title("⚡ أداة حرق السوفتوير لشريحة ESP32 (HDMI-CEC TV Autostart)")
        self.root.geometry("680x620")
        self.root.minsize(620, 560)
        self.root.configure(bg="#0f172a")

        # Set default values
        self.is_flashing = False
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
        self.project_dir = os.path.dirname(self.script_dir)

        # Style configuration
        self.setup_styles()

        # Build UI widgets
        self.create_widgets()

        # Initial port scan
        self.refresh_ports()

    def setup_styles(self):
        self.style = ttk.Style()
        self.style.theme_use("clam")

        # General Styles
        self.style.configure("TFrame", background="#0f172a")
        self.style.configure("Card.TFrame", background="#1e293b", relief="flat")
        self.style.configure("TLabel", background="#0f172a", foreground="#f8fafc", font=("Segoe UI", 10))
        self.style.configure("Card.TLabel", background="#1e293b", foreground="#f8fafc", font=("Segoe UI", 10))
        self.style.configure("Title.TLabel", background="#0f172a", foreground="#38bdf8", font=("Segoe UI", 14, "bold"))
        self.style.configure("SubTitle.TLabel", background="#0f172a", foreground="#94a3b8", font=("Segoe UI", 9))
        self.style.configure("Header.TLabel", background="#1e293b", foreground="#38bdf8", font=("Segoe UI", 11, "bold"))
        
        # Radio button
        self.style.configure("TRadiobutton", background="#1e293b", foreground="#f8fafc", font=("Segoe UI", 10))
        self.style.map("TRadiobutton", background=[("active", "#1e293b")], foreground=[("active", "#38bdf8")])

        # Buttons
        self.style.configure("Primary.TButton", background="#0284c7", foreground="#ffffff", font=("Segoe UI", 11, "bold"), padding=8)
        self.style.map("Primary.TButton", background=[("active", "#0369a1"), ("disabled", "#475569")])

        self.style.configure("Secondary.TButton", background="#334155", foreground="#ffffff", font=("Segoe UI", 9), padding=5)
        self.style.map("Secondary.TButton", background=[("active", "#475569")])

        # Progress bar
        self.style.configure("TProgressbar", troughcolor="#334155", background="#0284c7", thickness=14)

    def create_widgets(self):
        # Header frame
        header_frame = ttk.Frame(self.root)
        header_frame.pack(fill="x", padx=20, pady=(15, 10))

        title_lbl = ttk.Label(header_frame, text="📺 نظام تشغيل التلفزيون التلقائي (ESP32 HDMI-CEC)", style="Title.TLabel")
        title_lbl.pack(anchor="e")

        sub_lbl = ttk.Label(header_frame, text="أداة سهلة وسريعة لحرق السوفتوير وتجهيز الشريحة لنظام ويندوز", style="SubTitle.TLabel")
        sub_lbl.pack(anchor="e", pady=(2, 0))

        # Main content card
        card_frame = ttk.Frame(self.root, style="Card.TFrame", padding=15)
        card_frame.pack(fill="x", padx=20, pady=5)

        # 1. Target Board Selection
        board_header = ttk.Label(card_frame, text="1. اختر نوع اللوحة (Target Board):", style="Header.TLabel")
        board_header.pack(anchor="e", pady=(0, 5))

        self.board_var = tk.StringVar(value="esp32_wroom")
        
        rb1 = ttk.Radiobutton(card_frame, text="ESP32 WROOM / DevKit v1 (الأساسية الافتراضية)", value="esp32_wroom", variable=self.board_var, command=self.on_board_change)
        rb1.pack(anchor="e", padx=10, pady=2)

        rb2 = ttk.Radiobutton(card_frame, text="ESP32-C3 Super Mini (الاختيارية الصغيرة)", value="esp32_c3", variable=self.board_var, command=self.on_board_change)
        rb2.pack(anchor="e", padx=10, pady=2)

        ttk.Separator(card_frame, orient="horizontal").pack(fill="x", pady=10)

        # 2. COM Port Selection
        port_header = ttk.Label(card_frame, text="2. منفذ التوصيل (COM Port):", style="Header.TLabel")
        port_header.pack(anchor="e", pady=(0, 5))

        port_box = ttk.Frame(card_frame, style="Card.TFrame")
        port_box.pack(fill="x", pady=2)

        self.btn_refresh = ttk.Button(port_box, text="🔄 تحديث المنافذ", style="Secondary.TButton", command=self.refresh_ports)
        self.btn_refresh.pack(side="left", padx=(0, 10))

        self.port_combo = ttk.Combobox(port_box, state="readonly", font=("Consolas", 10), width=35)
        self.port_combo.pack(side="right", fill="x", expand=True)

        ttk.Separator(card_frame, orient="horizontal").pack(fill="x", pady=10)

        # 3. Binary File Selection
        bin_header = ttk.Label(card_frame, text="3. ملف السوفتوير (.bin File):", style="Header.TLabel")
        bin_header.pack(anchor="e", pady=(0, 5))

        bin_box = ttk.Frame(card_frame, style="Card.TFrame")
        bin_box.pack(fill="x", pady=2)

        self.btn_browse = ttk.Button(bin_box, text="📂 استعراض ملف...", style="Secondary.TButton", command=self.browse_bin)
        self.btn_browse.pack(side="left", padx=(0, 10))

        self.bin_path_var = tk.StringVar(value=self.get_default_bin_path())
        self.entry_bin = ttk.Entry(bin_box, textvariable=self.bin_path_var, font=("Consolas", 9), state="readonly")
        self.entry_bin.pack(side="right", fill="x", expand=True)

        # Flash Action Button & Progress
        action_frame = ttk.Frame(self.root)
        action_frame.pack(fill="x", padx=20, pady=10)

        self.progress_bar = ttk.Progressbar(action_frame, style="TProgressbar", mode="indeterminate")
        self.progress_bar.pack(fill="x", pady=(0, 8))

        self.btn_flash = ttk.Button(action_frame, text="🔥 بدء حرق السوفتوير على الشريحة (Flash)", style="Primary.TButton", command=self.start_flash_thread)
        self.btn_flash.pack(fill="x")

        # 4. Console Log Output
        log_frame = ttk.Frame(self.root, style="Card.TFrame", padding=10)
        log_frame.pack(fill="both", expand=True, padx=20, pady=(5, 15))

        log_lbl = ttk.Label(log_frame, text="سجل العمليات (Console Output):", style="Header.TLabel")
        log_lbl.pack(anchor="e", pady=(0, 5))

        self.text_log = tk.Text(log_frame, bg="#020617", fg="#38bdf8", insertbackground="#38bdf8", font=("Consolas", 9), wrap="word", height=8)
        self.text_log.pack(fill="both", expand=True, side="left")

        scrollbar = ttk.Scrollbar(log_frame, orient="vertical", command=self.text_log.yview)
        scrollbar.pack(side="right", fill="y")
        self.text_log.configure(yscrollcommand=scrollbar.set)

        self.log("✅ الأداة جاهزة. قم بتوصيل شريحة ESP32 بمنفذ USB ثم اضغط 'بدء حرق السوفتوير'.")

    def log(self, message):
        self.text_log.insert(tk.END, message + "\n")
        self.text_log.see(tk.END)

    def on_board_change(self):
        self.bin_path_var.set(self.get_default_bin_path())
        self.log(f"📌 تم تغيير اللوحة إلى: {'ESP32 WROOM (الأساسية)' if self.board_var.get() == 'esp32_wroom' else 'ESP32-C3 Super Mini'}")

    def get_default_bin_path(self):
        board = self.board_var.get()
        # Look for precompiled merged binary in common paths
        candidate_paths = []
        
        if board == "esp32_wroom":
            candidate_paths = [
                os.path.join(self.project_dir, "release_binaries", "esp32-wroom-complete-flash-offset-0x0.bin"),
                os.path.join(self.project_dir, ".pio", "build", "esp32dev", "firmware.bin"),
                os.path.join(self.script_dir, "esp32-wroom-firmware.bin"),
                os.path.join(self.project_dir, "esp32-wroom-firmware.bin")
            ]
        else:
            candidate_paths = [
                os.path.join(self.project_dir, "release_binaries", "esp32-c3-complete-flash-offset-0x0.bin"),
                os.path.join(self.project_dir, ".pio", "build", "esp32c3", "firmware.bin"),
                os.path.join(self.script_dir, "esp32-c3-firmware.bin"),
                os.path.join(self.project_dir, "esp32-c3-firmware.bin")
            ]

        for path in candidate_paths:
            if os.path.exists(path):
                return path

        return candidate_paths[0]  # Fallback to default expected path

    def browse_bin(self):
        chosen = filedialog.askopenfilename(
            title="اختر ملف السوفتوير (.bin)",
            filetypes=[("ESP32 Firmware (*.bin)", "*.bin"), ("All Files (*.*)", "*.*")]
        )
        if chosen:
            self.bin_path_var.set(chosen)
            self.log(f"📂 تم اختيار الملف: {chosen}")

    def refresh_ports(self):
        self.log("🔍 جاري البحث عن منافذ COM المتصلة...")
        ports_list = []
        
        if serial:
            ports = serial.tools.list_ports.comports()
            for p in ports:
                desc = f"{p.device} - {p.description}"
                ports_list.append((p.device, desc))
        else:
            # Fallback for Windows without pyserial
            if sys.platform == "win32":
                for i in range(1, 30):
                    p = f"COM{i}"
                    ports_list.append((p, p))

        if ports_list:
            display_values = [p[1] for p in ports_list]
            self.port_combo["values"] = display_values
            self.port_combo.current(0)
            self.log(f"✅ تم العثور على {len(ports_list)} منفذ: {', '.join([p[0] for p in ports_list])}")
        else:
            self.port_combo["values"] = ["لم يتم العثور على أي شريحة متصلة!"]
            self.port_combo.current(0)
            self.log("⚠️ لم يتم العثور على أي منفذ COM. تأكد من توصيل كابل USB وتثبيت تعريف CH340 / CP2102.")

    def get_selected_port(self):
        selected_text = self.port_combo.get()
        if not selected_text or "لم يتم" in selected_text:
            return None
        # Extract COMx
        port_name = selected_text.split(" ")[0].strip()
        return port_name

    def start_flash_thread(self):
        if self.is_flashing:
            return

        port = self.get_selected_port()
        if not port:
            messagebox.showerror("خطأ في المنفذ", "الرجاء اختيار منفذ COM صحيح للوحة ESP32!")
            return

        bin_file = self.bin_path_var.get()
        if not os.path.exists(bin_file):
            # Try building it automatically via PlatformIO if available
            confirm = messagebox.askyesno(
                "الملف غير موجود",
                f"ملف السوفتوير غير موجود في المسار المحدد:\n{bin_file}\n\nهل ترغب في محاولة تجميع الكود محلياً باستخدام PlatformIO الآن؟"
            )
            if confirm:
                threading.Thread(target=self.build_and_flash, args=(port,), daemon=True).start()
                return
            else:
                return

        threading.Thread(target=self.flash_firmware, args=(port, bin_file), daemon=True).start()

    def build_and_flash(self, port):
        self.set_flashing_state(True)
        board = self.board_var.get()
        env_name = "esp32dev" if board == "esp32_wroom" else "esp32c3"

        self.log(f"⚙️ جاري تجميع السوفتوير للبيئة [{env_name}] عبر PlatformIO...")
        try:
            cmd = ["pio", "run", "-e", env_name, "-d", self.project_dir]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)

            for line in iter(process.stdout.readline, ""):
                if line:
                    self.log(line.strip())

            process.wait()
            if process.returncode == 0:
                self.log("✅ تم تجميع السوفتوير بنجاح!")
                bin_path = os.path.join(self.project_dir, ".pio", "build", env_name, "firmware.bin")
                self.bin_path_var.set(bin_path)
                self.set_flashing_state(False)
                # Continue with flash
                self.flash_firmware(port, bin_path)
            else:
                self.log("❌ فشل تجميع السوفتوير. تأكد من تثبيت PlatformIO وتوفر الملفات.")
                self.set_flashing_state(False)
        except Exception as e:
            self.log(f"❌ خطأ أثناء التجميع: {e}")
            self.set_flashing_state(False)

    def flash_firmware(self, port, bin_file):
        self.set_flashing_state(True)
        board = self.board_var.get()
        chip = "esp32" if board == "esp32_wroom" else "esp32c3"

        # Determine flash offset: 0x0 for complete/merged files, 0x10000 for app firmware
        offset = "0x0" if "complete" in bin_file or "offset-0x0" in bin_file else "0x10000"

        self.log(f"\n==================================================")
        self.log(f"🚀 بدء عملية الحرق:")
        self.log(f"   اللوحة: {chip}")
        self.log(f"   المنفذ: {port}")
        self.log(f"   العنوان: {offset}")
        self.log(f"   الملف: {os.path.basename(bin_file)}")
        self.log(f"==================================================")
        self.log("⏳ جاري الاتصال بالشريحة ومسح الذاكرة... (إذا توقف، اضغط زر BOOT في الشريحة)")

        try:
            # First try using python -m esptool
            cmd = [
                sys.executable, "-m", "esptool",
                "--chip", chip,
                "--port", port,
                "--baud", "460800",
                "write_flash",
                "-z",
                offset, bin_file
            ]

            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)

            for line in iter(process.stdout.readline, ""):
                if line:
                    clean_line = line.strip()
                    self.log(clean_line)

            process.wait()

            if process.returncode == 0:
                self.log("\n🎉 تم حرق السوفتوير بنجاح 100%! الشريحة جاهزة الآن للاستخدام.")
                messagebox.showinfo("تم بنجاح!", "🎉 تمت عملية البرمجة وحرق السوفتوير بنجاح 100%!\nيمكنك الآن فصل الشريحة وتركيبها في منفذ HDMI بالتلفزيون.")
            else:
                # Retry with slower baud rate 115200
                self.log("\n⚠️ فشلت المحاولة الأولى. جاري إعادة المحاولة بسرعة نقل أبطأ (115200)...")
                cmd[6] = "115200"
                retry_proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
                for line in iter(retry_proc.stdout.readline, ""):
                    if line:
                        self.log(line.strip())
                retry_proc.wait()

                if retry_proc.returncode == 0:
                    self.log("\n🎉 تم حرق السوفتوير بنجاح 100%!")
                    messagebox.showinfo("تم بنجاح!", "🎉 تمت عملية البرمجة وحرق السوفتوير بنجاح!")
                else:
                    self.log("\n❌ فشل الاتصال بالشريحة. تأكد من:")
                    self.log("   1. الضغط باستمرار على زر BOOT في الشريحة أثناء بدء الحرق.")
                    self.log("   2. تثبيت تعريف المنفذ CH340 أو CP2102.")
                    self.log("   3. التأكد من أن كابل الـ USB يدعم نقل البيانات وليس للشحن فقط.")
                    messagebox.showerror("فشل الحرق", "تعذر حرق السوفتوير على الشريحة. راجع سجل العمليات للتفاصيل.")

        except Exception as ex:
            self.log(f"❌ حدث خطأ غير متوقع: {ex}")
            messagebox.showerror("خطأ", f"حدث خطأ أثناء التنفيذ:\n{ex}")

        finally:
            self.set_flashing_state(False)

    def set_flashing_state(self, flashing):
        self.is_flashing = flashing
        if flashing:
            self.btn_flash.configure(state="disabled", text="⏳ جاري الحرق، يرجى الانتظار...")
            self.btn_refresh.configure(state="disabled")
            self.btn_browse.configure(state="disabled")
            self.progress_bar.start(10)
        else:
            self.btn_flash.configure(state="normal", text="🔥 بدء حرق السوفتوير على الشريحة (Flash)")
            self.btn_refresh.configure(state="normal")
            self.btn_browse.configure(state="normal")
            self.progress_bar.stop()


def main():
    root = tk.Tk()
    app = Esp32FlasherApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
