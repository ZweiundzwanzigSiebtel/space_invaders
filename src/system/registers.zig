pub fn Register(comptime R: type) type {
    return RegisterRW(R, R);
}

pub fn RegisterRW(comptime Read: type, comptime Write: type) type {
    return struct {
        raw_ptr: *volatile u32,

        const Self = @This();

        pub fn init(address: usize) Self {
            return Self{ .raw_ptr = @intToPtr(*volatile u32, address) };
        }

        pub fn initRange(address: usize, comptime dim_increment: usize, comptime num_registers: usize) [num_registers]Self {
            var registers: [num_registers]Self = undefined;
            var i: usize = 0;
            while (i < num_registers) : (i += 1) {
                registers[i] = Self.init(address + (i * dim_increment));
            }
            return registers;
        }

        pub fn read(self: Self) Read {
            return @bitCast(Read, self.raw_ptr.*);
        }

        pub fn write(self: Self, value: Write) void {
            // Forcing the alignment is a workaround for stores through
            // volatile pointers generating multiple loads and stores.
            // This is necessary for LLVM to generate code that can successfully
            // modify MMIO registers that only allow word-sized stores.
            // https://github.com/ziglang/zig/issues/8981#issuecomment-854911077
            const aligned: Write align(4) = value;
            self.raw_ptr.* = @ptrCast(*const u32, &aligned).*;
        }

        pub fn modify(self: Self, new_value: anytype) void {
            if (Read != Write) {
                @compileError("Can't modify because read and write types for this register aren't the same.");
            }
            var old_value = self.read();
            const info = @typeInfo(@TypeOf(new_value));
            inline for (info.Struct.fields) |field| {
                @field(old_value, field.name) = @field(new_value, field.name);
            }
            self.write(old_value);
        }

        pub fn read_raw(self: Self) u32 {
            return self.raw_ptr.*;
        }

        pub fn write_raw(self: Self, value: u32) void {
            self.raw_ptr.* = value;
        }

        pub fn default_read_value(_: Self) Read {
            return Read{};
        }

        pub fn default_write_value(_: Self) Write {
            return Write{};
        }
    };
}

pub const device_name = "STM32F401";
pub const device_revision = "1.1";
pub const device_description = "STM32F401";

pub const cpu = struct {
    pub const name = "CM4";
    pub const revision = "r1p0";
    pub const endian = "little";
    pub const mpu_present = false;
    pub const fpu_present = false;
    pub const vendor_systick_config = false;
    pub const nvic_prio_bits = 3;
};

/// ADC common registers
pub const ADC_Common = struct {
    const base_address = 0x40012300;
    /// CSR
    const CSR_val = packed struct {
        /// AWD1 [0:0]
        /// Analog watchdog flag of ADC
        AWD1: u1 = 0,
        /// EOC1 [1:1]
        /// End of conversion of ADC 1
        EOC1: u1 = 0,
        /// JEOC1 [2:2]
        /// Injected channel end of conversion of
        JEOC1: u1 = 0,
        /// JSTRT1 [3:3]
        /// Injected channel Start flag of ADC
        JSTRT1: u1 = 0,
        /// STRT1 [4:4]
        /// Regular channel Start flag of ADC
        STRT1: u1 = 0,
        /// OVR1 [5:5]
        /// Overrun flag of ADC 1
        OVR1: u1 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// AWD2 [8:8]
        /// Analog watchdog flag of ADC
        AWD2: u1 = 0,
        /// EOC2 [9:9]
        /// End of conversion of ADC 2
        EOC2: u1 = 0,
        /// JEOC2 [10:10]
        /// Injected channel end of conversion of
        JEOC2: u1 = 0,
        /// JSTRT2 [11:11]
        /// Injected channel Start flag of ADC
        JSTRT2: u1 = 0,
        /// STRT2 [12:12]
        /// Regular channel Start flag of ADC
        STRT2: u1 = 0,
        /// OVR2 [13:13]
        /// Overrun flag of ADC 2
        OVR2: u1 = 0,
        /// unused [14:15]
        _unused14: u2 = 0,
        /// AWD3 [16:16]
        /// Analog watchdog flag of ADC
        AWD3: u1 = 0,
        /// EOC3 [17:17]
        /// End of conversion of ADC 3
        EOC3: u1 = 0,
        /// JEOC3 [18:18]
        /// Injected channel end of conversion of
        JEOC3: u1 = 0,
        /// JSTRT3 [19:19]
        /// Injected channel Start flag of ADC
        JSTRT3: u1 = 0,
        /// STRT3 [20:20]
        /// Regular channel Start flag of ADC
        STRT3: u1 = 0,
        /// OVR3 [21:21]
        /// Overrun flag of ADC3
        OVR3: u1 = 0,
        /// unused [22:31]
        _unused22: u2 = 0,
        _unused24: u8 = 0,
    };
    /// ADC Common status register
    pub const CSR = Register(CSR_val).init(base_address + 0x0);

    /// CCR
    const CCR_val = packed struct {
        /// unused [0:7]
        _unused0: u8 = 0,
        /// DELAY [8:11]
        /// Delay between 2 sampling
        DELAY: u4 = 0,
        /// unused [12:12]
        _unused12: u1 = 0,
        /// DDS [13:13]
        /// DMA disable selection for multi-ADC
        DDS: u1 = 0,
        /// DMA [14:15]
        /// Direct memory access mode for multi ADC
        DMA: u2 = 0,
        /// ADCPRE [16:17]
        /// ADC prescaler
        ADCPRE: u2 = 0,
        /// unused [18:21]
        _unused18: u4 = 0,
        /// VBATE [22:22]
        /// VBAT enable
        VBATE: u1 = 0,
        /// TSVREFE [23:23]
        /// Temperature sensor and VREFINT
        TSVREFE: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// ADC common control register
    pub const CCR = Register(CCR_val).init(base_address + 0x4);
};

/// Analog-to-digital converter
pub const ADC1 = struct {
    const base_address = 0x40012000;
    /// SR
    const SR_val = packed struct {
        /// AWD [0:0]
        /// Analog watchdog flag
        AWD: u1 = 0,
        /// EOC [1:1]
        /// Regular channel end of
        EOC: u1 = 0,
        /// JEOC [2:2]
        /// Injected channel end of
        JEOC: u1 = 0,
        /// JSTRT [3:3]
        /// Injected channel start
        JSTRT: u1 = 0,
        /// STRT [4:4]
        /// Regular channel start flag
        STRT: u1 = 0,
        /// OVR [5:5]
        /// Overrun
        OVR: u1 = 0,
        /// unused [6:31]
        _unused6: u2 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x0);

    /// CR1
    const CR1_val = packed struct {
        /// AWDCH [0:4]
        /// Analog watchdog channel select
        AWDCH: u5 = 0,
        /// EOCIE [5:5]
        /// Interrupt enable for EOC
        EOCIE: u1 = 0,
        /// AWDIE [6:6]
        /// Analog watchdog interrupt
        AWDIE: u1 = 0,
        /// JEOCIE [7:7]
        /// Interrupt enable for injected
        JEOCIE: u1 = 0,
        /// SCAN [8:8]
        /// Scan mode
        SCAN: u1 = 0,
        /// AWDSGL [9:9]
        /// Enable the watchdog on a single channel
        AWDSGL: u1 = 0,
        /// JAUTO [10:10]
        /// Automatic injected group
        JAUTO: u1 = 0,
        /// DISCEN [11:11]
        /// Discontinuous mode on regular
        DISCEN: u1 = 0,
        /// JDISCEN [12:12]
        /// Discontinuous mode on injected
        JDISCEN: u1 = 0,
        /// DISCNUM [13:15]
        /// Discontinuous mode channel
        DISCNUM: u3 = 0,
        /// unused [16:21]
        _unused16: u6 = 0,
        /// JAWDEN [22:22]
        /// Analog watchdog enable on injected
        JAWDEN: u1 = 0,
        /// AWDEN [23:23]
        /// Analog watchdog enable on regular
        AWDEN: u1 = 0,
        /// RES [24:25]
        /// Resolution
        RES: u2 = 0,
        /// OVRIE [26:26]
        /// Overrun interrupt enable
        OVRIE: u1 = 0,
        /// unused [27:31]
        _unused27: u5 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x4);

    /// CR2
    const CR2_val = packed struct {
        /// ADON [0:0]
        /// A/D Converter ON / OFF
        ADON: u1 = 0,
        /// CONT [1:1]
        /// Continuous conversion
        CONT: u1 = 0,
        /// unused [2:7]
        _unused2: u6 = 0,
        /// DMA [8:8]
        /// Direct memory access mode (for single
        DMA: u1 = 0,
        /// DDS [9:9]
        /// DMA disable selection (for single ADC
        DDS: u1 = 0,
        /// EOCS [10:10]
        /// End of conversion
        EOCS: u1 = 0,
        /// ALIGN [11:11]
        /// Data alignment
        ALIGN: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// JEXTSEL [16:19]
        /// External event select for injected
        JEXTSEL: u4 = 0,
        /// JEXTEN [20:21]
        /// External trigger enable for injected
        JEXTEN: u2 = 0,
        /// JSWSTART [22:22]
        /// Start conversion of injected
        JSWSTART: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// EXTSEL [24:27]
        /// External event select for regular
        EXTSEL: u4 = 0,
        /// EXTEN [28:29]
        /// External trigger enable for regular
        EXTEN: u2 = 0,
        /// SWSTART [30:30]
        /// Start conversion of regular
        SWSTART: u1 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x8);

    /// SMPR1
    const SMPR1_val = packed struct {
        /// SMPx_x [0:31]
        /// Sample time bits
        SMPx_x: u32 = 0,
    };
    /// sample time register 1
    pub const SMPR1 = Register(SMPR1_val).init(base_address + 0xc);

    /// SMPR2
    const SMPR2_val = packed struct {
        /// SMPx_x [0:31]
        /// Sample time bits
        SMPx_x: u32 = 0,
    };
    /// sample time register 2
    pub const SMPR2 = Register(SMPR2_val).init(base_address + 0x10);

    /// JOFR1
    const JOFR1_val = packed struct {
        /// JOFFSET1 [0:11]
        /// Data offset for injected channel
        JOFFSET1: u12 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected channel data offset register
    pub const JOFR1 = Register(JOFR1_val).init(base_address + 0x14);

    /// JOFR2
    const JOFR2_val = packed struct {
        /// JOFFSET2 [0:11]
        /// Data offset for injected channel
        JOFFSET2: u12 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected channel data offset register
    pub const JOFR2 = Register(JOFR2_val).init(base_address + 0x18);

    /// JOFR3
    const JOFR3_val = packed struct {
        /// JOFFSET3 [0:11]
        /// Data offset for injected channel
        JOFFSET3: u12 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected channel data offset register
    pub const JOFR3 = Register(JOFR3_val).init(base_address + 0x1c);

    /// JOFR4
    const JOFR4_val = packed struct {
        /// JOFFSET4 [0:11]
        /// Data offset for injected channel
        JOFFSET4: u12 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected channel data offset register
    pub const JOFR4 = Register(JOFR4_val).init(base_address + 0x20);

    /// HTR
    const HTR_val = packed struct {
        /// HT [0:11]
        /// Analog watchdog higher
        HT: u12 = 4095,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// watchdog higher threshold
    pub const HTR = Register(HTR_val).init(base_address + 0x24);

    /// LTR
    const LTR_val = packed struct {
        /// LT [0:11]
        /// Analog watchdog lower
        LT: u12 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// watchdog lower threshold
    pub const LTR = Register(LTR_val).init(base_address + 0x28);

    /// SQR1
    const SQR1_val = packed struct {
        /// SQ13 [0:4]
        /// 13th conversion in regular
        SQ13: u5 = 0,
        /// SQ14 [5:9]
        /// 14th conversion in regular
        SQ14: u5 = 0,
        /// SQ15 [10:14]
        /// 15th conversion in regular
        SQ15: u5 = 0,
        /// SQ16 [15:19]
        /// 16th conversion in regular
        SQ16: u5 = 0,
        /// L [20:23]
        /// Regular channel sequence
        L: u4 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// regular sequence register 1
    pub const SQR1 = Register(SQR1_val).init(base_address + 0x2c);

    /// SQR2
    const SQR2_val = packed struct {
        /// SQ7 [0:4]
        /// 7th conversion in regular
        SQ7: u5 = 0,
        /// SQ8 [5:9]
        /// 8th conversion in regular
        SQ8: u5 = 0,
        /// SQ9 [10:14]
        /// 9th conversion in regular
        SQ9: u5 = 0,
        /// SQ10 [15:19]
        /// 10th conversion in regular
        SQ10: u5 = 0,
        /// SQ11 [20:24]
        /// 11th conversion in regular
        SQ11: u5 = 0,
        /// SQ12 [25:29]
        /// 12th conversion in regular
        SQ12: u5 = 0,
        /// unused [30:31]
        _unused30: u2 = 0,
    };
    /// regular sequence register 2
    pub const SQR2 = Register(SQR2_val).init(base_address + 0x30);

    /// SQR3
    const SQR3_val = packed struct {
        /// SQ1 [0:4]
        /// 1st conversion in regular
        SQ1: u5 = 0,
        /// SQ2 [5:9]
        /// 2nd conversion in regular
        SQ2: u5 = 0,
        /// SQ3 [10:14]
        /// 3rd conversion in regular
        SQ3: u5 = 0,
        /// SQ4 [15:19]
        /// 4th conversion in regular
        SQ4: u5 = 0,
        /// SQ5 [20:24]
        /// 5th conversion in regular
        SQ5: u5 = 0,
        /// SQ6 [25:29]
        /// 6th conversion in regular
        SQ6: u5 = 0,
        /// unused [30:31]
        _unused30: u2 = 0,
    };
    /// regular sequence register 3
    pub const SQR3 = Register(SQR3_val).init(base_address + 0x34);

    /// JSQR
    const JSQR_val = packed struct {
        /// JSQ1 [0:4]
        /// 1st conversion in injected
        JSQ1: u5 = 0,
        /// JSQ2 [5:9]
        /// 2nd conversion in injected
        JSQ2: u5 = 0,
        /// JSQ3 [10:14]
        /// 3rd conversion in injected
        JSQ3: u5 = 0,
        /// JSQ4 [15:19]
        /// 4th conversion in injected
        JSQ4: u5 = 0,
        /// JL [20:21]
        /// Injected sequence length
        JL: u2 = 0,
        /// unused [22:31]
        _unused22: u2 = 0,
        _unused24: u8 = 0,
    };
    /// injected sequence register
    pub const JSQR = Register(JSQR_val).init(base_address + 0x38);

    /// JDR1
    const JDR1_val = packed struct {
        /// JDATA [0:15]
        /// Injected data
        JDATA: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected data register x
    pub const JDR1 = Register(JDR1_val).init(base_address + 0x3c);

    /// JDR2
    const JDR2_val = packed struct {
        /// JDATA [0:15]
        /// Injected data
        JDATA: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected data register x
    pub const JDR2 = Register(JDR2_val).init(base_address + 0x40);

    /// JDR3
    const JDR3_val = packed struct {
        /// JDATA [0:15]
        /// Injected data
        JDATA: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected data register x
    pub const JDR3 = Register(JDR3_val).init(base_address + 0x44);

    /// JDR4
    const JDR4_val = packed struct {
        /// JDATA [0:15]
        /// Injected data
        JDATA: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// injected data register x
    pub const JDR4 = Register(JDR4_val).init(base_address + 0x48);

    /// DR
    const DR_val = packed struct {
        /// DATA [0:15]
        /// Regular data
        DATA: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// regular data register
    pub const DR = Register(DR_val).init(base_address + 0x4c);
};

/// Cryptographic processor
pub const CRC = struct {
    const base_address = 0x40023000;
    /// DR
    const DR_val = packed struct {
        /// DR [0:31]
        /// Data Register
        DR: u32 = 4294967295,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x0);

    /// IDR
    const IDR_val = packed struct {
        /// IDR [0:7]
        /// Independent Data register
        IDR: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Independent Data register
    pub const IDR = Register(IDR_val).init(base_address + 0x4);

    /// CR
    const CR_val = packed struct {
        /// CR [0:0]
        /// Control regidter
        CR: u1 = 0,
        /// unused [1:31]
        _unused1: u7 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register
    pub const CR = Register(CR_val).init(base_address + 0x8);
};

/// Debug support
pub const DBG = struct {
    const base_address = 0xe0042000;
    /// DBGMCU_IDCODE
    const DBGMCU_IDCODE_val = packed struct {
        /// DEV_ID [0:11]
        /// DEV_ID
        DEV_ID: u12 = 1041,
        /// unused [12:15]
        _unused12: u4 = 6,
        /// REV_ID [16:31]
        /// REV_ID
        REV_ID: u16 = 4096,
    };
    /// IDCODE
    pub const DBGMCU_IDCODE = Register(DBGMCU_IDCODE_val).init(base_address + 0x0);

    /// DBGMCU_CR
    const DBGMCU_CR_val = packed struct {
        /// DBG_SLEEP [0:0]
        /// DBG_SLEEP
        DBG_SLEEP: u1 = 0,
        /// DBG_STOP [1:1]
        /// DBG_STOP
        DBG_STOP: u1 = 0,
        /// DBG_STANDBY [2:2]
        /// DBG_STANDBY
        DBG_STANDBY: u1 = 0,
        /// unused [3:4]
        _unused3: u2 = 0,
        /// TRACE_IOEN [5:5]
        /// TRACE_IOEN
        TRACE_IOEN: u1 = 0,
        /// TRACE_MODE [6:7]
        /// TRACE_MODE
        TRACE_MODE: u2 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control Register
    pub const DBGMCU_CR = Register(DBGMCU_CR_val).init(base_address + 0x4);

    /// DBGMCU_APB1_FZ
    const DBGMCU_APB1_FZ_val = packed struct {
        /// DBG_TIM2_STOP [0:0]
        /// DBG_TIM2_STOP
        DBG_TIM2_STOP: u1 = 0,
        /// DBG_TIM3_STOP [1:1]
        /// DBG_TIM3 _STOP
        DBG_TIM3_STOP: u1 = 0,
        /// DBG_TIM4_STOP [2:2]
        /// DBG_TIM4_STOP
        DBG_TIM4_STOP: u1 = 0,
        /// DBG_TIM5_STOP [3:3]
        /// DBG_TIM5_STOP
        DBG_TIM5_STOP: u1 = 0,
        /// unused [4:9]
        _unused4: u4 = 0,
        _unused8: u2 = 0,
        /// DBG_RTC_Stop [10:10]
        /// RTC stopped when Core is
        DBG_RTC_Stop: u1 = 0,
        /// DBG_WWDG_STOP [11:11]
        /// DBG_WWDG_STOP
        DBG_WWDG_STOP: u1 = 0,
        /// DBG_IWDEG_STOP [12:12]
        /// DBG_IWDEG_STOP
        DBG_IWDEG_STOP: u1 = 0,
        /// unused [13:20]
        _unused13: u3 = 0,
        _unused16: u5 = 0,
        /// DBG_I2C1_SMBUS_TIMEOUT [21:21]
        /// DBG_J2C1_SMBUS_TIMEOUT
        DBG_I2C1_SMBUS_TIMEOUT: u1 = 0,
        /// DBG_I2C2_SMBUS_TIMEOUT [22:22]
        /// DBG_J2C2_SMBUS_TIMEOUT
        DBG_I2C2_SMBUS_TIMEOUT: u1 = 0,
        /// DBG_I2C3SMBUS_TIMEOUT [23:23]
        /// DBG_J2C3SMBUS_TIMEOUT
        DBG_I2C3SMBUS_TIMEOUT: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// Debug MCU APB1 Freeze registe
    pub const DBGMCU_APB1_FZ = Register(DBGMCU_APB1_FZ_val).init(base_address + 0x8);

    /// DBGMCU_APB2_FZ
    const DBGMCU_APB2_FZ_val = packed struct {
        /// DBG_TIM1_STOP [0:0]
        /// TIM1 counter stopped when core is
        DBG_TIM1_STOP: u1 = 0,
        /// unused [1:15]
        _unused1: u7 = 0,
        _unused8: u8 = 0,
        /// DBG_TIM9_STOP [16:16]
        /// TIM9 counter stopped when core is
        DBG_TIM9_STOP: u1 = 0,
        /// DBG_TIM10_STOP [17:17]
        /// TIM10 counter stopped when core is
        DBG_TIM10_STOP: u1 = 0,
        /// DBG_TIM11_STOP [18:18]
        /// TIM11 counter stopped when core is
        DBG_TIM11_STOP: u1 = 0,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// Debug MCU APB2 Freeze registe
    pub const DBGMCU_APB2_FZ = Register(DBGMCU_APB2_FZ_val).init(base_address + 0xc);
};

/// External interrupt/event
pub const EXTI = struct {
    const base_address = 0x40013c00;
    /// IMR
    const IMR_val = packed struct {
        /// MR0 [0:0]
        /// Interrupt Mask on line 0
        MR0: u1 = 0,
        /// MR1 [1:1]
        /// Interrupt Mask on line 1
        MR1: u1 = 0,
        /// MR2 [2:2]
        /// Interrupt Mask on line 2
        MR2: u1 = 0,
        /// MR3 [3:3]
        /// Interrupt Mask on line 3
        MR3: u1 = 0,
        /// MR4 [4:4]
        /// Interrupt Mask on line 4
        MR4: u1 = 0,
        /// MR5 [5:5]
        /// Interrupt Mask on line 5
        MR5: u1 = 0,
        /// MR6 [6:6]
        /// Interrupt Mask on line 6
        MR6: u1 = 0,
        /// MR7 [7:7]
        /// Interrupt Mask on line 7
        MR7: u1 = 0,
        /// MR8 [8:8]
        /// Interrupt Mask on line 8
        MR8: u1 = 0,
        /// MR9 [9:9]
        /// Interrupt Mask on line 9
        MR9: u1 = 0,
        /// MR10 [10:10]
        /// Interrupt Mask on line 10
        MR10: u1 = 0,
        /// MR11 [11:11]
        /// Interrupt Mask on line 11
        MR11: u1 = 0,
        /// MR12 [12:12]
        /// Interrupt Mask on line 12
        MR12: u1 = 0,
        /// MR13 [13:13]
        /// Interrupt Mask on line 13
        MR13: u1 = 0,
        /// MR14 [14:14]
        /// Interrupt Mask on line 14
        MR14: u1 = 0,
        /// MR15 [15:15]
        /// Interrupt Mask on line 15
        MR15: u1 = 0,
        /// MR16 [16:16]
        /// Interrupt Mask on line 16
        MR16: u1 = 0,
        /// MR17 [17:17]
        /// Interrupt Mask on line 17
        MR17: u1 = 0,
        /// MR18 [18:18]
        /// Interrupt Mask on line 18
        MR18: u1 = 0,
        /// MR19 [19:19]
        /// Interrupt Mask on line 19
        MR19: u1 = 0,
        /// MR20 [20:20]
        /// Interrupt Mask on line 20
        MR20: u1 = 0,
        /// MR21 [21:21]
        /// Interrupt Mask on line 21
        MR21: u1 = 0,
        /// MR22 [22:22]
        /// Interrupt Mask on line 22
        MR22: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// Interrupt mask register
    pub const IMR = Register(IMR_val).init(base_address + 0x0);

    /// EMR
    const EMR_val = packed struct {
        /// MR0 [0:0]
        /// Event Mask on line 0
        MR0: u1 = 0,
        /// MR1 [1:1]
        /// Event Mask on line 1
        MR1: u1 = 0,
        /// MR2 [2:2]
        /// Event Mask on line 2
        MR2: u1 = 0,
        /// MR3 [3:3]
        /// Event Mask on line 3
        MR3: u1 = 0,
        /// MR4 [4:4]
        /// Event Mask on line 4
        MR4: u1 = 0,
        /// MR5 [5:5]
        /// Event Mask on line 5
        MR5: u1 = 0,
        /// MR6 [6:6]
        /// Event Mask on line 6
        MR6: u1 = 0,
        /// MR7 [7:7]
        /// Event Mask on line 7
        MR7: u1 = 0,
        /// MR8 [8:8]
        /// Event Mask on line 8
        MR8: u1 = 0,
        /// MR9 [9:9]
        /// Event Mask on line 9
        MR9: u1 = 0,
        /// MR10 [10:10]
        /// Event Mask on line 10
        MR10: u1 = 0,
        /// MR11 [11:11]
        /// Event Mask on line 11
        MR11: u1 = 0,
        /// MR12 [12:12]
        /// Event Mask on line 12
        MR12: u1 = 0,
        /// MR13 [13:13]
        /// Event Mask on line 13
        MR13: u1 = 0,
        /// MR14 [14:14]
        /// Event Mask on line 14
        MR14: u1 = 0,
        /// MR15 [15:15]
        /// Event Mask on line 15
        MR15: u1 = 0,
        /// MR16 [16:16]
        /// Event Mask on line 16
        MR16: u1 = 0,
        /// MR17 [17:17]
        /// Event Mask on line 17
        MR17: u1 = 0,
        /// MR18 [18:18]
        /// Event Mask on line 18
        MR18: u1 = 0,
        /// MR19 [19:19]
        /// Event Mask on line 19
        MR19: u1 = 0,
        /// MR20 [20:20]
        /// Event Mask on line 20
        MR20: u1 = 0,
        /// MR21 [21:21]
        /// Event Mask on line 21
        MR21: u1 = 0,
        /// MR22 [22:22]
        /// Event Mask on line 22
        MR22: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// Event mask register (EXTI_EMR)
    pub const EMR = Register(EMR_val).init(base_address + 0x4);

    /// RTSR
    const RTSR_val = packed struct {
        /// TR0 [0:0]
        /// Rising trigger event configuration of
        TR0: u1 = 0,
        /// TR1 [1:1]
        /// Rising trigger event configuration of
        TR1: u1 = 0,
        /// TR2 [2:2]
        /// Rising trigger event configuration of
        TR2: u1 = 0,
        /// TR3 [3:3]
        /// Rising trigger event configuration of
        TR3: u1 = 0,
        /// TR4 [4:4]
        /// Rising trigger event configuration of
        TR4: u1 = 0,
        /// TR5 [5:5]
        /// Rising trigger event configuration of
        TR5: u1 = 0,
        /// TR6 [6:6]
        /// Rising trigger event configuration of
        TR6: u1 = 0,
        /// TR7 [7:7]
        /// Rising trigger event configuration of
        TR7: u1 = 0,
        /// TR8 [8:8]
        /// Rising trigger event configuration of
        TR8: u1 = 0,
        /// TR9 [9:9]
        /// Rising trigger event configuration of
        TR9: u1 = 0,
        /// TR10 [10:10]
        /// Rising trigger event configuration of
        TR10: u1 = 0,
        /// TR11 [11:11]
        /// Rising trigger event configuration of
        TR11: u1 = 0,
        /// TR12 [12:12]
        /// Rising trigger event configuration of
        TR12: u1 = 0,
        /// TR13 [13:13]
        /// Rising trigger event configuration of
        TR13: u1 = 0,
        /// TR14 [14:14]
        /// Rising trigger event configuration of
        TR14: u1 = 0,
        /// TR15 [15:15]
        /// Rising trigger event configuration of
        TR15: u1 = 0,
        /// TR16 [16:16]
        /// Rising trigger event configuration of
        TR16: u1 = 0,
        /// TR17 [17:17]
        /// Rising trigger event configuration of
        TR17: u1 = 0,
        /// TR18 [18:18]
        /// Rising trigger event configuration of
        TR18: u1 = 0,
        /// TR19 [19:19]
        /// Rising trigger event configuration of
        TR19: u1 = 0,
        /// TR20 [20:20]
        /// Rising trigger event configuration of
        TR20: u1 = 0,
        /// TR21 [21:21]
        /// Rising trigger event configuration of
        TR21: u1 = 0,
        /// TR22 [22:22]
        /// Rising trigger event configuration of
        TR22: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// Rising Trigger selection register
    pub const RTSR = Register(RTSR_val).init(base_address + 0x8);

    /// FTSR
    const FTSR_val = packed struct {
        /// TR0 [0:0]
        /// Falling trigger event configuration of
        TR0: u1 = 0,
        /// TR1 [1:1]
        /// Falling trigger event configuration of
        TR1: u1 = 0,
        /// TR2 [2:2]
        /// Falling trigger event configuration of
        TR2: u1 = 0,
        /// TR3 [3:3]
        /// Falling trigger event configuration of
        TR3: u1 = 0,
        /// TR4 [4:4]
        /// Falling trigger event configuration of
        TR4: u1 = 0,
        /// TR5 [5:5]
        /// Falling trigger event configuration of
        TR5: u1 = 0,
        /// TR6 [6:6]
        /// Falling trigger event configuration of
        TR6: u1 = 0,
        /// TR7 [7:7]
        /// Falling trigger event configuration of
        TR7: u1 = 0,
        /// TR8 [8:8]
        /// Falling trigger event configuration of
        TR8: u1 = 0,
        /// TR9 [9:9]
        /// Falling trigger event configuration of
        TR9: u1 = 0,
        /// TR10 [10:10]
        /// Falling trigger event configuration of
        TR10: u1 = 0,
        /// TR11 [11:11]
        /// Falling trigger event configuration of
        TR11: u1 = 0,
        /// TR12 [12:12]
        /// Falling trigger event configuration of
        TR12: u1 = 0,
        /// TR13 [13:13]
        /// Falling trigger event configuration of
        TR13: u1 = 0,
        /// TR14 [14:14]
        /// Falling trigger event configuration of
        TR14: u1 = 0,
        /// TR15 [15:15]
        /// Falling trigger event configuration of
        TR15: u1 = 0,
        /// TR16 [16:16]
        /// Falling trigger event configuration of
        TR16: u1 = 0,
        /// TR17 [17:17]
        /// Falling trigger event configuration of
        TR17: u1 = 0,
        /// TR18 [18:18]
        /// Falling trigger event configuration of
        TR18: u1 = 0,
        /// TR19 [19:19]
        /// Falling trigger event configuration of
        TR19: u1 = 0,
        /// TR20 [20:20]
        /// Falling trigger event configuration of
        TR20: u1 = 0,
        /// TR21 [21:21]
        /// Falling trigger event configuration of
        TR21: u1 = 0,
        /// TR22 [22:22]
        /// Falling trigger event configuration of
        TR22: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// Falling Trigger selection register
    pub const FTSR = Register(FTSR_val).init(base_address + 0xc);

    /// SWIER
    const SWIER_val = packed struct {
        /// SWIER0 [0:0]
        /// Software Interrupt on line
        SWIER0: u1 = 0,
        /// SWIER1 [1:1]
        /// Software Interrupt on line
        SWIER1: u1 = 0,
        /// SWIER2 [2:2]
        /// Software Interrupt on line
        SWIER2: u1 = 0,
        /// SWIER3 [3:3]
        /// Software Interrupt on line
        SWIER3: u1 = 0,
        /// SWIER4 [4:4]
        /// Software Interrupt on line
        SWIER4: u1 = 0,
        /// SWIER5 [5:5]
        /// Software Interrupt on line
        SWIER5: u1 = 0,
        /// SWIER6 [6:6]
        /// Software Interrupt on line
        SWIER6: u1 = 0,
        /// SWIER7 [7:7]
        /// Software Interrupt on line
        SWIER7: u1 = 0,
        /// SWIER8 [8:8]
        /// Software Interrupt on line
        SWIER8: u1 = 0,
        /// SWIER9 [9:9]
        /// Software Interrupt on line
        SWIER9: u1 = 0,
        /// SWIER10 [10:10]
        /// Software Interrupt on line
        SWIER10: u1 = 0,
        /// SWIER11 [11:11]
        /// Software Interrupt on line
        SWIER11: u1 = 0,
        /// SWIER12 [12:12]
        /// Software Interrupt on line
        SWIER12: u1 = 0,
        /// SWIER13 [13:13]
        /// Software Interrupt on line
        SWIER13: u1 = 0,
        /// SWIER14 [14:14]
        /// Software Interrupt on line
        SWIER14: u1 = 0,
        /// SWIER15 [15:15]
        /// Software Interrupt on line
        SWIER15: u1 = 0,
        /// SWIER16 [16:16]
        /// Software Interrupt on line
        SWIER16: u1 = 0,
        /// SWIER17 [17:17]
        /// Software Interrupt on line
        SWIER17: u1 = 0,
        /// SWIER18 [18:18]
        /// Software Interrupt on line
        SWIER18: u1 = 0,
        /// SWIER19 [19:19]
        /// Software Interrupt on line
        SWIER19: u1 = 0,
        /// SWIER20 [20:20]
        /// Software Interrupt on line
        SWIER20: u1 = 0,
        /// SWIER21 [21:21]
        /// Software Interrupt on line
        SWIER21: u1 = 0,
        /// SWIER22 [22:22]
        /// Software Interrupt on line
        SWIER22: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// Software interrupt event register
    pub const SWIER = Register(SWIER_val).init(base_address + 0x10);

    /// PR
    const PR_val = packed struct {
        /// PR0 [0:0]
        /// Pending bit 0
        PR0: u1 = 0,
        /// PR1 [1:1]
        /// Pending bit 1
        PR1: u1 = 0,
        /// PR2 [2:2]
        /// Pending bit 2
        PR2: u1 = 0,
        /// PR3 [3:3]
        /// Pending bit 3
        PR3: u1 = 0,
        /// PR4 [4:4]
        /// Pending bit 4
        PR4: u1 = 0,
        /// PR5 [5:5]
        /// Pending bit 5
        PR5: u1 = 0,
        /// PR6 [6:6]
        /// Pending bit 6
        PR6: u1 = 0,
        /// PR7 [7:7]
        /// Pending bit 7
        PR7: u1 = 0,
        /// PR8 [8:8]
        /// Pending bit 8
        PR8: u1 = 0,
        /// PR9 [9:9]
        /// Pending bit 9
        PR9: u1 = 0,
        /// PR10 [10:10]
        /// Pending bit 10
        PR10: u1 = 0,
        /// PR11 [11:11]
        /// Pending bit 11
        PR11: u1 = 0,
        /// PR12 [12:12]
        /// Pending bit 12
        PR12: u1 = 0,
        /// PR13 [13:13]
        /// Pending bit 13
        PR13: u1 = 0,
        /// PR14 [14:14]
        /// Pending bit 14
        PR14: u1 = 0,
        /// PR15 [15:15]
        /// Pending bit 15
        PR15: u1 = 0,
        /// PR16 [16:16]
        /// Pending bit 16
        PR16: u1 = 0,
        /// PR17 [17:17]
        /// Pending bit 17
        PR17: u1 = 0,
        /// PR18 [18:18]
        /// Pending bit 18
        PR18: u1 = 0,
        /// PR19 [19:19]
        /// Pending bit 19
        PR19: u1 = 0,
        /// PR20 [20:20]
        /// Pending bit 20
        PR20: u1 = 0,
        /// PR21 [21:21]
        /// Pending bit 21
        PR21: u1 = 0,
        /// PR22 [22:22]
        /// Pending bit 22
        PR22: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// Pending register (EXTI_PR)
    pub const PR = Register(PR_val).init(base_address + 0x14);
};

/// FLASH
pub const FLASH = struct {
    const base_address = 0x40023c00;
    /// ACR
    const ACR_val = packed struct {
        /// LATENCY [0:2]
        /// Latency
        LATENCY: u3 = 0,
        /// unused [3:7]
        _unused3: u5 = 0,
        /// PRFTEN [8:8]
        /// Prefetch enable
        PRFTEN: u1 = 0,
        /// ICEN [9:9]
        /// Instruction cache enable
        ICEN: u1 = 0,
        /// DCEN [10:10]
        /// Data cache enable
        DCEN: u1 = 0,
        /// ICRST [11:11]
        /// Instruction cache reset
        ICRST: u1 = 0,
        /// DCRST [12:12]
        /// Data cache reset
        DCRST: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Flash access control register
    pub const ACR = Register(ACR_val).init(base_address + 0x0);

    /// KEYR
    const KEYR_val = packed struct {
        /// KEY [0:31]
        /// FPEC key
        KEY: u32 = 0,
    };
    /// Flash key register
    pub const KEYR = Register(KEYR_val).init(base_address + 0x4);

    /// OPTKEYR
    const OPTKEYR_val = packed struct {
        /// OPTKEY [0:31]
        /// Option byte key
        OPTKEY: u32 = 0,
    };
    /// Flash option key register
    pub const OPTKEYR = Register(OPTKEYR_val).init(base_address + 0x8);

    /// SR
    const SR_val = packed struct {
        /// EOP [0:0]
        /// End of operation
        EOP: u1 = 0,
        /// OPERR [1:1]
        /// Operation error
        OPERR: u1 = 0,
        /// unused [2:3]
        _unused2: u2 = 0,
        /// WRPERR [4:4]
        /// Write protection error
        WRPERR: u1 = 0,
        /// PGAERR [5:5]
        /// Programming alignment
        PGAERR: u1 = 0,
        /// PGPERR [6:6]
        /// Programming parallelism
        PGPERR: u1 = 0,
        /// PGSERR [7:7]
        /// Programming sequence error
        PGSERR: u1 = 0,
        /// unused [8:15]
        _unused8: u8 = 0,
        /// BSY [16:16]
        /// Busy
        BSY: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// Status register
    pub const SR = Register(SR_val).init(base_address + 0xc);

    /// CR
    const CR_val = packed struct {
        /// PG [0:0]
        /// Programming
        PG: u1 = 0,
        /// SER [1:1]
        /// Sector Erase
        SER: u1 = 0,
        /// MER [2:2]
        /// Mass Erase
        MER: u1 = 0,
        /// SNB [3:6]
        /// Sector number
        SNB: u4 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// PSIZE [8:9]
        /// Program size
        PSIZE: u2 = 0,
        /// unused [10:15]
        _unused10: u6 = 0,
        /// STRT [16:16]
        /// Start
        STRT: u1 = 0,
        /// unused [17:23]
        _unused17: u7 = 0,
        /// EOPIE [24:24]
        /// End of operation interrupt
        EOPIE: u1 = 0,
        /// ERRIE [25:25]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// unused [26:30]
        _unused26: u5 = 0,
        /// LOCK [31:31]
        /// Lock
        LOCK: u1 = 1,
    };
    /// Control register
    pub const CR = Register(CR_val).init(base_address + 0x10);

    /// OPTCR
    const OPTCR_val = packed struct {
        /// OPTLOCK [0:0]
        /// Option lock
        OPTLOCK: u1 = 0,
        /// OPTSTRT [1:1]
        /// Option start
        OPTSTRT: u1 = 0,
        /// BOR_LEV [2:3]
        /// BOR reset Level
        BOR_LEV: u2 = 1,
        /// unused [4:4]
        _unused4: u1 = 1,
        /// WDG_SW [5:5]
        /// WDG_SW User option bytes
        WDG_SW: u1 = 0,
        /// nRST_STOP [6:6]
        /// nRST_STOP User option
        nRST_STOP: u1 = 0,
        /// nRST_STDBY [7:7]
        /// nRST_STDBY User option
        nRST_STDBY: u1 = 0,
        /// RDP [8:15]
        /// Read protect
        RDP: u8 = 0,
        /// nWRP [16:27]
        /// Not write protect
        nWRP: u12 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// Flash option control register
    pub const OPTCR = Register(OPTCR_val).init(base_address + 0x14);
};

/// Independent watchdog
pub const IWDG = struct {
    const base_address = 0x40003000;
    /// KR
    const KR_val = packed struct {
        /// KEY [0:15]
        /// Key value
        KEY: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Key register
    pub const KR = Register(KR_val).init(base_address + 0x0);

    /// PR
    const PR_val = packed struct {
        /// PR [0:2]
        /// Prescaler divider
        PR: u3 = 0,
        /// unused [3:31]
        _unused3: u5 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Prescaler register
    pub const PR = Register(PR_val).init(base_address + 0x4);

    /// RLR
    const RLR_val = packed struct {
        /// RL [0:11]
        /// Watchdog counter reload
        RL: u12 = 4095,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Reload register
    pub const RLR = Register(RLR_val).init(base_address + 0x8);

    /// SR
    const SR_val = packed struct {
        /// PVU [0:0]
        /// Watchdog prescaler value
        PVU: u1 = 0,
        /// RVU [1:1]
        /// Watchdog counter reload value
        RVU: u1 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register
    pub const SR = Register(SR_val).init(base_address + 0xc);
};

/// USB on the go full speed
pub const OTG_FS_DEVICE = struct {
    const base_address = 0x50000800;
    /// FS_DCFG
    const FS_DCFG_val = packed struct {
        /// DSPD [0:1]
        /// Device speed
        DSPD: u2 = 0,
        /// NZLSOHSK [2:2]
        /// Non-zero-length status OUT
        NZLSOHSK: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// DAD [4:10]
        /// Device address
        DAD: u7 = 0,
        /// PFIVL [11:12]
        /// Periodic frame interval
        PFIVL: u2 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 32,
        _unused24: u8 = 2,
    };
    /// OTG_FS device configuration register
    pub const FS_DCFG = Register(FS_DCFG_val).init(base_address + 0x0);

    /// FS_DCTL
    const FS_DCTL_val = packed struct {
        /// RWUSIG [0:0]
        /// Remote wakeup signaling
        RWUSIG: u1 = 0,
        /// SDIS [1:1]
        /// Soft disconnect
        SDIS: u1 = 0,
        /// GINSTS [2:2]
        /// Global IN NAK status
        GINSTS: u1 = 0,
        /// GONSTS [3:3]
        /// Global OUT NAK status
        GONSTS: u1 = 0,
        /// TCTL [4:6]
        /// Test control
        TCTL: u3 = 0,
        /// SGINAK [7:7]
        /// Set global IN NAK
        SGINAK: u1 = 0,
        /// CGINAK [8:8]
        /// Clear global IN NAK
        CGINAK: u1 = 0,
        /// SGONAK [9:9]
        /// Set global OUT NAK
        SGONAK: u1 = 0,
        /// CGONAK [10:10]
        /// Clear global OUT NAK
        CGONAK: u1 = 0,
        /// POPRGDNE [11:11]
        /// Power-on programming done
        POPRGDNE: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device control register
    pub const FS_DCTL = Register(FS_DCTL_val).init(base_address + 0x4);

    /// FS_DSTS
    const FS_DSTS_val = packed struct {
        /// SUSPSTS [0:0]
        /// Suspend status
        SUSPSTS: u1 = 0,
        /// ENUMSPD [1:2]
        /// Enumerated speed
        ENUMSPD: u2 = 0,
        /// EERR [3:3]
        /// Erratic error
        EERR: u1 = 0,
        /// unused [4:7]
        _unused4: u4 = 1,
        /// FNSOF [8:21]
        /// Frame number of the received
        FNSOF: u14 = 0,
        /// unused [22:31]
        _unused22: u2 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device status register
    pub const FS_DSTS = Register(FS_DSTS_val).init(base_address + 0x8);

    /// FS_DIEPMSK
    const FS_DIEPMSK_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed interrupt
        XFRCM: u1 = 0,
        /// EPDM [1:1]
        /// Endpoint disabled interrupt
        EPDM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// TOM [3:3]
        /// Timeout condition mask (Non-isochronous
        TOM: u1 = 0,
        /// ITTXFEMSK [4:4]
        /// IN token received when TxFIFO empty
        ITTXFEMSK: u1 = 0,
        /// INEPNMM [5:5]
        /// IN token received with EP mismatch
        INEPNMM: u1 = 0,
        /// INEPNEM [6:6]
        /// IN endpoint NAK effective
        INEPNEM: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device IN endpoint common interrupt
    pub const FS_DIEPMSK = Register(FS_DIEPMSK_val).init(base_address + 0x10);

    /// FS_DOEPMSK
    const FS_DOEPMSK_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed interrupt
        XFRCM: u1 = 0,
        /// EPDM [1:1]
        /// Endpoint disabled interrupt
        EPDM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STUPM [3:3]
        /// SETUP phase done mask
        STUPM: u1 = 0,
        /// OTEPDM [4:4]
        /// OUT token received when endpoint
        OTEPDM: u1 = 0,
        /// unused [5:31]
        _unused5: u3 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device OUT endpoint common interrupt
    pub const FS_DOEPMSK = Register(FS_DOEPMSK_val).init(base_address + 0x14);

    /// FS_DAINT
    const FS_DAINT_val = packed struct {
        /// IEPINT [0:15]
        /// IN endpoint interrupt bits
        IEPINT: u16 = 0,
        /// OEPINT [16:31]
        /// OUT endpoint interrupt
        OEPINT: u16 = 0,
    };
    /// OTG_FS device all endpoints interrupt
    pub const FS_DAINT = Register(FS_DAINT_val).init(base_address + 0x18);

    /// FS_DAINTMSK
    const FS_DAINTMSK_val = packed struct {
        /// IEPM [0:15]
        /// IN EP interrupt mask bits
        IEPM: u16 = 0,
        /// OEPINT [16:31]
        /// OUT endpoint interrupt
        OEPINT: u16 = 0,
    };
    /// OTG_FS all endpoints interrupt mask register
    pub const FS_DAINTMSK = Register(FS_DAINTMSK_val).init(base_address + 0x1c);

    /// DVBUSDIS
    const DVBUSDIS_val = packed struct {
        /// VBUSDT [0:15]
        /// Device VBUS discharge time
        VBUSDT: u16 = 6103,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device VBUS discharge time
    pub const DVBUSDIS = Register(DVBUSDIS_val).init(base_address + 0x28);

    /// DVBUSPULSE
    const DVBUSPULSE_val = packed struct {
        /// DVBUSP [0:11]
        /// Device VBUS pulsing time
        DVBUSP: u12 = 1464,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device VBUS pulsing time
    pub const DVBUSPULSE = Register(DVBUSPULSE_val).init(base_address + 0x2c);

    /// DIEPEMPMSK
    const DIEPEMPMSK_val = packed struct {
        /// INEPTXFEM [0:15]
        /// IN EP Tx FIFO empty interrupt mask
        INEPTXFEM: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device IN endpoint FIFO empty
    pub const DIEPEMPMSK = Register(DIEPEMPMSK_val).init(base_address + 0x34);

    /// FS_DIEPCTL0
    const FS_DIEPCTL0_val = packed struct {
        /// MPSIZ [0:1]
        /// Maximum packet size
        MPSIZ: u2 = 0,
        /// unused [2:14]
        _unused2: u6 = 0,
        _unused8: u7 = 0,
        /// USBAEP [15:15]
        /// USB active endpoint
        USBAEP: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// NAKSTS [17:17]
        /// NAK status
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// unused [20:20]
        _unused20: u1 = 0,
        /// STALL [21:21]
        /// STALL handshake
        STALL: u1 = 0,
        /// TXFNUM [22:25]
        /// TxFIFO number
        TXFNUM: u4 = 0,
        /// CNAK [26:26]
        /// Clear NAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// Set NAK
        SNAK: u1 = 0,
        /// unused [28:29]
        _unused28: u2 = 0,
        /// EPDIS [30:30]
        /// Endpoint disable
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// Endpoint enable
        EPENA: u1 = 0,
    };
    /// OTG_FS device control IN endpoint 0 control
    pub const FS_DIEPCTL0 = Register(FS_DIEPCTL0_val).init(base_address + 0x100);

    /// DIEPCTL1
    const DIEPCTL1_val = packed struct {
        /// MPSIZ [0:10]
        /// MPSIZ
        MPSIZ: u11 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 0,
        /// EONUM_DPID [16:16]
        /// EONUM/DPID
        EONUM_DPID: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// unused [20:20]
        _unused20: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// TXFNUM [22:25]
        /// TXFNUM
        TXFNUM: u4 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// SD0PID_SEVNFRM [28:28]
        /// SD0PID/SEVNFRM
        SD0PID_SEVNFRM: u1 = 0,
        /// SODDFRM_SD1PID [29:29]
        /// SODDFRM/SD1PID
        SODDFRM_SD1PID: u1 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// OTG device endpoint-1 control
    pub const DIEPCTL1 = Register(DIEPCTL1_val).init(base_address + 0x120);

    /// DIEPCTL2
    const DIEPCTL2_val = packed struct {
        /// MPSIZ [0:10]
        /// MPSIZ
        MPSIZ: u11 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 0,
        /// EONUM_DPID [16:16]
        /// EONUM/DPID
        EONUM_DPID: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// unused [20:20]
        _unused20: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// TXFNUM [22:25]
        /// TXFNUM
        TXFNUM: u4 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// SD0PID_SEVNFRM [28:28]
        /// SD0PID/SEVNFRM
        SD0PID_SEVNFRM: u1 = 0,
        /// SODDFRM [29:29]
        /// SODDFRM
        SODDFRM: u1 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// OTG device endpoint-2 control
    pub const DIEPCTL2 = Register(DIEPCTL2_val).init(base_address + 0x140);

    /// DIEPCTL3
    const DIEPCTL3_val = packed struct {
        /// MPSIZ [0:10]
        /// MPSIZ
        MPSIZ: u11 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 0,
        /// EONUM_DPID [16:16]
        /// EONUM/DPID
        EONUM_DPID: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// unused [20:20]
        _unused20: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// TXFNUM [22:25]
        /// TXFNUM
        TXFNUM: u4 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// SD0PID_SEVNFRM [28:28]
        /// SD0PID/SEVNFRM
        SD0PID_SEVNFRM: u1 = 0,
        /// SODDFRM [29:29]
        /// SODDFRM
        SODDFRM: u1 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// OTG device endpoint-3 control
    pub const DIEPCTL3 = Register(DIEPCTL3_val).init(base_address + 0x160);

    /// DOEPCTL0
    const DOEPCTL0_val = packed struct {
        /// MPSIZ [0:1]
        /// MPSIZ
        MPSIZ: u2 = 0,
        /// unused [2:14]
        _unused2: u6 = 0,
        _unused8: u7 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 1,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// SNPM [20:20]
        /// SNPM
        SNPM: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// unused [22:25]
        _unused22: u2 = 0,
        _unused24: u2 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// unused [28:29]
        _unused28: u2 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// device endpoint-0 control
    pub const DOEPCTL0 = Register(DOEPCTL0_val).init(base_address + 0x300);

    /// DOEPCTL1
    const DOEPCTL1_val = packed struct {
        /// MPSIZ [0:10]
        /// MPSIZ
        MPSIZ: u11 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 0,
        /// EONUM_DPID [16:16]
        /// EONUM/DPID
        EONUM_DPID: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// SNPM [20:20]
        /// SNPM
        SNPM: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// unused [22:25]
        _unused22: u2 = 0,
        _unused24: u2 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// SD0PID_SEVNFRM [28:28]
        /// SD0PID/SEVNFRM
        SD0PID_SEVNFRM: u1 = 0,
        /// SODDFRM [29:29]
        /// SODDFRM
        SODDFRM: u1 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// device endpoint-1 control
    pub const DOEPCTL1 = Register(DOEPCTL1_val).init(base_address + 0x320);

    /// DOEPCTL2
    const DOEPCTL2_val = packed struct {
        /// MPSIZ [0:10]
        /// MPSIZ
        MPSIZ: u11 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 0,
        /// EONUM_DPID [16:16]
        /// EONUM/DPID
        EONUM_DPID: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// SNPM [20:20]
        /// SNPM
        SNPM: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// unused [22:25]
        _unused22: u2 = 0,
        _unused24: u2 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// SD0PID_SEVNFRM [28:28]
        /// SD0PID/SEVNFRM
        SD0PID_SEVNFRM: u1 = 0,
        /// SODDFRM [29:29]
        /// SODDFRM
        SODDFRM: u1 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// device endpoint-2 control
    pub const DOEPCTL2 = Register(DOEPCTL2_val).init(base_address + 0x340);

    /// DOEPCTL3
    const DOEPCTL3_val = packed struct {
        /// MPSIZ [0:10]
        /// MPSIZ
        MPSIZ: u11 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// USBAEP [15:15]
        /// USBAEP
        USBAEP: u1 = 0,
        /// EONUM_DPID [16:16]
        /// EONUM/DPID
        EONUM_DPID: u1 = 0,
        /// NAKSTS [17:17]
        /// NAKSTS
        NAKSTS: u1 = 0,
        /// EPTYP [18:19]
        /// EPTYP
        EPTYP: u2 = 0,
        /// SNPM [20:20]
        /// SNPM
        SNPM: u1 = 0,
        /// Stall [21:21]
        /// Stall
        Stall: u1 = 0,
        /// unused [22:25]
        _unused22: u2 = 0,
        _unused24: u2 = 0,
        /// CNAK [26:26]
        /// CNAK
        CNAK: u1 = 0,
        /// SNAK [27:27]
        /// SNAK
        SNAK: u1 = 0,
        /// SD0PID_SEVNFRM [28:28]
        /// SD0PID/SEVNFRM
        SD0PID_SEVNFRM: u1 = 0,
        /// SODDFRM [29:29]
        /// SODDFRM
        SODDFRM: u1 = 0,
        /// EPDIS [30:30]
        /// EPDIS
        EPDIS: u1 = 0,
        /// EPENA [31:31]
        /// EPENA
        EPENA: u1 = 0,
    };
    /// device endpoint-3 control
    pub const DOEPCTL3 = Register(DOEPCTL3_val).init(base_address + 0x360);

    /// DIEPINT0
    const DIEPINT0_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// TOC [3:3]
        /// TOC
        TOC: u1 = 0,
        /// ITTXFE [4:4]
        /// ITTXFE
        ITTXFE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// INEPNE [6:6]
        /// INEPNE
        INEPNE: u1 = 0,
        /// TXFE [7:7]
        /// TXFE
        TXFE: u1 = 1,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-x interrupt
    pub const DIEPINT0 = Register(DIEPINT0_val).init(base_address + 0x108);

    /// DIEPINT1
    const DIEPINT1_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// TOC [3:3]
        /// TOC
        TOC: u1 = 0,
        /// ITTXFE [4:4]
        /// ITTXFE
        ITTXFE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// INEPNE [6:6]
        /// INEPNE
        INEPNE: u1 = 0,
        /// TXFE [7:7]
        /// TXFE
        TXFE: u1 = 1,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-1 interrupt
    pub const DIEPINT1 = Register(DIEPINT1_val).init(base_address + 0x128);

    /// DIEPINT2
    const DIEPINT2_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// TOC [3:3]
        /// TOC
        TOC: u1 = 0,
        /// ITTXFE [4:4]
        /// ITTXFE
        ITTXFE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// INEPNE [6:6]
        /// INEPNE
        INEPNE: u1 = 0,
        /// TXFE [7:7]
        /// TXFE
        TXFE: u1 = 1,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-2 interrupt
    pub const DIEPINT2 = Register(DIEPINT2_val).init(base_address + 0x148);

    /// DIEPINT3
    const DIEPINT3_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// TOC [3:3]
        /// TOC
        TOC: u1 = 0,
        /// ITTXFE [4:4]
        /// ITTXFE
        ITTXFE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// INEPNE [6:6]
        /// INEPNE
        INEPNE: u1 = 0,
        /// TXFE [7:7]
        /// TXFE
        TXFE: u1 = 1,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-3 interrupt
    pub const DIEPINT3 = Register(DIEPINT3_val).init(base_address + 0x168);

    /// DOEPINT0
    const DOEPINT0_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STUP [3:3]
        /// STUP
        STUP: u1 = 0,
        /// OTEPDIS [4:4]
        /// OTEPDIS
        OTEPDIS: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// B2BSTUP [6:6]
        /// B2BSTUP
        B2BSTUP: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 1,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-0 interrupt
    pub const DOEPINT0 = Register(DOEPINT0_val).init(base_address + 0x308);

    /// DOEPINT1
    const DOEPINT1_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STUP [3:3]
        /// STUP
        STUP: u1 = 0,
        /// OTEPDIS [4:4]
        /// OTEPDIS
        OTEPDIS: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// B2BSTUP [6:6]
        /// B2BSTUP
        B2BSTUP: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 1,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-1 interrupt
    pub const DOEPINT1 = Register(DOEPINT1_val).init(base_address + 0x328);

    /// DOEPINT2
    const DOEPINT2_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STUP [3:3]
        /// STUP
        STUP: u1 = 0,
        /// OTEPDIS [4:4]
        /// OTEPDIS
        OTEPDIS: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// B2BSTUP [6:6]
        /// B2BSTUP
        B2BSTUP: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 1,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-2 interrupt
    pub const DOEPINT2 = Register(DOEPINT2_val).init(base_address + 0x348);

    /// DOEPINT3
    const DOEPINT3_val = packed struct {
        /// XFRC [0:0]
        /// XFRC
        XFRC: u1 = 0,
        /// EPDISD [1:1]
        /// EPDISD
        EPDISD: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STUP [3:3]
        /// STUP
        STUP: u1 = 0,
        /// OTEPDIS [4:4]
        /// OTEPDIS
        OTEPDIS: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// B2BSTUP [6:6]
        /// B2BSTUP
        B2BSTUP: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 1,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-3 interrupt
    pub const DOEPINT3 = Register(DOEPINT3_val).init(base_address + 0x368);

    /// DIEPTSIZ0
    const DIEPTSIZ0_val = packed struct {
        /// XFRSIZ [0:6]
        /// Transfer size
        XFRSIZ: u7 = 0,
        /// unused [7:18]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u3 = 0,
        /// PKTCNT [19:20]
        /// Packet count
        PKTCNT: u2 = 0,
        /// unused [21:31]
        _unused21: u3 = 0,
        _unused24: u8 = 0,
    };
    /// device endpoint-0 transfer size
    pub const DIEPTSIZ0 = Register(DIEPTSIZ0_val).init(base_address + 0x110);

    /// DOEPTSIZ0
    const DOEPTSIZ0_val = packed struct {
        /// XFRSIZ [0:6]
        /// Transfer size
        XFRSIZ: u7 = 0,
        /// unused [7:18]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u3 = 0,
        /// PKTCNT [19:19]
        /// Packet count
        PKTCNT: u1 = 0,
        /// unused [20:28]
        _unused20: u4 = 0,
        _unused24: u5 = 0,
        /// STUPCNT [29:30]
        /// SETUP packet count
        STUPCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device OUT endpoint-0 transfer size
    pub const DOEPTSIZ0 = Register(DOEPTSIZ0_val).init(base_address + 0x310);

    /// DIEPTSIZ1
    const DIEPTSIZ1_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// MCNT [29:30]
        /// Multi count
        MCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device endpoint-1 transfer size
    pub const DIEPTSIZ1 = Register(DIEPTSIZ1_val).init(base_address + 0x130);

    /// DIEPTSIZ2
    const DIEPTSIZ2_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// MCNT [29:30]
        /// Multi count
        MCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device endpoint-2 transfer size
    pub const DIEPTSIZ2 = Register(DIEPTSIZ2_val).init(base_address + 0x150);

    /// DIEPTSIZ3
    const DIEPTSIZ3_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// MCNT [29:30]
        /// Multi count
        MCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device endpoint-3 transfer size
    pub const DIEPTSIZ3 = Register(DIEPTSIZ3_val).init(base_address + 0x170);

    /// DTXFSTS0
    const DTXFSTS0_val = packed struct {
        /// INEPTFSAV [0:15]
        /// IN endpoint TxFIFO space
        INEPTFSAV: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device IN endpoint transmit FIFO
    pub const DTXFSTS0 = Register(DTXFSTS0_val).init(base_address + 0x118);

    /// DTXFSTS1
    const DTXFSTS1_val = packed struct {
        /// INEPTFSAV [0:15]
        /// IN endpoint TxFIFO space
        INEPTFSAV: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device IN endpoint transmit FIFO
    pub const DTXFSTS1 = Register(DTXFSTS1_val).init(base_address + 0x138);

    /// DTXFSTS2
    const DTXFSTS2_val = packed struct {
        /// INEPTFSAV [0:15]
        /// IN endpoint TxFIFO space
        INEPTFSAV: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device IN endpoint transmit FIFO
    pub const DTXFSTS2 = Register(DTXFSTS2_val).init(base_address + 0x158);

    /// DTXFSTS3
    const DTXFSTS3_val = packed struct {
        /// INEPTFSAV [0:15]
        /// IN endpoint TxFIFO space
        INEPTFSAV: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS device IN endpoint transmit FIFO
    pub const DTXFSTS3 = Register(DTXFSTS3_val).init(base_address + 0x178);

    /// DOEPTSIZ1
    const DOEPTSIZ1_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// RXDPID_STUPCNT [29:30]
        /// Received data PID/SETUP packet
        RXDPID_STUPCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device OUT endpoint-1 transfer size
    pub const DOEPTSIZ1 = Register(DOEPTSIZ1_val).init(base_address + 0x330);

    /// DOEPTSIZ2
    const DOEPTSIZ2_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// RXDPID_STUPCNT [29:30]
        /// Received data PID/SETUP packet
        RXDPID_STUPCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device OUT endpoint-2 transfer size
    pub const DOEPTSIZ2 = Register(DOEPTSIZ2_val).init(base_address + 0x350);

    /// DOEPTSIZ3
    const DOEPTSIZ3_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// RXDPID_STUPCNT [29:30]
        /// Received data PID/SETUP packet
        RXDPID_STUPCNT: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// device OUT endpoint-3 transfer size
    pub const DOEPTSIZ3 = Register(DOEPTSIZ3_val).init(base_address + 0x370);
};

/// USB on the go full speed
pub const OTG_FS_GLOBAL = struct {
    const base_address = 0x50000000;
    /// FS_GOTGCTL
    const FS_GOTGCTL_val = packed struct {
        /// SRQSCS [0:0]
        /// Session request success
        SRQSCS: u1 = 0,
        /// SRQ [1:1]
        /// Session request
        SRQ: u1 = 0,
        /// unused [2:7]
        _unused2: u6 = 0,
        /// HNGSCS [8:8]
        /// Host negotiation success
        HNGSCS: u1 = 0,
        /// HNPRQ [9:9]
        /// HNP request
        HNPRQ: u1 = 0,
        /// HSHNPEN [10:10]
        /// Host set HNP enable
        HSHNPEN: u1 = 0,
        /// DHNPEN [11:11]
        /// Device HNP enabled
        DHNPEN: u1 = 1,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// CIDSTS [16:16]
        /// Connector ID status
        CIDSTS: u1 = 0,
        /// DBCT [17:17]
        /// Long/short debounce time
        DBCT: u1 = 0,
        /// ASVLD [18:18]
        /// A-session valid
        ASVLD: u1 = 0,
        /// BSVLD [19:19]
        /// B-session valid
        BSVLD: u1 = 0,
        /// unused [20:31]
        _unused20: u4 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS control and status register
    pub const FS_GOTGCTL = Register(FS_GOTGCTL_val).init(base_address + 0x0);

    /// FS_GOTGINT
    const FS_GOTGINT_val = packed struct {
        /// unused [0:1]
        _unused0: u2 = 0,
        /// SEDET [2:2]
        /// Session end detected
        SEDET: u1 = 0,
        /// unused [3:7]
        _unused3: u5 = 0,
        /// SRSSCHG [8:8]
        /// Session request success status
        SRSSCHG: u1 = 0,
        /// HNSSCHG [9:9]
        /// Host negotiation success status
        HNSSCHG: u1 = 0,
        /// unused [10:16]
        _unused10: u6 = 0,
        _unused16: u1 = 0,
        /// HNGDET [17:17]
        /// Host negotiation detected
        HNGDET: u1 = 0,
        /// ADTOCHG [18:18]
        /// A-device timeout change
        ADTOCHG: u1 = 0,
        /// DBCDNE [19:19]
        /// Debounce done
        DBCDNE: u1 = 0,
        /// unused [20:31]
        _unused20: u4 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS interrupt register
    pub const FS_GOTGINT = Register(FS_GOTGINT_val).init(base_address + 0x4);

    /// FS_GAHBCFG
    const FS_GAHBCFG_val = packed struct {
        /// GINT [0:0]
        /// Global interrupt mask
        GINT: u1 = 0,
        /// unused [1:6]
        _unused1: u6 = 0,
        /// TXFELVL [7:7]
        /// TxFIFO empty level
        TXFELVL: u1 = 0,
        /// PTXFELVL [8:8]
        /// Periodic TxFIFO empty
        PTXFELVL: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS AHB configuration register
    pub const FS_GAHBCFG = Register(FS_GAHBCFG_val).init(base_address + 0x8);

    /// FS_GUSBCFG
    const FS_GUSBCFG_val = packed struct {
        /// TOCAL [0:2]
        /// FS timeout calibration
        TOCAL: u3 = 0,
        /// unused [3:5]
        _unused3: u3 = 0,
        /// PHYSEL [6:6]
        /// Full Speed serial transceiver
        PHYSEL: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// SRPCAP [8:8]
        /// SRP-capable
        SRPCAP: u1 = 0,
        /// HNPCAP [9:9]
        /// HNP-capable
        HNPCAP: u1 = 1,
        /// TRDT [10:13]
        /// USB turnaround time
        TRDT: u4 = 2,
        /// unused [14:28]
        _unused14: u2 = 0,
        _unused16: u8 = 0,
        _unused24: u5 = 0,
        /// FHMOD [29:29]
        /// Force host mode
        FHMOD: u1 = 0,
        /// FDMOD [30:30]
        /// Force device mode
        FDMOD: u1 = 0,
        /// CTXPKT [31:31]
        /// Corrupt Tx packet
        CTXPKT: u1 = 0,
    };
    /// OTG_FS USB configuration register
    pub const FS_GUSBCFG = Register(FS_GUSBCFG_val).init(base_address + 0xc);

    /// FS_GRSTCTL
    const FS_GRSTCTL_val = packed struct {
        /// CSRST [0:0]
        /// Core soft reset
        CSRST: u1 = 0,
        /// HSRST [1:1]
        /// HCLK soft reset
        HSRST: u1 = 0,
        /// FCRST [2:2]
        /// Host frame counter reset
        FCRST: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// RXFFLSH [4:4]
        /// RxFIFO flush
        RXFFLSH: u1 = 0,
        /// TXFFLSH [5:5]
        /// TxFIFO flush
        TXFFLSH: u1 = 0,
        /// TXFNUM [6:10]
        /// TxFIFO number
        TXFNUM: u5 = 0,
        /// unused [11:30]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u7 = 32,
        /// AHBIDL [31:31]
        /// AHB master idle
        AHBIDL: u1 = 0,
    };
    /// OTG_FS reset register
    pub const FS_GRSTCTL = Register(FS_GRSTCTL_val).init(base_address + 0x10);

    /// FS_GINTSTS
    const FS_GINTSTS_val = packed struct {
        /// CMOD [0:0]
        /// Current mode of operation
        CMOD: u1 = 0,
        /// MMIS [1:1]
        /// Mode mismatch interrupt
        MMIS: u1 = 0,
        /// OTGINT [2:2]
        /// OTG interrupt
        OTGINT: u1 = 0,
        /// SOF [3:3]
        /// Start of frame
        SOF: u1 = 0,
        /// RXFLVL [4:4]
        /// RxFIFO non-empty
        RXFLVL: u1 = 0,
        /// NPTXFE [5:5]
        /// Non-periodic TxFIFO empty
        NPTXFE: u1 = 1,
        /// GINAKEFF [6:6]
        /// Global IN non-periodic NAK
        GINAKEFF: u1 = 0,
        /// GOUTNAKEFF [7:7]
        /// Global OUT NAK effective
        GOUTNAKEFF: u1 = 0,
        /// unused [8:9]
        _unused8: u2 = 0,
        /// ESUSP [10:10]
        /// Early suspend
        ESUSP: u1 = 0,
        /// USBSUSP [11:11]
        /// USB suspend
        USBSUSP: u1 = 0,
        /// USBRST [12:12]
        /// USB reset
        USBRST: u1 = 0,
        /// ENUMDNE [13:13]
        /// Enumeration done
        ENUMDNE: u1 = 0,
        /// ISOODRP [14:14]
        /// Isochronous OUT packet dropped
        ISOODRP: u1 = 0,
        /// EOPF [15:15]
        /// End of periodic frame
        EOPF: u1 = 0,
        /// unused [16:17]
        _unused16: u2 = 0,
        /// IEPINT [18:18]
        /// IN endpoint interrupt
        IEPINT: u1 = 0,
        /// OEPINT [19:19]
        /// OUT endpoint interrupt
        OEPINT: u1 = 0,
        /// IISOIXFR [20:20]
        /// Incomplete isochronous IN
        IISOIXFR: u1 = 0,
        /// IPXFR_INCOMPISOOUT [21:21]
        /// Incomplete periodic transfer(Host
        IPXFR_INCOMPISOOUT: u1 = 0,
        /// unused [22:23]
        _unused22: u2 = 0,
        /// HPRTINT [24:24]
        /// Host port interrupt
        HPRTINT: u1 = 0,
        /// HCINT [25:25]
        /// Host channels interrupt
        HCINT: u1 = 0,
        /// PTXFE [26:26]
        /// Periodic TxFIFO empty
        PTXFE: u1 = 1,
        /// unused [27:27]
        _unused27: u1 = 0,
        /// CIDSCHG [28:28]
        /// Connector ID status change
        CIDSCHG: u1 = 0,
        /// DISCINT [29:29]
        /// Disconnect detected
        DISCINT: u1 = 0,
        /// SRQINT [30:30]
        /// Session request/new session detected
        SRQINT: u1 = 0,
        /// WKUPINT [31:31]
        /// Resume/remote wakeup detected
        WKUPINT: u1 = 0,
    };
    /// OTG_FS core interrupt register
    pub const FS_GINTSTS = Register(FS_GINTSTS_val).init(base_address + 0x14);

    /// FS_GINTMSK
    const FS_GINTMSK_val = packed struct {
        /// unused [0:0]
        _unused0: u1 = 0,
        /// MMISM [1:1]
        /// Mode mismatch interrupt
        MMISM: u1 = 0,
        /// OTGINT [2:2]
        /// OTG interrupt mask
        OTGINT: u1 = 0,
        /// SOFM [3:3]
        /// Start of frame mask
        SOFM: u1 = 0,
        /// RXFLVLM [4:4]
        /// Receive FIFO non-empty
        RXFLVLM: u1 = 0,
        /// NPTXFEM [5:5]
        /// Non-periodic TxFIFO empty
        NPTXFEM: u1 = 0,
        /// GINAKEFFM [6:6]
        /// Global non-periodic IN NAK effective
        GINAKEFFM: u1 = 0,
        /// GONAKEFFM [7:7]
        /// Global OUT NAK effective
        GONAKEFFM: u1 = 0,
        /// unused [8:9]
        _unused8: u2 = 0,
        /// ESUSPM [10:10]
        /// Early suspend mask
        ESUSPM: u1 = 0,
        /// USBSUSPM [11:11]
        /// USB suspend mask
        USBSUSPM: u1 = 0,
        /// USBRST [12:12]
        /// USB reset mask
        USBRST: u1 = 0,
        /// ENUMDNEM [13:13]
        /// Enumeration done mask
        ENUMDNEM: u1 = 0,
        /// ISOODRPM [14:14]
        /// Isochronous OUT packet dropped interrupt
        ISOODRPM: u1 = 0,
        /// EOPFM [15:15]
        /// End of periodic frame interrupt
        EOPFM: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// EPMISM [17:17]
        /// Endpoint mismatch interrupt
        EPMISM: u1 = 0,
        /// IEPINT [18:18]
        /// IN endpoints interrupt
        IEPINT: u1 = 0,
        /// OEPINT [19:19]
        /// OUT endpoints interrupt
        OEPINT: u1 = 0,
        /// IISOIXFRM [20:20]
        /// Incomplete isochronous IN transfer
        IISOIXFRM: u1 = 0,
        /// IPXFRM_IISOOXFRM [21:21]
        /// Incomplete periodic transfer mask(Host
        IPXFRM_IISOOXFRM: u1 = 0,
        /// unused [22:23]
        _unused22: u2 = 0,
        /// PRTIM [24:24]
        /// Host port interrupt mask
        PRTIM: u1 = 0,
        /// HCIM [25:25]
        /// Host channels interrupt
        HCIM: u1 = 0,
        /// PTXFEM [26:26]
        /// Periodic TxFIFO empty mask
        PTXFEM: u1 = 0,
        /// unused [27:27]
        _unused27: u1 = 0,
        /// CIDSCHGM [28:28]
        /// Connector ID status change
        CIDSCHGM: u1 = 0,
        /// DISCINT [29:29]
        /// Disconnect detected interrupt
        DISCINT: u1 = 0,
        /// SRQIM [30:30]
        /// Session request/new session detected
        SRQIM: u1 = 0,
        /// WUIM [31:31]
        /// Resume/remote wakeup detected interrupt
        WUIM: u1 = 0,
    };
    /// OTG_FS interrupt mask register
    pub const FS_GINTMSK = Register(FS_GINTMSK_val).init(base_address + 0x18);

    /// FS_GRXSTSR_Device
    const FS_GRXSTSR_Device_val = packed struct {
        /// EPNUM [0:3]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// BCNT [4:14]
        /// Byte count
        BCNT: u11 = 0,
        /// DPID [15:16]
        /// Data PID
        DPID: u2 = 0,
        /// PKTSTS [17:20]
        /// Packet status
        PKTSTS: u4 = 0,
        /// FRMNUM [21:24]
        /// Frame number
        FRMNUM: u4 = 0,
        /// unused [25:31]
        _unused25: u7 = 0,
    };
    /// OTG_FS Receive status debug read(Device
    pub const FS_GRXSTSR_Device = Register(FS_GRXSTSR_Device_val).init(base_address + 0x1c);

    /// FS_GRXSTSR_Host
    const FS_GRXSTSR_Host_val = packed struct {
        /// EPNUM [0:3]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// BCNT [4:14]
        /// Byte count
        BCNT: u11 = 0,
        /// DPID [15:16]
        /// Data PID
        DPID: u2 = 0,
        /// PKTSTS [17:20]
        /// Packet status
        PKTSTS: u4 = 0,
        /// FRMNUM [21:24]
        /// Frame number
        FRMNUM: u4 = 0,
        /// unused [25:31]
        _unused25: u7 = 0,
    };
    /// OTG_FS Receive status debug read(Host
    pub const FS_GRXSTSR_Host = Register(FS_GRXSTSR_Host_val).init(base_address + 0x1c);

    /// FS_GRXFSIZ
    const FS_GRXFSIZ_val = packed struct {
        /// RXFD [0:15]
        /// RxFIFO depth
        RXFD: u16 = 512,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS Receive FIFO size register
    pub const FS_GRXFSIZ = Register(FS_GRXFSIZ_val).init(base_address + 0x24);

    /// FS_GNPTXFSIZ_Device
    const FS_GNPTXFSIZ_Device_val = packed struct {
        /// TX0FSA [0:15]
        /// Endpoint 0 transmit RAM start
        TX0FSA: u16 = 512,
        /// TX0FD [16:31]
        /// Endpoint 0 TxFIFO depth
        TX0FD: u16 = 0,
    };
    /// OTG_FS non-periodic transmit FIFO size
    pub const FS_GNPTXFSIZ_Device = Register(FS_GNPTXFSIZ_Device_val).init(base_address + 0x28);

    /// FS_GNPTXFSIZ_Host
    const FS_GNPTXFSIZ_Host_val = packed struct {
        /// NPTXFSA [0:15]
        /// Non-periodic transmit RAM start
        NPTXFSA: u16 = 512,
        /// NPTXFD [16:31]
        /// Non-periodic TxFIFO depth
        NPTXFD: u16 = 0,
    };
    /// OTG_FS non-periodic transmit FIFO size
    pub const FS_GNPTXFSIZ_Host = Register(FS_GNPTXFSIZ_Host_val).init(base_address + 0x28);

    /// FS_GNPTXSTS
    const FS_GNPTXSTS_val = packed struct {
        /// NPTXFSAV [0:15]
        /// Non-periodic TxFIFO space
        NPTXFSAV: u16 = 512,
        /// NPTQXSAV [16:23]
        /// Non-periodic transmit request queue
        NPTQXSAV: u8 = 8,
        /// NPTXQTOP [24:30]
        /// Top of the non-periodic transmit request
        NPTXQTOP: u7 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS non-periodic transmit FIFO/queue
    pub const FS_GNPTXSTS = Register(FS_GNPTXSTS_val).init(base_address + 0x2c);

    /// FS_GCCFG
    const FS_GCCFG_val = packed struct {
        /// unused [0:15]
        _unused0: u8 = 0,
        _unused8: u8 = 0,
        /// PWRDWN [16:16]
        /// Power down
        PWRDWN: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// VBUSASEN [18:18]
        /// Enable the VBUS sensing
        VBUSASEN: u1 = 0,
        /// VBUSBSEN [19:19]
        /// Enable the VBUS sensing
        VBUSBSEN: u1 = 0,
        /// SOFOUTEN [20:20]
        /// SOF output enable
        SOFOUTEN: u1 = 0,
        /// unused [21:31]
        _unused21: u3 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS general core configuration register
    pub const FS_GCCFG = Register(FS_GCCFG_val).init(base_address + 0x38);

    /// FS_CID
    const FS_CID_val = packed struct {
        /// PRODUCT_ID [0:31]
        /// Product ID field
        PRODUCT_ID: u32 = 4096,
    };
    /// core ID register
    pub const FS_CID = Register(FS_CID_val).init(base_address + 0x3c);

    /// FS_HPTXFSIZ
    const FS_HPTXFSIZ_val = packed struct {
        /// PTXSA [0:15]
        /// Host periodic TxFIFO start
        PTXSA: u16 = 1536,
        /// PTXFSIZ [16:31]
        /// Host periodic TxFIFO depth
        PTXFSIZ: u16 = 512,
    };
    /// OTG_FS Host periodic transmit FIFO size
    pub const FS_HPTXFSIZ = Register(FS_HPTXFSIZ_val).init(base_address + 0x100);

    /// FS_DIEPTXF1
    const FS_DIEPTXF1_val = packed struct {
        /// INEPTXSA [0:15]
        /// IN endpoint FIFO2 transmit RAM start
        INEPTXSA: u16 = 1024,
        /// INEPTXFD [16:31]
        /// IN endpoint TxFIFO depth
        INEPTXFD: u16 = 512,
    };
    /// OTG_FS device IN endpoint transmit FIFO size
    pub const FS_DIEPTXF1 = Register(FS_DIEPTXF1_val).init(base_address + 0x104);

    /// FS_DIEPTXF2
    const FS_DIEPTXF2_val = packed struct {
        /// INEPTXSA [0:15]
        /// IN endpoint FIFO3 transmit RAM start
        INEPTXSA: u16 = 1024,
        /// INEPTXFD [16:31]
        /// IN endpoint TxFIFO depth
        INEPTXFD: u16 = 512,
    };
    /// OTG_FS device IN endpoint transmit FIFO size
    pub const FS_DIEPTXF2 = Register(FS_DIEPTXF2_val).init(base_address + 0x108);

    /// FS_DIEPTXF3
    const FS_DIEPTXF3_val = packed struct {
        /// INEPTXSA [0:15]
        /// IN endpoint FIFO4 transmit RAM start
        INEPTXSA: u16 = 1024,
        /// INEPTXFD [16:31]
        /// IN endpoint TxFIFO depth
        INEPTXFD: u16 = 512,
    };
    /// OTG_FS device IN endpoint transmit FIFO size
    pub const FS_DIEPTXF3 = Register(FS_DIEPTXF3_val).init(base_address + 0x10c);
};

/// USB on the go full speed
pub const OTG_FS_HOST = struct {
    const base_address = 0x50000400;
    /// FS_HCFG
    const FS_HCFG_val = packed struct {
        /// FSLSPCS [0:1]
        /// FS/LS PHY clock select
        FSLSPCS: u2 = 0,
        /// FSLSS [2:2]
        /// FS- and LS-only support
        FSLSS: u1 = 0,
        /// unused [3:31]
        _unused3: u5 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host configuration register
    pub const FS_HCFG = Register(FS_HCFG_val).init(base_address + 0x0);

    /// HFIR
    const HFIR_val = packed struct {
        /// FRIVL [0:15]
        /// Frame interval
        FRIVL: u16 = 60000,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS Host frame interval
    pub const HFIR = Register(HFIR_val).init(base_address + 0x4);

    /// FS_HFNUM
    const FS_HFNUM_val = packed struct {
        /// FRNUM [0:15]
        /// Frame number
        FRNUM: u16 = 16383,
        /// FTREM [16:31]
        /// Frame time remaining
        FTREM: u16 = 0,
    };
    /// OTG_FS host frame number/frame time
    pub const FS_HFNUM = Register(FS_HFNUM_val).init(base_address + 0x8);

    /// FS_HPTXSTS
    const FS_HPTXSTS_val = packed struct {
        /// PTXFSAVL [0:15]
        /// Periodic transmit data FIFO space
        PTXFSAVL: u16 = 256,
        /// PTXQSAV [16:23]
        /// Periodic transmit request queue space
        PTXQSAV: u8 = 8,
        /// PTXQTOP [24:31]
        /// Top of the periodic transmit request
        PTXQTOP: u8 = 0,
    };
    /// OTG_FS_Host periodic transmit FIFO/queue
    pub const FS_HPTXSTS = Register(FS_HPTXSTS_val).init(base_address + 0x10);

    /// HAINT
    const HAINT_val = packed struct {
        /// HAINT [0:15]
        /// Channel interrupts
        HAINT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS Host all channels interrupt
    pub const HAINT = Register(HAINT_val).init(base_address + 0x14);

    /// HAINTMSK
    const HAINTMSK_val = packed struct {
        /// HAINTM [0:15]
        /// Channel interrupt mask
        HAINTM: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host all channels interrupt mask
    pub const HAINTMSK = Register(HAINTMSK_val).init(base_address + 0x18);

    /// FS_HPRT
    const FS_HPRT_val = packed struct {
        /// PCSTS [0:0]
        /// Port connect status
        PCSTS: u1 = 0,
        /// PCDET [1:1]
        /// Port connect detected
        PCDET: u1 = 0,
        /// PENA [2:2]
        /// Port enable
        PENA: u1 = 0,
        /// PENCHNG [3:3]
        /// Port enable/disable change
        PENCHNG: u1 = 0,
        /// POCA [4:4]
        /// Port overcurrent active
        POCA: u1 = 0,
        /// POCCHNG [5:5]
        /// Port overcurrent change
        POCCHNG: u1 = 0,
        /// PRES [6:6]
        /// Port resume
        PRES: u1 = 0,
        /// PSUSP [7:7]
        /// Port suspend
        PSUSP: u1 = 0,
        /// PRST [8:8]
        /// Port reset
        PRST: u1 = 0,
        /// unused [9:9]
        _unused9: u1 = 0,
        /// PLSTS [10:11]
        /// Port line status
        PLSTS: u2 = 0,
        /// PPWR [12:12]
        /// Port power
        PPWR: u1 = 0,
        /// PTCTL [13:16]
        /// Port test control
        PTCTL: u4 = 0,
        /// PSPD [17:18]
        /// Port speed
        PSPD: u2 = 0,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host port control and status register
    pub const FS_HPRT = Register(FS_HPRT_val).init(base_address + 0x40);

    /// FS_HCCHAR0
    const FS_HCCHAR0_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-0 characteristics
    pub const FS_HCCHAR0 = Register(FS_HCCHAR0_val).init(base_address + 0x100);

    /// FS_HCCHAR1
    const FS_HCCHAR1_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-1 characteristics
    pub const FS_HCCHAR1 = Register(FS_HCCHAR1_val).init(base_address + 0x120);

    /// FS_HCCHAR2
    const FS_HCCHAR2_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-2 characteristics
    pub const FS_HCCHAR2 = Register(FS_HCCHAR2_val).init(base_address + 0x140);

    /// FS_HCCHAR3
    const FS_HCCHAR3_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-3 characteristics
    pub const FS_HCCHAR3 = Register(FS_HCCHAR3_val).init(base_address + 0x160);

    /// FS_HCCHAR4
    const FS_HCCHAR4_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-4 characteristics
    pub const FS_HCCHAR4 = Register(FS_HCCHAR4_val).init(base_address + 0x180);

    /// FS_HCCHAR5
    const FS_HCCHAR5_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-5 characteristics
    pub const FS_HCCHAR5 = Register(FS_HCCHAR5_val).init(base_address + 0x1a0);

    /// FS_HCCHAR6
    const FS_HCCHAR6_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-6 characteristics
    pub const FS_HCCHAR6 = Register(FS_HCCHAR6_val).init(base_address + 0x1c0);

    /// FS_HCCHAR7
    const FS_HCCHAR7_val = packed struct {
        /// MPSIZ [0:10]
        /// Maximum packet size
        MPSIZ: u11 = 0,
        /// EPNUM [11:14]
        /// Endpoint number
        EPNUM: u4 = 0,
        /// EPDIR [15:15]
        /// Endpoint direction
        EPDIR: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// LSDEV [17:17]
        /// Low-speed device
        LSDEV: u1 = 0,
        /// EPTYP [18:19]
        /// Endpoint type
        EPTYP: u2 = 0,
        /// MCNT [20:21]
        /// Multicount
        MCNT: u2 = 0,
        /// DAD [22:28]
        /// Device address
        DAD: u7 = 0,
        /// ODDFRM [29:29]
        /// Odd frame
        ODDFRM: u1 = 0,
        /// CHDIS [30:30]
        /// Channel disable
        CHDIS: u1 = 0,
        /// CHENA [31:31]
        /// Channel enable
        CHENA: u1 = 0,
    };
    /// OTG_FS host channel-7 characteristics
    pub const FS_HCCHAR7 = Register(FS_HCCHAR7_val).init(base_address + 0x1e0);

    /// FS_HCINT0
    const FS_HCINT0_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-0 interrupt register
    pub const FS_HCINT0 = Register(FS_HCINT0_val).init(base_address + 0x108);

    /// FS_HCINT1
    const FS_HCINT1_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-1 interrupt register
    pub const FS_HCINT1 = Register(FS_HCINT1_val).init(base_address + 0x128);

    /// FS_HCINT2
    const FS_HCINT2_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-2 interrupt register
    pub const FS_HCINT2 = Register(FS_HCINT2_val).init(base_address + 0x148);

    /// FS_HCINT3
    const FS_HCINT3_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-3 interrupt register
    pub const FS_HCINT3 = Register(FS_HCINT3_val).init(base_address + 0x168);

    /// FS_HCINT4
    const FS_HCINT4_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-4 interrupt register
    pub const FS_HCINT4 = Register(FS_HCINT4_val).init(base_address + 0x188);

    /// FS_HCINT5
    const FS_HCINT5_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-5 interrupt register
    pub const FS_HCINT5 = Register(FS_HCINT5_val).init(base_address + 0x1a8);

    /// FS_HCINT6
    const FS_HCINT6_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-6 interrupt register
    pub const FS_HCINT6 = Register(FS_HCINT6_val).init(base_address + 0x1c8);

    /// FS_HCINT7
    const FS_HCINT7_val = packed struct {
        /// XFRC [0:0]
        /// Transfer completed
        XFRC: u1 = 0,
        /// CHH [1:1]
        /// Channel halted
        CHH: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALL [3:3]
        /// STALL response received
        STALL: u1 = 0,
        /// NAK [4:4]
        /// NAK response received
        NAK: u1 = 0,
        /// ACK [5:5]
        /// ACK response received/transmitted
        ACK: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// TXERR [7:7]
        /// Transaction error
        TXERR: u1 = 0,
        /// BBERR [8:8]
        /// Babble error
        BBERR: u1 = 0,
        /// FRMOR [9:9]
        /// Frame overrun
        FRMOR: u1 = 0,
        /// DTERR [10:10]
        /// Data toggle error
        DTERR: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-7 interrupt register
    pub const FS_HCINT7 = Register(FS_HCINT7_val).init(base_address + 0x1e8);

    /// FS_HCINTMSK0
    const FS_HCINTMSK0_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-0 mask register
    pub const FS_HCINTMSK0 = Register(FS_HCINTMSK0_val).init(base_address + 0x10c);

    /// FS_HCINTMSK1
    const FS_HCINTMSK1_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-1 mask register
    pub const FS_HCINTMSK1 = Register(FS_HCINTMSK1_val).init(base_address + 0x12c);

    /// FS_HCINTMSK2
    const FS_HCINTMSK2_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-2 mask register
    pub const FS_HCINTMSK2 = Register(FS_HCINTMSK2_val).init(base_address + 0x14c);

    /// FS_HCINTMSK3
    const FS_HCINTMSK3_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-3 mask register
    pub const FS_HCINTMSK3 = Register(FS_HCINTMSK3_val).init(base_address + 0x16c);

    /// FS_HCINTMSK4
    const FS_HCINTMSK4_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-4 mask register
    pub const FS_HCINTMSK4 = Register(FS_HCINTMSK4_val).init(base_address + 0x18c);

    /// FS_HCINTMSK5
    const FS_HCINTMSK5_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-5 mask register
    pub const FS_HCINTMSK5 = Register(FS_HCINTMSK5_val).init(base_address + 0x1ac);

    /// FS_HCINTMSK6
    const FS_HCINTMSK6_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-6 mask register
    pub const FS_HCINTMSK6 = Register(FS_HCINTMSK6_val).init(base_address + 0x1cc);

    /// FS_HCINTMSK7
    const FS_HCINTMSK7_val = packed struct {
        /// XFRCM [0:0]
        /// Transfer completed mask
        XFRCM: u1 = 0,
        /// CHHM [1:1]
        /// Channel halted mask
        CHHM: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// STALLM [3:3]
        /// STALL response received interrupt
        STALLM: u1 = 0,
        /// NAKM [4:4]
        /// NAK response received interrupt
        NAKM: u1 = 0,
        /// ACKM [5:5]
        /// ACK response received/transmitted
        ACKM: u1 = 0,
        /// NYET [6:6]
        /// response received interrupt
        NYET: u1 = 0,
        /// TXERRM [7:7]
        /// Transaction error mask
        TXERRM: u1 = 0,
        /// BBERRM [8:8]
        /// Babble error mask
        BBERRM: u1 = 0,
        /// FRMORM [9:9]
        /// Frame overrun mask
        FRMORM: u1 = 0,
        /// DTERRM [10:10]
        /// Data toggle error mask
        DTERRM: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS host channel-7 mask register
    pub const FS_HCINTMSK7 = Register(FS_HCINTMSK7_val).init(base_address + 0x1ec);

    /// FS_HCTSIZ0
    const FS_HCTSIZ0_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-0 transfer size
    pub const FS_HCTSIZ0 = Register(FS_HCTSIZ0_val).init(base_address + 0x110);

    /// FS_HCTSIZ1
    const FS_HCTSIZ1_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-1 transfer size
    pub const FS_HCTSIZ1 = Register(FS_HCTSIZ1_val).init(base_address + 0x130);

    /// FS_HCTSIZ2
    const FS_HCTSIZ2_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-2 transfer size
    pub const FS_HCTSIZ2 = Register(FS_HCTSIZ2_val).init(base_address + 0x150);

    /// FS_HCTSIZ3
    const FS_HCTSIZ3_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-3 transfer size
    pub const FS_HCTSIZ3 = Register(FS_HCTSIZ3_val).init(base_address + 0x170);

    /// FS_HCTSIZ4
    const FS_HCTSIZ4_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-x transfer size
    pub const FS_HCTSIZ4 = Register(FS_HCTSIZ4_val).init(base_address + 0x190);

    /// FS_HCTSIZ5
    const FS_HCTSIZ5_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-5 transfer size
    pub const FS_HCTSIZ5 = Register(FS_HCTSIZ5_val).init(base_address + 0x1b0);

    /// FS_HCTSIZ6
    const FS_HCTSIZ6_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-6 transfer size
    pub const FS_HCTSIZ6 = Register(FS_HCTSIZ6_val).init(base_address + 0x1d0);

    /// FS_HCTSIZ7
    const FS_HCTSIZ7_val = packed struct {
        /// XFRSIZ [0:18]
        /// Transfer size
        XFRSIZ: u19 = 0,
        /// PKTCNT [19:28]
        /// Packet count
        PKTCNT: u10 = 0,
        /// DPID [29:30]
        /// Data PID
        DPID: u2 = 0,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// OTG_FS host channel-7 transfer size
    pub const FS_HCTSIZ7 = Register(FS_HCTSIZ7_val).init(base_address + 0x1f0);
};

/// USB on the go full speed
pub const OTG_FS_PWRCLK = struct {
    const base_address = 0x50000e00;
    /// FS_PCGCCTL
    const FS_PCGCCTL_val = packed struct {
        /// STPPCLK [0:0]
        /// Stop PHY clock
        STPPCLK: u1 = 0,
        /// GATEHCLK [1:1]
        /// Gate HCLK
        GATEHCLK: u1 = 0,
        /// unused [2:3]
        _unused2: u2 = 0,
        /// PHYSUSP [4:4]
        /// PHY Suspended
        PHYSUSP: u1 = 0,
        /// unused [5:31]
        _unused5: u3 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// OTG_FS power and clock gating control
    pub const FS_PCGCCTL = Register(FS_PCGCCTL_val).init(base_address + 0x0);
};

/// Power control
pub const PWR = struct {
    const base_address = 0x40007000;
    /// CR
    const CR_val = packed struct {
        /// LPDS [0:0]
        /// Low-power deep sleep
        LPDS: u1 = 0,
        /// PDDS [1:1]
        /// Power down deepsleep
        PDDS: u1 = 0,
        /// CWUF [2:2]
        /// Clear wakeup flag
        CWUF: u1 = 0,
        /// CSBF [3:3]
        /// Clear standby flag
        CSBF: u1 = 0,
        /// PVDE [4:4]
        /// Power voltage detector
        PVDE: u1 = 0,
        /// PLS [5:7]
        /// PVD level selection
        PLS: u3 = 0,
        /// DBP [8:8]
        /// Disable backup domain write
        DBP: u1 = 0,
        /// FPDS [9:9]
        /// Flash power down in Stop
        FPDS: u1 = 0,
        /// unused [10:12]
        _unused10: u3 = 0,
        /// ADCDC1 [13:13]
        /// ADCDC1
        ADCDC1: u1 = 0,
        /// VOS [14:15]
        /// Regulator voltage scaling output
        VOS: u2 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// power control register
    pub const CR = Register(CR_val).init(base_address + 0x0);

    /// CSR
    const CSR_val = packed struct {
        /// WUF [0:0]
        /// Wakeup flag
        WUF: u1 = 0,
        /// SBF [1:1]
        /// Standby flag
        SBF: u1 = 0,
        /// PVDO [2:2]
        /// PVD output
        PVDO: u1 = 0,
        /// BRR [3:3]
        /// Backup regulator ready
        BRR: u1 = 0,
        /// unused [4:7]
        _unused4: u4 = 0,
        /// EWUP [8:8]
        /// Enable WKUP pin
        EWUP: u1 = 0,
        /// BRE [9:9]
        /// Backup regulator enable
        BRE: u1 = 0,
        /// unused [10:13]
        _unused10: u4 = 0,
        /// VOSRDY [14:14]
        /// Regulator voltage scaling output
        VOSRDY: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// power control/status register
    pub const CSR = Register(CSR_val).init(base_address + 0x4);
};

/// Reset and clock control
pub const RCC = struct {
    const base_address = 0x40023800;
    /// CR
    const CR_val = packed struct {
        /// HSION [0:0]
        /// Internal high-speed clock
        HSION: u1 = 1,
        /// HSIRDY [1:1]
        /// Internal high-speed clock ready
        HSIRDY: u1 = 1,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// HSITRIM [3:7]
        /// Internal high-speed clock
        HSITRIM: u5 = 16,
        /// HSICAL [8:15]
        /// Internal high-speed clock
        HSICAL: u8 = 0,
        /// HSEON [16:16]
        /// HSE clock enable
        HSEON: u1 = 0,
        /// HSERDY [17:17]
        /// HSE clock ready flag
        HSERDY: u1 = 0,
        /// HSEBYP [18:18]
        /// HSE clock bypass
        HSEBYP: u1 = 0,
        /// CSSON [19:19]
        /// Clock security system
        CSSON: u1 = 0,
        /// unused [20:23]
        _unused20: u4 = 0,
        /// PLLON [24:24]
        /// Main PLL (PLL) enable
        PLLON: u1 = 0,
        /// PLLRDY [25:25]
        /// Main PLL (PLL) clock ready
        PLLRDY: u1 = 0,
        /// PLLI2SON [26:26]
        /// PLLI2S enable
        PLLI2SON: u1 = 0,
        /// PLLI2SRDY [27:27]
        /// PLLI2S clock ready flag
        PLLI2SRDY: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// clock control register
    pub const CR = Register(CR_val).init(base_address + 0x0);

    /// PLLCFGR
    const PLLCFGR_val = packed struct {
        /// PLLM0 [0:0]
        /// Division factor for the main PLL (PLL)
        PLLM0: u1 = 0,
        /// PLLM1 [1:1]
        /// Division factor for the main PLL (PLL)
        PLLM1: u1 = 0,
        /// PLLM2 [2:2]
        /// Division factor for the main PLL (PLL)
        PLLM2: u1 = 0,
        /// PLLM3 [3:3]
        /// Division factor for the main PLL (PLL)
        PLLM3: u1 = 0,
        /// PLLM4 [4:4]
        /// Division factor for the main PLL (PLL)
        PLLM4: u1 = 1,
        /// PLLM5 [5:5]
        /// Division factor for the main PLL (PLL)
        PLLM5: u1 = 0,
        /// PLLN0 [6:6]
        /// Main PLL (PLL) multiplication factor for
        PLLN0: u1 = 0,
        /// PLLN1 [7:7]
        /// Main PLL (PLL) multiplication factor for
        PLLN1: u1 = 0,
        /// PLLN2 [8:8]
        /// Main PLL (PLL) multiplication factor for
        PLLN2: u1 = 0,
        /// PLLN3 [9:9]
        /// Main PLL (PLL) multiplication factor for
        PLLN3: u1 = 0,
        /// PLLN4 [10:10]
        /// Main PLL (PLL) multiplication factor for
        PLLN4: u1 = 0,
        /// PLLN5 [11:11]
        /// Main PLL (PLL) multiplication factor for
        PLLN5: u1 = 0,
        /// PLLN6 [12:12]
        /// Main PLL (PLL) multiplication factor for
        PLLN6: u1 = 1,
        /// PLLN7 [13:13]
        /// Main PLL (PLL) multiplication factor for
        PLLN7: u1 = 1,
        /// PLLN8 [14:14]
        /// Main PLL (PLL) multiplication factor for
        PLLN8: u1 = 0,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// PLLP0 [16:16]
        /// Main PLL (PLL) division factor for main
        PLLP0: u1 = 0,
        /// PLLP1 [17:17]
        /// Main PLL (PLL) division factor for main
        PLLP1: u1 = 0,
        /// unused [18:21]
        _unused18: u4 = 0,
        /// PLLSRC [22:22]
        /// Main PLL(PLL) and audio PLL (PLLI2S)
        PLLSRC: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// PLLQ0 [24:24]
        /// Main PLL (PLL) division factor for USB
        PLLQ0: u1 = 0,
        /// PLLQ1 [25:25]
        /// Main PLL (PLL) division factor for USB
        PLLQ1: u1 = 0,
        /// PLLQ2 [26:26]
        /// Main PLL (PLL) division factor for USB
        PLLQ2: u1 = 1,
        /// PLLQ3 [27:27]
        /// Main PLL (PLL) division factor for USB
        PLLQ3: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 2,
    };
    /// PLL configuration register
    pub const PLLCFGR = Register(PLLCFGR_val).init(base_address + 0x4);

    /// CFGR
    const CFGR_val = packed struct {
        /// SW0 [0:0]
        /// System clock switch
        SW0: u1 = 0,
        /// SW1 [1:1]
        /// System clock switch
        SW1: u1 = 0,
        /// SWS0 [2:2]
        /// System clock switch status
        SWS0: u1 = 0,
        /// SWS1 [3:3]
        /// System clock switch status
        SWS1: u1 = 0,
        /// HPRE [4:7]
        /// AHB prescaler
        HPRE: u4 = 0,
        /// unused [8:9]
        _unused8: u2 = 0,
        /// PPRE1 [10:12]
        /// APB Low speed prescaler
        PPRE1: u3 = 0,
        /// PPRE2 [13:15]
        /// APB high-speed prescaler
        PPRE2: u3 = 0,
        /// RTCPRE [16:20]
        /// HSE division factor for RTC
        RTCPRE: u5 = 0,
        /// MCO1 [21:22]
        /// Microcontroller clock output
        MCO1: u2 = 0,
        /// I2SSRC [23:23]
        /// I2S clock selection
        I2SSRC: u1 = 0,
        /// MCO1PRE [24:26]
        /// MCO1 prescaler
        MCO1PRE: u3 = 0,
        /// MCO2PRE [27:29]
        /// MCO2 prescaler
        MCO2PRE: u3 = 0,
        /// MCO2 [30:31]
        /// Microcontroller clock output
        MCO2: u2 = 0,
    };
    /// clock configuration register
    pub const CFGR = Register(CFGR_val).init(base_address + 0x8);

    /// CIR
    const CIR_val = packed struct {
        /// LSIRDYF [0:0]
        /// LSI ready interrupt flag
        LSIRDYF: u1 = 0,
        /// LSERDYF [1:1]
        /// LSE ready interrupt flag
        LSERDYF: u1 = 0,
        /// HSIRDYF [2:2]
        /// HSI ready interrupt flag
        HSIRDYF: u1 = 0,
        /// HSERDYF [3:3]
        /// HSE ready interrupt flag
        HSERDYF: u1 = 0,
        /// PLLRDYF [4:4]
        /// Main PLL (PLL) ready interrupt
        PLLRDYF: u1 = 0,
        /// PLLI2SRDYF [5:5]
        /// PLLI2S ready interrupt
        PLLI2SRDYF: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// CSSF [7:7]
        /// Clock security system interrupt
        CSSF: u1 = 0,
        /// LSIRDYIE [8:8]
        /// LSI ready interrupt enable
        LSIRDYIE: u1 = 0,
        /// LSERDYIE [9:9]
        /// LSE ready interrupt enable
        LSERDYIE: u1 = 0,
        /// HSIRDYIE [10:10]
        /// HSI ready interrupt enable
        HSIRDYIE: u1 = 0,
        /// HSERDYIE [11:11]
        /// HSE ready interrupt enable
        HSERDYIE: u1 = 0,
        /// PLLRDYIE [12:12]
        /// Main PLL (PLL) ready interrupt
        PLLRDYIE: u1 = 0,
        /// PLLI2SRDYIE [13:13]
        /// PLLI2S ready interrupt
        PLLI2SRDYIE: u1 = 0,
        /// unused [14:15]
        _unused14: u2 = 0,
        /// LSIRDYC [16:16]
        /// LSI ready interrupt clear
        LSIRDYC: u1 = 0,
        /// LSERDYC [17:17]
        /// LSE ready interrupt clear
        LSERDYC: u1 = 0,
        /// HSIRDYC [18:18]
        /// HSI ready interrupt clear
        HSIRDYC: u1 = 0,
        /// HSERDYC [19:19]
        /// HSE ready interrupt clear
        HSERDYC: u1 = 0,
        /// PLLRDYC [20:20]
        /// Main PLL(PLL) ready interrupt
        PLLRDYC: u1 = 0,
        /// PLLI2SRDYC [21:21]
        /// PLLI2S ready interrupt
        PLLI2SRDYC: u1 = 0,
        /// unused [22:22]
        _unused22: u1 = 0,
        /// CSSC [23:23]
        /// Clock security system interrupt
        CSSC: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// clock interrupt register
    pub const CIR = Register(CIR_val).init(base_address + 0xc);

    /// AHB1RSTR
    const AHB1RSTR_val = packed struct {
        /// GPIOARST [0:0]
        /// IO port A reset
        GPIOARST: u1 = 0,
        /// GPIOBRST [1:1]
        /// IO port B reset
        GPIOBRST: u1 = 0,
        /// GPIOCRST [2:2]
        /// IO port C reset
        GPIOCRST: u1 = 0,
        /// GPIODRST [3:3]
        /// IO port D reset
        GPIODRST: u1 = 0,
        /// GPIOERST [4:4]
        /// IO port E reset
        GPIOERST: u1 = 0,
        /// unused [5:6]
        _unused5: u2 = 0,
        /// GPIOHRST [7:7]
        /// IO port H reset
        GPIOHRST: u1 = 0,
        /// unused [8:11]
        _unused8: u4 = 0,
        /// CRCRST [12:12]
        /// CRC reset
        CRCRST: u1 = 0,
        /// unused [13:20]
        _unused13: u3 = 0,
        _unused16: u5 = 0,
        /// DMA1RST [21:21]
        /// DMA2 reset
        DMA1RST: u1 = 0,
        /// DMA2RST [22:22]
        /// DMA2 reset
        DMA2RST: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// AHB1 peripheral reset register
    pub const AHB1RSTR = Register(AHB1RSTR_val).init(base_address + 0x10);

    /// AHB2RSTR
    const AHB2RSTR_val = packed struct {
        /// unused [0:6]
        _unused0: u7 = 0,
        /// OTGFSRST [7:7]
        /// USB OTG FS module reset
        OTGFSRST: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// AHB2 peripheral reset register
    pub const AHB2RSTR = Register(AHB2RSTR_val).init(base_address + 0x14);

    /// APB1RSTR
    const APB1RSTR_val = packed struct {
        /// TIM2RST [0:0]
        /// TIM2 reset
        TIM2RST: u1 = 0,
        /// TIM3RST [1:1]
        /// TIM3 reset
        TIM3RST: u1 = 0,
        /// TIM4RST [2:2]
        /// TIM4 reset
        TIM4RST: u1 = 0,
        /// TIM5RST [3:3]
        /// TIM5 reset
        TIM5RST: u1 = 0,
        /// unused [4:10]
        _unused4: u4 = 0,
        _unused8: u3 = 0,
        /// WWDGRST [11:11]
        /// Window watchdog reset
        WWDGRST: u1 = 0,
        /// unused [12:13]
        _unused12: u2 = 0,
        /// SPI2RST [14:14]
        /// SPI 2 reset
        SPI2RST: u1 = 0,
        /// SPI3RST [15:15]
        /// SPI 3 reset
        SPI3RST: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// UART2RST [17:17]
        /// USART 2 reset
        UART2RST: u1 = 0,
        /// unused [18:20]
        _unused18: u3 = 0,
        /// I2C1RST [21:21]
        /// I2C 1 reset
        I2C1RST: u1 = 0,
        /// I2C2RST [22:22]
        /// I2C 2 reset
        I2C2RST: u1 = 0,
        /// I2C3RST [23:23]
        /// I2C3 reset
        I2C3RST: u1 = 0,
        /// unused [24:27]
        _unused24: u4 = 0,
        /// PWRRST [28:28]
        /// Power interface reset
        PWRRST: u1 = 0,
        /// unused [29:31]
        _unused29: u3 = 0,
    };
    /// APB1 peripheral reset register
    pub const APB1RSTR = Register(APB1RSTR_val).init(base_address + 0x20);

    /// APB2RSTR
    const APB2RSTR_val = packed struct {
        /// TIM1RST [0:0]
        /// TIM1 reset
        TIM1RST: u1 = 0,
        /// unused [1:3]
        _unused1: u3 = 0,
        /// USART1RST [4:4]
        /// USART1 reset
        USART1RST: u1 = 0,
        /// USART6RST [5:5]
        /// USART6 reset
        USART6RST: u1 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// ADCRST [8:8]
        /// ADC interface reset (common to all
        ADCRST: u1 = 0,
        /// unused [9:10]
        _unused9: u2 = 0,
        /// SDIORST [11:11]
        /// SDIO reset
        SDIORST: u1 = 0,
        /// SPI1RST [12:12]
        /// SPI 1 reset
        SPI1RST: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// SYSCFGRST [14:14]
        /// System configuration controller
        SYSCFGRST: u1 = 0,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// TIM9RST [16:16]
        /// TIM9 reset
        TIM9RST: u1 = 0,
        /// TIM10RST [17:17]
        /// TIM10 reset
        TIM10RST: u1 = 0,
        /// TIM11RST [18:18]
        /// TIM11 reset
        TIM11RST: u1 = 0,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// APB2 peripheral reset register
    pub const APB2RSTR = Register(APB2RSTR_val).init(base_address + 0x24);

    /// AHB1ENR
    const AHB1ENR_val = packed struct {
        /// GPIOAEN [0:0]
        /// IO port A clock enable
        GPIOAEN: u1 = 0,
        /// GPIOBEN [1:1]
        /// IO port B clock enable
        GPIOBEN: u1 = 0,
        /// GPIOCEN [2:2]
        /// IO port C clock enable
        GPIOCEN: u1 = 0,
        /// GPIODEN [3:3]
        /// IO port D clock enable
        GPIODEN: u1 = 0,
        /// GPIOEEN [4:4]
        /// IO port E clock enable
        GPIOEEN: u1 = 0,
        /// unused [5:6]
        _unused5: u2 = 0,
        /// GPIOHEN [7:7]
        /// IO port H clock enable
        GPIOHEN: u1 = 0,
        /// unused [8:11]
        _unused8: u4 = 0,
        /// CRCEN [12:12]
        /// CRC clock enable
        CRCEN: u1 = 0,
        /// unused [13:20]
        _unused13: u3 = 0,
        _unused16: u5 = 16,
        /// DMA1EN [21:21]
        /// DMA1 clock enable
        DMA1EN: u1 = 0,
        /// DMA2EN [22:22]
        /// DMA2 clock enable
        DMA2EN: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// AHB1 peripheral clock register
    pub const AHB1ENR = Register(AHB1ENR_val).init(base_address + 0x30);

    /// AHB2ENR
    const AHB2ENR_val = packed struct {
        /// unused [0:6]
        _unused0: u7 = 0,
        /// OTGFSEN [7:7]
        /// USB OTG FS clock enable
        OTGFSEN: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// AHB2 peripheral clock enable
    pub const AHB2ENR = Register(AHB2ENR_val).init(base_address + 0x34);

    /// APB1ENR
    const APB1ENR_val = packed struct {
        /// TIM2EN [0:0]
        /// TIM2 clock enable
        TIM2EN: u1 = 0,
        /// TIM3EN [1:1]
        /// TIM3 clock enable
        TIM3EN: u1 = 0,
        /// TIM4EN [2:2]
        /// TIM4 clock enable
        TIM4EN: u1 = 0,
        /// TIM5EN [3:3]
        /// TIM5 clock enable
        TIM5EN: u1 = 0,
        /// unused [4:10]
        _unused4: u4 = 0,
        _unused8: u3 = 0,
        /// WWDGEN [11:11]
        /// Window watchdog clock
        WWDGEN: u1 = 0,
        /// unused [12:13]
        _unused12: u2 = 0,
        /// SPI2EN [14:14]
        /// SPI2 clock enable
        SPI2EN: u1 = 0,
        /// SPI3EN [15:15]
        /// SPI3 clock enable
        SPI3EN: u1 = 0,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// USART2EN [17:17]
        /// USART 2 clock enable
        USART2EN: u1 = 0,
        /// unused [18:20]
        _unused18: u3 = 0,
        /// I2C1EN [21:21]
        /// I2C1 clock enable
        I2C1EN: u1 = 0,
        /// I2C2EN [22:22]
        /// I2C2 clock enable
        I2C2EN: u1 = 0,
        /// I2C3EN [23:23]
        /// I2C3 clock enable
        I2C3EN: u1 = 0,
        /// unused [24:27]
        _unused24: u4 = 0,
        /// PWREN [28:28]
        /// Power interface clock
        PWREN: u1 = 0,
        /// unused [29:31]
        _unused29: u3 = 0,
    };
    /// APB1 peripheral clock enable
    pub const APB1ENR = Register(APB1ENR_val).init(base_address + 0x40);

    /// APB2ENR
    const APB2ENR_val = packed struct {
        /// TIM1EN [0:0]
        /// TIM1 clock enable
        TIM1EN: u1 = 0,
        /// unused [1:3]
        _unused1: u3 = 0,
        /// USART1EN [4:4]
        /// USART1 clock enable
        USART1EN: u1 = 0,
        /// USART6EN [5:5]
        /// USART6 clock enable
        USART6EN: u1 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// ADC1EN [8:8]
        /// ADC1 clock enable
        ADC1EN: u1 = 0,
        /// unused [9:10]
        _unused9: u2 = 0,
        /// SDIOEN [11:11]
        /// SDIO clock enable
        SDIOEN: u1 = 0,
        /// SPI1EN [12:12]
        /// SPI1 clock enable
        SPI1EN: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// SYSCFGEN [14:14]
        /// System configuration controller clock
        SYSCFGEN: u1 = 0,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// TIM9EN [16:16]
        /// TIM9 clock enable
        TIM9EN: u1 = 0,
        /// TIM10EN [17:17]
        /// TIM10 clock enable
        TIM10EN: u1 = 0,
        /// TIM11EN [18:18]
        /// TIM11 clock enable
        TIM11EN: u1 = 0,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// APB2 peripheral clock enable
    pub const APB2ENR = Register(APB2ENR_val).init(base_address + 0x44);

    /// AHB1LPENR
    const AHB1LPENR_val = packed struct {
        /// GPIOALPEN [0:0]
        /// IO port A clock enable during sleep
        GPIOALPEN: u1 = 1,
        /// GPIOBLPEN [1:1]
        /// IO port B clock enable during Sleep
        GPIOBLPEN: u1 = 1,
        /// GPIOCLPEN [2:2]
        /// IO port C clock enable during Sleep
        GPIOCLPEN: u1 = 1,
        /// GPIODLPEN [3:3]
        /// IO port D clock enable during Sleep
        GPIODLPEN: u1 = 1,
        /// GPIOELPEN [4:4]
        /// IO port E clock enable during Sleep
        GPIOELPEN: u1 = 1,
        /// unused [5:6]
        _unused5: u2 = 3,
        /// GPIOHLPEN [7:7]
        /// IO port H clock enable during Sleep
        GPIOHLPEN: u1 = 1,
        /// unused [8:11]
        _unused8: u4 = 1,
        /// CRCLPEN [12:12]
        /// CRC clock enable during Sleep
        CRCLPEN: u1 = 1,
        /// unused [13:14]
        _unused13: u2 = 0,
        /// FLITFLPEN [15:15]
        /// Flash interface clock enable during
        FLITFLPEN: u1 = 1,
        /// SRAM1LPEN [16:16]
        /// SRAM 1interface clock enable during
        SRAM1LPEN: u1 = 1,
        /// unused [17:20]
        _unused17: u4 = 3,
        /// DMA1LPEN [21:21]
        /// DMA1 clock enable during Sleep
        DMA1LPEN: u1 = 1,
        /// DMA2LPEN [22:22]
        /// DMA2 clock enable during Sleep
        DMA2LPEN: u1 = 1,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 126,
    };
    /// AHB1 peripheral clock enable in low power
    pub const AHB1LPENR = Register(AHB1LPENR_val).init(base_address + 0x50);

    /// AHB2LPENR
    const AHB2LPENR_val = packed struct {
        /// unused [0:6]
        _unused0: u7 = 113,
        /// OTGFSLPEN [7:7]
        /// USB OTG FS clock enable during Sleep
        OTGFSLPEN: u1 = 1,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// AHB2 peripheral clock enable in low power
    pub const AHB2LPENR = Register(AHB2LPENR_val).init(base_address + 0x54);

    /// APB1LPENR
    const APB1LPENR_val = packed struct {
        /// TIM2LPEN [0:0]
        /// TIM2 clock enable during Sleep
        TIM2LPEN: u1 = 1,
        /// TIM3LPEN [1:1]
        /// TIM3 clock enable during Sleep
        TIM3LPEN: u1 = 1,
        /// TIM4LPEN [2:2]
        /// TIM4 clock enable during Sleep
        TIM4LPEN: u1 = 1,
        /// TIM5LPEN [3:3]
        /// TIM5 clock enable during Sleep
        TIM5LPEN: u1 = 1,
        /// unused [4:10]
        _unused4: u4 = 15,
        _unused8: u3 = 1,
        /// WWDGLPEN [11:11]
        /// Window watchdog clock enable during
        WWDGLPEN: u1 = 1,
        /// unused [12:13]
        _unused12: u2 = 0,
        /// SPI2LPEN [14:14]
        /// SPI2 clock enable during Sleep
        SPI2LPEN: u1 = 1,
        /// SPI3LPEN [15:15]
        /// SPI3 clock enable during Sleep
        SPI3LPEN: u1 = 1,
        /// unused [16:16]
        _unused16: u1 = 0,
        /// USART2LPEN [17:17]
        /// USART2 clock enable during Sleep
        USART2LPEN: u1 = 1,
        /// unused [18:20]
        _unused18: u3 = 7,
        /// I2C1LPEN [21:21]
        /// I2C1 clock enable during Sleep
        I2C1LPEN: u1 = 1,
        /// I2C2LPEN [22:22]
        /// I2C2 clock enable during Sleep
        I2C2LPEN: u1 = 1,
        /// I2C3LPEN [23:23]
        /// I2C3 clock enable during Sleep
        I2C3LPEN: u1 = 1,
        /// unused [24:27]
        _unused24: u4 = 6,
        /// PWRLPEN [28:28]
        /// Power interface clock enable during
        PWRLPEN: u1 = 1,
        /// unused [29:31]
        _unused29: u3 = 1,
    };
    /// APB1 peripheral clock enable in low power
    pub const APB1LPENR = Register(APB1LPENR_val).init(base_address + 0x60);

    /// APB2LPENR
    const APB2LPENR_val = packed struct {
        /// TIM1LPEN [0:0]
        /// TIM1 clock enable during Sleep
        TIM1LPEN: u1 = 1,
        /// unused [1:3]
        _unused1: u3 = 1,
        /// USART1LPEN [4:4]
        /// USART1 clock enable during Sleep
        USART1LPEN: u1 = 1,
        /// USART6LPEN [5:5]
        /// USART6 clock enable during Sleep
        USART6LPEN: u1 = 1,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// ADC1LPEN [8:8]
        /// ADC1 clock enable during Sleep
        ADC1LPEN: u1 = 1,
        /// unused [9:10]
        _unused9: u2 = 3,
        /// SDIOLPEN [11:11]
        /// SDIO clock enable during Sleep
        SDIOLPEN: u1 = 1,
        /// SPI1LPEN [12:12]
        /// SPI 1 clock enable during Sleep
        SPI1LPEN: u1 = 1,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// SYSCFGLPEN [14:14]
        /// System configuration controller clock
        SYSCFGLPEN: u1 = 1,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// TIM9LPEN [16:16]
        /// TIM9 clock enable during sleep
        TIM9LPEN: u1 = 1,
        /// TIM10LPEN [17:17]
        /// TIM10 clock enable during Sleep
        TIM10LPEN: u1 = 1,
        /// TIM11LPEN [18:18]
        /// TIM11 clock enable during Sleep
        TIM11LPEN: u1 = 1,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// APB2 peripheral clock enabled in low power
    pub const APB2LPENR = Register(APB2LPENR_val).init(base_address + 0x64);

    /// BDCR
    const BDCR_val = packed struct {
        /// LSEON [0:0]
        /// External low-speed oscillator
        LSEON: u1 = 0,
        /// LSERDY [1:1]
        /// External low-speed oscillator
        LSERDY: u1 = 0,
        /// LSEBYP [2:2]
        /// External low-speed oscillator
        LSEBYP: u1 = 0,
        /// unused [3:7]
        _unused3: u5 = 0,
        /// RTCSEL0 [8:8]
        /// RTC clock source selection
        RTCSEL0: u1 = 0,
        /// RTCSEL1 [9:9]
        /// RTC clock source selection
        RTCSEL1: u1 = 0,
        /// unused [10:14]
        _unused10: u5 = 0,
        /// RTCEN [15:15]
        /// RTC clock enable
        RTCEN: u1 = 0,
        /// BDRST [16:16]
        /// Backup domain software
        BDRST: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// Backup domain control register
    pub const BDCR = Register(BDCR_val).init(base_address + 0x70);

    /// CSR
    const CSR_val = packed struct {
        /// LSION [0:0]
        /// Internal low-speed oscillator
        LSION: u1 = 0,
        /// LSIRDY [1:1]
        /// Internal low-speed oscillator
        LSIRDY: u1 = 0,
        /// unused [2:23]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        /// RMVF [24:24]
        /// Remove reset flag
        RMVF: u1 = 0,
        /// BORRSTF [25:25]
        /// BOR reset flag
        BORRSTF: u1 = 1,
        /// PADRSTF [26:26]
        /// PIN reset flag
        PADRSTF: u1 = 1,
        /// PORRSTF [27:27]
        /// POR/PDR reset flag
        PORRSTF: u1 = 1,
        /// SFTRSTF [28:28]
        /// Software reset flag
        SFTRSTF: u1 = 0,
        /// WDGRSTF [29:29]
        /// Independent watchdog reset
        WDGRSTF: u1 = 0,
        /// WWDGRSTF [30:30]
        /// Window watchdog reset flag
        WWDGRSTF: u1 = 0,
        /// LPWRRSTF [31:31]
        /// Low-power reset flag
        LPWRRSTF: u1 = 0,
    };
    /// clock control &amp; status
    pub const CSR = Register(CSR_val).init(base_address + 0x74);

    /// SSCGR
    const SSCGR_val = packed struct {
        /// MODPER [0:12]
        /// Modulation period
        MODPER: u13 = 0,
        /// INCSTEP [13:27]
        /// Incrementation step
        INCSTEP: u15 = 0,
        /// unused [28:29]
        _unused28: u2 = 0,
        /// SPREADSEL [30:30]
        /// Spread Select
        SPREADSEL: u1 = 0,
        /// SSCGEN [31:31]
        /// Spread spectrum modulation
        SSCGEN: u1 = 0,
    };
    /// spread spectrum clock generation
    pub const SSCGR = Register(SSCGR_val).init(base_address + 0x80);

    /// PLLI2SCFGR
    const PLLI2SCFGR_val = packed struct {
        /// unused [0:5]
        _unused0: u6 = 0,
        /// PLLI2SNx [6:14]
        /// PLLI2S multiplication factor for
        PLLI2SNx: u9 = 192,
        /// unused [15:27]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u4 = 0,
        /// PLLI2SRx [28:30]
        /// PLLI2S division factor for I2S
        PLLI2SRx: u3 = 2,
        /// unused [31:31]
        _unused31: u1 = 0,
    };
    /// PLLI2S configuration register
    pub const PLLI2SCFGR = Register(PLLI2SCFGR_val).init(base_address + 0x84);
};

/// Real-time clock
pub const RTC = struct {
    const base_address = 0x40002800;
    /// TR
    const TR_val = packed struct {
        /// SU [0:3]
        /// Second units in BCD format
        SU: u4 = 0,
        /// ST [4:6]
        /// Second tens in BCD format
        ST: u3 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// MNU [8:11]
        /// Minute units in BCD format
        MNU: u4 = 0,
        /// MNT [12:14]
        /// Minute tens in BCD format
        MNT: u3 = 0,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// HU [16:19]
        /// Hour units in BCD format
        HU: u4 = 0,
        /// HT [20:21]
        /// Hour tens in BCD format
        HT: u2 = 0,
        /// PM [22:22]
        /// AM/PM notation
        PM: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// time register
    pub const TR = Register(TR_val).init(base_address + 0x0);

    /// DR
    const DR_val = packed struct {
        /// DU [0:3]
        /// Date units in BCD format
        DU: u4 = 1,
        /// DT [4:5]
        /// Date tens in BCD format
        DT: u2 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// MU [8:11]
        /// Month units in BCD format
        MU: u4 = 1,
        /// MT [12:12]
        /// Month tens in BCD format
        MT: u1 = 0,
        /// WDU [13:15]
        /// Week day units
        WDU: u3 = 1,
        /// YU [16:19]
        /// Year units in BCD format
        YU: u4 = 0,
        /// YT [20:23]
        /// Year tens in BCD format
        YT: u4 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// date register
    pub const DR = Register(DR_val).init(base_address + 0x4);

    /// CR
    const CR_val = packed struct {
        /// WCKSEL [0:2]
        /// Wakeup clock selection
        WCKSEL: u3 = 0,
        /// TSEDGE [3:3]
        /// Time-stamp event active
        TSEDGE: u1 = 0,
        /// REFCKON [4:4]
        /// Reference clock detection enable (50 or
        REFCKON: u1 = 0,
        /// BYPSHAD [5:5]
        /// Bypass the shadow
        BYPSHAD: u1 = 0,
        /// FMT [6:6]
        /// Hour format
        FMT: u1 = 0,
        /// DCE [7:7]
        /// Coarse digital calibration
        DCE: u1 = 0,
        /// ALRAE [8:8]
        /// Alarm A enable
        ALRAE: u1 = 0,
        /// ALRBE [9:9]
        /// Alarm B enable
        ALRBE: u1 = 0,
        /// WUTE [10:10]
        /// Wakeup timer enable
        WUTE: u1 = 0,
        /// TSE [11:11]
        /// Time stamp enable
        TSE: u1 = 0,
        /// ALRAIE [12:12]
        /// Alarm A interrupt enable
        ALRAIE: u1 = 0,
        /// ALRBIE [13:13]
        /// Alarm B interrupt enable
        ALRBIE: u1 = 0,
        /// WUTIE [14:14]
        /// Wakeup timer interrupt
        WUTIE: u1 = 0,
        /// TSIE [15:15]
        /// Time-stamp interrupt
        TSIE: u1 = 0,
        /// ADD1H [16:16]
        /// Add 1 hour (summer time
        ADD1H: u1 = 0,
        /// SUB1H [17:17]
        /// Subtract 1 hour (winter time
        SUB1H: u1 = 0,
        /// BKP [18:18]
        /// Backup
        BKP: u1 = 0,
        /// COSEL [19:19]
        /// Calibration Output
        COSEL: u1 = 0,
        /// POL [20:20]
        /// Output polarity
        POL: u1 = 0,
        /// OSEL [21:22]
        /// Output selection
        OSEL: u2 = 0,
        /// COE [23:23]
        /// Calibration output enable
        COE: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// control register
    pub const CR = Register(CR_val).init(base_address + 0x8);

    /// ISR
    const ISR_val = packed struct {
        /// ALRAWF [0:0]
        /// Alarm A write flag
        ALRAWF: u1 = 1,
        /// ALRBWF [1:1]
        /// Alarm B write flag
        ALRBWF: u1 = 1,
        /// WUTWF [2:2]
        /// Wakeup timer write flag
        WUTWF: u1 = 1,
        /// SHPF [3:3]
        /// Shift operation pending
        SHPF: u1 = 0,
        /// INITS [4:4]
        /// Initialization status flag
        INITS: u1 = 0,
        /// RSF [5:5]
        /// Registers synchronization
        RSF: u1 = 0,
        /// INITF [6:6]
        /// Initialization flag
        INITF: u1 = 0,
        /// INIT [7:7]
        /// Initialization mode
        INIT: u1 = 0,
        /// ALRAF [8:8]
        /// Alarm A flag
        ALRAF: u1 = 0,
        /// ALRBF [9:9]
        /// Alarm B flag
        ALRBF: u1 = 0,
        /// WUTF [10:10]
        /// Wakeup timer flag
        WUTF: u1 = 0,
        /// TSF [11:11]
        /// Time-stamp flag
        TSF: u1 = 0,
        /// TSOVF [12:12]
        /// Time-stamp overflow flag
        TSOVF: u1 = 0,
        /// TAMP1F [13:13]
        /// Tamper detection flag
        TAMP1F: u1 = 0,
        /// TAMP2F [14:14]
        /// TAMPER2 detection flag
        TAMP2F: u1 = 0,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// RECALPF [16:16]
        /// Recalibration pending Flag
        RECALPF: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// initialization and status
    pub const ISR = Register(ISR_val).init(base_address + 0xc);

    /// PRER
    const PRER_val = packed struct {
        /// PREDIV_S [0:14]
        /// Synchronous prescaler
        PREDIV_S: u15 = 255,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// PREDIV_A [16:22]
        /// Asynchronous prescaler
        PREDIV_A: u7 = 127,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler register
    pub const PRER = Register(PRER_val).init(base_address + 0x10);

    /// WUTR
    const WUTR_val = packed struct {
        /// WUT [0:15]
        /// Wakeup auto-reload value
        WUT: u16 = 65535,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// wakeup timer register
    pub const WUTR = Register(WUTR_val).init(base_address + 0x14);

    /// CALIBR
    const CALIBR_val = packed struct {
        /// DC [0:4]
        /// Digital calibration
        DC: u5 = 0,
        /// unused [5:6]
        _unused5: u2 = 0,
        /// DCS [7:7]
        /// Digital calibration sign
        DCS: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// calibration register
    pub const CALIBR = Register(CALIBR_val).init(base_address + 0x18);

    /// ALRMAR
    const ALRMAR_val = packed struct {
        /// SU [0:3]
        /// Second units in BCD format
        SU: u4 = 0,
        /// ST [4:6]
        /// Second tens in BCD format
        ST: u3 = 0,
        /// MSK1 [7:7]
        /// Alarm A seconds mask
        MSK1: u1 = 0,
        /// MNU [8:11]
        /// Minute units in BCD format
        MNU: u4 = 0,
        /// MNT [12:14]
        /// Minute tens in BCD format
        MNT: u3 = 0,
        /// MSK2 [15:15]
        /// Alarm A minutes mask
        MSK2: u1 = 0,
        /// HU [16:19]
        /// Hour units in BCD format
        HU: u4 = 0,
        /// HT [20:21]
        /// Hour tens in BCD format
        HT: u2 = 0,
        /// PM [22:22]
        /// AM/PM notation
        PM: u1 = 0,
        /// MSK3 [23:23]
        /// Alarm A hours mask
        MSK3: u1 = 0,
        /// DU [24:27]
        /// Date units or day in BCD
        DU: u4 = 0,
        /// DT [28:29]
        /// Date tens in BCD format
        DT: u2 = 0,
        /// WDSEL [30:30]
        /// Week day selection
        WDSEL: u1 = 0,
        /// MSK4 [31:31]
        /// Alarm A date mask
        MSK4: u1 = 0,
    };
    /// alarm A register
    pub const ALRMAR = Register(ALRMAR_val).init(base_address + 0x1c);

    /// ALRMBR
    const ALRMBR_val = packed struct {
        /// SU [0:3]
        /// Second units in BCD format
        SU: u4 = 0,
        /// ST [4:6]
        /// Second tens in BCD format
        ST: u3 = 0,
        /// MSK1 [7:7]
        /// Alarm B seconds mask
        MSK1: u1 = 0,
        /// MNU [8:11]
        /// Minute units in BCD format
        MNU: u4 = 0,
        /// MNT [12:14]
        /// Minute tens in BCD format
        MNT: u3 = 0,
        /// MSK2 [15:15]
        /// Alarm B minutes mask
        MSK2: u1 = 0,
        /// HU [16:19]
        /// Hour units in BCD format
        HU: u4 = 0,
        /// HT [20:21]
        /// Hour tens in BCD format
        HT: u2 = 0,
        /// PM [22:22]
        /// AM/PM notation
        PM: u1 = 0,
        /// MSK3 [23:23]
        /// Alarm B hours mask
        MSK3: u1 = 0,
        /// DU [24:27]
        /// Date units or day in BCD
        DU: u4 = 0,
        /// DT [28:29]
        /// Date tens in BCD format
        DT: u2 = 0,
        /// WDSEL [30:30]
        /// Week day selection
        WDSEL: u1 = 0,
        /// MSK4 [31:31]
        /// Alarm B date mask
        MSK4: u1 = 0,
    };
    /// alarm B register
    pub const ALRMBR = Register(ALRMBR_val).init(base_address + 0x20);

    /// WPR
    const WPR_val = packed struct {
        /// KEY [0:7]
        /// Write protection key
        KEY: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// write protection register
    pub const WPR = Register(WPR_val).init(base_address + 0x24);

    /// SSR
    const SSR_val = packed struct {
        /// SS [0:15]
        /// Sub second value
        SS: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// sub second register
    pub const SSR = Register(SSR_val).init(base_address + 0x28);

    /// SHIFTR
    const SHIFTR_val = packed struct {
        /// SUBFS [0:14]
        /// Subtract a fraction of a
        SUBFS: u15 = 0,
        /// unused [15:30]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u7 = 0,
        /// ADD1S [31:31]
        /// Add one second
        ADD1S: u1 = 0,
    };
    /// shift control register
    pub const SHIFTR = Register(SHIFTR_val).init(base_address + 0x2c);

    /// TSTR
    const TSTR_val = packed struct {
        /// SU [0:3]
        /// Second units in BCD format
        SU: u4 = 0,
        /// ST [4:6]
        /// Second tens in BCD format
        ST: u3 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// MNU [8:11]
        /// Minute units in BCD format
        MNU: u4 = 0,
        /// MNT [12:14]
        /// Minute tens in BCD format
        MNT: u3 = 0,
        /// unused [15:15]
        _unused15: u1 = 0,
        /// HU [16:19]
        /// Hour units in BCD format
        HU: u4 = 0,
        /// HT [20:21]
        /// Hour tens in BCD format
        HT: u2 = 0,
        /// PM [22:22]
        /// AM/PM notation
        PM: u1 = 0,
        /// unused [23:31]
        _unused23: u1 = 0,
        _unused24: u8 = 0,
    };
    /// time stamp time register
    pub const TSTR = Register(TSTR_val).init(base_address + 0x30);

    /// TSDR
    const TSDR_val = packed struct {
        /// DU [0:3]
        /// Date units in BCD format
        DU: u4 = 0,
        /// DT [4:5]
        /// Date tens in BCD format
        DT: u2 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// MU [8:11]
        /// Month units in BCD format
        MU: u4 = 0,
        /// MT [12:12]
        /// Month tens in BCD format
        MT: u1 = 0,
        /// WDU [13:15]
        /// Week day units
        WDU: u3 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// time stamp date register
    pub const TSDR = Register(TSDR_val).init(base_address + 0x34);

    /// TSSSR
    const TSSSR_val = packed struct {
        /// SS [0:15]
        /// Sub second value
        SS: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// timestamp sub second register
    pub const TSSSR = Register(TSSSR_val).init(base_address + 0x38);

    /// CALR
    const CALR_val = packed struct {
        /// CALM [0:8]
        /// Calibration minus
        CALM: u9 = 0,
        /// unused [9:12]
        _unused9: u4 = 0,
        /// CALW16 [13:13]
        /// Use a 16-second calibration cycle
        CALW16: u1 = 0,
        /// CALW8 [14:14]
        /// Use an 8-second calibration cycle
        CALW8: u1 = 0,
        /// CALP [15:15]
        /// Increase frequency of RTC by 488.5
        CALP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// calibration register
    pub const CALR = Register(CALR_val).init(base_address + 0x3c);

    /// TAFCR
    const TAFCR_val = packed struct {
        /// TAMP1E [0:0]
        /// Tamper 1 detection enable
        TAMP1E: u1 = 0,
        /// TAMP1TRG [1:1]
        /// Active level for tamper 1
        TAMP1TRG: u1 = 0,
        /// TAMPIE [2:2]
        /// Tamper interrupt enable
        TAMPIE: u1 = 0,
        /// TAMP2E [3:3]
        /// Tamper 2 detection enable
        TAMP2E: u1 = 0,
        /// TAMP2TRG [4:4]
        /// Active level for tamper 2
        TAMP2TRG: u1 = 0,
        /// unused [5:6]
        _unused5: u2 = 0,
        /// TAMPTS [7:7]
        /// Activate timestamp on tamper detection
        TAMPTS: u1 = 0,
        /// TAMPFREQ [8:10]
        /// Tamper sampling frequency
        TAMPFREQ: u3 = 0,
        /// TAMPFLT [11:12]
        /// Tamper filter count
        TAMPFLT: u2 = 0,
        /// TAMPPRCH [13:14]
        /// Tamper precharge duration
        TAMPPRCH: u2 = 0,
        /// TAMPPUDIS [15:15]
        /// TAMPER pull-up disable
        TAMPPUDIS: u1 = 0,
        /// TAMP1INSEL [16:16]
        /// TAMPER1 mapping
        TAMP1INSEL: u1 = 0,
        /// TSINSEL [17:17]
        /// TIMESTAMP mapping
        TSINSEL: u1 = 0,
        /// ALARMOUTTYPE [18:18]
        /// AFO_ALARM output type
        ALARMOUTTYPE: u1 = 0,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// tamper and alternate function configuration
    pub const TAFCR = Register(TAFCR_val).init(base_address + 0x40);

    /// ALRMASSR
    const ALRMASSR_val = packed struct {
        /// SS [0:14]
        /// Sub seconds value
        SS: u15 = 0,
        /// unused [15:23]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        /// MASKSS [24:27]
        /// Mask the most-significant bits starting
        MASKSS: u4 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// alarm A sub second register
    pub const ALRMASSR = Register(ALRMASSR_val).init(base_address + 0x44);

    /// ALRMBSSR
    const ALRMBSSR_val = packed struct {
        /// SS [0:14]
        /// Sub seconds value
        SS: u15 = 0,
        /// unused [15:23]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        /// MASKSS [24:27]
        /// Mask the most-significant bits starting
        MASKSS: u4 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// alarm B sub second register
    pub const ALRMBSSR = Register(ALRMBSSR_val).init(base_address + 0x48);

    /// BKP0R
    const BKP0R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP0R = Register(BKP0R_val).init(base_address + 0x50);

    /// BKP1R
    const BKP1R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP1R = Register(BKP1R_val).init(base_address + 0x54);

    /// BKP2R
    const BKP2R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP2R = Register(BKP2R_val).init(base_address + 0x58);

    /// BKP3R
    const BKP3R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP3R = Register(BKP3R_val).init(base_address + 0x5c);

    /// BKP4R
    const BKP4R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP4R = Register(BKP4R_val).init(base_address + 0x60);

    /// BKP5R
    const BKP5R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP5R = Register(BKP5R_val).init(base_address + 0x64);

    /// BKP6R
    const BKP6R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP6R = Register(BKP6R_val).init(base_address + 0x68);

    /// BKP7R
    const BKP7R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP7R = Register(BKP7R_val).init(base_address + 0x6c);

    /// BKP8R
    const BKP8R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP8R = Register(BKP8R_val).init(base_address + 0x70);

    /// BKP9R
    const BKP9R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP9R = Register(BKP9R_val).init(base_address + 0x74);

    /// BKP10R
    const BKP10R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP10R = Register(BKP10R_val).init(base_address + 0x78);

    /// BKP11R
    const BKP11R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP11R = Register(BKP11R_val).init(base_address + 0x7c);

    /// BKP12R
    const BKP12R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP12R = Register(BKP12R_val).init(base_address + 0x80);

    /// BKP13R
    const BKP13R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP13R = Register(BKP13R_val).init(base_address + 0x84);

    /// BKP14R
    const BKP14R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP14R = Register(BKP14R_val).init(base_address + 0x88);

    /// BKP15R
    const BKP15R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP15R = Register(BKP15R_val).init(base_address + 0x8c);

    /// BKP16R
    const BKP16R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP16R = Register(BKP16R_val).init(base_address + 0x90);

    /// BKP17R
    const BKP17R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP17R = Register(BKP17R_val).init(base_address + 0x94);

    /// BKP18R
    const BKP18R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP18R = Register(BKP18R_val).init(base_address + 0x98);

    /// BKP19R
    const BKP19R_val = packed struct {
        /// BKP [0:31]
        /// BKP
        BKP: u32 = 0,
    };
    /// backup register
    pub const BKP19R = Register(BKP19R_val).init(base_address + 0x9c);
};

/// Secure digital input/output
pub const SDIO = struct {
    const base_address = 0x40012c00;
    /// POWER
    const POWER_val = packed struct {
        /// PWRCTRL [0:1]
        /// PWRCTRL
        PWRCTRL: u2 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// power control register
    pub const POWER = Register(POWER_val).init(base_address + 0x0);

    /// CLKCR
    const CLKCR_val = packed struct {
        /// CLKDIV [0:7]
        /// Clock divide factor
        CLKDIV: u8 = 0,
        /// CLKEN [8:8]
        /// Clock enable bit
        CLKEN: u1 = 0,
        /// PWRSAV [9:9]
        /// Power saving configuration
        PWRSAV: u1 = 0,
        /// BYPASS [10:10]
        /// Clock divider bypass enable
        BYPASS: u1 = 0,
        /// WIDBUS [11:12]
        /// Wide bus mode enable bit
        WIDBUS: u2 = 0,
        /// NEGEDGE [13:13]
        /// SDIO_CK dephasing selection
        NEGEDGE: u1 = 0,
        /// HWFC_EN [14:14]
        /// HW Flow Control enable
        HWFC_EN: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// SDI clock control register
    pub const CLKCR = Register(CLKCR_val).init(base_address + 0x4);

    /// ARG
    const ARG_val = packed struct {
        /// CMDARG [0:31]
        /// Command argument
        CMDARG: u32 = 0,
    };
    /// argument register
    pub const ARG = Register(ARG_val).init(base_address + 0x8);

    /// CMD
    const CMD_val = packed struct {
        /// CMDINDEX [0:5]
        /// Command index
        CMDINDEX: u6 = 0,
        /// WAITRESP [6:7]
        /// Wait for response bits
        WAITRESP: u2 = 0,
        /// WAITINT [8:8]
        /// CPSM waits for interrupt
        WAITINT: u1 = 0,
        /// WAITPEND [9:9]
        /// CPSM Waits for ends of data transfer
        WAITPEND: u1 = 0,
        /// CPSMEN [10:10]
        /// Command path state machine (CPSM) Enable
        CPSMEN: u1 = 0,
        /// SDIOSuspend [11:11]
        /// SD I/O suspend command
        SDIOSuspend: u1 = 0,
        /// ENCMDcompl [12:12]
        /// Enable CMD completion
        ENCMDcompl: u1 = 0,
        /// nIEN [13:13]
        /// not Interrupt Enable
        nIEN: u1 = 0,
        /// CE_ATACMD [14:14]
        /// CE-ATA command
        CE_ATACMD: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// command register
    pub const CMD = Register(CMD_val).init(base_address + 0xc);

    /// RESPCMD
    const RESPCMD_val = packed struct {
        /// RESPCMD [0:5]
        /// Response command index
        RESPCMD: u6 = 0,
        /// unused [6:31]
        _unused6: u2 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// command response register
    pub const RESPCMD = Register(RESPCMD_val).init(base_address + 0x10);

    /// RESP1
    const RESP1_val = packed struct {
        /// CARDSTATUS1 [0:31]
        /// Card Status
        CARDSTATUS1: u32 = 0,
    };
    /// response 1..4 register
    pub const RESP1 = Register(RESP1_val).init(base_address + 0x14);

    /// RESP2
    const RESP2_val = packed struct {
        /// CARDSTATUS2 [0:31]
        /// Card Status
        CARDSTATUS2: u32 = 0,
    };
    /// response 1..4 register
    pub const RESP2 = Register(RESP2_val).init(base_address + 0x18);

    /// RESP3
    const RESP3_val = packed struct {
        /// CARDSTATUS3 [0:31]
        /// Card Status
        CARDSTATUS3: u32 = 0,
    };
    /// response 1..4 register
    pub const RESP3 = Register(RESP3_val).init(base_address + 0x1c);

    /// RESP4
    const RESP4_val = packed struct {
        /// CARDSTATUS4 [0:31]
        /// Card Status
        CARDSTATUS4: u32 = 0,
    };
    /// response 1..4 register
    pub const RESP4 = Register(RESP4_val).init(base_address + 0x20);

    /// DTIMER
    const DTIMER_val = packed struct {
        /// DATATIME [0:31]
        /// Data timeout period
        DATATIME: u32 = 0,
    };
    /// data timer register
    pub const DTIMER = Register(DTIMER_val).init(base_address + 0x24);

    /// DLEN
    const DLEN_val = packed struct {
        /// DATALENGTH [0:24]
        /// Data length value
        DATALENGTH: u25 = 0,
        /// unused [25:31]
        _unused25: u7 = 0,
    };
    /// data length register
    pub const DLEN = Register(DLEN_val).init(base_address + 0x28);

    /// DCTRL
    const DCTRL_val = packed struct {
        /// DTEN [0:0]
        /// DTEN
        DTEN: u1 = 0,
        /// DTDIR [1:1]
        /// Data transfer direction
        DTDIR: u1 = 0,
        /// DTMODE [2:2]
        /// Data transfer mode selection 1: Stream
        DTMODE: u1 = 0,
        /// DMAEN [3:3]
        /// DMA enable bit
        DMAEN: u1 = 0,
        /// DBLOCKSIZE [4:7]
        /// Data block size
        DBLOCKSIZE: u4 = 0,
        /// RWSTART [8:8]
        /// Read wait start
        RWSTART: u1 = 0,
        /// RWSTOP [9:9]
        /// Read wait stop
        RWSTOP: u1 = 0,
        /// RWMOD [10:10]
        /// Read wait mode
        RWMOD: u1 = 0,
        /// SDIOEN [11:11]
        /// SD I/O enable functions
        SDIOEN: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data control register
    pub const DCTRL = Register(DCTRL_val).init(base_address + 0x2c);

    /// DCOUNT
    const DCOUNT_val = packed struct {
        /// DATACOUNT [0:24]
        /// Data count value
        DATACOUNT: u25 = 0,
        /// unused [25:31]
        _unused25: u7 = 0,
    };
    /// data counter register
    pub const DCOUNT = Register(DCOUNT_val).init(base_address + 0x30);

    /// STA
    const STA_val = packed struct {
        /// CCRCFAIL [0:0]
        /// Command response received (CRC check
        CCRCFAIL: u1 = 0,
        /// DCRCFAIL [1:1]
        /// Data block sent/received (CRC check
        DCRCFAIL: u1 = 0,
        /// CTIMEOUT [2:2]
        /// Command response timeout
        CTIMEOUT: u1 = 0,
        /// DTIMEOUT [3:3]
        /// Data timeout
        DTIMEOUT: u1 = 0,
        /// TXUNDERR [4:4]
        /// Transmit FIFO underrun
        TXUNDERR: u1 = 0,
        /// RXOVERR [5:5]
        /// Received FIFO overrun
        RXOVERR: u1 = 0,
        /// CMDREND [6:6]
        /// Command response received (CRC check
        CMDREND: u1 = 0,
        /// CMDSENT [7:7]
        /// Command sent (no response
        CMDSENT: u1 = 0,
        /// DATAEND [8:8]
        /// Data end (data counter, SDIDCOUNT, is
        DATAEND: u1 = 0,
        /// STBITERR [9:9]
        /// Start bit not detected on all data
        STBITERR: u1 = 0,
        /// DBCKEND [10:10]
        /// Data block sent/received (CRC check
        DBCKEND: u1 = 0,
        /// CMDACT [11:11]
        /// Command transfer in
        CMDACT: u1 = 0,
        /// TXACT [12:12]
        /// Data transmit in progress
        TXACT: u1 = 0,
        /// RXACT [13:13]
        /// Data receive in progress
        RXACT: u1 = 0,
        /// TXFIFOHE [14:14]
        /// Transmit FIFO half empty: at least 8
        TXFIFOHE: u1 = 0,
        /// RXFIFOHF [15:15]
        /// Receive FIFO half full: there are at
        RXFIFOHF: u1 = 0,
        /// TXFIFOF [16:16]
        /// Transmit FIFO full
        TXFIFOF: u1 = 0,
        /// RXFIFOF [17:17]
        /// Receive FIFO full
        RXFIFOF: u1 = 0,
        /// TXFIFOE [18:18]
        /// Transmit FIFO empty
        TXFIFOE: u1 = 0,
        /// RXFIFOE [19:19]
        /// Receive FIFO empty
        RXFIFOE: u1 = 0,
        /// TXDAVL [20:20]
        /// Data available in transmit
        TXDAVL: u1 = 0,
        /// RXDAVL [21:21]
        /// Data available in receive
        RXDAVL: u1 = 0,
        /// SDIOIT [22:22]
        /// SDIO interrupt received
        SDIOIT: u1 = 0,
        /// CEATAEND [23:23]
        /// CE-ATA command completion signal
        CEATAEND: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// status register
    pub const STA = Register(STA_val).init(base_address + 0x34);

    /// ICR
    const ICR_val = packed struct {
        /// CCRCFAILC [0:0]
        /// CCRCFAIL flag clear bit
        CCRCFAILC: u1 = 0,
        /// DCRCFAILC [1:1]
        /// DCRCFAIL flag clear bit
        DCRCFAILC: u1 = 0,
        /// CTIMEOUTC [2:2]
        /// CTIMEOUT flag clear bit
        CTIMEOUTC: u1 = 0,
        /// DTIMEOUTC [3:3]
        /// DTIMEOUT flag clear bit
        DTIMEOUTC: u1 = 0,
        /// TXUNDERRC [4:4]
        /// TXUNDERR flag clear bit
        TXUNDERRC: u1 = 0,
        /// RXOVERRC [5:5]
        /// RXOVERR flag clear bit
        RXOVERRC: u1 = 0,
        /// CMDRENDC [6:6]
        /// CMDREND flag clear bit
        CMDRENDC: u1 = 0,
        /// CMDSENTC [7:7]
        /// CMDSENT flag clear bit
        CMDSENTC: u1 = 0,
        /// DATAENDC [8:8]
        /// DATAEND flag clear bit
        DATAENDC: u1 = 0,
        /// STBITERRC [9:9]
        /// STBITERR flag clear bit
        STBITERRC: u1 = 0,
        /// DBCKENDC [10:10]
        /// DBCKEND flag clear bit
        DBCKENDC: u1 = 0,
        /// unused [11:21]
        _unused11: u5 = 0,
        _unused16: u6 = 0,
        /// SDIOITC [22:22]
        /// SDIOIT flag clear bit
        SDIOITC: u1 = 0,
        /// CEATAENDC [23:23]
        /// CEATAEND flag clear bit
        CEATAENDC: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// interrupt clear register
    pub const ICR = Register(ICR_val).init(base_address + 0x38);

    /// MASK
    const MASK_val = packed struct {
        /// CCRCFAILIE [0:0]
        /// Command CRC fail interrupt
        CCRCFAILIE: u1 = 0,
        /// DCRCFAILIE [1:1]
        /// Data CRC fail interrupt
        DCRCFAILIE: u1 = 0,
        /// CTIMEOUTIE [2:2]
        /// Command timeout interrupt
        CTIMEOUTIE: u1 = 0,
        /// DTIMEOUTIE [3:3]
        /// Data timeout interrupt
        DTIMEOUTIE: u1 = 0,
        /// TXUNDERRIE [4:4]
        /// Tx FIFO underrun error interrupt
        TXUNDERRIE: u1 = 0,
        /// RXOVERRIE [5:5]
        /// Rx FIFO overrun error interrupt
        RXOVERRIE: u1 = 0,
        /// CMDRENDIE [6:6]
        /// Command response received interrupt
        CMDRENDIE: u1 = 0,
        /// CMDSENTIE [7:7]
        /// Command sent interrupt
        CMDSENTIE: u1 = 0,
        /// DATAENDIE [8:8]
        /// Data end interrupt enable
        DATAENDIE: u1 = 0,
        /// STBITERRIE [9:9]
        /// Start bit error interrupt
        STBITERRIE: u1 = 0,
        /// DBCKENDIE [10:10]
        /// Data block end interrupt
        DBCKENDIE: u1 = 0,
        /// CMDACTIE [11:11]
        /// Command acting interrupt
        CMDACTIE: u1 = 0,
        /// TXACTIE [12:12]
        /// Data transmit acting interrupt
        TXACTIE: u1 = 0,
        /// RXACTIE [13:13]
        /// Data receive acting interrupt
        RXACTIE: u1 = 0,
        /// TXFIFOHEIE [14:14]
        /// Tx FIFO half empty interrupt
        TXFIFOHEIE: u1 = 0,
        /// RXFIFOHFIE [15:15]
        /// Rx FIFO half full interrupt
        RXFIFOHFIE: u1 = 0,
        /// TXFIFOFIE [16:16]
        /// Tx FIFO full interrupt
        TXFIFOFIE: u1 = 0,
        /// RXFIFOFIE [17:17]
        /// Rx FIFO full interrupt
        RXFIFOFIE: u1 = 0,
        /// TXFIFOEIE [18:18]
        /// Tx FIFO empty interrupt
        TXFIFOEIE: u1 = 0,
        /// RXFIFOEIE [19:19]
        /// Rx FIFO empty interrupt
        RXFIFOEIE: u1 = 0,
        /// TXDAVLIE [20:20]
        /// Data available in Tx FIFO interrupt
        TXDAVLIE: u1 = 0,
        /// RXDAVLIE [21:21]
        /// Data available in Rx FIFO interrupt
        RXDAVLIE: u1 = 0,
        /// SDIOITIE [22:22]
        /// SDIO mode interrupt received interrupt
        SDIOITIE: u1 = 0,
        /// CEATAENDIE [23:23]
        /// CE-ATA command completion signal
        CEATAENDIE: u1 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// mask register
    pub const MASK = Register(MASK_val).init(base_address + 0x3c);

    /// FIFOCNT
    const FIFOCNT_val = packed struct {
        /// FIFOCOUNT [0:23]
        /// Remaining number of words to be written
        FIFOCOUNT: u24 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// FIFO counter register
    pub const FIFOCNT = Register(FIFOCNT_val).init(base_address + 0x48);

    /// FIFO
    const FIFO_val = packed struct {
        /// FIFOData [0:31]
        /// Receive and transmit FIFO
        FIFOData: u32 = 0,
    };
    /// data FIFO register
    pub const FIFO = Register(FIFO_val).init(base_address + 0x80);
};

/// System configuration controller
pub const SYSCFG = struct {
    const base_address = 0x40013800;
    /// MEMRM
    const MEMRM_val = packed struct {
        /// MEM_MODE [0:1]
        /// MEM_MODE
        MEM_MODE: u2 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// memory remap register
    pub const MEMRM = Register(MEMRM_val).init(base_address + 0x0);

    /// PMC
    const PMC_val = packed struct {
        /// unused [0:15]
        _unused0: u8 = 0,
        _unused8: u8 = 0,
        /// ADC1DC2 [16:16]
        /// ADC1DC2
        ADC1DC2: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// peripheral mode configuration
    pub const PMC = Register(PMC_val).init(base_address + 0x4);

    /// EXTICR1
    const EXTICR1_val = packed struct {
        /// EXTI0 [0:3]
        /// EXTI x configuration (x = 0 to
        EXTI0: u4 = 0,
        /// EXTI1 [4:7]
        /// EXTI x configuration (x = 0 to
        EXTI1: u4 = 0,
        /// EXTI2 [8:11]
        /// EXTI x configuration (x = 0 to
        EXTI2: u4 = 0,
        /// EXTI3 [12:15]
        /// EXTI x configuration (x = 0 to
        EXTI3: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// external interrupt configuration register
    pub const EXTICR1 = Register(EXTICR1_val).init(base_address + 0x8);

    /// EXTICR2
    const EXTICR2_val = packed struct {
        /// EXTI4 [0:3]
        /// EXTI x configuration (x = 4 to
        EXTI4: u4 = 0,
        /// EXTI5 [4:7]
        /// EXTI x configuration (x = 4 to
        EXTI5: u4 = 0,
        /// EXTI6 [8:11]
        /// EXTI x configuration (x = 4 to
        EXTI6: u4 = 0,
        /// EXTI7 [12:15]
        /// EXTI x configuration (x = 4 to
        EXTI7: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// external interrupt configuration register
    pub const EXTICR2 = Register(EXTICR2_val).init(base_address + 0xc);

    /// EXTICR3
    const EXTICR3_val = packed struct {
        /// EXTI8 [0:3]
        /// EXTI x configuration (x = 8 to
        EXTI8: u4 = 0,
        /// EXTI9 [4:7]
        /// EXTI x configuration (x = 8 to
        EXTI9: u4 = 0,
        /// EXTI10 [8:11]
        /// EXTI10
        EXTI10: u4 = 0,
        /// EXTI11 [12:15]
        /// EXTI x configuration (x = 8 to
        EXTI11: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// external interrupt configuration register
    pub const EXTICR3 = Register(EXTICR3_val).init(base_address + 0x10);

    /// EXTICR4
    const EXTICR4_val = packed struct {
        /// EXTI12 [0:3]
        /// EXTI x configuration (x = 12 to
        EXTI12: u4 = 0,
        /// EXTI13 [4:7]
        /// EXTI x configuration (x = 12 to
        EXTI13: u4 = 0,
        /// EXTI14 [8:11]
        /// EXTI x configuration (x = 12 to
        EXTI14: u4 = 0,
        /// EXTI15 [12:15]
        /// EXTI x configuration (x = 12 to
        EXTI15: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// external interrupt configuration register
    pub const EXTICR4 = Register(EXTICR4_val).init(base_address + 0x14);

    /// CMPCR
    const CMPCR_val = packed struct {
        /// CMP_PD [0:0]
        /// Compensation cell
        CMP_PD: u1 = 0,
        /// unused [1:7]
        _unused1: u7 = 0,
        /// READY [8:8]
        /// READY
        READY: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Compensation cell control
    pub const CMPCR = Register(CMPCR_val).init(base_address + 0x20);
};

/// Advanced-timers
pub const TIM1 = struct {
    const base_address = 0x40010000;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// DIR [4:4]
        /// Direction
        DIR: u1 = 0,
        /// CMS [5:6]
        /// Center-aligned mode
        CMS: u2 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// CCPC [0:0]
        /// Capture/compare preloaded
        CCPC: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// CCUS [2:2]
        /// Capture/compare control update
        CCUS: u1 = 0,
        /// CCDS [3:3]
        /// Capture/compare DMA
        CCDS: u1 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// TI1S [7:7]
        /// TI1 selection
        TI1S: u1 = 0,
        /// OIS1 [8:8]
        /// Output Idle state 1
        OIS1: u1 = 0,
        /// OIS1N [9:9]
        /// Output Idle state 1
        OIS1N: u1 = 0,
        /// OIS2 [10:10]
        /// Output Idle state 2
        OIS2: u1 = 0,
        /// OIS2N [11:11]
        /// Output Idle state 2
        OIS2N: u1 = 0,
        /// OIS3 [12:12]
        /// Output Idle state 3
        OIS3: u1 = 0,
        /// OIS3N [13:13]
        /// Output Idle state 3
        OIS3N: u1 = 0,
        /// OIS4 [14:14]
        /// Output Idle state 4
        OIS4: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// ETF [8:11]
        /// External trigger filter
        ETF: u4 = 0,
        /// ETPS [12:13]
        /// External trigger prescaler
        ETPS: u2 = 0,
        /// ECE [14:14]
        /// External clock enable
        ECE: u1 = 0,
        /// ETP [15:15]
        /// External trigger polarity
        ETP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// CC3IE [3:3]
        /// Capture/Compare 3 interrupt
        CC3IE: u1 = 0,
        /// CC4IE [4:4]
        /// Capture/Compare 4 interrupt
        CC4IE: u1 = 0,
        /// COMIE [5:5]
        /// COM interrupt enable
        COMIE: u1 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// BIE [7:7]
        /// Break interrupt enable
        BIE: u1 = 0,
        /// UDE [8:8]
        /// Update DMA request enable
        UDE: u1 = 0,
        /// CC1DE [9:9]
        /// Capture/Compare 1 DMA request
        CC1DE: u1 = 0,
        /// CC2DE [10:10]
        /// Capture/Compare 2 DMA request
        CC2DE: u1 = 0,
        /// CC3DE [11:11]
        /// Capture/Compare 3 DMA request
        CC3DE: u1 = 0,
        /// CC4DE [12:12]
        /// Capture/Compare 4 DMA request
        CC4DE: u1 = 0,
        /// COMDE [13:13]
        /// COM DMA request enable
        COMDE: u1 = 0,
        /// TDE [14:14]
        /// Trigger DMA request enable
        TDE: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// CC3IF [3:3]
        /// Capture/Compare 3 interrupt
        CC3IF: u1 = 0,
        /// CC4IF [4:4]
        /// Capture/Compare 4 interrupt
        CC4IF: u1 = 0,
        /// COMIF [5:5]
        /// COM interrupt flag
        COMIF: u1 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// BIF [7:7]
        /// Break interrupt flag
        BIF: u1 = 0,
        /// unused [8:8]
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// CC3OF [11:11]
        /// Capture/Compare 3 overcapture
        CC3OF: u1 = 0,
        /// CC4OF [12:12]
        /// Capture/Compare 4 overcapture
        CC4OF: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// CC3G [3:3]
        /// Capture/compare 3
        CC3G: u1 = 0,
        /// CC4G [4:4]
        /// Capture/compare 4
        CC4G: u1 = 0,
        /// COMG [5:5]
        /// Capture/Compare control update
        COMG: u1 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// BG [7:7]
        /// Break generation
        BG: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// Output Compare 1 fast
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// Output Compare 1 preload
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// Output Compare 1 mode
        OC1M: u3 = 0,
        /// OC1CE [7:7]
        /// Output Compare 1 clear
        OC1CE: u1 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// Output Compare 2 fast
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// Output Compare 2 preload
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// Output Compare 2 mode
        OC2M: u3 = 0,
        /// OC2CE [15:15]
        /// Output Compare 2 clear
        OC2CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:15]
        /// Input capture 2 filter
        IC2F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCMR2_Output
    const CCMR2_Output_val = packed struct {
        /// CC3S [0:1]
        /// Capture/Compare 3
        CC3S: u2 = 0,
        /// OC3FE [2:2]
        /// Output compare 3 fast
        OC3FE: u1 = 0,
        /// OC3PE [3:3]
        /// Output compare 3 preload
        OC3PE: u1 = 0,
        /// OC3M [4:6]
        /// Output compare 3 mode
        OC3M: u3 = 0,
        /// OC3CE [7:7]
        /// Output compare 3 clear
        OC3CE: u1 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// OC4FE [10:10]
        /// Output compare 4 fast
        OC4FE: u1 = 0,
        /// OC4PE [11:11]
        /// Output compare 4 preload
        OC4PE: u1 = 0,
        /// OC4M [12:14]
        /// Output compare 4 mode
        OC4M: u3 = 0,
        /// OC4CE [15:15]
        /// Output compare 4 clear
        OC4CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (output
    pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

    /// CCMR2_Input
    const CCMR2_Input_val = packed struct {
        /// CC3S [0:1]
        /// Capture/compare 3
        CC3S: u2 = 0,
        /// IC3PSC [2:3]
        /// Input capture 3 prescaler
        IC3PSC: u2 = 0,
        /// IC3F [4:7]
        /// Input capture 3 filter
        IC3F: u4 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// IC4PSC [10:11]
        /// Input capture 4 prescaler
        IC4PSC: u2 = 0,
        /// IC4F [12:15]
        /// Input capture 4 filter
        IC4F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (input
    pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// CC1NE [2:2]
        /// Capture/Compare 1 complementary output
        CC1NE: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// CC2NE [6:6]
        /// Capture/Compare 2 complementary output
        CC2NE: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// CC3E [8:8]
        /// Capture/Compare 3 output
        CC3E: u1 = 0,
        /// CC3P [9:9]
        /// Capture/Compare 3 output
        CC3P: u1 = 0,
        /// CC3NE [10:10]
        /// Capture/Compare 3 complementary output
        CC3NE: u1 = 0,
        /// CC3NP [11:11]
        /// Capture/Compare 3 output
        CC3NP: u1 = 0,
        /// CC4E [12:12]
        /// Capture/Compare 4 output
        CC4E: u1 = 0,
        /// CC4P [13:13]
        /// Capture/Compare 3 output
        CC4P: u1 = 0,
        /// unused [14:31]
        _unused14: u2 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT [0:15]
        /// counter value
        CNT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR [0:15]
        /// Auto-reload value
        ARR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1 [0:15]
        /// Capture/Compare 1 value
        CCR1: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2 [0:15]
        /// Capture/Compare 2 value
        CCR2: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

    /// CCR3
    const CCR3_val = packed struct {
        /// CCR3 [0:15]
        /// Capture/Compare value
        CCR3: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 3
    pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

    /// CCR4
    const CCR4_val = packed struct {
        /// CCR4 [0:15]
        /// Capture/Compare value
        CCR4: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 4
    pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

    /// DCR
    const DCR_val = packed struct {
        /// DBA [0:4]
        /// DMA base address
        DBA: u5 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// DBL [8:12]
        /// DMA burst length
        DBL: u5 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA control register
    pub const DCR = Register(DCR_val).init(base_address + 0x48);

    /// DMAR
    const DMAR_val = packed struct {
        /// DMAB [0:15]
        /// DMA register for burst
        DMAB: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA address for full transfer
    pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

    /// RCR
    const RCR_val = packed struct {
        /// REP [0:7]
        /// Repetition counter value
        REP: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// repetition counter register
    pub const RCR = Register(RCR_val).init(base_address + 0x30);

    /// BDTR
    const BDTR_val = packed struct {
        /// DTG [0:7]
        /// Dead-time generator setup
        DTG: u8 = 0,
        /// LOCK [8:9]
        /// Lock configuration
        LOCK: u2 = 0,
        /// OSSI [10:10]
        /// Off-state selection for Idle
        OSSI: u1 = 0,
        /// OSSR [11:11]
        /// Off-state selection for Run
        OSSR: u1 = 0,
        /// BKE [12:12]
        /// Break enable
        BKE: u1 = 0,
        /// BKP [13:13]
        /// Break polarity
        BKP: u1 = 0,
        /// AOE [14:14]
        /// Automatic output enable
        AOE: u1 = 0,
        /// MOE [15:15]
        /// Main output enable
        MOE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// break and dead-time register
    pub const BDTR = Register(BDTR_val).init(base_address + 0x44);
};

/// Advanced-timers
pub const TIM8 = struct {
    const base_address = 0x40010400;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// DIR [4:4]
        /// Direction
        DIR: u1 = 0,
        /// CMS [5:6]
        /// Center-aligned mode
        CMS: u2 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// CCPC [0:0]
        /// Capture/compare preloaded
        CCPC: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// CCUS [2:2]
        /// Capture/compare control update
        CCUS: u1 = 0,
        /// CCDS [3:3]
        /// Capture/compare DMA
        CCDS: u1 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// TI1S [7:7]
        /// TI1 selection
        TI1S: u1 = 0,
        /// OIS1 [8:8]
        /// Output Idle state 1
        OIS1: u1 = 0,
        /// OIS1N [9:9]
        /// Output Idle state 1
        OIS1N: u1 = 0,
        /// OIS2 [10:10]
        /// Output Idle state 2
        OIS2: u1 = 0,
        /// OIS2N [11:11]
        /// Output Idle state 2
        OIS2N: u1 = 0,
        /// OIS3 [12:12]
        /// Output Idle state 3
        OIS3: u1 = 0,
        /// OIS3N [13:13]
        /// Output Idle state 3
        OIS3N: u1 = 0,
        /// OIS4 [14:14]
        /// Output Idle state 4
        OIS4: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// ETF [8:11]
        /// External trigger filter
        ETF: u4 = 0,
        /// ETPS [12:13]
        /// External trigger prescaler
        ETPS: u2 = 0,
        /// ECE [14:14]
        /// External clock enable
        ECE: u1 = 0,
        /// ETP [15:15]
        /// External trigger polarity
        ETP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// CC3IE [3:3]
        /// Capture/Compare 3 interrupt
        CC3IE: u1 = 0,
        /// CC4IE [4:4]
        /// Capture/Compare 4 interrupt
        CC4IE: u1 = 0,
        /// COMIE [5:5]
        /// COM interrupt enable
        COMIE: u1 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// BIE [7:7]
        /// Break interrupt enable
        BIE: u1 = 0,
        /// UDE [8:8]
        /// Update DMA request enable
        UDE: u1 = 0,
        /// CC1DE [9:9]
        /// Capture/Compare 1 DMA request
        CC1DE: u1 = 0,
        /// CC2DE [10:10]
        /// Capture/Compare 2 DMA request
        CC2DE: u1 = 0,
        /// CC3DE [11:11]
        /// Capture/Compare 3 DMA request
        CC3DE: u1 = 0,
        /// CC4DE [12:12]
        /// Capture/Compare 4 DMA request
        CC4DE: u1 = 0,
        /// COMDE [13:13]
        /// COM DMA request enable
        COMDE: u1 = 0,
        /// TDE [14:14]
        /// Trigger DMA request enable
        TDE: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// CC3IF [3:3]
        /// Capture/Compare 3 interrupt
        CC3IF: u1 = 0,
        /// CC4IF [4:4]
        /// Capture/Compare 4 interrupt
        CC4IF: u1 = 0,
        /// COMIF [5:5]
        /// COM interrupt flag
        COMIF: u1 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// BIF [7:7]
        /// Break interrupt flag
        BIF: u1 = 0,
        /// unused [8:8]
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// CC3OF [11:11]
        /// Capture/Compare 3 overcapture
        CC3OF: u1 = 0,
        /// CC4OF [12:12]
        /// Capture/Compare 4 overcapture
        CC4OF: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// CC3G [3:3]
        /// Capture/compare 3
        CC3G: u1 = 0,
        /// CC4G [4:4]
        /// Capture/compare 4
        CC4G: u1 = 0,
        /// COMG [5:5]
        /// Capture/Compare control update
        COMG: u1 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// BG [7:7]
        /// Break generation
        BG: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// Output Compare 1 fast
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// Output Compare 1 preload
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// Output Compare 1 mode
        OC1M: u3 = 0,
        /// OC1CE [7:7]
        /// Output Compare 1 clear
        OC1CE: u1 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// Output Compare 2 fast
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// Output Compare 2 preload
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// Output Compare 2 mode
        OC2M: u3 = 0,
        /// OC2CE [15:15]
        /// Output Compare 2 clear
        OC2CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:15]
        /// Input capture 2 filter
        IC2F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCMR2_Output
    const CCMR2_Output_val = packed struct {
        /// CC3S [0:1]
        /// Capture/Compare 3
        CC3S: u2 = 0,
        /// OC3FE [2:2]
        /// Output compare 3 fast
        OC3FE: u1 = 0,
        /// OC3PE [3:3]
        /// Output compare 3 preload
        OC3PE: u1 = 0,
        /// OC3M [4:6]
        /// Output compare 3 mode
        OC3M: u3 = 0,
        /// OC3CE [7:7]
        /// Output compare 3 clear
        OC3CE: u1 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// OC4FE [10:10]
        /// Output compare 4 fast
        OC4FE: u1 = 0,
        /// OC4PE [11:11]
        /// Output compare 4 preload
        OC4PE: u1 = 0,
        /// OC4M [12:14]
        /// Output compare 4 mode
        OC4M: u3 = 0,
        /// OC4CE [15:15]
        /// Output compare 4 clear
        OC4CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (output
    pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

    /// CCMR2_Input
    const CCMR2_Input_val = packed struct {
        /// CC3S [0:1]
        /// Capture/compare 3
        CC3S: u2 = 0,
        /// IC3PSC [2:3]
        /// Input capture 3 prescaler
        IC3PSC: u2 = 0,
        /// IC3F [4:7]
        /// Input capture 3 filter
        IC3F: u4 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// IC4PSC [10:11]
        /// Input capture 4 prescaler
        IC4PSC: u2 = 0,
        /// IC4F [12:15]
        /// Input capture 4 filter
        IC4F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (input
    pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// CC1NE [2:2]
        /// Capture/Compare 1 complementary output
        CC1NE: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// CC2NE [6:6]
        /// Capture/Compare 2 complementary output
        CC2NE: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// CC3E [8:8]
        /// Capture/Compare 3 output
        CC3E: u1 = 0,
        /// CC3P [9:9]
        /// Capture/Compare 3 output
        CC3P: u1 = 0,
        /// CC3NE [10:10]
        /// Capture/Compare 3 complementary output
        CC3NE: u1 = 0,
        /// CC3NP [11:11]
        /// Capture/Compare 3 output
        CC3NP: u1 = 0,
        /// CC4E [12:12]
        /// Capture/Compare 4 output
        CC4E: u1 = 0,
        /// CC4P [13:13]
        /// Capture/Compare 3 output
        CC4P: u1 = 0,
        /// unused [14:31]
        _unused14: u2 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT [0:15]
        /// counter value
        CNT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR [0:15]
        /// Auto-reload value
        ARR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1 [0:15]
        /// Capture/Compare 1 value
        CCR1: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2 [0:15]
        /// Capture/Compare 2 value
        CCR2: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

    /// CCR3
    const CCR3_val = packed struct {
        /// CCR3 [0:15]
        /// Capture/Compare value
        CCR3: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 3
    pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

    /// CCR4
    const CCR4_val = packed struct {
        /// CCR4 [0:15]
        /// Capture/Compare value
        CCR4: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 4
    pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

    /// DCR
    const DCR_val = packed struct {
        /// DBA [0:4]
        /// DMA base address
        DBA: u5 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// DBL [8:12]
        /// DMA burst length
        DBL: u5 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA control register
    pub const DCR = Register(DCR_val).init(base_address + 0x48);

    /// DMAR
    const DMAR_val = packed struct {
        /// DMAB [0:15]
        /// DMA register for burst
        DMAB: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA address for full transfer
    pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

    /// RCR
    const RCR_val = packed struct {
        /// REP [0:7]
        /// Repetition counter value
        REP: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// repetition counter register
    pub const RCR = Register(RCR_val).init(base_address + 0x30);

    /// BDTR
    const BDTR_val = packed struct {
        /// DTG [0:7]
        /// Dead-time generator setup
        DTG: u8 = 0,
        /// LOCK [8:9]
        /// Lock configuration
        LOCK: u2 = 0,
        /// OSSI [10:10]
        /// Off-state selection for Idle
        OSSI: u1 = 0,
        /// OSSR [11:11]
        /// Off-state selection for Run
        OSSR: u1 = 0,
        /// BKE [12:12]
        /// Break enable
        BKE: u1 = 0,
        /// BKP [13:13]
        /// Break polarity
        BKP: u1 = 0,
        /// AOE [14:14]
        /// Automatic output enable
        AOE: u1 = 0,
        /// MOE [15:15]
        /// Main output enable
        MOE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// break and dead-time register
    pub const BDTR = Register(BDTR_val).init(base_address + 0x44);
};

/// General-purpose-timers
pub const TIM10 = struct {
    const base_address = 0x40014400;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// unused [3:6]
        _unused3: u4 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// unused [2:8]
        _unused2: u6 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// Output Compare 1 fast
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// Output Compare 1 preload
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// Output Compare 1 mode
        OC1M: u3 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// unused [4:31]
        _unused4: u4 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT [0:15]
        /// counter value
        CNT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR [0:15]
        /// Auto-reload value
        ARR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1 [0:15]
        /// Capture/Compare 1 value
        CCR1: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);
};

/// General-purpose-timers
pub const TIM11 = struct {
    const base_address = 0x40014800;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// unused [3:6]
        _unused3: u4 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// unused [2:8]
        _unused2: u6 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// Output Compare 1 fast
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// Output Compare 1 preload
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// Output Compare 1 mode
        OC1M: u3 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// unused [4:31]
        _unused4: u4 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT [0:15]
        /// counter value
        CNT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR [0:15]
        /// Auto-reload value
        ARR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1 [0:15]
        /// Capture/Compare 1 value
        CCR1: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// OR
    const OR_val = packed struct {
        /// RMP [0:1]
        /// Input 1 remapping
        RMP: u2 = 0,
        /// unused [2:31]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// option register
    pub const OR = Register(OR_val).init(base_address + 0x50);
};

/// General purpose timers
pub const TIM2 = struct {
    const base_address = 0x40000000;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// DIR [4:4]
        /// Direction
        DIR: u1 = 0,
        /// CMS [5:6]
        /// Center-aligned mode
        CMS: u2 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// unused [0:2]
        _unused0: u3 = 0,
        /// CCDS [3:3]
        /// Capture/compare DMA
        CCDS: u1 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// TI1S [7:7]
        /// TI1 selection
        TI1S: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// ETF [8:11]
        /// External trigger filter
        ETF: u4 = 0,
        /// ETPS [12:13]
        /// External trigger prescaler
        ETPS: u2 = 0,
        /// ECE [14:14]
        /// External clock enable
        ECE: u1 = 0,
        /// ETP [15:15]
        /// External trigger polarity
        ETP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// CC3IE [3:3]
        /// Capture/Compare 3 interrupt
        CC3IE: u1 = 0,
        /// CC4IE [4:4]
        /// Capture/Compare 4 interrupt
        CC4IE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// UDE [8:8]
        /// Update DMA request enable
        UDE: u1 = 0,
        /// CC1DE [9:9]
        /// Capture/Compare 1 DMA request
        CC1DE: u1 = 0,
        /// CC2DE [10:10]
        /// Capture/Compare 2 DMA request
        CC2DE: u1 = 0,
        /// CC3DE [11:11]
        /// Capture/Compare 3 DMA request
        CC3DE: u1 = 0,
        /// CC4DE [12:12]
        /// Capture/Compare 4 DMA request
        CC4DE: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TDE [14:14]
        /// Trigger DMA request enable
        TDE: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// CC3IF [3:3]
        /// Capture/Compare 3 interrupt
        CC3IF: u1 = 0,
        /// CC4IF [4:4]
        /// Capture/Compare 4 interrupt
        CC4IF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// unused [7:8]
        _unused7: u1 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// CC3OF [11:11]
        /// Capture/Compare 3 overcapture
        CC3OF: u1 = 0,
        /// CC4OF [12:12]
        /// Capture/Compare 4 overcapture
        CC4OF: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// CC3G [3:3]
        /// Capture/compare 3
        CC3G: u1 = 0,
        /// CC4G [4:4]
        /// Capture/compare 4
        CC4G: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// CC1S
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// OC1FE
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// OC1PE
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// OC1M
        OC1M: u3 = 0,
        /// OC1CE [7:7]
        /// OC1CE
        OC1CE: u1 = 0,
        /// CC2S [8:9]
        /// CC2S
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// OC2FE
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// OC2PE
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// OC2M
        OC2M: u3 = 0,
        /// OC2CE [15:15]
        /// OC2CE
        OC2CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:15]
        /// Input capture 2 filter
        IC2F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCMR2_Output
    const CCMR2_Output_val = packed struct {
        /// CC3S [0:1]
        /// CC3S
        CC3S: u2 = 0,
        /// OC3FE [2:2]
        /// OC3FE
        OC3FE: u1 = 0,
        /// OC3PE [3:3]
        /// OC3PE
        OC3PE: u1 = 0,
        /// OC3M [4:6]
        /// OC3M
        OC3M: u3 = 0,
        /// OC3CE [7:7]
        /// OC3CE
        OC3CE: u1 = 0,
        /// CC4S [8:9]
        /// CC4S
        CC4S: u2 = 0,
        /// OC4FE [10:10]
        /// OC4FE
        OC4FE: u1 = 0,
        /// OC4PE [11:11]
        /// OC4PE
        OC4PE: u1 = 0,
        /// OC4M [12:14]
        /// OC4M
        OC4M: u3 = 0,
        /// O24CE [15:15]
        /// O24CE
        O24CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (output
    pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

    /// CCMR2_Input
    const CCMR2_Input_val = packed struct {
        /// CC3S [0:1]
        /// Capture/compare 3
        CC3S: u2 = 0,
        /// IC3PSC [2:3]
        /// Input capture 3 prescaler
        IC3PSC: u2 = 0,
        /// IC3F [4:7]
        /// Input capture 3 filter
        IC3F: u4 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// IC4PSC [10:11]
        /// Input capture 4 prescaler
        IC4PSC: u2 = 0,
        /// IC4F [12:15]
        /// Input capture 4 filter
        IC4F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (input
    pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// CC3E [8:8]
        /// Capture/Compare 3 output
        CC3E: u1 = 0,
        /// CC3P [9:9]
        /// Capture/Compare 3 output
        CC3P: u1 = 0,
        /// unused [10:10]
        _unused10: u1 = 0,
        /// CC3NP [11:11]
        /// Capture/Compare 3 output
        CC3NP: u1 = 0,
        /// CC4E [12:12]
        /// Capture/Compare 4 output
        CC4E: u1 = 0,
        /// CC4P [13:13]
        /// Capture/Compare 3 output
        CC4P: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// CC4NP [15:15]
        /// Capture/Compare 4 output
        CC4NP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT_L [0:15]
        /// Low counter value
        CNT_L: u16 = 0,
        /// CNT_H [16:31]
        /// High counter value
        CNT_H: u16 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR_L [0:15]
        /// Low Auto-reload value
        ARR_L: u16 = 0,
        /// ARR_H [16:31]
        /// High Auto-reload value
        ARR_H: u16 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1_L [0:15]
        /// Low Capture/Compare 1
        CCR1_L: u16 = 0,
        /// CCR1_H [16:31]
        /// High Capture/Compare 1
        CCR1_H: u16 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2_L [0:15]
        /// Low Capture/Compare 2
        CCR2_L: u16 = 0,
        /// CCR2_H [16:31]
        /// High Capture/Compare 2
        CCR2_H: u16 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

    /// CCR3
    const CCR3_val = packed struct {
        /// CCR3_L [0:15]
        /// Low Capture/Compare value
        CCR3_L: u16 = 0,
        /// CCR3_H [16:31]
        /// High Capture/Compare value
        CCR3_H: u16 = 0,
    };
    /// capture/compare register 3
    pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

    /// CCR4
    const CCR4_val = packed struct {
        /// CCR4_L [0:15]
        /// Low Capture/Compare value
        CCR4_L: u16 = 0,
        /// CCR4_H [16:31]
        /// High Capture/Compare value
        CCR4_H: u16 = 0,
    };
    /// capture/compare register 4
    pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

    /// DCR
    const DCR_val = packed struct {
        /// DBA [0:4]
        /// DMA base address
        DBA: u5 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// DBL [8:12]
        /// DMA burst length
        DBL: u5 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA control register
    pub const DCR = Register(DCR_val).init(base_address + 0x48);

    /// DMAR
    const DMAR_val = packed struct {
        /// DMAB [0:15]
        /// DMA register for burst
        DMAB: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA address for full transfer
    pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

    /// OR
    const OR_val = packed struct {
        /// unused [0:9]
        _unused0: u8 = 0,
        _unused8: u2 = 0,
        /// ITR1_RMP [10:11]
        /// Timer Input 4 remap
        ITR1_RMP: u2 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TIM5 option register
    pub const OR = Register(OR_val).init(base_address + 0x50);
};

/// General purpose timers
pub const TIM3 = struct {
    const base_address = 0x40000400;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// DIR [4:4]
        /// Direction
        DIR: u1 = 0,
        /// CMS [5:6]
        /// Center-aligned mode
        CMS: u2 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// unused [0:2]
        _unused0: u3 = 0,
        /// CCDS [3:3]
        /// Capture/compare DMA
        CCDS: u1 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// TI1S [7:7]
        /// TI1 selection
        TI1S: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// ETF [8:11]
        /// External trigger filter
        ETF: u4 = 0,
        /// ETPS [12:13]
        /// External trigger prescaler
        ETPS: u2 = 0,
        /// ECE [14:14]
        /// External clock enable
        ECE: u1 = 0,
        /// ETP [15:15]
        /// External trigger polarity
        ETP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// CC3IE [3:3]
        /// Capture/Compare 3 interrupt
        CC3IE: u1 = 0,
        /// CC4IE [4:4]
        /// Capture/Compare 4 interrupt
        CC4IE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// UDE [8:8]
        /// Update DMA request enable
        UDE: u1 = 0,
        /// CC1DE [9:9]
        /// Capture/Compare 1 DMA request
        CC1DE: u1 = 0,
        /// CC2DE [10:10]
        /// Capture/Compare 2 DMA request
        CC2DE: u1 = 0,
        /// CC3DE [11:11]
        /// Capture/Compare 3 DMA request
        CC3DE: u1 = 0,
        /// CC4DE [12:12]
        /// Capture/Compare 4 DMA request
        CC4DE: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TDE [14:14]
        /// Trigger DMA request enable
        TDE: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// CC3IF [3:3]
        /// Capture/Compare 3 interrupt
        CC3IF: u1 = 0,
        /// CC4IF [4:4]
        /// Capture/Compare 4 interrupt
        CC4IF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// unused [7:8]
        _unused7: u1 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// CC3OF [11:11]
        /// Capture/Compare 3 overcapture
        CC3OF: u1 = 0,
        /// CC4OF [12:12]
        /// Capture/Compare 4 overcapture
        CC4OF: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// CC3G [3:3]
        /// Capture/compare 3
        CC3G: u1 = 0,
        /// CC4G [4:4]
        /// Capture/compare 4
        CC4G: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// CC1S
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// OC1FE
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// OC1PE
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// OC1M
        OC1M: u3 = 0,
        /// OC1CE [7:7]
        /// OC1CE
        OC1CE: u1 = 0,
        /// CC2S [8:9]
        /// CC2S
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// OC2FE
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// OC2PE
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// OC2M
        OC2M: u3 = 0,
        /// OC2CE [15:15]
        /// OC2CE
        OC2CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:15]
        /// Input capture 2 filter
        IC2F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCMR2_Output
    const CCMR2_Output_val = packed struct {
        /// CC3S [0:1]
        /// CC3S
        CC3S: u2 = 0,
        /// OC3FE [2:2]
        /// OC3FE
        OC3FE: u1 = 0,
        /// OC3PE [3:3]
        /// OC3PE
        OC3PE: u1 = 0,
        /// OC3M [4:6]
        /// OC3M
        OC3M: u3 = 0,
        /// OC3CE [7:7]
        /// OC3CE
        OC3CE: u1 = 0,
        /// CC4S [8:9]
        /// CC4S
        CC4S: u2 = 0,
        /// OC4FE [10:10]
        /// OC4FE
        OC4FE: u1 = 0,
        /// OC4PE [11:11]
        /// OC4PE
        OC4PE: u1 = 0,
        /// OC4M [12:14]
        /// OC4M
        OC4M: u3 = 0,
        /// O24CE [15:15]
        /// O24CE
        O24CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (output
    pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

    /// CCMR2_Input
    const CCMR2_Input_val = packed struct {
        /// CC3S [0:1]
        /// Capture/compare 3
        CC3S: u2 = 0,
        /// IC3PSC [2:3]
        /// Input capture 3 prescaler
        IC3PSC: u2 = 0,
        /// IC3F [4:7]
        /// Input capture 3 filter
        IC3F: u4 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// IC4PSC [10:11]
        /// Input capture 4 prescaler
        IC4PSC: u2 = 0,
        /// IC4F [12:15]
        /// Input capture 4 filter
        IC4F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (input
    pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// CC3E [8:8]
        /// Capture/Compare 3 output
        CC3E: u1 = 0,
        /// CC3P [9:9]
        /// Capture/Compare 3 output
        CC3P: u1 = 0,
        /// unused [10:10]
        _unused10: u1 = 0,
        /// CC3NP [11:11]
        /// Capture/Compare 3 output
        CC3NP: u1 = 0,
        /// CC4E [12:12]
        /// Capture/Compare 4 output
        CC4E: u1 = 0,
        /// CC4P [13:13]
        /// Capture/Compare 3 output
        CC4P: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// CC4NP [15:15]
        /// Capture/Compare 4 output
        CC4NP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT_L [0:15]
        /// Low counter value
        CNT_L: u16 = 0,
        /// CNT_H [16:31]
        /// High counter value
        CNT_H: u16 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR_L [0:15]
        /// Low Auto-reload value
        ARR_L: u16 = 0,
        /// ARR_H [16:31]
        /// High Auto-reload value
        ARR_H: u16 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1_L [0:15]
        /// Low Capture/Compare 1
        CCR1_L: u16 = 0,
        /// CCR1_H [16:31]
        /// High Capture/Compare 1
        CCR1_H: u16 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2_L [0:15]
        /// Low Capture/Compare 2
        CCR2_L: u16 = 0,
        /// CCR2_H [16:31]
        /// High Capture/Compare 2
        CCR2_H: u16 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

    /// CCR3
    const CCR3_val = packed struct {
        /// CCR3_L [0:15]
        /// Low Capture/Compare value
        CCR3_L: u16 = 0,
        /// CCR3_H [16:31]
        /// High Capture/Compare value
        CCR3_H: u16 = 0,
    };
    /// capture/compare register 3
    pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

    /// CCR4
    const CCR4_val = packed struct {
        /// CCR4_L [0:15]
        /// Low Capture/Compare value
        CCR4_L: u16 = 0,
        /// CCR4_H [16:31]
        /// High Capture/Compare value
        CCR4_H: u16 = 0,
    };
    /// capture/compare register 4
    pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

    /// DCR
    const DCR_val = packed struct {
        /// DBA [0:4]
        /// DMA base address
        DBA: u5 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// DBL [8:12]
        /// DMA burst length
        DBL: u5 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA control register
    pub const DCR = Register(DCR_val).init(base_address + 0x48);

    /// DMAR
    const DMAR_val = packed struct {
        /// DMAB [0:15]
        /// DMA register for burst
        DMAB: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA address for full transfer
    pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);
};

/// General purpose timers
pub const TIM4 = struct {
    const base_address = 0x40000800;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// DIR [4:4]
        /// Direction
        DIR: u1 = 0,
        /// CMS [5:6]
        /// Center-aligned mode
        CMS: u2 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// unused [0:2]
        _unused0: u3 = 0,
        /// CCDS [3:3]
        /// Capture/compare DMA
        CCDS: u1 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// TI1S [7:7]
        /// TI1 selection
        TI1S: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// ETF [8:11]
        /// External trigger filter
        ETF: u4 = 0,
        /// ETPS [12:13]
        /// External trigger prescaler
        ETPS: u2 = 0,
        /// ECE [14:14]
        /// External clock enable
        ECE: u1 = 0,
        /// ETP [15:15]
        /// External trigger polarity
        ETP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// CC3IE [3:3]
        /// Capture/Compare 3 interrupt
        CC3IE: u1 = 0,
        /// CC4IE [4:4]
        /// Capture/Compare 4 interrupt
        CC4IE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// UDE [8:8]
        /// Update DMA request enable
        UDE: u1 = 0,
        /// CC1DE [9:9]
        /// Capture/Compare 1 DMA request
        CC1DE: u1 = 0,
        /// CC2DE [10:10]
        /// Capture/Compare 2 DMA request
        CC2DE: u1 = 0,
        /// CC3DE [11:11]
        /// Capture/Compare 3 DMA request
        CC3DE: u1 = 0,
        /// CC4DE [12:12]
        /// Capture/Compare 4 DMA request
        CC4DE: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TDE [14:14]
        /// Trigger DMA request enable
        TDE: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// CC3IF [3:3]
        /// Capture/Compare 3 interrupt
        CC3IF: u1 = 0,
        /// CC4IF [4:4]
        /// Capture/Compare 4 interrupt
        CC4IF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// unused [7:8]
        _unused7: u1 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// CC3OF [11:11]
        /// Capture/Compare 3 overcapture
        CC3OF: u1 = 0,
        /// CC4OF [12:12]
        /// Capture/Compare 4 overcapture
        CC4OF: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// CC3G [3:3]
        /// Capture/compare 3
        CC3G: u1 = 0,
        /// CC4G [4:4]
        /// Capture/compare 4
        CC4G: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// CC1S
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// OC1FE
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// OC1PE
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// OC1M
        OC1M: u3 = 0,
        /// OC1CE [7:7]
        /// OC1CE
        OC1CE: u1 = 0,
        /// CC2S [8:9]
        /// CC2S
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// OC2FE
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// OC2PE
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// OC2M
        OC2M: u3 = 0,
        /// OC2CE [15:15]
        /// OC2CE
        OC2CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:15]
        /// Input capture 2 filter
        IC2F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCMR2_Output
    const CCMR2_Output_val = packed struct {
        /// CC3S [0:1]
        /// CC3S
        CC3S: u2 = 0,
        /// OC3FE [2:2]
        /// OC3FE
        OC3FE: u1 = 0,
        /// OC3PE [3:3]
        /// OC3PE
        OC3PE: u1 = 0,
        /// OC3M [4:6]
        /// OC3M
        OC3M: u3 = 0,
        /// OC3CE [7:7]
        /// OC3CE
        OC3CE: u1 = 0,
        /// CC4S [8:9]
        /// CC4S
        CC4S: u2 = 0,
        /// OC4FE [10:10]
        /// OC4FE
        OC4FE: u1 = 0,
        /// OC4PE [11:11]
        /// OC4PE
        OC4PE: u1 = 0,
        /// OC4M [12:14]
        /// OC4M
        OC4M: u3 = 0,
        /// O24CE [15:15]
        /// O24CE
        O24CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (output
    pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

    /// CCMR2_Input
    const CCMR2_Input_val = packed struct {
        /// CC3S [0:1]
        /// Capture/compare 3
        CC3S: u2 = 0,
        /// IC3PSC [2:3]
        /// Input capture 3 prescaler
        IC3PSC: u2 = 0,
        /// IC3F [4:7]
        /// Input capture 3 filter
        IC3F: u4 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// IC4PSC [10:11]
        /// Input capture 4 prescaler
        IC4PSC: u2 = 0,
        /// IC4F [12:15]
        /// Input capture 4 filter
        IC4F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (input
    pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// CC3E [8:8]
        /// Capture/Compare 3 output
        CC3E: u1 = 0,
        /// CC3P [9:9]
        /// Capture/Compare 3 output
        CC3P: u1 = 0,
        /// unused [10:10]
        _unused10: u1 = 0,
        /// CC3NP [11:11]
        /// Capture/Compare 3 output
        CC3NP: u1 = 0,
        /// CC4E [12:12]
        /// Capture/Compare 4 output
        CC4E: u1 = 0,
        /// CC4P [13:13]
        /// Capture/Compare 3 output
        CC4P: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// CC4NP [15:15]
        /// Capture/Compare 4 output
        CC4NP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT_L [0:15]
        /// Low counter value
        CNT_L: u16 = 0,
        /// CNT_H [16:31]
        /// High counter value
        CNT_H: u16 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR_L [0:15]
        /// Low Auto-reload value
        ARR_L: u16 = 0,
        /// ARR_H [16:31]
        /// High Auto-reload value
        ARR_H: u16 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1_L [0:15]
        /// Low Capture/Compare 1
        CCR1_L: u16 = 0,
        /// CCR1_H [16:31]
        /// High Capture/Compare 1
        CCR1_H: u16 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2_L [0:15]
        /// Low Capture/Compare 2
        CCR2_L: u16 = 0,
        /// CCR2_H [16:31]
        /// High Capture/Compare 2
        CCR2_H: u16 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

    /// CCR3
    const CCR3_val = packed struct {
        /// CCR3_L [0:15]
        /// Low Capture/Compare value
        CCR3_L: u16 = 0,
        /// CCR3_H [16:31]
        /// High Capture/Compare value
        CCR3_H: u16 = 0,
    };
    /// capture/compare register 3
    pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

    /// CCR4
    const CCR4_val = packed struct {
        /// CCR4_L [0:15]
        /// Low Capture/Compare value
        CCR4_L: u16 = 0,
        /// CCR4_H [16:31]
        /// High Capture/Compare value
        CCR4_H: u16 = 0,
    };
    /// capture/compare register 4
    pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

    /// DCR
    const DCR_val = packed struct {
        /// DBA [0:4]
        /// DMA base address
        DBA: u5 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// DBL [8:12]
        /// DMA burst length
        DBL: u5 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA control register
    pub const DCR = Register(DCR_val).init(base_address + 0x48);

    /// DMAR
    const DMAR_val = packed struct {
        /// DMAB [0:15]
        /// DMA register for burst
        DMAB: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA address for full transfer
    pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);
};

/// General-purpose-timers
pub const TIM5 = struct {
    const base_address = 0x40000c00;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// DIR [4:4]
        /// Direction
        DIR: u1 = 0,
        /// CMS [5:6]
        /// Center-aligned mode
        CMS: u2 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// unused [0:2]
        _unused0: u3 = 0,
        /// CCDS [3:3]
        /// Capture/compare DMA
        CCDS: u1 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// TI1S [7:7]
        /// TI1 selection
        TI1S: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// ETF [8:11]
        /// External trigger filter
        ETF: u4 = 0,
        /// ETPS [12:13]
        /// External trigger prescaler
        ETPS: u2 = 0,
        /// ECE [14:14]
        /// External clock enable
        ECE: u1 = 0,
        /// ETP [15:15]
        /// External trigger polarity
        ETP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// CC3IE [3:3]
        /// Capture/Compare 3 interrupt
        CC3IE: u1 = 0,
        /// CC4IE [4:4]
        /// Capture/Compare 4 interrupt
        CC4IE: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// UDE [8:8]
        /// Update DMA request enable
        UDE: u1 = 0,
        /// CC1DE [9:9]
        /// Capture/Compare 1 DMA request
        CC1DE: u1 = 0,
        /// CC2DE [10:10]
        /// Capture/Compare 2 DMA request
        CC2DE: u1 = 0,
        /// CC3DE [11:11]
        /// Capture/Compare 3 DMA request
        CC3DE: u1 = 0,
        /// CC4DE [12:12]
        /// Capture/Compare 4 DMA request
        CC4DE: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TDE [14:14]
        /// Trigger DMA request enable
        TDE: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// CC3IF [3:3]
        /// Capture/Compare 3 interrupt
        CC3IF: u1 = 0,
        /// CC4IF [4:4]
        /// Capture/Compare 4 interrupt
        CC4IF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// unused [7:8]
        _unused7: u1 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// CC3OF [11:11]
        /// Capture/Compare 3 overcapture
        CC3OF: u1 = 0,
        /// CC4OF [12:12]
        /// Capture/Compare 4 overcapture
        CC4OF: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// CC3G [3:3]
        /// Capture/compare 3
        CC3G: u1 = 0,
        /// CC4G [4:4]
        /// Capture/compare 4
        CC4G: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// CC1S
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// OC1FE
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// OC1PE
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// OC1M
        OC1M: u3 = 0,
        /// OC1CE [7:7]
        /// OC1CE
        OC1CE: u1 = 0,
        /// CC2S [8:9]
        /// CC2S
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// OC2FE
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// OC2PE
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// OC2M
        OC2M: u3 = 0,
        /// OC2CE [15:15]
        /// OC2CE
        OC2CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:7]
        /// Input capture 1 filter
        IC1F: u4 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:15]
        /// Input capture 2 filter
        IC2F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCMR2_Output
    const CCMR2_Output_val = packed struct {
        /// CC3S [0:1]
        /// CC3S
        CC3S: u2 = 0,
        /// OC3FE [2:2]
        /// OC3FE
        OC3FE: u1 = 0,
        /// OC3PE [3:3]
        /// OC3PE
        OC3PE: u1 = 0,
        /// OC3M [4:6]
        /// OC3M
        OC3M: u3 = 0,
        /// OC3CE [7:7]
        /// OC3CE
        OC3CE: u1 = 0,
        /// CC4S [8:9]
        /// CC4S
        CC4S: u2 = 0,
        /// OC4FE [10:10]
        /// OC4FE
        OC4FE: u1 = 0,
        /// OC4PE [11:11]
        /// OC4PE
        OC4PE: u1 = 0,
        /// OC4M [12:14]
        /// OC4M
        OC4M: u3 = 0,
        /// O24CE [15:15]
        /// O24CE
        O24CE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (output
    pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

    /// CCMR2_Input
    const CCMR2_Input_val = packed struct {
        /// CC3S [0:1]
        /// Capture/compare 3
        CC3S: u2 = 0,
        /// IC3PSC [2:3]
        /// Input capture 3 prescaler
        IC3PSC: u2 = 0,
        /// IC3F [4:7]
        /// Input capture 3 filter
        IC3F: u4 = 0,
        /// CC4S [8:9]
        /// Capture/Compare 4
        CC4S: u2 = 0,
        /// IC4PSC [10:11]
        /// Input capture 4 prescaler
        IC4PSC: u2 = 0,
        /// IC4F [12:15]
        /// Input capture 4 filter
        IC4F: u4 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 2 (input
    pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// CC3E [8:8]
        /// Capture/Compare 3 output
        CC3E: u1 = 0,
        /// CC3P [9:9]
        /// Capture/Compare 3 output
        CC3P: u1 = 0,
        /// unused [10:10]
        _unused10: u1 = 0,
        /// CC3NP [11:11]
        /// Capture/Compare 3 output
        CC3NP: u1 = 0,
        /// CC4E [12:12]
        /// Capture/Compare 4 output
        CC4E: u1 = 0,
        /// CC4P [13:13]
        /// Capture/Compare 3 output
        CC4P: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// CC4NP [15:15]
        /// Capture/Compare 4 output
        CC4NP: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT_L [0:15]
        /// Low counter value
        CNT_L: u16 = 0,
        /// CNT_H [16:31]
        /// High counter value
        CNT_H: u16 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR_L [0:15]
        /// Low Auto-reload value
        ARR_L: u16 = 0,
        /// ARR_H [16:31]
        /// High Auto-reload value
        ARR_H: u16 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1_L [0:15]
        /// Low Capture/Compare 1
        CCR1_L: u16 = 0,
        /// CCR1_H [16:31]
        /// High Capture/Compare 1
        CCR1_H: u16 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2_L [0:15]
        /// Low Capture/Compare 2
        CCR2_L: u16 = 0,
        /// CCR2_H [16:31]
        /// High Capture/Compare 2
        CCR2_H: u16 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

    /// CCR3
    const CCR3_val = packed struct {
        /// CCR3_L [0:15]
        /// Low Capture/Compare value
        CCR3_L: u16 = 0,
        /// CCR3_H [16:31]
        /// High Capture/Compare value
        CCR3_H: u16 = 0,
    };
    /// capture/compare register 3
    pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

    /// CCR4
    const CCR4_val = packed struct {
        /// CCR4_L [0:15]
        /// Low Capture/Compare value
        CCR4_L: u16 = 0,
        /// CCR4_H [16:31]
        /// High Capture/Compare value
        CCR4_H: u16 = 0,
    };
    /// capture/compare register 4
    pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

    /// DCR
    const DCR_val = packed struct {
        /// DBA [0:4]
        /// DMA base address
        DBA: u5 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// DBL [8:12]
        /// DMA burst length
        DBL: u5 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA control register
    pub const DCR = Register(DCR_val).init(base_address + 0x48);

    /// DMAR
    const DMAR_val = packed struct {
        /// DMAB [0:15]
        /// DMA register for burst
        DMAB: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA address for full transfer
    pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

    /// OR
    const OR_val = packed struct {
        /// unused [0:5]
        _unused0: u6 = 0,
        /// IT4_RMP [6:7]
        /// Timer Input 4 remap
        IT4_RMP: u2 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TIM5 option register
    pub const OR = Register(OR_val).init(base_address + 0x50);
};

/// General purpose timers
pub const TIM9 = struct {
    const base_address = 0x40014000;
    /// CR1
    const CR1_val = packed struct {
        /// CEN [0:0]
        /// Counter enable
        CEN: u1 = 0,
        /// UDIS [1:1]
        /// Update disable
        UDIS: u1 = 0,
        /// URS [2:2]
        /// Update request source
        URS: u1 = 0,
        /// OPM [3:3]
        /// One-pulse mode
        OPM: u1 = 0,
        /// unused [4:6]
        _unused4: u3 = 0,
        /// ARPE [7:7]
        /// Auto-reload preload enable
        ARPE: u1 = 0,
        /// CKD [8:9]
        /// Clock division
        CKD: u2 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// unused [0:3]
        _unused0: u4 = 0,
        /// MMS [4:6]
        /// Master mode selection
        MMS: u3 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SMCR
    const SMCR_val = packed struct {
        /// SMS [0:2]
        /// Slave mode selection
        SMS: u3 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// TS [4:6]
        /// Trigger selection
        TS: u3 = 0,
        /// MSM [7:7]
        /// Master/Slave mode
        MSM: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// slave mode control register
    pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

    /// DIER
    const DIER_val = packed struct {
        /// UIE [0:0]
        /// Update interrupt enable
        UIE: u1 = 0,
        /// CC1IE [1:1]
        /// Capture/Compare 1 interrupt
        CC1IE: u1 = 0,
        /// CC2IE [2:2]
        /// Capture/Compare 2 interrupt
        CC2IE: u1 = 0,
        /// unused [3:5]
        _unused3: u3 = 0,
        /// TIE [6:6]
        /// Trigger interrupt enable
        TIE: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// DMA/Interrupt enable register
    pub const DIER = Register(DIER_val).init(base_address + 0xc);

    /// SR
    const SR_val = packed struct {
        /// UIF [0:0]
        /// Update interrupt flag
        UIF: u1 = 0,
        /// CC1IF [1:1]
        /// Capture/compare 1 interrupt
        CC1IF: u1 = 0,
        /// CC2IF [2:2]
        /// Capture/Compare 2 interrupt
        CC2IF: u1 = 0,
        /// unused [3:5]
        _unused3: u3 = 0,
        /// TIF [6:6]
        /// Trigger interrupt flag
        TIF: u1 = 0,
        /// unused [7:8]
        _unused7: u1 = 0,
        _unused8: u1 = 0,
        /// CC1OF [9:9]
        /// Capture/Compare 1 overcapture
        CC1OF: u1 = 0,
        /// CC2OF [10:10]
        /// Capture/compare 2 overcapture
        CC2OF: u1 = 0,
        /// unused [11:31]
        _unused11: u5 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x10);

    /// EGR
    const EGR_val = packed struct {
        /// UG [0:0]
        /// Update generation
        UG: u1 = 0,
        /// CC1G [1:1]
        /// Capture/compare 1
        CC1G: u1 = 0,
        /// CC2G [2:2]
        /// Capture/compare 2
        CC2G: u1 = 0,
        /// unused [3:5]
        _unused3: u3 = 0,
        /// TG [6:6]
        /// Trigger generation
        TG: u1 = 0,
        /// unused [7:31]
        _unused7: u1 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// event generation register
    pub const EGR = Register(EGR_val).init(base_address + 0x14);

    /// CCMR1_Output
    const CCMR1_Output_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// OC1FE [2:2]
        /// Output Compare 1 fast
        OC1FE: u1 = 0,
        /// OC1PE [3:3]
        /// Output Compare 1 preload
        OC1PE: u1 = 0,
        /// OC1M [4:6]
        /// Output Compare 1 mode
        OC1M: u3 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// OC2FE [10:10]
        /// Output Compare 2 fast
        OC2FE: u1 = 0,
        /// OC2PE [11:11]
        /// Output Compare 2 preload
        OC2PE: u1 = 0,
        /// OC2M [12:14]
        /// Output Compare 2 mode
        OC2M: u3 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (output
    pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

    /// CCMR1_Input
    const CCMR1_Input_val = packed struct {
        /// CC1S [0:1]
        /// Capture/Compare 1
        CC1S: u2 = 0,
        /// ICPCS [2:3]
        /// Input capture 1 prescaler
        ICPCS: u2 = 0,
        /// IC1F [4:6]
        /// Input capture 1 filter
        IC1F: u3 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// CC2S [8:9]
        /// Capture/Compare 2
        CC2S: u2 = 0,
        /// IC2PCS [10:11]
        /// Input capture 2 prescaler
        IC2PCS: u2 = 0,
        /// IC2F [12:14]
        /// Input capture 2 filter
        IC2F: u3 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare mode register 1 (input
    pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

    /// CCER
    const CCER_val = packed struct {
        /// CC1E [0:0]
        /// Capture/Compare 1 output
        CC1E: u1 = 0,
        /// CC1P [1:1]
        /// Capture/Compare 1 output
        CC1P: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// CC1NP [3:3]
        /// Capture/Compare 1 output
        CC1NP: u1 = 0,
        /// CC2E [4:4]
        /// Capture/Compare 2 output
        CC2E: u1 = 0,
        /// CC2P [5:5]
        /// Capture/Compare 2 output
        CC2P: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// CC2NP [7:7]
        /// Capture/Compare 2 output
        CC2NP: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare enable
    pub const CCER = Register(CCER_val).init(base_address + 0x20);

    /// CNT
    const CNT_val = packed struct {
        /// CNT [0:15]
        /// counter value
        CNT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// counter
    pub const CNT = Register(CNT_val).init(base_address + 0x24);

    /// PSC
    const PSC_val = packed struct {
        /// PSC [0:15]
        /// Prescaler value
        PSC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// prescaler
    pub const PSC = Register(PSC_val).init(base_address + 0x28);

    /// ARR
    const ARR_val = packed struct {
        /// ARR [0:15]
        /// Auto-reload value
        ARR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// auto-reload register
    pub const ARR = Register(ARR_val).init(base_address + 0x2c);

    /// CCR1
    const CCR1_val = packed struct {
        /// CCR1 [0:15]
        /// Capture/Compare 1 value
        CCR1: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 1
    pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

    /// CCR2
    const CCR2_val = packed struct {
        /// CCR2 [0:15]
        /// Capture/Compare 2 value
        CCR2: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// capture/compare register 2
    pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);
};

/// Universal synchronous asynchronous receiver
pub const USART1 = struct {
    const base_address = 0x40011000;
    /// SR
    const SR_val = packed struct {
        /// PE [0:0]
        /// Parity error
        PE: u1 = 0,
        /// FE [1:1]
        /// Framing error
        FE: u1 = 0,
        /// NF [2:2]
        /// Noise detected flag
        NF: u1 = 0,
        /// ORE [3:3]
        /// Overrun error
        ORE: u1 = 0,
        /// IDLE [4:4]
        /// IDLE line detected
        IDLE: u1 = 0,
        /// RXNE [5:5]
        /// Read data register not
        RXNE: u1 = 0,
        /// TC [6:6]
        /// Transmission complete
        TC: u1 = 0,
        /// TXE [7:7]
        /// Transmit data register
        TXE: u1 = 0,
        /// LBD [8:8]
        /// LIN break detection flag
        LBD: u1 = 0,
        /// CTS [9:9]
        /// CTS flag
        CTS: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 192,
        _unused24: u8 = 0,
    };
    /// Status register
    pub const SR = Register(SR_val).init(base_address + 0x0);

    /// DR
    const DR_val = packed struct {
        /// DR [0:8]
        /// Data value
        DR: u9 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x4);

    /// BRR
    const BRR_val = packed struct {
        /// DIV_Fraction [0:3]
        /// fraction of USARTDIV
        DIV_Fraction: u4 = 0,
        /// DIV_Mantissa [4:15]
        /// mantissa of USARTDIV
        DIV_Mantissa: u12 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Baud rate register
    pub const BRR = Register(BRR_val).init(base_address + 0x8);

    /// CR1
    const CR1_val = packed struct {
        /// SBK [0:0]
        /// Send break
        SBK: u1 = 0,
        /// RWU [1:1]
        /// Receiver wakeup
        RWU: u1 = 0,
        /// RE [2:2]
        /// Receiver enable
        RE: u1 = 0,
        /// TE [3:3]
        /// Transmitter enable
        TE: u1 = 0,
        /// IDLEIE [4:4]
        /// IDLE interrupt enable
        IDLEIE: u1 = 0,
        /// RXNEIE [5:5]
        /// RXNE interrupt enable
        RXNEIE: u1 = 0,
        /// TCIE [6:6]
        /// Transmission complete interrupt
        TCIE: u1 = 0,
        /// TXEIE [7:7]
        /// TXE interrupt enable
        TXEIE: u1 = 0,
        /// PEIE [8:8]
        /// PE interrupt enable
        PEIE: u1 = 0,
        /// PS [9:9]
        /// Parity selection
        PS: u1 = 0,
        /// PCE [10:10]
        /// Parity control enable
        PCE: u1 = 0,
        /// WAKE [11:11]
        /// Wakeup method
        WAKE: u1 = 0,
        /// M [12:12]
        /// Word length
        M: u1 = 0,
        /// UE [13:13]
        /// USART enable
        UE: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// OVER8 [15:15]
        /// Oversampling mode
        OVER8: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0xc);

    /// CR2
    const CR2_val = packed struct {
        /// ADD [0:3]
        /// Address of the USART node
        ADD: u4 = 0,
        /// unused [4:4]
        _unused4: u1 = 0,
        /// LBDL [5:5]
        /// lin break detection length
        LBDL: u1 = 0,
        /// LBDIE [6:6]
        /// LIN break detection interrupt
        LBDIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// LBCL [8:8]
        /// Last bit clock pulse
        LBCL: u1 = 0,
        /// CPHA [9:9]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [10:10]
        /// Clock polarity
        CPOL: u1 = 0,
        /// CLKEN [11:11]
        /// Clock enable
        CLKEN: u1 = 0,
        /// STOP [12:13]
        /// STOP bits
        STOP: u2 = 0,
        /// LINEN [14:14]
        /// LIN mode enable
        LINEN: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x10);

    /// CR3
    const CR3_val = packed struct {
        /// EIE [0:0]
        /// Error interrupt enable
        EIE: u1 = 0,
        /// IREN [1:1]
        /// IrDA mode enable
        IREN: u1 = 0,
        /// IRLP [2:2]
        /// IrDA low-power
        IRLP: u1 = 0,
        /// HDSEL [3:3]
        /// Half-duplex selection
        HDSEL: u1 = 0,
        /// NACK [4:4]
        /// Smartcard NACK enable
        NACK: u1 = 0,
        /// SCEN [5:5]
        /// Smartcard mode enable
        SCEN: u1 = 0,
        /// DMAR [6:6]
        /// DMA enable receiver
        DMAR: u1 = 0,
        /// DMAT [7:7]
        /// DMA enable transmitter
        DMAT: u1 = 0,
        /// RTSE [8:8]
        /// RTS enable
        RTSE: u1 = 0,
        /// CTSE [9:9]
        /// CTS enable
        CTSE: u1 = 0,
        /// CTSIE [10:10]
        /// CTS interrupt enable
        CTSIE: u1 = 0,
        /// ONEBIT [11:11]
        /// One sample bit method
        ONEBIT: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 3
    pub const CR3 = Register(CR3_val).init(base_address + 0x14);

    /// GTPR
    const GTPR_val = packed struct {
        /// PSC [0:7]
        /// Prescaler value
        PSC: u8 = 0,
        /// GT [8:15]
        /// Guard time value
        GT: u8 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Guard time and prescaler
    pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Universal synchronous asynchronous receiver
pub const USART2 = struct {
    const base_address = 0x40004400;
    /// SR
    const SR_val = packed struct {
        /// PE [0:0]
        /// Parity error
        PE: u1 = 0,
        /// FE [1:1]
        /// Framing error
        FE: u1 = 0,
        /// NF [2:2]
        /// Noise detected flag
        NF: u1 = 0,
        /// ORE [3:3]
        /// Overrun error
        ORE: u1 = 0,
        /// IDLE [4:4]
        /// IDLE line detected
        IDLE: u1 = 0,
        /// RXNE [5:5]
        /// Read data register not
        RXNE: u1 = 0,
        /// TC [6:6]
        /// Transmission complete
        TC: u1 = 0,
        /// TXE [7:7]
        /// Transmit data register
        TXE: u1 = 0,
        /// LBD [8:8]
        /// LIN break detection flag
        LBD: u1 = 0,
        /// CTS [9:9]
        /// CTS flag
        CTS: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 192,
        _unused24: u8 = 0,
    };
    /// Status register
    pub const SR = Register(SR_val).init(base_address + 0x0);

    /// DR
    const DR_val = packed struct {
        /// DR [0:8]
        /// Data value
        DR: u9 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x4);

    /// BRR
    const BRR_val = packed struct {
        /// DIV_Fraction [0:3]
        /// fraction of USARTDIV
        DIV_Fraction: u4 = 0,
        /// DIV_Mantissa [4:15]
        /// mantissa of USARTDIV
        DIV_Mantissa: u12 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Baud rate register
    pub const BRR = Register(BRR_val).init(base_address + 0x8);

    /// CR1
    const CR1_val = packed struct {
        /// SBK [0:0]
        /// Send break
        SBK: u1 = 0,
        /// RWU [1:1]
        /// Receiver wakeup
        RWU: u1 = 0,
        /// RE [2:2]
        /// Receiver enable
        RE: u1 = 0,
        /// TE [3:3]
        /// Transmitter enable
        TE: u1 = 0,
        /// IDLEIE [4:4]
        /// IDLE interrupt enable
        IDLEIE: u1 = 0,
        /// RXNEIE [5:5]
        /// RXNE interrupt enable
        RXNEIE: u1 = 0,
        /// TCIE [6:6]
        /// Transmission complete interrupt
        TCIE: u1 = 0,
        /// TXEIE [7:7]
        /// TXE interrupt enable
        TXEIE: u1 = 0,
        /// PEIE [8:8]
        /// PE interrupt enable
        PEIE: u1 = 0,
        /// PS [9:9]
        /// Parity selection
        PS: u1 = 0,
        /// PCE [10:10]
        /// Parity control enable
        PCE: u1 = 0,
        /// WAKE [11:11]
        /// Wakeup method
        WAKE: u1 = 0,
        /// M [12:12]
        /// Word length
        M: u1 = 0,
        /// UE [13:13]
        /// USART enable
        UE: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// OVER8 [15:15]
        /// Oversampling mode
        OVER8: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0xc);

    /// CR2
    const CR2_val = packed struct {
        /// ADD [0:3]
        /// Address of the USART node
        ADD: u4 = 0,
        /// unused [4:4]
        _unused4: u1 = 0,
        /// LBDL [5:5]
        /// lin break detection length
        LBDL: u1 = 0,
        /// LBDIE [6:6]
        /// LIN break detection interrupt
        LBDIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// LBCL [8:8]
        /// Last bit clock pulse
        LBCL: u1 = 0,
        /// CPHA [9:9]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [10:10]
        /// Clock polarity
        CPOL: u1 = 0,
        /// CLKEN [11:11]
        /// Clock enable
        CLKEN: u1 = 0,
        /// STOP [12:13]
        /// STOP bits
        STOP: u2 = 0,
        /// LINEN [14:14]
        /// LIN mode enable
        LINEN: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x10);

    /// CR3
    const CR3_val = packed struct {
        /// EIE [0:0]
        /// Error interrupt enable
        EIE: u1 = 0,
        /// IREN [1:1]
        /// IrDA mode enable
        IREN: u1 = 0,
        /// IRLP [2:2]
        /// IrDA low-power
        IRLP: u1 = 0,
        /// HDSEL [3:3]
        /// Half-duplex selection
        HDSEL: u1 = 0,
        /// NACK [4:4]
        /// Smartcard NACK enable
        NACK: u1 = 0,
        /// SCEN [5:5]
        /// Smartcard mode enable
        SCEN: u1 = 0,
        /// DMAR [6:6]
        /// DMA enable receiver
        DMAR: u1 = 0,
        /// DMAT [7:7]
        /// DMA enable transmitter
        DMAT: u1 = 0,
        /// RTSE [8:8]
        /// RTS enable
        RTSE: u1 = 0,
        /// CTSE [9:9]
        /// CTS enable
        CTSE: u1 = 0,
        /// CTSIE [10:10]
        /// CTS interrupt enable
        CTSIE: u1 = 0,
        /// ONEBIT [11:11]
        /// One sample bit method
        ONEBIT: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 3
    pub const CR3 = Register(CR3_val).init(base_address + 0x14);

    /// GTPR
    const GTPR_val = packed struct {
        /// PSC [0:7]
        /// Prescaler value
        PSC: u8 = 0,
        /// GT [8:15]
        /// Guard time value
        GT: u8 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Guard time and prescaler
    pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Universal synchronous asynchronous receiver
pub const USART6 = struct {
    const base_address = 0x40011400;
    /// SR
    const SR_val = packed struct {
        /// PE [0:0]
        /// Parity error
        PE: u1 = 0,
        /// FE [1:1]
        /// Framing error
        FE: u1 = 0,
        /// NF [2:2]
        /// Noise detected flag
        NF: u1 = 0,
        /// ORE [3:3]
        /// Overrun error
        ORE: u1 = 0,
        /// IDLE [4:4]
        /// IDLE line detected
        IDLE: u1 = 0,
        /// RXNE [5:5]
        /// Read data register not
        RXNE: u1 = 0,
        /// TC [6:6]
        /// Transmission complete
        TC: u1 = 0,
        /// TXE [7:7]
        /// Transmit data register
        TXE: u1 = 0,
        /// LBD [8:8]
        /// LIN break detection flag
        LBD: u1 = 0,
        /// CTS [9:9]
        /// CTS flag
        CTS: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 192,
        _unused24: u8 = 0,
    };
    /// Status register
    pub const SR = Register(SR_val).init(base_address + 0x0);

    /// DR
    const DR_val = packed struct {
        /// DR [0:8]
        /// Data value
        DR: u9 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x4);

    /// BRR
    const BRR_val = packed struct {
        /// DIV_Fraction [0:3]
        /// fraction of USARTDIV
        DIV_Fraction: u4 = 0,
        /// DIV_Mantissa [4:15]
        /// mantissa of USARTDIV
        DIV_Mantissa: u12 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Baud rate register
    pub const BRR = Register(BRR_val).init(base_address + 0x8);

    /// CR1
    const CR1_val = packed struct {
        /// SBK [0:0]
        /// Send break
        SBK: u1 = 0,
        /// RWU [1:1]
        /// Receiver wakeup
        RWU: u1 = 0,
        /// RE [2:2]
        /// Receiver enable
        RE: u1 = 0,
        /// TE [3:3]
        /// Transmitter enable
        TE: u1 = 0,
        /// IDLEIE [4:4]
        /// IDLE interrupt enable
        IDLEIE: u1 = 0,
        /// RXNEIE [5:5]
        /// RXNE interrupt enable
        RXNEIE: u1 = 0,
        /// TCIE [6:6]
        /// Transmission complete interrupt
        TCIE: u1 = 0,
        /// TXEIE [7:7]
        /// TXE interrupt enable
        TXEIE: u1 = 0,
        /// PEIE [8:8]
        /// PE interrupt enable
        PEIE: u1 = 0,
        /// PS [9:9]
        /// Parity selection
        PS: u1 = 0,
        /// PCE [10:10]
        /// Parity control enable
        PCE: u1 = 0,
        /// WAKE [11:11]
        /// Wakeup method
        WAKE: u1 = 0,
        /// M [12:12]
        /// Word length
        M: u1 = 0,
        /// UE [13:13]
        /// USART enable
        UE: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// OVER8 [15:15]
        /// Oversampling mode
        OVER8: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0xc);

    /// CR2
    const CR2_val = packed struct {
        /// ADD [0:3]
        /// Address of the USART node
        ADD: u4 = 0,
        /// unused [4:4]
        _unused4: u1 = 0,
        /// LBDL [5:5]
        /// lin break detection length
        LBDL: u1 = 0,
        /// LBDIE [6:6]
        /// LIN break detection interrupt
        LBDIE: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// LBCL [8:8]
        /// Last bit clock pulse
        LBCL: u1 = 0,
        /// CPHA [9:9]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [10:10]
        /// Clock polarity
        CPOL: u1 = 0,
        /// CLKEN [11:11]
        /// Clock enable
        CLKEN: u1 = 0,
        /// STOP [12:13]
        /// STOP bits
        STOP: u2 = 0,
        /// LINEN [14:14]
        /// LIN mode enable
        LINEN: u1 = 0,
        /// unused [15:31]
        _unused15: u1 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x10);

    /// CR3
    const CR3_val = packed struct {
        /// EIE [0:0]
        /// Error interrupt enable
        EIE: u1 = 0,
        /// IREN [1:1]
        /// IrDA mode enable
        IREN: u1 = 0,
        /// IRLP [2:2]
        /// IrDA low-power
        IRLP: u1 = 0,
        /// HDSEL [3:3]
        /// Half-duplex selection
        HDSEL: u1 = 0,
        /// NACK [4:4]
        /// Smartcard NACK enable
        NACK: u1 = 0,
        /// SCEN [5:5]
        /// Smartcard mode enable
        SCEN: u1 = 0,
        /// DMAR [6:6]
        /// DMA enable receiver
        DMAR: u1 = 0,
        /// DMAT [7:7]
        /// DMA enable transmitter
        DMAT: u1 = 0,
        /// RTSE [8:8]
        /// RTS enable
        RTSE: u1 = 0,
        /// CTSE [9:9]
        /// CTS enable
        CTSE: u1 = 0,
        /// CTSIE [10:10]
        /// CTS interrupt enable
        CTSIE: u1 = 0,
        /// ONEBIT [11:11]
        /// One sample bit method
        ONEBIT: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 3
    pub const CR3 = Register(CR3_val).init(base_address + 0x14);

    /// GTPR
    const GTPR_val = packed struct {
        /// PSC [0:7]
        /// Prescaler value
        PSC: u8 = 0,
        /// GT [8:15]
        /// Guard time value
        GT: u8 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Guard time and prescaler
    pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Window watchdog
pub const WWDG = struct {
    const base_address = 0x40002c00;
    /// CR
    const CR_val = packed struct {
        /// T [0:6]
        /// 7-bit counter (MSB to LSB)
        T: u7 = 127,
        /// WDGA [7:7]
        /// Activation bit
        WDGA: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register
    pub const CR = Register(CR_val).init(base_address + 0x0);

    /// CFR
    const CFR_val = packed struct {
        /// W [0:6]
        /// 7-bit window value
        W: u7 = 127,
        /// WDGTB0 [7:7]
        /// Timer base
        WDGTB0: u1 = 0,
        /// WDGTB1 [8:8]
        /// Timer base
        WDGTB1: u1 = 0,
        /// EWI [9:9]
        /// Early wakeup interrupt
        EWI: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Configuration register
    pub const CFR = Register(CFR_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// EWIF [0:0]
        /// Early wakeup interrupt
        EWIF: u1 = 0,
        /// unused [1:31]
        _unused1: u7 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register
    pub const SR = Register(SR_val).init(base_address + 0x8);
};

/// DMA controller
pub const DMA2 = struct {
    const base_address = 0x40026400;
    /// LISR
    const LISR_val = packed struct {
        /// FEIF0 [0:0]
        /// Stream x FIFO error interrupt flag
        FEIF0: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// DMEIF0 [2:2]
        /// Stream x direct mode error interrupt
        DMEIF0: u1 = 0,
        /// TEIF0 [3:3]
        /// Stream x transfer error interrupt flag
        TEIF0: u1 = 0,
        /// HTIF0 [4:4]
        /// Stream x half transfer interrupt flag
        HTIF0: u1 = 0,
        /// TCIF0 [5:5]
        /// Stream x transfer complete interrupt
        TCIF0: u1 = 0,
        /// FEIF1 [6:6]
        /// Stream x FIFO error interrupt flag
        FEIF1: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// DMEIF1 [8:8]
        /// Stream x direct mode error interrupt
        DMEIF1: u1 = 0,
        /// TEIF1 [9:9]
        /// Stream x transfer error interrupt flag
        TEIF1: u1 = 0,
        /// HTIF1 [10:10]
        /// Stream x half transfer interrupt flag
        HTIF1: u1 = 0,
        /// TCIF1 [11:11]
        /// Stream x transfer complete interrupt
        TCIF1: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// FEIF2 [16:16]
        /// Stream x FIFO error interrupt flag
        FEIF2: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// DMEIF2 [18:18]
        /// Stream x direct mode error interrupt
        DMEIF2: u1 = 0,
        /// TEIF2 [19:19]
        /// Stream x transfer error interrupt flag
        TEIF2: u1 = 0,
        /// HTIF2 [20:20]
        /// Stream x half transfer interrupt flag
        HTIF2: u1 = 0,
        /// TCIF2 [21:21]
        /// Stream x transfer complete interrupt
        TCIF2: u1 = 0,
        /// FEIF3 [22:22]
        /// Stream x FIFO error interrupt flag
        FEIF3: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// DMEIF3 [24:24]
        /// Stream x direct mode error interrupt
        DMEIF3: u1 = 0,
        /// TEIF3 [25:25]
        /// Stream x transfer error interrupt flag
        TEIF3: u1 = 0,
        /// HTIF3 [26:26]
        /// Stream x half transfer interrupt flag
        HTIF3: u1 = 0,
        /// TCIF3 [27:27]
        /// Stream x transfer complete interrupt
        TCIF3: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// low interrupt status register
    pub const LISR = Register(LISR_val).init(base_address + 0x0);

    /// HISR
    const HISR_val = packed struct {
        /// FEIF4 [0:0]
        /// Stream x FIFO error interrupt flag
        FEIF4: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// DMEIF4 [2:2]
        /// Stream x direct mode error interrupt
        DMEIF4: u1 = 0,
        /// TEIF4 [3:3]
        /// Stream x transfer error interrupt flag
        TEIF4: u1 = 0,
        /// HTIF4 [4:4]
        /// Stream x half transfer interrupt flag
        HTIF4: u1 = 0,
        /// TCIF4 [5:5]
        /// Stream x transfer complete interrupt
        TCIF4: u1 = 0,
        /// FEIF5 [6:6]
        /// Stream x FIFO error interrupt flag
        FEIF5: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// DMEIF5 [8:8]
        /// Stream x direct mode error interrupt
        DMEIF5: u1 = 0,
        /// TEIF5 [9:9]
        /// Stream x transfer error interrupt flag
        TEIF5: u1 = 0,
        /// HTIF5 [10:10]
        /// Stream x half transfer interrupt flag
        HTIF5: u1 = 0,
        /// TCIF5 [11:11]
        /// Stream x transfer complete interrupt
        TCIF5: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// FEIF6 [16:16]
        /// Stream x FIFO error interrupt flag
        FEIF6: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// DMEIF6 [18:18]
        /// Stream x direct mode error interrupt
        DMEIF6: u1 = 0,
        /// TEIF6 [19:19]
        /// Stream x transfer error interrupt flag
        TEIF6: u1 = 0,
        /// HTIF6 [20:20]
        /// Stream x half transfer interrupt flag
        HTIF6: u1 = 0,
        /// TCIF6 [21:21]
        /// Stream x transfer complete interrupt
        TCIF6: u1 = 0,
        /// FEIF7 [22:22]
        /// Stream x FIFO error interrupt flag
        FEIF7: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// DMEIF7 [24:24]
        /// Stream x direct mode error interrupt
        DMEIF7: u1 = 0,
        /// TEIF7 [25:25]
        /// Stream x transfer error interrupt flag
        TEIF7: u1 = 0,
        /// HTIF7 [26:26]
        /// Stream x half transfer interrupt flag
        HTIF7: u1 = 0,
        /// TCIF7 [27:27]
        /// Stream x transfer complete interrupt
        TCIF7: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// high interrupt status register
    pub const HISR = Register(HISR_val).init(base_address + 0x4);

    /// LIFCR
    const LIFCR_val = packed struct {
        /// CFEIF0 [0:0]
        /// Stream x clear FIFO error interrupt flag
        CFEIF0: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// CDMEIF0 [2:2]
        /// Stream x clear direct mode error
        CDMEIF0: u1 = 0,
        /// CTEIF0 [3:3]
        /// Stream x clear transfer error interrupt
        CTEIF0: u1 = 0,
        /// CHTIF0 [4:4]
        /// Stream x clear half transfer interrupt
        CHTIF0: u1 = 0,
        /// CTCIF0 [5:5]
        /// Stream x clear transfer complete
        CTCIF0: u1 = 0,
        /// CFEIF1 [6:6]
        /// Stream x clear FIFO error interrupt flag
        CFEIF1: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// CDMEIF1 [8:8]
        /// Stream x clear direct mode error
        CDMEIF1: u1 = 0,
        /// CTEIF1 [9:9]
        /// Stream x clear transfer error interrupt
        CTEIF1: u1 = 0,
        /// CHTIF1 [10:10]
        /// Stream x clear half transfer interrupt
        CHTIF1: u1 = 0,
        /// CTCIF1 [11:11]
        /// Stream x clear transfer complete
        CTCIF1: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// CFEIF2 [16:16]
        /// Stream x clear FIFO error interrupt flag
        CFEIF2: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// CDMEIF2 [18:18]
        /// Stream x clear direct mode error
        CDMEIF2: u1 = 0,
        /// CTEIF2 [19:19]
        /// Stream x clear transfer error interrupt
        CTEIF2: u1 = 0,
        /// CHTIF2 [20:20]
        /// Stream x clear half transfer interrupt
        CHTIF2: u1 = 0,
        /// CTCIF2 [21:21]
        /// Stream x clear transfer complete
        CTCIF2: u1 = 0,
        /// CFEIF3 [22:22]
        /// Stream x clear FIFO error interrupt flag
        CFEIF3: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// CDMEIF3 [24:24]
        /// Stream x clear direct mode error
        CDMEIF3: u1 = 0,
        /// CTEIF3 [25:25]
        /// Stream x clear transfer error interrupt
        CTEIF3: u1 = 0,
        /// CHTIF3 [26:26]
        /// Stream x clear half transfer interrupt
        CHTIF3: u1 = 0,
        /// CTCIF3 [27:27]
        /// Stream x clear transfer complete
        CTCIF3: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// low interrupt flag clear
    pub const LIFCR = Register(LIFCR_val).init(base_address + 0x8);

    /// HIFCR
    const HIFCR_val = packed struct {
        /// CFEIF4 [0:0]
        /// Stream x clear FIFO error interrupt flag
        CFEIF4: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// CDMEIF4 [2:2]
        /// Stream x clear direct mode error
        CDMEIF4: u1 = 0,
        /// CTEIF4 [3:3]
        /// Stream x clear transfer error interrupt
        CTEIF4: u1 = 0,
        /// CHTIF4 [4:4]
        /// Stream x clear half transfer interrupt
        CHTIF4: u1 = 0,
        /// CTCIF4 [5:5]
        /// Stream x clear transfer complete
        CTCIF4: u1 = 0,
        /// CFEIF5 [6:6]
        /// Stream x clear FIFO error interrupt flag
        CFEIF5: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// CDMEIF5 [8:8]
        /// Stream x clear direct mode error
        CDMEIF5: u1 = 0,
        /// CTEIF5 [9:9]
        /// Stream x clear transfer error interrupt
        CTEIF5: u1 = 0,
        /// CHTIF5 [10:10]
        /// Stream x clear half transfer interrupt
        CHTIF5: u1 = 0,
        /// CTCIF5 [11:11]
        /// Stream x clear transfer complete
        CTCIF5: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// CFEIF6 [16:16]
        /// Stream x clear FIFO error interrupt flag
        CFEIF6: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// CDMEIF6 [18:18]
        /// Stream x clear direct mode error
        CDMEIF6: u1 = 0,
        /// CTEIF6 [19:19]
        /// Stream x clear transfer error interrupt
        CTEIF6: u1 = 0,
        /// CHTIF6 [20:20]
        /// Stream x clear half transfer interrupt
        CHTIF6: u1 = 0,
        /// CTCIF6 [21:21]
        /// Stream x clear transfer complete
        CTCIF6: u1 = 0,
        /// CFEIF7 [22:22]
        /// Stream x clear FIFO error interrupt flag
        CFEIF7: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// CDMEIF7 [24:24]
        /// Stream x clear direct mode error
        CDMEIF7: u1 = 0,
        /// CTEIF7 [25:25]
        /// Stream x clear transfer error interrupt
        CTEIF7: u1 = 0,
        /// CHTIF7 [26:26]
        /// Stream x clear half transfer interrupt
        CHTIF7: u1 = 0,
        /// CTCIF7 [27:27]
        /// Stream x clear transfer complete
        CTCIF7: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// high interrupt flag clear
    pub const HIFCR = Register(HIFCR_val).init(base_address + 0xc);

    /// S0CR
    const S0CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// unused [20:20]
        _unused20: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S0CR = Register(S0CR_val).init(base_address + 0x10);

    /// S0NDTR
    const S0NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S0NDTR = Register(S0NDTR_val).init(base_address + 0x14);

    /// S0PAR
    const S0PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S0PAR = Register(S0PAR_val).init(base_address + 0x18);

    /// S0M0AR
    const S0M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S0M0AR = Register(S0M0AR_val).init(base_address + 0x1c);

    /// S0M1AR
    const S0M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S0M1AR = Register(S0M1AR_val).init(base_address + 0x20);

    /// S0FCR
    const S0FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S0FCR = Register(S0FCR_val).init(base_address + 0x24);

    /// S1CR
    const S1CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S1CR = Register(S1CR_val).init(base_address + 0x28);

    /// S1NDTR
    const S1NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S1NDTR = Register(S1NDTR_val).init(base_address + 0x2c);

    /// S1PAR
    const S1PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S1PAR = Register(S1PAR_val).init(base_address + 0x30);

    /// S1M0AR
    const S1M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S1M0AR = Register(S1M0AR_val).init(base_address + 0x34);

    /// S1M1AR
    const S1M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S1M1AR = Register(S1M1AR_val).init(base_address + 0x38);

    /// S1FCR
    const S1FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S1FCR = Register(S1FCR_val).init(base_address + 0x3c);

    /// S2CR
    const S2CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S2CR = Register(S2CR_val).init(base_address + 0x40);

    /// S2NDTR
    const S2NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S2NDTR = Register(S2NDTR_val).init(base_address + 0x44);

    /// S2PAR
    const S2PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S2PAR = Register(S2PAR_val).init(base_address + 0x48);

    /// S2M0AR
    const S2M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S2M0AR = Register(S2M0AR_val).init(base_address + 0x4c);

    /// S2M1AR
    const S2M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S2M1AR = Register(S2M1AR_val).init(base_address + 0x50);

    /// S2FCR
    const S2FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S2FCR = Register(S2FCR_val).init(base_address + 0x54);

    /// S3CR
    const S3CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S3CR = Register(S3CR_val).init(base_address + 0x58);

    /// S3NDTR
    const S3NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S3NDTR = Register(S3NDTR_val).init(base_address + 0x5c);

    /// S3PAR
    const S3PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S3PAR = Register(S3PAR_val).init(base_address + 0x60);

    /// S3M0AR
    const S3M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S3M0AR = Register(S3M0AR_val).init(base_address + 0x64);

    /// S3M1AR
    const S3M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S3M1AR = Register(S3M1AR_val).init(base_address + 0x68);

    /// S3FCR
    const S3FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S3FCR = Register(S3FCR_val).init(base_address + 0x6c);

    /// S4CR
    const S4CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S4CR = Register(S4CR_val).init(base_address + 0x70);

    /// S4NDTR
    const S4NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S4NDTR = Register(S4NDTR_val).init(base_address + 0x74);

    /// S4PAR
    const S4PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S4PAR = Register(S4PAR_val).init(base_address + 0x78);

    /// S4M0AR
    const S4M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S4M0AR = Register(S4M0AR_val).init(base_address + 0x7c);

    /// S4M1AR
    const S4M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S4M1AR = Register(S4M1AR_val).init(base_address + 0x80);

    /// S4FCR
    const S4FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S4FCR = Register(S4FCR_val).init(base_address + 0x84);

    /// S5CR
    const S5CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S5CR = Register(S5CR_val).init(base_address + 0x88);

    /// S5NDTR
    const S5NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S5NDTR = Register(S5NDTR_val).init(base_address + 0x8c);

    /// S5PAR
    const S5PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S5PAR = Register(S5PAR_val).init(base_address + 0x90);

    /// S5M0AR
    const S5M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S5M0AR = Register(S5M0AR_val).init(base_address + 0x94);

    /// S5M1AR
    const S5M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S5M1AR = Register(S5M1AR_val).init(base_address + 0x98);

    /// S5FCR
    const S5FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S5FCR = Register(S5FCR_val).init(base_address + 0x9c);

    /// S6CR
    const S6CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S6CR = Register(S6CR_val).init(base_address + 0xa0);

    /// S6NDTR
    const S6NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S6NDTR = Register(S6NDTR_val).init(base_address + 0xa4);

    /// S6PAR
    const S6PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S6PAR = Register(S6PAR_val).init(base_address + 0xa8);

    /// S6M0AR
    const S6M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S6M0AR = Register(S6M0AR_val).init(base_address + 0xac);

    /// S6M1AR
    const S6M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S6M1AR = Register(S6M1AR_val).init(base_address + 0xb0);

    /// S6FCR
    const S6FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S6FCR = Register(S6FCR_val).init(base_address + 0xb4);

    /// S7CR
    const S7CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S7CR = Register(S7CR_val).init(base_address + 0xb8);

    /// S7NDTR
    const S7NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S7NDTR = Register(S7NDTR_val).init(base_address + 0xbc);

    /// S7PAR
    const S7PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S7PAR = Register(S7PAR_val).init(base_address + 0xc0);

    /// S7M0AR
    const S7M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S7M0AR = Register(S7M0AR_val).init(base_address + 0xc4);

    /// S7M1AR
    const S7M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S7M1AR = Register(S7M1AR_val).init(base_address + 0xc8);

    /// S7FCR
    const S7FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S7FCR = Register(S7FCR_val).init(base_address + 0xcc);
};

/// DMA controller
pub const DMA1 = struct {
    const base_address = 0x40026000;
    /// LISR
    const LISR_val = packed struct {
        /// FEIF0 [0:0]
        /// Stream x FIFO error interrupt flag
        FEIF0: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// DMEIF0 [2:2]
        /// Stream x direct mode error interrupt
        DMEIF0: u1 = 0,
        /// TEIF0 [3:3]
        /// Stream x transfer error interrupt flag
        TEIF0: u1 = 0,
        /// HTIF0 [4:4]
        /// Stream x half transfer interrupt flag
        HTIF0: u1 = 0,
        /// TCIF0 [5:5]
        /// Stream x transfer complete interrupt
        TCIF0: u1 = 0,
        /// FEIF1 [6:6]
        /// Stream x FIFO error interrupt flag
        FEIF1: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// DMEIF1 [8:8]
        /// Stream x direct mode error interrupt
        DMEIF1: u1 = 0,
        /// TEIF1 [9:9]
        /// Stream x transfer error interrupt flag
        TEIF1: u1 = 0,
        /// HTIF1 [10:10]
        /// Stream x half transfer interrupt flag
        HTIF1: u1 = 0,
        /// TCIF1 [11:11]
        /// Stream x transfer complete interrupt
        TCIF1: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// FEIF2 [16:16]
        /// Stream x FIFO error interrupt flag
        FEIF2: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// DMEIF2 [18:18]
        /// Stream x direct mode error interrupt
        DMEIF2: u1 = 0,
        /// TEIF2 [19:19]
        /// Stream x transfer error interrupt flag
        TEIF2: u1 = 0,
        /// HTIF2 [20:20]
        /// Stream x half transfer interrupt flag
        HTIF2: u1 = 0,
        /// TCIF2 [21:21]
        /// Stream x transfer complete interrupt
        TCIF2: u1 = 0,
        /// FEIF3 [22:22]
        /// Stream x FIFO error interrupt flag
        FEIF3: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// DMEIF3 [24:24]
        /// Stream x direct mode error interrupt
        DMEIF3: u1 = 0,
        /// TEIF3 [25:25]
        /// Stream x transfer error interrupt flag
        TEIF3: u1 = 0,
        /// HTIF3 [26:26]
        /// Stream x half transfer interrupt flag
        HTIF3: u1 = 0,
        /// TCIF3 [27:27]
        /// Stream x transfer complete interrupt
        TCIF3: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// low interrupt status register
    pub const LISR = Register(LISR_val).init(base_address + 0x0);

    /// HISR
    const HISR_val = packed struct {
        /// FEIF4 [0:0]
        /// Stream x FIFO error interrupt flag
        FEIF4: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// DMEIF4 [2:2]
        /// Stream x direct mode error interrupt
        DMEIF4: u1 = 0,
        /// TEIF4 [3:3]
        /// Stream x transfer error interrupt flag
        TEIF4: u1 = 0,
        /// HTIF4 [4:4]
        /// Stream x half transfer interrupt flag
        HTIF4: u1 = 0,
        /// TCIF4 [5:5]
        /// Stream x transfer complete interrupt
        TCIF4: u1 = 0,
        /// FEIF5 [6:6]
        /// Stream x FIFO error interrupt flag
        FEIF5: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// DMEIF5 [8:8]
        /// Stream x direct mode error interrupt
        DMEIF5: u1 = 0,
        /// TEIF5 [9:9]
        /// Stream x transfer error interrupt flag
        TEIF5: u1 = 0,
        /// HTIF5 [10:10]
        /// Stream x half transfer interrupt flag
        HTIF5: u1 = 0,
        /// TCIF5 [11:11]
        /// Stream x transfer complete interrupt
        TCIF5: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// FEIF6 [16:16]
        /// Stream x FIFO error interrupt flag
        FEIF6: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// DMEIF6 [18:18]
        /// Stream x direct mode error interrupt
        DMEIF6: u1 = 0,
        /// TEIF6 [19:19]
        /// Stream x transfer error interrupt flag
        TEIF6: u1 = 0,
        /// HTIF6 [20:20]
        /// Stream x half transfer interrupt flag
        HTIF6: u1 = 0,
        /// TCIF6 [21:21]
        /// Stream x transfer complete interrupt
        TCIF6: u1 = 0,
        /// FEIF7 [22:22]
        /// Stream x FIFO error interrupt flag
        FEIF7: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// DMEIF7 [24:24]
        /// Stream x direct mode error interrupt
        DMEIF7: u1 = 0,
        /// TEIF7 [25:25]
        /// Stream x transfer error interrupt flag
        TEIF7: u1 = 0,
        /// HTIF7 [26:26]
        /// Stream x half transfer interrupt flag
        HTIF7: u1 = 0,
        /// TCIF7 [27:27]
        /// Stream x transfer complete interrupt
        TCIF7: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// high interrupt status register
    pub const HISR = Register(HISR_val).init(base_address + 0x4);

    /// LIFCR
    const LIFCR_val = packed struct {
        /// CFEIF0 [0:0]
        /// Stream x clear FIFO error interrupt flag
        CFEIF0: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// CDMEIF0 [2:2]
        /// Stream x clear direct mode error
        CDMEIF0: u1 = 0,
        /// CTEIF0 [3:3]
        /// Stream x clear transfer error interrupt
        CTEIF0: u1 = 0,
        /// CHTIF0 [4:4]
        /// Stream x clear half transfer interrupt
        CHTIF0: u1 = 0,
        /// CTCIF0 [5:5]
        /// Stream x clear transfer complete
        CTCIF0: u1 = 0,
        /// CFEIF1 [6:6]
        /// Stream x clear FIFO error interrupt flag
        CFEIF1: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// CDMEIF1 [8:8]
        /// Stream x clear direct mode error
        CDMEIF1: u1 = 0,
        /// CTEIF1 [9:9]
        /// Stream x clear transfer error interrupt
        CTEIF1: u1 = 0,
        /// CHTIF1 [10:10]
        /// Stream x clear half transfer interrupt
        CHTIF1: u1 = 0,
        /// CTCIF1 [11:11]
        /// Stream x clear transfer complete
        CTCIF1: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// CFEIF2 [16:16]
        /// Stream x clear FIFO error interrupt flag
        CFEIF2: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// CDMEIF2 [18:18]
        /// Stream x clear direct mode error
        CDMEIF2: u1 = 0,
        /// CTEIF2 [19:19]
        /// Stream x clear transfer error interrupt
        CTEIF2: u1 = 0,
        /// CHTIF2 [20:20]
        /// Stream x clear half transfer interrupt
        CHTIF2: u1 = 0,
        /// CTCIF2 [21:21]
        /// Stream x clear transfer complete
        CTCIF2: u1 = 0,
        /// CFEIF3 [22:22]
        /// Stream x clear FIFO error interrupt flag
        CFEIF3: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// CDMEIF3 [24:24]
        /// Stream x clear direct mode error
        CDMEIF3: u1 = 0,
        /// CTEIF3 [25:25]
        /// Stream x clear transfer error interrupt
        CTEIF3: u1 = 0,
        /// CHTIF3 [26:26]
        /// Stream x clear half transfer interrupt
        CHTIF3: u1 = 0,
        /// CTCIF3 [27:27]
        /// Stream x clear transfer complete
        CTCIF3: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// low interrupt flag clear
    pub const LIFCR = Register(LIFCR_val).init(base_address + 0x8);

    /// HIFCR
    const HIFCR_val = packed struct {
        /// CFEIF4 [0:0]
        /// Stream x clear FIFO error interrupt flag
        CFEIF4: u1 = 0,
        /// unused [1:1]
        _unused1: u1 = 0,
        /// CDMEIF4 [2:2]
        /// Stream x clear direct mode error
        CDMEIF4: u1 = 0,
        /// CTEIF4 [3:3]
        /// Stream x clear transfer error interrupt
        CTEIF4: u1 = 0,
        /// CHTIF4 [4:4]
        /// Stream x clear half transfer interrupt
        CHTIF4: u1 = 0,
        /// CTCIF4 [5:5]
        /// Stream x clear transfer complete
        CTCIF4: u1 = 0,
        /// CFEIF5 [6:6]
        /// Stream x clear FIFO error interrupt flag
        CFEIF5: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// CDMEIF5 [8:8]
        /// Stream x clear direct mode error
        CDMEIF5: u1 = 0,
        /// CTEIF5 [9:9]
        /// Stream x clear transfer error interrupt
        CTEIF5: u1 = 0,
        /// CHTIF5 [10:10]
        /// Stream x clear half transfer interrupt
        CHTIF5: u1 = 0,
        /// CTCIF5 [11:11]
        /// Stream x clear transfer complete
        CTCIF5: u1 = 0,
        /// unused [12:15]
        _unused12: u4 = 0,
        /// CFEIF6 [16:16]
        /// Stream x clear FIFO error interrupt flag
        CFEIF6: u1 = 0,
        /// unused [17:17]
        _unused17: u1 = 0,
        /// CDMEIF6 [18:18]
        /// Stream x clear direct mode error
        CDMEIF6: u1 = 0,
        /// CTEIF6 [19:19]
        /// Stream x clear transfer error interrupt
        CTEIF6: u1 = 0,
        /// CHTIF6 [20:20]
        /// Stream x clear half transfer interrupt
        CHTIF6: u1 = 0,
        /// CTCIF6 [21:21]
        /// Stream x clear transfer complete
        CTCIF6: u1 = 0,
        /// CFEIF7 [22:22]
        /// Stream x clear FIFO error interrupt flag
        CFEIF7: u1 = 0,
        /// unused [23:23]
        _unused23: u1 = 0,
        /// CDMEIF7 [24:24]
        /// Stream x clear direct mode error
        CDMEIF7: u1 = 0,
        /// CTEIF7 [25:25]
        /// Stream x clear transfer error interrupt
        CTEIF7: u1 = 0,
        /// CHTIF7 [26:26]
        /// Stream x clear half transfer interrupt
        CHTIF7: u1 = 0,
        /// CTCIF7 [27:27]
        /// Stream x clear transfer complete
        CTCIF7: u1 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// high interrupt flag clear
    pub const HIFCR = Register(HIFCR_val).init(base_address + 0xc);

    /// S0CR
    const S0CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// unused [20:20]
        _unused20: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S0CR = Register(S0CR_val).init(base_address + 0x10);

    /// S0NDTR
    const S0NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S0NDTR = Register(S0NDTR_val).init(base_address + 0x14);

    /// S0PAR
    const S0PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S0PAR = Register(S0PAR_val).init(base_address + 0x18);

    /// S0M0AR
    const S0M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S0M0AR = Register(S0M0AR_val).init(base_address + 0x1c);

    /// S0M1AR
    const S0M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S0M1AR = Register(S0M1AR_val).init(base_address + 0x20);

    /// S0FCR
    const S0FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S0FCR = Register(S0FCR_val).init(base_address + 0x24);

    /// S1CR
    const S1CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S1CR = Register(S1CR_val).init(base_address + 0x28);

    /// S1NDTR
    const S1NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S1NDTR = Register(S1NDTR_val).init(base_address + 0x2c);

    /// S1PAR
    const S1PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S1PAR = Register(S1PAR_val).init(base_address + 0x30);

    /// S1M0AR
    const S1M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S1M0AR = Register(S1M0AR_val).init(base_address + 0x34);

    /// S1M1AR
    const S1M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S1M1AR = Register(S1M1AR_val).init(base_address + 0x38);

    /// S1FCR
    const S1FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S1FCR = Register(S1FCR_val).init(base_address + 0x3c);

    /// S2CR
    const S2CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S2CR = Register(S2CR_val).init(base_address + 0x40);

    /// S2NDTR
    const S2NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S2NDTR = Register(S2NDTR_val).init(base_address + 0x44);

    /// S2PAR
    const S2PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S2PAR = Register(S2PAR_val).init(base_address + 0x48);

    /// S2M0AR
    const S2M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S2M0AR = Register(S2M0AR_val).init(base_address + 0x4c);

    /// S2M1AR
    const S2M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S2M1AR = Register(S2M1AR_val).init(base_address + 0x50);

    /// S2FCR
    const S2FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S2FCR = Register(S2FCR_val).init(base_address + 0x54);

    /// S3CR
    const S3CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S3CR = Register(S3CR_val).init(base_address + 0x58);

    /// S3NDTR
    const S3NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S3NDTR = Register(S3NDTR_val).init(base_address + 0x5c);

    /// S3PAR
    const S3PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S3PAR = Register(S3PAR_val).init(base_address + 0x60);

    /// S3M0AR
    const S3M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S3M0AR = Register(S3M0AR_val).init(base_address + 0x64);

    /// S3M1AR
    const S3M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S3M1AR = Register(S3M1AR_val).init(base_address + 0x68);

    /// S3FCR
    const S3FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S3FCR = Register(S3FCR_val).init(base_address + 0x6c);

    /// S4CR
    const S4CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S4CR = Register(S4CR_val).init(base_address + 0x70);

    /// S4NDTR
    const S4NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S4NDTR = Register(S4NDTR_val).init(base_address + 0x74);

    /// S4PAR
    const S4PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S4PAR = Register(S4PAR_val).init(base_address + 0x78);

    /// S4M0AR
    const S4M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S4M0AR = Register(S4M0AR_val).init(base_address + 0x7c);

    /// S4M1AR
    const S4M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S4M1AR = Register(S4M1AR_val).init(base_address + 0x80);

    /// S4FCR
    const S4FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S4FCR = Register(S4FCR_val).init(base_address + 0x84);

    /// S5CR
    const S5CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S5CR = Register(S5CR_val).init(base_address + 0x88);

    /// S5NDTR
    const S5NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S5NDTR = Register(S5NDTR_val).init(base_address + 0x8c);

    /// S5PAR
    const S5PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S5PAR = Register(S5PAR_val).init(base_address + 0x90);

    /// S5M0AR
    const S5M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S5M0AR = Register(S5M0AR_val).init(base_address + 0x94);

    /// S5M1AR
    const S5M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S5M1AR = Register(S5M1AR_val).init(base_address + 0x98);

    /// S5FCR
    const S5FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S5FCR = Register(S5FCR_val).init(base_address + 0x9c);

    /// S6CR
    const S6CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S6CR = Register(S6CR_val).init(base_address + 0xa0);

    /// S6NDTR
    const S6NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S6NDTR = Register(S6NDTR_val).init(base_address + 0xa4);

    /// S6PAR
    const S6PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S6PAR = Register(S6PAR_val).init(base_address + 0xa8);

    /// S6M0AR
    const S6M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S6M0AR = Register(S6M0AR_val).init(base_address + 0xac);

    /// S6M1AR
    const S6M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S6M1AR = Register(S6M1AR_val).init(base_address + 0xb0);

    /// S6FCR
    const S6FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S6FCR = Register(S6FCR_val).init(base_address + 0xb4);

    /// S7CR
    const S7CR_val = packed struct {
        /// EN [0:0]
        /// Stream enable / flag stream ready when
        EN: u1 = 0,
        /// DMEIE [1:1]
        /// Direct mode error interrupt
        DMEIE: u1 = 0,
        /// TEIE [2:2]
        /// Transfer error interrupt
        TEIE: u1 = 0,
        /// HTIE [3:3]
        /// Half transfer interrupt
        HTIE: u1 = 0,
        /// TCIE [4:4]
        /// Transfer complete interrupt
        TCIE: u1 = 0,
        /// PFCTRL [5:5]
        /// Peripheral flow controller
        PFCTRL: u1 = 0,
        /// DIR [6:7]
        /// Data transfer direction
        DIR: u2 = 0,
        /// CIRC [8:8]
        /// Circular mode
        CIRC: u1 = 0,
        /// PINC [9:9]
        /// Peripheral increment mode
        PINC: u1 = 0,
        /// MINC [10:10]
        /// Memory increment mode
        MINC: u1 = 0,
        /// PSIZE [11:12]
        /// Peripheral data size
        PSIZE: u2 = 0,
        /// MSIZE [13:14]
        /// Memory data size
        MSIZE: u2 = 0,
        /// PINCOS [15:15]
        /// Peripheral increment offset
        PINCOS: u1 = 0,
        /// PL [16:17]
        /// Priority level
        PL: u2 = 0,
        /// DBM [18:18]
        /// Double buffer mode
        DBM: u1 = 0,
        /// CT [19:19]
        /// Current target (only in double buffer
        CT: u1 = 0,
        /// ACK [20:20]
        /// ACK
        ACK: u1 = 0,
        /// PBURST [21:22]
        /// Peripheral burst transfer
        PBURST: u2 = 0,
        /// MBURST [23:24]
        /// Memory burst transfer
        MBURST: u2 = 0,
        /// CHSEL [25:27]
        /// Channel selection
        CHSEL: u3 = 0,
        /// unused [28:31]
        _unused28: u4 = 0,
    };
    /// stream x configuration
    pub const S7CR = Register(S7CR_val).init(base_address + 0xb8);

    /// S7NDTR
    const S7NDTR_val = packed struct {
        /// NDT [0:15]
        /// Number of data items to
        NDT: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x number of data
    pub const S7NDTR = Register(S7NDTR_val).init(base_address + 0xbc);

    /// S7PAR
    const S7PAR_val = packed struct {
        /// PA [0:31]
        /// Peripheral address
        PA: u32 = 0,
    };
    /// stream x peripheral address
    pub const S7PAR = Register(S7PAR_val).init(base_address + 0xc0);

    /// S7M0AR
    const S7M0AR_val = packed struct {
        /// M0A [0:31]
        /// Memory 0 address
        M0A: u32 = 0,
    };
    /// stream x memory 0 address
    pub const S7M0AR = Register(S7M0AR_val).init(base_address + 0xc4);

    /// S7M1AR
    const S7M1AR_val = packed struct {
        /// M1A [0:31]
        /// Memory 1 address (used in case of Double
        M1A: u32 = 0,
    };
    /// stream x memory 1 address
    pub const S7M1AR = Register(S7M1AR_val).init(base_address + 0xc8);

    /// S7FCR
    const S7FCR_val = packed struct {
        /// FTH [0:1]
        /// FIFO threshold selection
        FTH: u2 = 1,
        /// DMDIS [2:2]
        /// Direct mode disable
        DMDIS: u1 = 0,
        /// FS [3:5]
        /// FIFO status
        FS: u3 = 4,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// FEIE [7:7]
        /// FIFO error interrupt
        FEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// stream x FIFO control register
    pub const S7FCR = Register(S7FCR_val).init(base_address + 0xcc);
};

/// General-purpose I/Os
pub const GPIOH = struct {
    const base_address = 0x40021c00;
    /// MODER
    const MODER_val = packed struct {
        /// MODER0 [0:1]
        /// Port x configuration bits (y =
        MODER0: u2 = 0,
        /// MODER1 [2:3]
        /// Port x configuration bits (y =
        MODER1: u2 = 0,
        /// MODER2 [4:5]
        /// Port x configuration bits (y =
        MODER2: u2 = 0,
        /// MODER3 [6:7]
        /// Port x configuration bits (y =
        MODER3: u2 = 0,
        /// MODER4 [8:9]
        /// Port x configuration bits (y =
        MODER4: u2 = 0,
        /// MODER5 [10:11]
        /// Port x configuration bits (y =
        MODER5: u2 = 0,
        /// MODER6 [12:13]
        /// Port x configuration bits (y =
        MODER6: u2 = 0,
        /// MODER7 [14:15]
        /// Port x configuration bits (y =
        MODER7: u2 = 0,
        /// MODER8 [16:17]
        /// Port x configuration bits (y =
        MODER8: u2 = 0,
        /// MODER9 [18:19]
        /// Port x configuration bits (y =
        MODER9: u2 = 0,
        /// MODER10 [20:21]
        /// Port x configuration bits (y =
        MODER10: u2 = 0,
        /// MODER11 [22:23]
        /// Port x configuration bits (y =
        MODER11: u2 = 0,
        /// MODER12 [24:25]
        /// Port x configuration bits (y =
        MODER12: u2 = 0,
        /// MODER13 [26:27]
        /// Port x configuration bits (y =
        MODER13: u2 = 0,
        /// MODER14 [28:29]
        /// Port x configuration bits (y =
        MODER14: u2 = 0,
        /// MODER15 [30:31]
        /// Port x configuration bits (y =
        MODER15: u2 = 0,
    };
    /// GPIO port mode register
    pub const MODER = Register(MODER_val).init(base_address + 0x0);

    /// OTYPER
    const OTYPER_val = packed struct {
        /// OT0 [0:0]
        /// Port x configuration bits (y =
        OT0: u1 = 0,
        /// OT1 [1:1]
        /// Port x configuration bits (y =
        OT1: u1 = 0,
        /// OT2 [2:2]
        /// Port x configuration bits (y =
        OT2: u1 = 0,
        /// OT3 [3:3]
        /// Port x configuration bits (y =
        OT3: u1 = 0,
        /// OT4 [4:4]
        /// Port x configuration bits (y =
        OT4: u1 = 0,
        /// OT5 [5:5]
        /// Port x configuration bits (y =
        OT5: u1 = 0,
        /// OT6 [6:6]
        /// Port x configuration bits (y =
        OT6: u1 = 0,
        /// OT7 [7:7]
        /// Port x configuration bits (y =
        OT7: u1 = 0,
        /// OT8 [8:8]
        /// Port x configuration bits (y =
        OT8: u1 = 0,
        /// OT9 [9:9]
        /// Port x configuration bits (y =
        OT9: u1 = 0,
        /// OT10 [10:10]
        /// Port x configuration bits (y =
        OT10: u1 = 0,
        /// OT11 [11:11]
        /// Port x configuration bits (y =
        OT11: u1 = 0,
        /// OT12 [12:12]
        /// Port x configuration bits (y =
        OT12: u1 = 0,
        /// OT13 [13:13]
        /// Port x configuration bits (y =
        OT13: u1 = 0,
        /// OT14 [14:14]
        /// Port x configuration bits (y =
        OT14: u1 = 0,
        /// OT15 [15:15]
        /// Port x configuration bits (y =
        OT15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output type register
    pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

    /// OSPEEDR
    const OSPEEDR_val = packed struct {
        /// OSPEEDR0 [0:1]
        /// Port x configuration bits (y =
        OSPEEDR0: u2 = 0,
        /// OSPEEDR1 [2:3]
        /// Port x configuration bits (y =
        OSPEEDR1: u2 = 0,
        /// OSPEEDR2 [4:5]
        /// Port x configuration bits (y =
        OSPEEDR2: u2 = 0,
        /// OSPEEDR3 [6:7]
        /// Port x configuration bits (y =
        OSPEEDR3: u2 = 0,
        /// OSPEEDR4 [8:9]
        /// Port x configuration bits (y =
        OSPEEDR4: u2 = 0,
        /// OSPEEDR5 [10:11]
        /// Port x configuration bits (y =
        OSPEEDR5: u2 = 0,
        /// OSPEEDR6 [12:13]
        /// Port x configuration bits (y =
        OSPEEDR6: u2 = 0,
        /// OSPEEDR7 [14:15]
        /// Port x configuration bits (y =
        OSPEEDR7: u2 = 0,
        /// OSPEEDR8 [16:17]
        /// Port x configuration bits (y =
        OSPEEDR8: u2 = 0,
        /// OSPEEDR9 [18:19]
        /// Port x configuration bits (y =
        OSPEEDR9: u2 = 0,
        /// OSPEEDR10 [20:21]
        /// Port x configuration bits (y =
        OSPEEDR10: u2 = 0,
        /// OSPEEDR11 [22:23]
        /// Port x configuration bits (y =
        OSPEEDR11: u2 = 0,
        /// OSPEEDR12 [24:25]
        /// Port x configuration bits (y =
        OSPEEDR12: u2 = 0,
        /// OSPEEDR13 [26:27]
        /// Port x configuration bits (y =
        OSPEEDR13: u2 = 0,
        /// OSPEEDR14 [28:29]
        /// Port x configuration bits (y =
        OSPEEDR14: u2 = 0,
        /// OSPEEDR15 [30:31]
        /// Port x configuration bits (y =
        OSPEEDR15: u2 = 0,
    };
    /// GPIO port output speed
    pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

    /// PUPDR
    const PUPDR_val = packed struct {
        /// PUPDR0 [0:1]
        /// Port x configuration bits (y =
        PUPDR0: u2 = 0,
        /// PUPDR1 [2:3]
        /// Port x configuration bits (y =
        PUPDR1: u2 = 0,
        /// PUPDR2 [4:5]
        /// Port x configuration bits (y =
        PUPDR2: u2 = 0,
        /// PUPDR3 [6:7]
        /// Port x configuration bits (y =
        PUPDR3: u2 = 0,
        /// PUPDR4 [8:9]
        /// Port x configuration bits (y =
        PUPDR4: u2 = 0,
        /// PUPDR5 [10:11]
        /// Port x configuration bits (y =
        PUPDR5: u2 = 0,
        /// PUPDR6 [12:13]
        /// Port x configuration bits (y =
        PUPDR6: u2 = 0,
        /// PUPDR7 [14:15]
        /// Port x configuration bits (y =
        PUPDR7: u2 = 0,
        /// PUPDR8 [16:17]
        /// Port x configuration bits (y =
        PUPDR8: u2 = 0,
        /// PUPDR9 [18:19]
        /// Port x configuration bits (y =
        PUPDR9: u2 = 0,
        /// PUPDR10 [20:21]
        /// Port x configuration bits (y =
        PUPDR10: u2 = 0,
        /// PUPDR11 [22:23]
        /// Port x configuration bits (y =
        PUPDR11: u2 = 0,
        /// PUPDR12 [24:25]
        /// Port x configuration bits (y =
        PUPDR12: u2 = 0,
        /// PUPDR13 [26:27]
        /// Port x configuration bits (y =
        PUPDR13: u2 = 0,
        /// PUPDR14 [28:29]
        /// Port x configuration bits (y =
        PUPDR14: u2 = 0,
        /// PUPDR15 [30:31]
        /// Port x configuration bits (y =
        PUPDR15: u2 = 0,
    };
    /// GPIO port pull-up/pull-down
    pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

    /// IDR
    const IDR_val = packed struct {
        /// IDR0 [0:0]
        /// Port input data (y =
        IDR0: u1 = 0,
        /// IDR1 [1:1]
        /// Port input data (y =
        IDR1: u1 = 0,
        /// IDR2 [2:2]
        /// Port input data (y =
        IDR2: u1 = 0,
        /// IDR3 [3:3]
        /// Port input data (y =
        IDR3: u1 = 0,
        /// IDR4 [4:4]
        /// Port input data (y =
        IDR4: u1 = 0,
        /// IDR5 [5:5]
        /// Port input data (y =
        IDR5: u1 = 0,
        /// IDR6 [6:6]
        /// Port input data (y =
        IDR6: u1 = 0,
        /// IDR7 [7:7]
        /// Port input data (y =
        IDR7: u1 = 0,
        /// IDR8 [8:8]
        /// Port input data (y =
        IDR8: u1 = 0,
        /// IDR9 [9:9]
        /// Port input data (y =
        IDR9: u1 = 0,
        /// IDR10 [10:10]
        /// Port input data (y =
        IDR10: u1 = 0,
        /// IDR11 [11:11]
        /// Port input data (y =
        IDR11: u1 = 0,
        /// IDR12 [12:12]
        /// Port input data (y =
        IDR12: u1 = 0,
        /// IDR13 [13:13]
        /// Port input data (y =
        IDR13: u1 = 0,
        /// IDR14 [14:14]
        /// Port input data (y =
        IDR14: u1 = 0,
        /// IDR15 [15:15]
        /// Port input data (y =
        IDR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port input data register
    pub const IDR = Register(IDR_val).init(base_address + 0x10);

    /// ODR
    const ODR_val = packed struct {
        /// ODR0 [0:0]
        /// Port output data (y =
        ODR0: u1 = 0,
        /// ODR1 [1:1]
        /// Port output data (y =
        ODR1: u1 = 0,
        /// ODR2 [2:2]
        /// Port output data (y =
        ODR2: u1 = 0,
        /// ODR3 [3:3]
        /// Port output data (y =
        ODR3: u1 = 0,
        /// ODR4 [4:4]
        /// Port output data (y =
        ODR4: u1 = 0,
        /// ODR5 [5:5]
        /// Port output data (y =
        ODR5: u1 = 0,
        /// ODR6 [6:6]
        /// Port output data (y =
        ODR6: u1 = 0,
        /// ODR7 [7:7]
        /// Port output data (y =
        ODR7: u1 = 0,
        /// ODR8 [8:8]
        /// Port output data (y =
        ODR8: u1 = 0,
        /// ODR9 [9:9]
        /// Port output data (y =
        ODR9: u1 = 0,
        /// ODR10 [10:10]
        /// Port output data (y =
        ODR10: u1 = 0,
        /// ODR11 [11:11]
        /// Port output data (y =
        ODR11: u1 = 0,
        /// ODR12 [12:12]
        /// Port output data (y =
        ODR12: u1 = 0,
        /// ODR13 [13:13]
        /// Port output data (y =
        ODR13: u1 = 0,
        /// ODR14 [14:14]
        /// Port output data (y =
        ODR14: u1 = 0,
        /// ODR15 [15:15]
        /// Port output data (y =
        ODR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output data register
    pub const ODR = Register(ODR_val).init(base_address + 0x14);

    /// BSRR
    const BSRR_val = packed struct {
        /// BS0 [0:0]
        /// Port x set bit y (y=
        BS0: u1 = 0,
        /// BS1 [1:1]
        /// Port x set bit y (y=
        BS1: u1 = 0,
        /// BS2 [2:2]
        /// Port x set bit y (y=
        BS2: u1 = 0,
        /// BS3 [3:3]
        /// Port x set bit y (y=
        BS3: u1 = 0,
        /// BS4 [4:4]
        /// Port x set bit y (y=
        BS4: u1 = 0,
        /// BS5 [5:5]
        /// Port x set bit y (y=
        BS5: u1 = 0,
        /// BS6 [6:6]
        /// Port x set bit y (y=
        BS6: u1 = 0,
        /// BS7 [7:7]
        /// Port x set bit y (y=
        BS7: u1 = 0,
        /// BS8 [8:8]
        /// Port x set bit y (y=
        BS8: u1 = 0,
        /// BS9 [9:9]
        /// Port x set bit y (y=
        BS9: u1 = 0,
        /// BS10 [10:10]
        /// Port x set bit y (y=
        BS10: u1 = 0,
        /// BS11 [11:11]
        /// Port x set bit y (y=
        BS11: u1 = 0,
        /// BS12 [12:12]
        /// Port x set bit y (y=
        BS12: u1 = 0,
        /// BS13 [13:13]
        /// Port x set bit y (y=
        BS13: u1 = 0,
        /// BS14 [14:14]
        /// Port x set bit y (y=
        BS14: u1 = 0,
        /// BS15 [15:15]
        /// Port x set bit y (y=
        BS15: u1 = 0,
        /// BR0 [16:16]
        /// Port x set bit y (y=
        BR0: u1 = 0,
        /// BR1 [17:17]
        /// Port x reset bit y (y =
        BR1: u1 = 0,
        /// BR2 [18:18]
        /// Port x reset bit y (y =
        BR2: u1 = 0,
        /// BR3 [19:19]
        /// Port x reset bit y (y =
        BR3: u1 = 0,
        /// BR4 [20:20]
        /// Port x reset bit y (y =
        BR4: u1 = 0,
        /// BR5 [21:21]
        /// Port x reset bit y (y =
        BR5: u1 = 0,
        /// BR6 [22:22]
        /// Port x reset bit y (y =
        BR6: u1 = 0,
        /// BR7 [23:23]
        /// Port x reset bit y (y =
        BR7: u1 = 0,
        /// BR8 [24:24]
        /// Port x reset bit y (y =
        BR8: u1 = 0,
        /// BR9 [25:25]
        /// Port x reset bit y (y =
        BR9: u1 = 0,
        /// BR10 [26:26]
        /// Port x reset bit y (y =
        BR10: u1 = 0,
        /// BR11 [27:27]
        /// Port x reset bit y (y =
        BR11: u1 = 0,
        /// BR12 [28:28]
        /// Port x reset bit y (y =
        BR12: u1 = 0,
        /// BR13 [29:29]
        /// Port x reset bit y (y =
        BR13: u1 = 0,
        /// BR14 [30:30]
        /// Port x reset bit y (y =
        BR14: u1 = 0,
        /// BR15 [31:31]
        /// Port x reset bit y (y =
        BR15: u1 = 0,
    };
    /// GPIO port bit set/reset
    pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

    /// LCKR
    const LCKR_val = packed struct {
        /// LCK0 [0:0]
        /// Port x lock bit y (y=
        LCK0: u1 = 0,
        /// LCK1 [1:1]
        /// Port x lock bit y (y=
        LCK1: u1 = 0,
        /// LCK2 [2:2]
        /// Port x lock bit y (y=
        LCK2: u1 = 0,
        /// LCK3 [3:3]
        /// Port x lock bit y (y=
        LCK3: u1 = 0,
        /// LCK4 [4:4]
        /// Port x lock bit y (y=
        LCK4: u1 = 0,
        /// LCK5 [5:5]
        /// Port x lock bit y (y=
        LCK5: u1 = 0,
        /// LCK6 [6:6]
        /// Port x lock bit y (y=
        LCK6: u1 = 0,
        /// LCK7 [7:7]
        /// Port x lock bit y (y=
        LCK7: u1 = 0,
        /// LCK8 [8:8]
        /// Port x lock bit y (y=
        LCK8: u1 = 0,
        /// LCK9 [9:9]
        /// Port x lock bit y (y=
        LCK9: u1 = 0,
        /// LCK10 [10:10]
        /// Port x lock bit y (y=
        LCK10: u1 = 0,
        /// LCK11 [11:11]
        /// Port x lock bit y (y=
        LCK11: u1 = 0,
        /// LCK12 [12:12]
        /// Port x lock bit y (y=
        LCK12: u1 = 0,
        /// LCK13 [13:13]
        /// Port x lock bit y (y=
        LCK13: u1 = 0,
        /// LCK14 [14:14]
        /// Port x lock bit y (y=
        LCK14: u1 = 0,
        /// LCK15 [15:15]
        /// Port x lock bit y (y=
        LCK15: u1 = 0,
        /// LCKK [16:16]
        /// Port x lock bit y (y=
        LCKK: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port configuration lock
    pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

    /// AFRL
    const AFRL_val = packed struct {
        /// AFRL0 [0:3]
        /// Alternate function selection for port x
        AFRL0: u4 = 0,
        /// AFRL1 [4:7]
        /// Alternate function selection for port x
        AFRL1: u4 = 0,
        /// AFRL2 [8:11]
        /// Alternate function selection for port x
        AFRL2: u4 = 0,
        /// AFRL3 [12:15]
        /// Alternate function selection for port x
        AFRL3: u4 = 0,
        /// AFRL4 [16:19]
        /// Alternate function selection for port x
        AFRL4: u4 = 0,
        /// AFRL5 [20:23]
        /// Alternate function selection for port x
        AFRL5: u4 = 0,
        /// AFRL6 [24:27]
        /// Alternate function selection for port x
        AFRL6: u4 = 0,
        /// AFRL7 [28:31]
        /// Alternate function selection for port x
        AFRL7: u4 = 0,
    };
    /// GPIO alternate function low
    pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

    /// AFRH
    const AFRH_val = packed struct {
        /// AFRH8 [0:3]
        /// Alternate function selection for port x
        AFRH8: u4 = 0,
        /// AFRH9 [4:7]
        /// Alternate function selection for port x
        AFRH9: u4 = 0,
        /// AFRH10 [8:11]
        /// Alternate function selection for port x
        AFRH10: u4 = 0,
        /// AFRH11 [12:15]
        /// Alternate function selection for port x
        AFRH11: u4 = 0,
        /// AFRH12 [16:19]
        /// Alternate function selection for port x
        AFRH12: u4 = 0,
        /// AFRH13 [20:23]
        /// Alternate function selection for port x
        AFRH13: u4 = 0,
        /// AFRH14 [24:27]
        /// Alternate function selection for port x
        AFRH14: u4 = 0,
        /// AFRH15 [28:31]
        /// Alternate function selection for port x
        AFRH15: u4 = 0,
    };
    /// GPIO alternate function high
    pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOE = struct {
    const base_address = 0x40021000;
    /// MODER
    const MODER_val = packed struct {
        /// MODER0 [0:1]
        /// Port x configuration bits (y =
        MODER0: u2 = 0,
        /// MODER1 [2:3]
        /// Port x configuration bits (y =
        MODER1: u2 = 0,
        /// MODER2 [4:5]
        /// Port x configuration bits (y =
        MODER2: u2 = 0,
        /// MODER3 [6:7]
        /// Port x configuration bits (y =
        MODER3: u2 = 0,
        /// MODER4 [8:9]
        /// Port x configuration bits (y =
        MODER4: u2 = 0,
        /// MODER5 [10:11]
        /// Port x configuration bits (y =
        MODER5: u2 = 0,
        /// MODER6 [12:13]
        /// Port x configuration bits (y =
        MODER6: u2 = 0,
        /// MODER7 [14:15]
        /// Port x configuration bits (y =
        MODER7: u2 = 0,
        /// MODER8 [16:17]
        /// Port x configuration bits (y =
        MODER8: u2 = 0,
        /// MODER9 [18:19]
        /// Port x configuration bits (y =
        MODER9: u2 = 0,
        /// MODER10 [20:21]
        /// Port x configuration bits (y =
        MODER10: u2 = 0,
        /// MODER11 [22:23]
        /// Port x configuration bits (y =
        MODER11: u2 = 0,
        /// MODER12 [24:25]
        /// Port x configuration bits (y =
        MODER12: u2 = 0,
        /// MODER13 [26:27]
        /// Port x configuration bits (y =
        MODER13: u2 = 0,
        /// MODER14 [28:29]
        /// Port x configuration bits (y =
        MODER14: u2 = 0,
        /// MODER15 [30:31]
        /// Port x configuration bits (y =
        MODER15: u2 = 0,
    };
    /// GPIO port mode register
    pub const MODER = Register(MODER_val).init(base_address + 0x0);

    /// OTYPER
    const OTYPER_val = packed struct {
        /// OT0 [0:0]
        /// Port x configuration bits (y =
        OT0: u1 = 0,
        /// OT1 [1:1]
        /// Port x configuration bits (y =
        OT1: u1 = 0,
        /// OT2 [2:2]
        /// Port x configuration bits (y =
        OT2: u1 = 0,
        /// OT3 [3:3]
        /// Port x configuration bits (y =
        OT3: u1 = 0,
        /// OT4 [4:4]
        /// Port x configuration bits (y =
        OT4: u1 = 0,
        /// OT5 [5:5]
        /// Port x configuration bits (y =
        OT5: u1 = 0,
        /// OT6 [6:6]
        /// Port x configuration bits (y =
        OT6: u1 = 0,
        /// OT7 [7:7]
        /// Port x configuration bits (y =
        OT7: u1 = 0,
        /// OT8 [8:8]
        /// Port x configuration bits (y =
        OT8: u1 = 0,
        /// OT9 [9:9]
        /// Port x configuration bits (y =
        OT9: u1 = 0,
        /// OT10 [10:10]
        /// Port x configuration bits (y =
        OT10: u1 = 0,
        /// OT11 [11:11]
        /// Port x configuration bits (y =
        OT11: u1 = 0,
        /// OT12 [12:12]
        /// Port x configuration bits (y =
        OT12: u1 = 0,
        /// OT13 [13:13]
        /// Port x configuration bits (y =
        OT13: u1 = 0,
        /// OT14 [14:14]
        /// Port x configuration bits (y =
        OT14: u1 = 0,
        /// OT15 [15:15]
        /// Port x configuration bits (y =
        OT15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output type register
    pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

    /// OSPEEDR
    const OSPEEDR_val = packed struct {
        /// OSPEEDR0 [0:1]
        /// Port x configuration bits (y =
        OSPEEDR0: u2 = 0,
        /// OSPEEDR1 [2:3]
        /// Port x configuration bits (y =
        OSPEEDR1: u2 = 0,
        /// OSPEEDR2 [4:5]
        /// Port x configuration bits (y =
        OSPEEDR2: u2 = 0,
        /// OSPEEDR3 [6:7]
        /// Port x configuration bits (y =
        OSPEEDR3: u2 = 0,
        /// OSPEEDR4 [8:9]
        /// Port x configuration bits (y =
        OSPEEDR4: u2 = 0,
        /// OSPEEDR5 [10:11]
        /// Port x configuration bits (y =
        OSPEEDR5: u2 = 0,
        /// OSPEEDR6 [12:13]
        /// Port x configuration bits (y =
        OSPEEDR6: u2 = 0,
        /// OSPEEDR7 [14:15]
        /// Port x configuration bits (y =
        OSPEEDR7: u2 = 0,
        /// OSPEEDR8 [16:17]
        /// Port x configuration bits (y =
        OSPEEDR8: u2 = 0,
        /// OSPEEDR9 [18:19]
        /// Port x configuration bits (y =
        OSPEEDR9: u2 = 0,
        /// OSPEEDR10 [20:21]
        /// Port x configuration bits (y =
        OSPEEDR10: u2 = 0,
        /// OSPEEDR11 [22:23]
        /// Port x configuration bits (y =
        OSPEEDR11: u2 = 0,
        /// OSPEEDR12 [24:25]
        /// Port x configuration bits (y =
        OSPEEDR12: u2 = 0,
        /// OSPEEDR13 [26:27]
        /// Port x configuration bits (y =
        OSPEEDR13: u2 = 0,
        /// OSPEEDR14 [28:29]
        /// Port x configuration bits (y =
        OSPEEDR14: u2 = 0,
        /// OSPEEDR15 [30:31]
        /// Port x configuration bits (y =
        OSPEEDR15: u2 = 0,
    };
    /// GPIO port output speed
    pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

    /// PUPDR
    const PUPDR_val = packed struct {
        /// PUPDR0 [0:1]
        /// Port x configuration bits (y =
        PUPDR0: u2 = 0,
        /// PUPDR1 [2:3]
        /// Port x configuration bits (y =
        PUPDR1: u2 = 0,
        /// PUPDR2 [4:5]
        /// Port x configuration bits (y =
        PUPDR2: u2 = 0,
        /// PUPDR3 [6:7]
        /// Port x configuration bits (y =
        PUPDR3: u2 = 0,
        /// PUPDR4 [8:9]
        /// Port x configuration bits (y =
        PUPDR4: u2 = 0,
        /// PUPDR5 [10:11]
        /// Port x configuration bits (y =
        PUPDR5: u2 = 0,
        /// PUPDR6 [12:13]
        /// Port x configuration bits (y =
        PUPDR6: u2 = 0,
        /// PUPDR7 [14:15]
        /// Port x configuration bits (y =
        PUPDR7: u2 = 0,
        /// PUPDR8 [16:17]
        /// Port x configuration bits (y =
        PUPDR8: u2 = 0,
        /// PUPDR9 [18:19]
        /// Port x configuration bits (y =
        PUPDR9: u2 = 0,
        /// PUPDR10 [20:21]
        /// Port x configuration bits (y =
        PUPDR10: u2 = 0,
        /// PUPDR11 [22:23]
        /// Port x configuration bits (y =
        PUPDR11: u2 = 0,
        /// PUPDR12 [24:25]
        /// Port x configuration bits (y =
        PUPDR12: u2 = 0,
        /// PUPDR13 [26:27]
        /// Port x configuration bits (y =
        PUPDR13: u2 = 0,
        /// PUPDR14 [28:29]
        /// Port x configuration bits (y =
        PUPDR14: u2 = 0,
        /// PUPDR15 [30:31]
        /// Port x configuration bits (y =
        PUPDR15: u2 = 0,
    };
    /// GPIO port pull-up/pull-down
    pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

    /// IDR
    const IDR_val = packed struct {
        /// IDR0 [0:0]
        /// Port input data (y =
        IDR0: u1 = 0,
        /// IDR1 [1:1]
        /// Port input data (y =
        IDR1: u1 = 0,
        /// IDR2 [2:2]
        /// Port input data (y =
        IDR2: u1 = 0,
        /// IDR3 [3:3]
        /// Port input data (y =
        IDR3: u1 = 0,
        /// IDR4 [4:4]
        /// Port input data (y =
        IDR4: u1 = 0,
        /// IDR5 [5:5]
        /// Port input data (y =
        IDR5: u1 = 0,
        /// IDR6 [6:6]
        /// Port input data (y =
        IDR6: u1 = 0,
        /// IDR7 [7:7]
        /// Port input data (y =
        IDR7: u1 = 0,
        /// IDR8 [8:8]
        /// Port input data (y =
        IDR8: u1 = 0,
        /// IDR9 [9:9]
        /// Port input data (y =
        IDR9: u1 = 0,
        /// IDR10 [10:10]
        /// Port input data (y =
        IDR10: u1 = 0,
        /// IDR11 [11:11]
        /// Port input data (y =
        IDR11: u1 = 0,
        /// IDR12 [12:12]
        /// Port input data (y =
        IDR12: u1 = 0,
        /// IDR13 [13:13]
        /// Port input data (y =
        IDR13: u1 = 0,
        /// IDR14 [14:14]
        /// Port input data (y =
        IDR14: u1 = 0,
        /// IDR15 [15:15]
        /// Port input data (y =
        IDR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port input data register
    pub const IDR = Register(IDR_val).init(base_address + 0x10);

    /// ODR
    const ODR_val = packed struct {
        /// ODR0 [0:0]
        /// Port output data (y =
        ODR0: u1 = 0,
        /// ODR1 [1:1]
        /// Port output data (y =
        ODR1: u1 = 0,
        /// ODR2 [2:2]
        /// Port output data (y =
        ODR2: u1 = 0,
        /// ODR3 [3:3]
        /// Port output data (y =
        ODR3: u1 = 0,
        /// ODR4 [4:4]
        /// Port output data (y =
        ODR4: u1 = 0,
        /// ODR5 [5:5]
        /// Port output data (y =
        ODR5: u1 = 0,
        /// ODR6 [6:6]
        /// Port output data (y =
        ODR6: u1 = 0,
        /// ODR7 [7:7]
        /// Port output data (y =
        ODR7: u1 = 0,
        /// ODR8 [8:8]
        /// Port output data (y =
        ODR8: u1 = 0,
        /// ODR9 [9:9]
        /// Port output data (y =
        ODR9: u1 = 0,
        /// ODR10 [10:10]
        /// Port output data (y =
        ODR10: u1 = 0,
        /// ODR11 [11:11]
        /// Port output data (y =
        ODR11: u1 = 0,
        /// ODR12 [12:12]
        /// Port output data (y =
        ODR12: u1 = 0,
        /// ODR13 [13:13]
        /// Port output data (y =
        ODR13: u1 = 0,
        /// ODR14 [14:14]
        /// Port output data (y =
        ODR14: u1 = 0,
        /// ODR15 [15:15]
        /// Port output data (y =
        ODR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output data register
    pub const ODR = Register(ODR_val).init(base_address + 0x14);

    /// BSRR
    const BSRR_val = packed struct {
        /// BS0 [0:0]
        /// Port x set bit y (y=
        BS0: u1 = 0,
        /// BS1 [1:1]
        /// Port x set bit y (y=
        BS1: u1 = 0,
        /// BS2 [2:2]
        /// Port x set bit y (y=
        BS2: u1 = 0,
        /// BS3 [3:3]
        /// Port x set bit y (y=
        BS3: u1 = 0,
        /// BS4 [4:4]
        /// Port x set bit y (y=
        BS4: u1 = 0,
        /// BS5 [5:5]
        /// Port x set bit y (y=
        BS5: u1 = 0,
        /// BS6 [6:6]
        /// Port x set bit y (y=
        BS6: u1 = 0,
        /// BS7 [7:7]
        /// Port x set bit y (y=
        BS7: u1 = 0,
        /// BS8 [8:8]
        /// Port x set bit y (y=
        BS8: u1 = 0,
        /// BS9 [9:9]
        /// Port x set bit y (y=
        BS9: u1 = 0,
        /// BS10 [10:10]
        /// Port x set bit y (y=
        BS10: u1 = 0,
        /// BS11 [11:11]
        /// Port x set bit y (y=
        BS11: u1 = 0,
        /// BS12 [12:12]
        /// Port x set bit y (y=
        BS12: u1 = 0,
        /// BS13 [13:13]
        /// Port x set bit y (y=
        BS13: u1 = 0,
        /// BS14 [14:14]
        /// Port x set bit y (y=
        BS14: u1 = 0,
        /// BS15 [15:15]
        /// Port x set bit y (y=
        BS15: u1 = 0,
        /// BR0 [16:16]
        /// Port x set bit y (y=
        BR0: u1 = 0,
        /// BR1 [17:17]
        /// Port x reset bit y (y =
        BR1: u1 = 0,
        /// BR2 [18:18]
        /// Port x reset bit y (y =
        BR2: u1 = 0,
        /// BR3 [19:19]
        /// Port x reset bit y (y =
        BR3: u1 = 0,
        /// BR4 [20:20]
        /// Port x reset bit y (y =
        BR4: u1 = 0,
        /// BR5 [21:21]
        /// Port x reset bit y (y =
        BR5: u1 = 0,
        /// BR6 [22:22]
        /// Port x reset bit y (y =
        BR6: u1 = 0,
        /// BR7 [23:23]
        /// Port x reset bit y (y =
        BR7: u1 = 0,
        /// BR8 [24:24]
        /// Port x reset bit y (y =
        BR8: u1 = 0,
        /// BR9 [25:25]
        /// Port x reset bit y (y =
        BR9: u1 = 0,
        /// BR10 [26:26]
        /// Port x reset bit y (y =
        BR10: u1 = 0,
        /// BR11 [27:27]
        /// Port x reset bit y (y =
        BR11: u1 = 0,
        /// BR12 [28:28]
        /// Port x reset bit y (y =
        BR12: u1 = 0,
        /// BR13 [29:29]
        /// Port x reset bit y (y =
        BR13: u1 = 0,
        /// BR14 [30:30]
        /// Port x reset bit y (y =
        BR14: u1 = 0,
        /// BR15 [31:31]
        /// Port x reset bit y (y =
        BR15: u1 = 0,
    };
    /// GPIO port bit set/reset
    pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

    /// LCKR
    const LCKR_val = packed struct {
        /// LCK0 [0:0]
        /// Port x lock bit y (y=
        LCK0: u1 = 0,
        /// LCK1 [1:1]
        /// Port x lock bit y (y=
        LCK1: u1 = 0,
        /// LCK2 [2:2]
        /// Port x lock bit y (y=
        LCK2: u1 = 0,
        /// LCK3 [3:3]
        /// Port x lock bit y (y=
        LCK3: u1 = 0,
        /// LCK4 [4:4]
        /// Port x lock bit y (y=
        LCK4: u1 = 0,
        /// LCK5 [5:5]
        /// Port x lock bit y (y=
        LCK5: u1 = 0,
        /// LCK6 [6:6]
        /// Port x lock bit y (y=
        LCK6: u1 = 0,
        /// LCK7 [7:7]
        /// Port x lock bit y (y=
        LCK7: u1 = 0,
        /// LCK8 [8:8]
        /// Port x lock bit y (y=
        LCK8: u1 = 0,
        /// LCK9 [9:9]
        /// Port x lock bit y (y=
        LCK9: u1 = 0,
        /// LCK10 [10:10]
        /// Port x lock bit y (y=
        LCK10: u1 = 0,
        /// LCK11 [11:11]
        /// Port x lock bit y (y=
        LCK11: u1 = 0,
        /// LCK12 [12:12]
        /// Port x lock bit y (y=
        LCK12: u1 = 0,
        /// LCK13 [13:13]
        /// Port x lock bit y (y=
        LCK13: u1 = 0,
        /// LCK14 [14:14]
        /// Port x lock bit y (y=
        LCK14: u1 = 0,
        /// LCK15 [15:15]
        /// Port x lock bit y (y=
        LCK15: u1 = 0,
        /// LCKK [16:16]
        /// Port x lock bit y (y=
        LCKK: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port configuration lock
    pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

    /// AFRL
    const AFRL_val = packed struct {
        /// AFRL0 [0:3]
        /// Alternate function selection for port x
        AFRL0: u4 = 0,
        /// AFRL1 [4:7]
        /// Alternate function selection for port x
        AFRL1: u4 = 0,
        /// AFRL2 [8:11]
        /// Alternate function selection for port x
        AFRL2: u4 = 0,
        /// AFRL3 [12:15]
        /// Alternate function selection for port x
        AFRL3: u4 = 0,
        /// AFRL4 [16:19]
        /// Alternate function selection for port x
        AFRL4: u4 = 0,
        /// AFRL5 [20:23]
        /// Alternate function selection for port x
        AFRL5: u4 = 0,
        /// AFRL6 [24:27]
        /// Alternate function selection for port x
        AFRL6: u4 = 0,
        /// AFRL7 [28:31]
        /// Alternate function selection for port x
        AFRL7: u4 = 0,
    };
    /// GPIO alternate function low
    pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

    /// AFRH
    const AFRH_val = packed struct {
        /// AFRH8 [0:3]
        /// Alternate function selection for port x
        AFRH8: u4 = 0,
        /// AFRH9 [4:7]
        /// Alternate function selection for port x
        AFRH9: u4 = 0,
        /// AFRH10 [8:11]
        /// Alternate function selection for port x
        AFRH10: u4 = 0,
        /// AFRH11 [12:15]
        /// Alternate function selection for port x
        AFRH11: u4 = 0,
        /// AFRH12 [16:19]
        /// Alternate function selection for port x
        AFRH12: u4 = 0,
        /// AFRH13 [20:23]
        /// Alternate function selection for port x
        AFRH13: u4 = 0,
        /// AFRH14 [24:27]
        /// Alternate function selection for port x
        AFRH14: u4 = 0,
        /// AFRH15 [28:31]
        /// Alternate function selection for port x
        AFRH15: u4 = 0,
    };
    /// GPIO alternate function high
    pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOD = struct {
    const base_address = 0x40020c00;
    /// MODER
    const MODER_val = packed struct {
        /// MODER0 [0:1]
        /// Port x configuration bits (y =
        MODER0: u2 = 0,
        /// MODER1 [2:3]
        /// Port x configuration bits (y =
        MODER1: u2 = 0,
        /// MODER2 [4:5]
        /// Port x configuration bits (y =
        MODER2: u2 = 0,
        /// MODER3 [6:7]
        /// Port x configuration bits (y =
        MODER3: u2 = 0,
        /// MODER4 [8:9]
        /// Port x configuration bits (y =
        MODER4: u2 = 0,
        /// MODER5 [10:11]
        /// Port x configuration bits (y =
        MODER5: u2 = 0,
        /// MODER6 [12:13]
        /// Port x configuration bits (y =
        MODER6: u2 = 0,
        /// MODER7 [14:15]
        /// Port x configuration bits (y =
        MODER7: u2 = 0,
        /// MODER8 [16:17]
        /// Port x configuration bits (y =
        MODER8: u2 = 0,
        /// MODER9 [18:19]
        /// Port x configuration bits (y =
        MODER9: u2 = 0,
        /// MODER10 [20:21]
        /// Port x configuration bits (y =
        MODER10: u2 = 0,
        /// MODER11 [22:23]
        /// Port x configuration bits (y =
        MODER11: u2 = 0,
        /// MODER12 [24:25]
        /// Port x configuration bits (y =
        MODER12: u2 = 0,
        /// MODER13 [26:27]
        /// Port x configuration bits (y =
        MODER13: u2 = 0,
        /// MODER14 [28:29]
        /// Port x configuration bits (y =
        MODER14: u2 = 0,
        /// MODER15 [30:31]
        /// Port x configuration bits (y =
        MODER15: u2 = 0,
    };
    /// GPIO port mode register
    pub const MODER = Register(MODER_val).init(base_address + 0x0);

    /// OTYPER
    const OTYPER_val = packed struct {
        /// OT0 [0:0]
        /// Port x configuration bits (y =
        OT0: u1 = 0,
        /// OT1 [1:1]
        /// Port x configuration bits (y =
        OT1: u1 = 0,
        /// OT2 [2:2]
        /// Port x configuration bits (y =
        OT2: u1 = 0,
        /// OT3 [3:3]
        /// Port x configuration bits (y =
        OT3: u1 = 0,
        /// OT4 [4:4]
        /// Port x configuration bits (y =
        OT4: u1 = 0,
        /// OT5 [5:5]
        /// Port x configuration bits (y =
        OT5: u1 = 0,
        /// OT6 [6:6]
        /// Port x configuration bits (y =
        OT6: u1 = 0,
        /// OT7 [7:7]
        /// Port x configuration bits (y =
        OT7: u1 = 0,
        /// OT8 [8:8]
        /// Port x configuration bits (y =
        OT8: u1 = 0,
        /// OT9 [9:9]
        /// Port x configuration bits (y =
        OT9: u1 = 0,
        /// OT10 [10:10]
        /// Port x configuration bits (y =
        OT10: u1 = 0,
        /// OT11 [11:11]
        /// Port x configuration bits (y =
        OT11: u1 = 0,
        /// OT12 [12:12]
        /// Port x configuration bits (y =
        OT12: u1 = 0,
        /// OT13 [13:13]
        /// Port x configuration bits (y =
        OT13: u1 = 0,
        /// OT14 [14:14]
        /// Port x configuration bits (y =
        OT14: u1 = 0,
        /// OT15 [15:15]
        /// Port x configuration bits (y =
        OT15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output type register
    pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

    /// OSPEEDR
    const OSPEEDR_val = packed struct {
        /// OSPEEDR0 [0:1]
        /// Port x configuration bits (y =
        OSPEEDR0: u2 = 0,
        /// OSPEEDR1 [2:3]
        /// Port x configuration bits (y =
        OSPEEDR1: u2 = 0,
        /// OSPEEDR2 [4:5]
        /// Port x configuration bits (y =
        OSPEEDR2: u2 = 0,
        /// OSPEEDR3 [6:7]
        /// Port x configuration bits (y =
        OSPEEDR3: u2 = 0,
        /// OSPEEDR4 [8:9]
        /// Port x configuration bits (y =
        OSPEEDR4: u2 = 0,
        /// OSPEEDR5 [10:11]
        /// Port x configuration bits (y =
        OSPEEDR5: u2 = 0,
        /// OSPEEDR6 [12:13]
        /// Port x configuration bits (y =
        OSPEEDR6: u2 = 0,
        /// OSPEEDR7 [14:15]
        /// Port x configuration bits (y =
        OSPEEDR7: u2 = 0,
        /// OSPEEDR8 [16:17]
        /// Port x configuration bits (y =
        OSPEEDR8: u2 = 0,
        /// OSPEEDR9 [18:19]
        /// Port x configuration bits (y =
        OSPEEDR9: u2 = 0,
        /// OSPEEDR10 [20:21]
        /// Port x configuration bits (y =
        OSPEEDR10: u2 = 0,
        /// OSPEEDR11 [22:23]
        /// Port x configuration bits (y =
        OSPEEDR11: u2 = 0,
        /// OSPEEDR12 [24:25]
        /// Port x configuration bits (y =
        OSPEEDR12: u2 = 0,
        /// OSPEEDR13 [26:27]
        /// Port x configuration bits (y =
        OSPEEDR13: u2 = 0,
        /// OSPEEDR14 [28:29]
        /// Port x configuration bits (y =
        OSPEEDR14: u2 = 0,
        /// OSPEEDR15 [30:31]
        /// Port x configuration bits (y =
        OSPEEDR15: u2 = 0,
    };
    /// GPIO port output speed
    pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

    /// PUPDR
    const PUPDR_val = packed struct {
        /// PUPDR0 [0:1]
        /// Port x configuration bits (y =
        PUPDR0: u2 = 0,
        /// PUPDR1 [2:3]
        /// Port x configuration bits (y =
        PUPDR1: u2 = 0,
        /// PUPDR2 [4:5]
        /// Port x configuration bits (y =
        PUPDR2: u2 = 0,
        /// PUPDR3 [6:7]
        /// Port x configuration bits (y =
        PUPDR3: u2 = 0,
        /// PUPDR4 [8:9]
        /// Port x configuration bits (y =
        PUPDR4: u2 = 0,
        /// PUPDR5 [10:11]
        /// Port x configuration bits (y =
        PUPDR5: u2 = 0,
        /// PUPDR6 [12:13]
        /// Port x configuration bits (y =
        PUPDR6: u2 = 0,
        /// PUPDR7 [14:15]
        /// Port x configuration bits (y =
        PUPDR7: u2 = 0,
        /// PUPDR8 [16:17]
        /// Port x configuration bits (y =
        PUPDR8: u2 = 0,
        /// PUPDR9 [18:19]
        /// Port x configuration bits (y =
        PUPDR9: u2 = 0,
        /// PUPDR10 [20:21]
        /// Port x configuration bits (y =
        PUPDR10: u2 = 0,
        /// PUPDR11 [22:23]
        /// Port x configuration bits (y =
        PUPDR11: u2 = 0,
        /// PUPDR12 [24:25]
        /// Port x configuration bits (y =
        PUPDR12: u2 = 0,
        /// PUPDR13 [26:27]
        /// Port x configuration bits (y =
        PUPDR13: u2 = 0,
        /// PUPDR14 [28:29]
        /// Port x configuration bits (y =
        PUPDR14: u2 = 0,
        /// PUPDR15 [30:31]
        /// Port x configuration bits (y =
        PUPDR15: u2 = 0,
    };
    /// GPIO port pull-up/pull-down
    pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

    /// IDR
    const IDR_val = packed struct {
        /// IDR0 [0:0]
        /// Port input data (y =
        IDR0: u1 = 0,
        /// IDR1 [1:1]
        /// Port input data (y =
        IDR1: u1 = 0,
        /// IDR2 [2:2]
        /// Port input data (y =
        IDR2: u1 = 0,
        /// IDR3 [3:3]
        /// Port input data (y =
        IDR3: u1 = 0,
        /// IDR4 [4:4]
        /// Port input data (y =
        IDR4: u1 = 0,
        /// IDR5 [5:5]
        /// Port input data (y =
        IDR5: u1 = 0,
        /// IDR6 [6:6]
        /// Port input data (y =
        IDR6: u1 = 0,
        /// IDR7 [7:7]
        /// Port input data (y =
        IDR7: u1 = 0,
        /// IDR8 [8:8]
        /// Port input data (y =
        IDR8: u1 = 0,
        /// IDR9 [9:9]
        /// Port input data (y =
        IDR9: u1 = 0,
        /// IDR10 [10:10]
        /// Port input data (y =
        IDR10: u1 = 0,
        /// IDR11 [11:11]
        /// Port input data (y =
        IDR11: u1 = 0,
        /// IDR12 [12:12]
        /// Port input data (y =
        IDR12: u1 = 0,
        /// IDR13 [13:13]
        /// Port input data (y =
        IDR13: u1 = 0,
        /// IDR14 [14:14]
        /// Port input data (y =
        IDR14: u1 = 0,
        /// IDR15 [15:15]
        /// Port input data (y =
        IDR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port input data register
    pub const IDR = Register(IDR_val).init(base_address + 0x10);

    /// ODR
    const ODR_val = packed struct {
        /// ODR0 [0:0]
        /// Port output data (y =
        ODR0: u1 = 0,
        /// ODR1 [1:1]
        /// Port output data (y =
        ODR1: u1 = 0,
        /// ODR2 [2:2]
        /// Port output data (y =
        ODR2: u1 = 0,
        /// ODR3 [3:3]
        /// Port output data (y =
        ODR3: u1 = 0,
        /// ODR4 [4:4]
        /// Port output data (y =
        ODR4: u1 = 0,
        /// ODR5 [5:5]
        /// Port output data (y =
        ODR5: u1 = 0,
        /// ODR6 [6:6]
        /// Port output data (y =
        ODR6: u1 = 0,
        /// ODR7 [7:7]
        /// Port output data (y =
        ODR7: u1 = 0,
        /// ODR8 [8:8]
        /// Port output data (y =
        ODR8: u1 = 0,
        /// ODR9 [9:9]
        /// Port output data (y =
        ODR9: u1 = 0,
        /// ODR10 [10:10]
        /// Port output data (y =
        ODR10: u1 = 0,
        /// ODR11 [11:11]
        /// Port output data (y =
        ODR11: u1 = 0,
        /// ODR12 [12:12]
        /// Port output data (y =
        ODR12: u1 = 0,
        /// ODR13 [13:13]
        /// Port output data (y =
        ODR13: u1 = 0,
        /// ODR14 [14:14]
        /// Port output data (y =
        ODR14: u1 = 0,
        /// ODR15 [15:15]
        /// Port output data (y =
        ODR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output data register
    pub const ODR = Register(ODR_val).init(base_address + 0x14);

    /// BSRR
    const BSRR_val = packed struct {
        /// BS0 [0:0]
        /// Port x set bit y (y=
        BS0: u1 = 0,
        /// BS1 [1:1]
        /// Port x set bit y (y=
        BS1: u1 = 0,
        /// BS2 [2:2]
        /// Port x set bit y (y=
        BS2: u1 = 0,
        /// BS3 [3:3]
        /// Port x set bit y (y=
        BS3: u1 = 0,
        /// BS4 [4:4]
        /// Port x set bit y (y=
        BS4: u1 = 0,
        /// BS5 [5:5]
        /// Port x set bit y (y=
        BS5: u1 = 0,
        /// BS6 [6:6]
        /// Port x set bit y (y=
        BS6: u1 = 0,
        /// BS7 [7:7]
        /// Port x set bit y (y=
        BS7: u1 = 0,
        /// BS8 [8:8]
        /// Port x set bit y (y=
        BS8: u1 = 0,
        /// BS9 [9:9]
        /// Port x set bit y (y=
        BS9: u1 = 0,
        /// BS10 [10:10]
        /// Port x set bit y (y=
        BS10: u1 = 0,
        /// BS11 [11:11]
        /// Port x set bit y (y=
        BS11: u1 = 0,
        /// BS12 [12:12]
        /// Port x set bit y (y=
        BS12: u1 = 0,
        /// BS13 [13:13]
        /// Port x set bit y (y=
        BS13: u1 = 0,
        /// BS14 [14:14]
        /// Port x set bit y (y=
        BS14: u1 = 0,
        /// BS15 [15:15]
        /// Port x set bit y (y=
        BS15: u1 = 0,
        /// BR0 [16:16]
        /// Port x set bit y (y=
        BR0: u1 = 0,
        /// BR1 [17:17]
        /// Port x reset bit y (y =
        BR1: u1 = 0,
        /// BR2 [18:18]
        /// Port x reset bit y (y =
        BR2: u1 = 0,
        /// BR3 [19:19]
        /// Port x reset bit y (y =
        BR3: u1 = 0,
        /// BR4 [20:20]
        /// Port x reset bit y (y =
        BR4: u1 = 0,
        /// BR5 [21:21]
        /// Port x reset bit y (y =
        BR5: u1 = 0,
        /// BR6 [22:22]
        /// Port x reset bit y (y =
        BR6: u1 = 0,
        /// BR7 [23:23]
        /// Port x reset bit y (y =
        BR7: u1 = 0,
        /// BR8 [24:24]
        /// Port x reset bit y (y =
        BR8: u1 = 0,
        /// BR9 [25:25]
        /// Port x reset bit y (y =
        BR9: u1 = 0,
        /// BR10 [26:26]
        /// Port x reset bit y (y =
        BR10: u1 = 0,
        /// BR11 [27:27]
        /// Port x reset bit y (y =
        BR11: u1 = 0,
        /// BR12 [28:28]
        /// Port x reset bit y (y =
        BR12: u1 = 0,
        /// BR13 [29:29]
        /// Port x reset bit y (y =
        BR13: u1 = 0,
        /// BR14 [30:30]
        /// Port x reset bit y (y =
        BR14: u1 = 0,
        /// BR15 [31:31]
        /// Port x reset bit y (y =
        BR15: u1 = 0,
    };
    /// GPIO port bit set/reset
    pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

    /// LCKR
    const LCKR_val = packed struct {
        /// LCK0 [0:0]
        /// Port x lock bit y (y=
        LCK0: u1 = 0,
        /// LCK1 [1:1]
        /// Port x lock bit y (y=
        LCK1: u1 = 0,
        /// LCK2 [2:2]
        /// Port x lock bit y (y=
        LCK2: u1 = 0,
        /// LCK3 [3:3]
        /// Port x lock bit y (y=
        LCK3: u1 = 0,
        /// LCK4 [4:4]
        /// Port x lock bit y (y=
        LCK4: u1 = 0,
        /// LCK5 [5:5]
        /// Port x lock bit y (y=
        LCK5: u1 = 0,
        /// LCK6 [6:6]
        /// Port x lock bit y (y=
        LCK6: u1 = 0,
        /// LCK7 [7:7]
        /// Port x lock bit y (y=
        LCK7: u1 = 0,
        /// LCK8 [8:8]
        /// Port x lock bit y (y=
        LCK8: u1 = 0,
        /// LCK9 [9:9]
        /// Port x lock bit y (y=
        LCK9: u1 = 0,
        /// LCK10 [10:10]
        /// Port x lock bit y (y=
        LCK10: u1 = 0,
        /// LCK11 [11:11]
        /// Port x lock bit y (y=
        LCK11: u1 = 0,
        /// LCK12 [12:12]
        /// Port x lock bit y (y=
        LCK12: u1 = 0,
        /// LCK13 [13:13]
        /// Port x lock bit y (y=
        LCK13: u1 = 0,
        /// LCK14 [14:14]
        /// Port x lock bit y (y=
        LCK14: u1 = 0,
        /// LCK15 [15:15]
        /// Port x lock bit y (y=
        LCK15: u1 = 0,
        /// LCKK [16:16]
        /// Port x lock bit y (y=
        LCKK: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port configuration lock
    pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

    /// AFRL
    const AFRL_val = packed struct {
        /// AFRL0 [0:3]
        /// Alternate function selection for port x
        AFRL0: u4 = 0,
        /// AFRL1 [4:7]
        /// Alternate function selection for port x
        AFRL1: u4 = 0,
        /// AFRL2 [8:11]
        /// Alternate function selection for port x
        AFRL2: u4 = 0,
        /// AFRL3 [12:15]
        /// Alternate function selection for port x
        AFRL3: u4 = 0,
        /// AFRL4 [16:19]
        /// Alternate function selection for port x
        AFRL4: u4 = 0,
        /// AFRL5 [20:23]
        /// Alternate function selection for port x
        AFRL5: u4 = 0,
        /// AFRL6 [24:27]
        /// Alternate function selection for port x
        AFRL6: u4 = 0,
        /// AFRL7 [28:31]
        /// Alternate function selection for port x
        AFRL7: u4 = 0,
    };
    /// GPIO alternate function low
    pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

    /// AFRH
    const AFRH_val = packed struct {
        /// AFRH8 [0:3]
        /// Alternate function selection for port x
        AFRH8: u4 = 0,
        /// AFRH9 [4:7]
        /// Alternate function selection for port x
        AFRH9: u4 = 0,
        /// AFRH10 [8:11]
        /// Alternate function selection for port x
        AFRH10: u4 = 0,
        /// AFRH11 [12:15]
        /// Alternate function selection for port x
        AFRH11: u4 = 0,
        /// AFRH12 [16:19]
        /// Alternate function selection for port x
        AFRH12: u4 = 0,
        /// AFRH13 [20:23]
        /// Alternate function selection for port x
        AFRH13: u4 = 0,
        /// AFRH14 [24:27]
        /// Alternate function selection for port x
        AFRH14: u4 = 0,
        /// AFRH15 [28:31]
        /// Alternate function selection for port x
        AFRH15: u4 = 0,
    };
    /// GPIO alternate function high
    pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOC = struct {
    const base_address = 0x40020800;
    /// MODER
    const MODER_val = packed struct {
        /// MODER0 [0:1]
        /// Port x configuration bits (y =
        MODER0: u2 = 0,
        /// MODER1 [2:3]
        /// Port x configuration bits (y =
        MODER1: u2 = 0,
        /// MODER2 [4:5]
        /// Port x configuration bits (y =
        MODER2: u2 = 0,
        /// MODER3 [6:7]
        /// Port x configuration bits (y =
        MODER3: u2 = 0,
        /// MODER4 [8:9]
        /// Port x configuration bits (y =
        MODER4: u2 = 0,
        /// MODER5 [10:11]
        /// Port x configuration bits (y =
        MODER5: u2 = 0,
        /// MODER6 [12:13]
        /// Port x configuration bits (y =
        MODER6: u2 = 0,
        /// MODER7 [14:15]
        /// Port x configuration bits (y =
        MODER7: u2 = 0,
        /// MODER8 [16:17]
        /// Port x configuration bits (y =
        MODER8: u2 = 0,
        /// MODER9 [18:19]
        /// Port x configuration bits (y =
        MODER9: u2 = 0,
        /// MODER10 [20:21]
        /// Port x configuration bits (y =
        MODER10: u2 = 0,
        /// MODER11 [22:23]
        /// Port x configuration bits (y =
        MODER11: u2 = 0,
        /// MODER12 [24:25]
        /// Port x configuration bits (y =
        MODER12: u2 = 0,
        /// MODER13 [26:27]
        /// Port x configuration bits (y =
        MODER13: u2 = 0,
        /// MODER14 [28:29]
        /// Port x configuration bits (y =
        MODER14: u2 = 0,
        /// MODER15 [30:31]
        /// Port x configuration bits (y =
        MODER15: u2 = 0,
    };
    /// GPIO port mode register
    pub const MODER = Register(MODER_val).init(base_address + 0x0);

    /// OTYPER
    const OTYPER_val = packed struct {
        /// OT0 [0:0]
        /// Port x configuration bits (y =
        OT0: u1 = 0,
        /// OT1 [1:1]
        /// Port x configuration bits (y =
        OT1: u1 = 0,
        /// OT2 [2:2]
        /// Port x configuration bits (y =
        OT2: u1 = 0,
        /// OT3 [3:3]
        /// Port x configuration bits (y =
        OT3: u1 = 0,
        /// OT4 [4:4]
        /// Port x configuration bits (y =
        OT4: u1 = 0,
        /// OT5 [5:5]
        /// Port x configuration bits (y =
        OT5: u1 = 0,
        /// OT6 [6:6]
        /// Port x configuration bits (y =
        OT6: u1 = 0,
        /// OT7 [7:7]
        /// Port x configuration bits (y =
        OT7: u1 = 0,
        /// OT8 [8:8]
        /// Port x configuration bits (y =
        OT8: u1 = 0,
        /// OT9 [9:9]
        /// Port x configuration bits (y =
        OT9: u1 = 0,
        /// OT10 [10:10]
        /// Port x configuration bits (y =
        OT10: u1 = 0,
        /// OT11 [11:11]
        /// Port x configuration bits (y =
        OT11: u1 = 0,
        /// OT12 [12:12]
        /// Port x configuration bits (y =
        OT12: u1 = 0,
        /// OT13 [13:13]
        /// Port x configuration bits (y =
        OT13: u1 = 0,
        /// OT14 [14:14]
        /// Port x configuration bits (y =
        OT14: u1 = 0,
        /// OT15 [15:15]
        /// Port x configuration bits (y =
        OT15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output type register
    pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

    /// OSPEEDR
    const OSPEEDR_val = packed struct {
        /// OSPEEDR0 [0:1]
        /// Port x configuration bits (y =
        OSPEEDR0: u2 = 0,
        /// OSPEEDR1 [2:3]
        /// Port x configuration bits (y =
        OSPEEDR1: u2 = 0,
        /// OSPEEDR2 [4:5]
        /// Port x configuration bits (y =
        OSPEEDR2: u2 = 0,
        /// OSPEEDR3 [6:7]
        /// Port x configuration bits (y =
        OSPEEDR3: u2 = 0,
        /// OSPEEDR4 [8:9]
        /// Port x configuration bits (y =
        OSPEEDR4: u2 = 0,
        /// OSPEEDR5 [10:11]
        /// Port x configuration bits (y =
        OSPEEDR5: u2 = 0,
        /// OSPEEDR6 [12:13]
        /// Port x configuration bits (y =
        OSPEEDR6: u2 = 0,
        /// OSPEEDR7 [14:15]
        /// Port x configuration bits (y =
        OSPEEDR7: u2 = 0,
        /// OSPEEDR8 [16:17]
        /// Port x configuration bits (y =
        OSPEEDR8: u2 = 0,
        /// OSPEEDR9 [18:19]
        /// Port x configuration bits (y =
        OSPEEDR9: u2 = 0,
        /// OSPEEDR10 [20:21]
        /// Port x configuration bits (y =
        OSPEEDR10: u2 = 0,
        /// OSPEEDR11 [22:23]
        /// Port x configuration bits (y =
        OSPEEDR11: u2 = 0,
        /// OSPEEDR12 [24:25]
        /// Port x configuration bits (y =
        OSPEEDR12: u2 = 0,
        /// OSPEEDR13 [26:27]
        /// Port x configuration bits (y =
        OSPEEDR13: u2 = 0,
        /// OSPEEDR14 [28:29]
        /// Port x configuration bits (y =
        OSPEEDR14: u2 = 0,
        /// OSPEEDR15 [30:31]
        /// Port x configuration bits (y =
        OSPEEDR15: u2 = 0,
    };
    /// GPIO port output speed
    pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

    /// PUPDR
    const PUPDR_val = packed struct {
        /// PUPDR0 [0:1]
        /// Port x configuration bits (y =
        PUPDR0: u2 = 0,
        /// PUPDR1 [2:3]
        /// Port x configuration bits (y =
        PUPDR1: u2 = 0,
        /// PUPDR2 [4:5]
        /// Port x configuration bits (y =
        PUPDR2: u2 = 0,
        /// PUPDR3 [6:7]
        /// Port x configuration bits (y =
        PUPDR3: u2 = 0,
        /// PUPDR4 [8:9]
        /// Port x configuration bits (y =
        PUPDR4: u2 = 0,
        /// PUPDR5 [10:11]
        /// Port x configuration bits (y =
        PUPDR5: u2 = 0,
        /// PUPDR6 [12:13]
        /// Port x configuration bits (y =
        PUPDR6: u2 = 0,
        /// PUPDR7 [14:15]
        /// Port x configuration bits (y =
        PUPDR7: u2 = 0,
        /// PUPDR8 [16:17]
        /// Port x configuration bits (y =
        PUPDR8: u2 = 0,
        /// PUPDR9 [18:19]
        /// Port x configuration bits (y =
        PUPDR9: u2 = 0,
        /// PUPDR10 [20:21]
        /// Port x configuration bits (y =
        PUPDR10: u2 = 0,
        /// PUPDR11 [22:23]
        /// Port x configuration bits (y =
        PUPDR11: u2 = 0,
        /// PUPDR12 [24:25]
        /// Port x configuration bits (y =
        PUPDR12: u2 = 0,
        /// PUPDR13 [26:27]
        /// Port x configuration bits (y =
        PUPDR13: u2 = 0,
        /// PUPDR14 [28:29]
        /// Port x configuration bits (y =
        PUPDR14: u2 = 0,
        /// PUPDR15 [30:31]
        /// Port x configuration bits (y =
        PUPDR15: u2 = 0,
    };
    /// GPIO port pull-up/pull-down
    pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

    /// IDR
    const IDR_val = packed struct {
        /// IDR0 [0:0]
        /// Port input data (y =
        IDR0: u1 = 0,
        /// IDR1 [1:1]
        /// Port input data (y =
        IDR1: u1 = 0,
        /// IDR2 [2:2]
        /// Port input data (y =
        IDR2: u1 = 0,
        /// IDR3 [3:3]
        /// Port input data (y =
        IDR3: u1 = 0,
        /// IDR4 [4:4]
        /// Port input data (y =
        IDR4: u1 = 0,
        /// IDR5 [5:5]
        /// Port input data (y =
        IDR5: u1 = 0,
        /// IDR6 [6:6]
        /// Port input data (y =
        IDR6: u1 = 0,
        /// IDR7 [7:7]
        /// Port input data (y =
        IDR7: u1 = 0,
        /// IDR8 [8:8]
        /// Port input data (y =
        IDR8: u1 = 0,
        /// IDR9 [9:9]
        /// Port input data (y =
        IDR9: u1 = 0,
        /// IDR10 [10:10]
        /// Port input data (y =
        IDR10: u1 = 0,
        /// IDR11 [11:11]
        /// Port input data (y =
        IDR11: u1 = 0,
        /// IDR12 [12:12]
        /// Port input data (y =
        IDR12: u1 = 0,
        /// IDR13 [13:13]
        /// Port input data (y =
        IDR13: u1 = 0,
        /// IDR14 [14:14]
        /// Port input data (y =
        IDR14: u1 = 0,
        /// IDR15 [15:15]
        /// Port input data (y =
        IDR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port input data register
    pub const IDR = Register(IDR_val).init(base_address + 0x10);

    /// ODR
    const ODR_val = packed struct {
        /// ODR0 [0:0]
        /// Port output data (y =
        ODR0: u1 = 0,
        /// ODR1 [1:1]
        /// Port output data (y =
        ODR1: u1 = 0,
        /// ODR2 [2:2]
        /// Port output data (y =
        ODR2: u1 = 0,
        /// ODR3 [3:3]
        /// Port output data (y =
        ODR3: u1 = 0,
        /// ODR4 [4:4]
        /// Port output data (y =
        ODR4: u1 = 0,
        /// ODR5 [5:5]
        /// Port output data (y =
        ODR5: u1 = 0,
        /// ODR6 [6:6]
        /// Port output data (y =
        ODR6: u1 = 0,
        /// ODR7 [7:7]
        /// Port output data (y =
        ODR7: u1 = 0,
        /// ODR8 [8:8]
        /// Port output data (y =
        ODR8: u1 = 0,
        /// ODR9 [9:9]
        /// Port output data (y =
        ODR9: u1 = 0,
        /// ODR10 [10:10]
        /// Port output data (y =
        ODR10: u1 = 0,
        /// ODR11 [11:11]
        /// Port output data (y =
        ODR11: u1 = 0,
        /// ODR12 [12:12]
        /// Port output data (y =
        ODR12: u1 = 0,
        /// ODR13 [13:13]
        /// Port output data (y =
        ODR13: u1 = 0,
        /// ODR14 [14:14]
        /// Port output data (y =
        ODR14: u1 = 0,
        /// ODR15 [15:15]
        /// Port output data (y =
        ODR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output data register
    pub const ODR = Register(ODR_val).init(base_address + 0x14);

    /// BSRR
    const BSRR_val = packed struct {
        /// BS0 [0:0]
        /// Port x set bit y (y=
        BS0: u1 = 0,
        /// BS1 [1:1]
        /// Port x set bit y (y=
        BS1: u1 = 0,
        /// BS2 [2:2]
        /// Port x set bit y (y=
        BS2: u1 = 0,
        /// BS3 [3:3]
        /// Port x set bit y (y=
        BS3: u1 = 0,
        /// BS4 [4:4]
        /// Port x set bit y (y=
        BS4: u1 = 0,
        /// BS5 [5:5]
        /// Port x set bit y (y=
        BS5: u1 = 0,
        /// BS6 [6:6]
        /// Port x set bit y (y=
        BS6: u1 = 0,
        /// BS7 [7:7]
        /// Port x set bit y (y=
        BS7: u1 = 0,
        /// BS8 [8:8]
        /// Port x set bit y (y=
        BS8: u1 = 0,
        /// BS9 [9:9]
        /// Port x set bit y (y=
        BS9: u1 = 0,
        /// BS10 [10:10]
        /// Port x set bit y (y=
        BS10: u1 = 0,
        /// BS11 [11:11]
        /// Port x set bit y (y=
        BS11: u1 = 0,
        /// BS12 [12:12]
        /// Port x set bit y (y=
        BS12: u1 = 0,
        /// BS13 [13:13]
        /// Port x set bit y (y=
        BS13: u1 = 0,
        /// BS14 [14:14]
        /// Port x set bit y (y=
        BS14: u1 = 0,
        /// BS15 [15:15]
        /// Port x set bit y (y=
        BS15: u1 = 0,
        /// BR0 [16:16]
        /// Port x set bit y (y=
        BR0: u1 = 0,
        /// BR1 [17:17]
        /// Port x reset bit y (y =
        BR1: u1 = 0,
        /// BR2 [18:18]
        /// Port x reset bit y (y =
        BR2: u1 = 0,
        /// BR3 [19:19]
        /// Port x reset bit y (y =
        BR3: u1 = 0,
        /// BR4 [20:20]
        /// Port x reset bit y (y =
        BR4: u1 = 0,
        /// BR5 [21:21]
        /// Port x reset bit y (y =
        BR5: u1 = 0,
        /// BR6 [22:22]
        /// Port x reset bit y (y =
        BR6: u1 = 0,
        /// BR7 [23:23]
        /// Port x reset bit y (y =
        BR7: u1 = 0,
        /// BR8 [24:24]
        /// Port x reset bit y (y =
        BR8: u1 = 0,
        /// BR9 [25:25]
        /// Port x reset bit y (y =
        BR9: u1 = 0,
        /// BR10 [26:26]
        /// Port x reset bit y (y =
        BR10: u1 = 0,
        /// BR11 [27:27]
        /// Port x reset bit y (y =
        BR11: u1 = 0,
        /// BR12 [28:28]
        /// Port x reset bit y (y =
        BR12: u1 = 0,
        /// BR13 [29:29]
        /// Port x reset bit y (y =
        BR13: u1 = 0,
        /// BR14 [30:30]
        /// Port x reset bit y (y =
        BR14: u1 = 0,
        /// BR15 [31:31]
        /// Port x reset bit y (y =
        BR15: u1 = 0,
    };
    /// GPIO port bit set/reset
    pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

    /// LCKR
    const LCKR_val = packed struct {
        /// LCK0 [0:0]
        /// Port x lock bit y (y=
        LCK0: u1 = 0,
        /// LCK1 [1:1]
        /// Port x lock bit y (y=
        LCK1: u1 = 0,
        /// LCK2 [2:2]
        /// Port x lock bit y (y=
        LCK2: u1 = 0,
        /// LCK3 [3:3]
        /// Port x lock bit y (y=
        LCK3: u1 = 0,
        /// LCK4 [4:4]
        /// Port x lock bit y (y=
        LCK4: u1 = 0,
        /// LCK5 [5:5]
        /// Port x lock bit y (y=
        LCK5: u1 = 0,
        /// LCK6 [6:6]
        /// Port x lock bit y (y=
        LCK6: u1 = 0,
        /// LCK7 [7:7]
        /// Port x lock bit y (y=
        LCK7: u1 = 0,
        /// LCK8 [8:8]
        /// Port x lock bit y (y=
        LCK8: u1 = 0,
        /// LCK9 [9:9]
        /// Port x lock bit y (y=
        LCK9: u1 = 0,
        /// LCK10 [10:10]
        /// Port x lock bit y (y=
        LCK10: u1 = 0,
        /// LCK11 [11:11]
        /// Port x lock bit y (y=
        LCK11: u1 = 0,
        /// LCK12 [12:12]
        /// Port x lock bit y (y=
        LCK12: u1 = 0,
        /// LCK13 [13:13]
        /// Port x lock bit y (y=
        LCK13: u1 = 0,
        /// LCK14 [14:14]
        /// Port x lock bit y (y=
        LCK14: u1 = 0,
        /// LCK15 [15:15]
        /// Port x lock bit y (y=
        LCK15: u1 = 0,
        /// LCKK [16:16]
        /// Port x lock bit y (y=
        LCKK: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port configuration lock
    pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

    /// AFRL
    const AFRL_val = packed struct {
        /// AFRL0 [0:3]
        /// Alternate function selection for port x
        AFRL0: u4 = 0,
        /// AFRL1 [4:7]
        /// Alternate function selection for port x
        AFRL1: u4 = 0,
        /// AFRL2 [8:11]
        /// Alternate function selection for port x
        AFRL2: u4 = 0,
        /// AFRL3 [12:15]
        /// Alternate function selection for port x
        AFRL3: u4 = 0,
        /// AFRL4 [16:19]
        /// Alternate function selection for port x
        AFRL4: u4 = 0,
        /// AFRL5 [20:23]
        /// Alternate function selection for port x
        AFRL5: u4 = 0,
        /// AFRL6 [24:27]
        /// Alternate function selection for port x
        AFRL6: u4 = 0,
        /// AFRL7 [28:31]
        /// Alternate function selection for port x
        AFRL7: u4 = 0,
    };
    /// GPIO alternate function low
    pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

    /// AFRH
    const AFRH_val = packed struct {
        /// AFRH8 [0:3]
        /// Alternate function selection for port x
        AFRH8: u4 = 0,
        /// AFRH9 [4:7]
        /// Alternate function selection for port x
        AFRH9: u4 = 0,
        /// AFRH10 [8:11]
        /// Alternate function selection for port x
        AFRH10: u4 = 0,
        /// AFRH11 [12:15]
        /// Alternate function selection for port x
        AFRH11: u4 = 0,
        /// AFRH12 [16:19]
        /// Alternate function selection for port x
        AFRH12: u4 = 0,
        /// AFRH13 [20:23]
        /// Alternate function selection for port x
        AFRH13: u4 = 0,
        /// AFRH14 [24:27]
        /// Alternate function selection for port x
        AFRH14: u4 = 0,
        /// AFRH15 [28:31]
        /// Alternate function selection for port x
        AFRH15: u4 = 0,
    };
    /// GPIO alternate function high
    pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOB = struct {
    const base_address = 0x40020400;
    /// MODER
    const MODER_val = packed struct {
        /// MODER0 [0:1]
        /// Port x configuration bits (y =
        MODER0: u2 = 0,
        /// MODER1 [2:3]
        /// Port x configuration bits (y =
        MODER1: u2 = 0,
        /// MODER2 [4:5]
        /// Port x configuration bits (y =
        MODER2: u2 = 0,
        /// MODER3 [6:7]
        /// Port x configuration bits (y =
        MODER3: u2 = 2,
        /// MODER4 [8:9]
        /// Port x configuration bits (y =
        MODER4: u2 = 2,
        /// MODER5 [10:11]
        /// Port x configuration bits (y =
        MODER5: u2 = 0,
        /// MODER6 [12:13]
        /// Port x configuration bits (y =
        MODER6: u2 = 0,
        /// MODER7 [14:15]
        /// Port x configuration bits (y =
        MODER7: u2 = 0,
        /// MODER8 [16:17]
        /// Port x configuration bits (y =
        MODER8: u2 = 0,
        /// MODER9 [18:19]
        /// Port x configuration bits (y =
        MODER9: u2 = 0,
        /// MODER10 [20:21]
        /// Port x configuration bits (y =
        MODER10: u2 = 0,
        /// MODER11 [22:23]
        /// Port x configuration bits (y =
        MODER11: u2 = 0,
        /// MODER12 [24:25]
        /// Port x configuration bits (y =
        MODER12: u2 = 0,
        /// MODER13 [26:27]
        /// Port x configuration bits (y =
        MODER13: u2 = 0,
        /// MODER14 [28:29]
        /// Port x configuration bits (y =
        MODER14: u2 = 0,
        /// MODER15 [30:31]
        /// Port x configuration bits (y =
        MODER15: u2 = 0,
    };
    /// GPIO port mode register
    pub const MODER = Register(MODER_val).init(base_address + 0x0);

    /// OTYPER
    const OTYPER_val = packed struct {
        /// OT0 [0:0]
        /// Port x configuration bits (y =
        OT0: u1 = 0,
        /// OT1 [1:1]
        /// Port x configuration bits (y =
        OT1: u1 = 0,
        /// OT2 [2:2]
        /// Port x configuration bits (y =
        OT2: u1 = 0,
        /// OT3 [3:3]
        /// Port x configuration bits (y =
        OT3: u1 = 0,
        /// OT4 [4:4]
        /// Port x configuration bits (y =
        OT4: u1 = 0,
        /// OT5 [5:5]
        /// Port x configuration bits (y =
        OT5: u1 = 0,
        /// OT6 [6:6]
        /// Port x configuration bits (y =
        OT6: u1 = 0,
        /// OT7 [7:7]
        /// Port x configuration bits (y =
        OT7: u1 = 0,
        /// OT8 [8:8]
        /// Port x configuration bits (y =
        OT8: u1 = 0,
        /// OT9 [9:9]
        /// Port x configuration bits (y =
        OT9: u1 = 0,
        /// OT10 [10:10]
        /// Port x configuration bits (y =
        OT10: u1 = 0,
        /// OT11 [11:11]
        /// Port x configuration bits (y =
        OT11: u1 = 0,
        /// OT12 [12:12]
        /// Port x configuration bits (y =
        OT12: u1 = 0,
        /// OT13 [13:13]
        /// Port x configuration bits (y =
        OT13: u1 = 0,
        /// OT14 [14:14]
        /// Port x configuration bits (y =
        OT14: u1 = 0,
        /// OT15 [15:15]
        /// Port x configuration bits (y =
        OT15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output type register
    pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

    /// OSPEEDR
    const OSPEEDR_val = packed struct {
        /// OSPEEDR0 [0:1]
        /// Port x configuration bits (y =
        OSPEEDR0: u2 = 0,
        /// OSPEEDR1 [2:3]
        /// Port x configuration bits (y =
        OSPEEDR1: u2 = 0,
        /// OSPEEDR2 [4:5]
        /// Port x configuration bits (y =
        OSPEEDR2: u2 = 0,
        /// OSPEEDR3 [6:7]
        /// Port x configuration bits (y =
        OSPEEDR3: u2 = 3,
        /// OSPEEDR4 [8:9]
        /// Port x configuration bits (y =
        OSPEEDR4: u2 = 0,
        /// OSPEEDR5 [10:11]
        /// Port x configuration bits (y =
        OSPEEDR5: u2 = 0,
        /// OSPEEDR6 [12:13]
        /// Port x configuration bits (y =
        OSPEEDR6: u2 = 0,
        /// OSPEEDR7 [14:15]
        /// Port x configuration bits (y =
        OSPEEDR7: u2 = 0,
        /// OSPEEDR8 [16:17]
        /// Port x configuration bits (y =
        OSPEEDR8: u2 = 0,
        /// OSPEEDR9 [18:19]
        /// Port x configuration bits (y =
        OSPEEDR9: u2 = 0,
        /// OSPEEDR10 [20:21]
        /// Port x configuration bits (y =
        OSPEEDR10: u2 = 0,
        /// OSPEEDR11 [22:23]
        /// Port x configuration bits (y =
        OSPEEDR11: u2 = 0,
        /// OSPEEDR12 [24:25]
        /// Port x configuration bits (y =
        OSPEEDR12: u2 = 0,
        /// OSPEEDR13 [26:27]
        /// Port x configuration bits (y =
        OSPEEDR13: u2 = 0,
        /// OSPEEDR14 [28:29]
        /// Port x configuration bits (y =
        OSPEEDR14: u2 = 0,
        /// OSPEEDR15 [30:31]
        /// Port x configuration bits (y =
        OSPEEDR15: u2 = 0,
    };
    /// GPIO port output speed
    pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

    /// PUPDR
    const PUPDR_val = packed struct {
        /// PUPDR0 [0:1]
        /// Port x configuration bits (y =
        PUPDR0: u2 = 0,
        /// PUPDR1 [2:3]
        /// Port x configuration bits (y =
        PUPDR1: u2 = 0,
        /// PUPDR2 [4:5]
        /// Port x configuration bits (y =
        PUPDR2: u2 = 0,
        /// PUPDR3 [6:7]
        /// Port x configuration bits (y =
        PUPDR3: u2 = 0,
        /// PUPDR4 [8:9]
        /// Port x configuration bits (y =
        PUPDR4: u2 = 1,
        /// PUPDR5 [10:11]
        /// Port x configuration bits (y =
        PUPDR5: u2 = 0,
        /// PUPDR6 [12:13]
        /// Port x configuration bits (y =
        PUPDR6: u2 = 0,
        /// PUPDR7 [14:15]
        /// Port x configuration bits (y =
        PUPDR7: u2 = 0,
        /// PUPDR8 [16:17]
        /// Port x configuration bits (y =
        PUPDR8: u2 = 0,
        /// PUPDR9 [18:19]
        /// Port x configuration bits (y =
        PUPDR9: u2 = 0,
        /// PUPDR10 [20:21]
        /// Port x configuration bits (y =
        PUPDR10: u2 = 0,
        /// PUPDR11 [22:23]
        /// Port x configuration bits (y =
        PUPDR11: u2 = 0,
        /// PUPDR12 [24:25]
        /// Port x configuration bits (y =
        PUPDR12: u2 = 0,
        /// PUPDR13 [26:27]
        /// Port x configuration bits (y =
        PUPDR13: u2 = 0,
        /// PUPDR14 [28:29]
        /// Port x configuration bits (y =
        PUPDR14: u2 = 0,
        /// PUPDR15 [30:31]
        /// Port x configuration bits (y =
        PUPDR15: u2 = 0,
    };
    /// GPIO port pull-up/pull-down
    pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

    /// IDR
    const IDR_val = packed struct {
        /// IDR0 [0:0]
        /// Port input data (y =
        IDR0: u1 = 0,
        /// IDR1 [1:1]
        /// Port input data (y =
        IDR1: u1 = 0,
        /// IDR2 [2:2]
        /// Port input data (y =
        IDR2: u1 = 0,
        /// IDR3 [3:3]
        /// Port input data (y =
        IDR3: u1 = 0,
        /// IDR4 [4:4]
        /// Port input data (y =
        IDR4: u1 = 0,
        /// IDR5 [5:5]
        /// Port input data (y =
        IDR5: u1 = 0,
        /// IDR6 [6:6]
        /// Port input data (y =
        IDR6: u1 = 0,
        /// IDR7 [7:7]
        /// Port input data (y =
        IDR7: u1 = 0,
        /// IDR8 [8:8]
        /// Port input data (y =
        IDR8: u1 = 0,
        /// IDR9 [9:9]
        /// Port input data (y =
        IDR9: u1 = 0,
        /// IDR10 [10:10]
        /// Port input data (y =
        IDR10: u1 = 0,
        /// IDR11 [11:11]
        /// Port input data (y =
        IDR11: u1 = 0,
        /// IDR12 [12:12]
        /// Port input data (y =
        IDR12: u1 = 0,
        /// IDR13 [13:13]
        /// Port input data (y =
        IDR13: u1 = 0,
        /// IDR14 [14:14]
        /// Port input data (y =
        IDR14: u1 = 0,
        /// IDR15 [15:15]
        /// Port input data (y =
        IDR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port input data register
    pub const IDR = Register(IDR_val).init(base_address + 0x10);

    /// ODR
    const ODR_val = packed struct {
        /// ODR0 [0:0]
        /// Port output data (y =
        ODR0: u1 = 0,
        /// ODR1 [1:1]
        /// Port output data (y =
        ODR1: u1 = 0,
        /// ODR2 [2:2]
        /// Port output data (y =
        ODR2: u1 = 0,
        /// ODR3 [3:3]
        /// Port output data (y =
        ODR3: u1 = 0,
        /// ODR4 [4:4]
        /// Port output data (y =
        ODR4: u1 = 0,
        /// ODR5 [5:5]
        /// Port output data (y =
        ODR5: u1 = 0,
        /// ODR6 [6:6]
        /// Port output data (y =
        ODR6: u1 = 0,
        /// ODR7 [7:7]
        /// Port output data (y =
        ODR7: u1 = 0,
        /// ODR8 [8:8]
        /// Port output data (y =
        ODR8: u1 = 0,
        /// ODR9 [9:9]
        /// Port output data (y =
        ODR9: u1 = 0,
        /// ODR10 [10:10]
        /// Port output data (y =
        ODR10: u1 = 0,
        /// ODR11 [11:11]
        /// Port output data (y =
        ODR11: u1 = 0,
        /// ODR12 [12:12]
        /// Port output data (y =
        ODR12: u1 = 0,
        /// ODR13 [13:13]
        /// Port output data (y =
        ODR13: u1 = 0,
        /// ODR14 [14:14]
        /// Port output data (y =
        ODR14: u1 = 0,
        /// ODR15 [15:15]
        /// Port output data (y =
        ODR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output data register
    pub const ODR = Register(ODR_val).init(base_address + 0x14);

    /// BSRR
    const BSRR_val = packed struct {
        /// BS0 [0:0]
        /// Port x set bit y (y=
        BS0: u1 = 0,
        /// BS1 [1:1]
        /// Port x set bit y (y=
        BS1: u1 = 0,
        /// BS2 [2:2]
        /// Port x set bit y (y=
        BS2: u1 = 0,
        /// BS3 [3:3]
        /// Port x set bit y (y=
        BS3: u1 = 0,
        /// BS4 [4:4]
        /// Port x set bit y (y=
        BS4: u1 = 0,
        /// BS5 [5:5]
        /// Port x set bit y (y=
        BS5: u1 = 0,
        /// BS6 [6:6]
        /// Port x set bit y (y=
        BS6: u1 = 0,
        /// BS7 [7:7]
        /// Port x set bit y (y=
        BS7: u1 = 0,
        /// BS8 [8:8]
        /// Port x set bit y (y=
        BS8: u1 = 0,
        /// BS9 [9:9]
        /// Port x set bit y (y=
        BS9: u1 = 0,
        /// BS10 [10:10]
        /// Port x set bit y (y=
        BS10: u1 = 0,
        /// BS11 [11:11]
        /// Port x set bit y (y=
        BS11: u1 = 0,
        /// BS12 [12:12]
        /// Port x set bit y (y=
        BS12: u1 = 0,
        /// BS13 [13:13]
        /// Port x set bit y (y=
        BS13: u1 = 0,
        /// BS14 [14:14]
        /// Port x set bit y (y=
        BS14: u1 = 0,
        /// BS15 [15:15]
        /// Port x set bit y (y=
        BS15: u1 = 0,
        /// BR0 [16:16]
        /// Port x set bit y (y=
        BR0: u1 = 0,
        /// BR1 [17:17]
        /// Port x reset bit y (y =
        BR1: u1 = 0,
        /// BR2 [18:18]
        /// Port x reset bit y (y =
        BR2: u1 = 0,
        /// BR3 [19:19]
        /// Port x reset bit y (y =
        BR3: u1 = 0,
        /// BR4 [20:20]
        /// Port x reset bit y (y =
        BR4: u1 = 0,
        /// BR5 [21:21]
        /// Port x reset bit y (y =
        BR5: u1 = 0,
        /// BR6 [22:22]
        /// Port x reset bit y (y =
        BR6: u1 = 0,
        /// BR7 [23:23]
        /// Port x reset bit y (y =
        BR7: u1 = 0,
        /// BR8 [24:24]
        /// Port x reset bit y (y =
        BR8: u1 = 0,
        /// BR9 [25:25]
        /// Port x reset bit y (y =
        BR9: u1 = 0,
        /// BR10 [26:26]
        /// Port x reset bit y (y =
        BR10: u1 = 0,
        /// BR11 [27:27]
        /// Port x reset bit y (y =
        BR11: u1 = 0,
        /// BR12 [28:28]
        /// Port x reset bit y (y =
        BR12: u1 = 0,
        /// BR13 [29:29]
        /// Port x reset bit y (y =
        BR13: u1 = 0,
        /// BR14 [30:30]
        /// Port x reset bit y (y =
        BR14: u1 = 0,
        /// BR15 [31:31]
        /// Port x reset bit y (y =
        BR15: u1 = 0,
    };
    /// GPIO port bit set/reset
    pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

    /// LCKR
    const LCKR_val = packed struct {
        /// LCK0 [0:0]
        /// Port x lock bit y (y=
        LCK0: u1 = 0,
        /// LCK1 [1:1]
        /// Port x lock bit y (y=
        LCK1: u1 = 0,
        /// LCK2 [2:2]
        /// Port x lock bit y (y=
        LCK2: u1 = 0,
        /// LCK3 [3:3]
        /// Port x lock bit y (y=
        LCK3: u1 = 0,
        /// LCK4 [4:4]
        /// Port x lock bit y (y=
        LCK4: u1 = 0,
        /// LCK5 [5:5]
        /// Port x lock bit y (y=
        LCK5: u1 = 0,
        /// LCK6 [6:6]
        /// Port x lock bit y (y=
        LCK6: u1 = 0,
        /// LCK7 [7:7]
        /// Port x lock bit y (y=
        LCK7: u1 = 0,
        /// LCK8 [8:8]
        /// Port x lock bit y (y=
        LCK8: u1 = 0,
        /// LCK9 [9:9]
        /// Port x lock bit y (y=
        LCK9: u1 = 0,
        /// LCK10 [10:10]
        /// Port x lock bit y (y=
        LCK10: u1 = 0,
        /// LCK11 [11:11]
        /// Port x lock bit y (y=
        LCK11: u1 = 0,
        /// LCK12 [12:12]
        /// Port x lock bit y (y=
        LCK12: u1 = 0,
        /// LCK13 [13:13]
        /// Port x lock bit y (y=
        LCK13: u1 = 0,
        /// LCK14 [14:14]
        /// Port x lock bit y (y=
        LCK14: u1 = 0,
        /// LCK15 [15:15]
        /// Port x lock bit y (y=
        LCK15: u1 = 0,
        /// LCKK [16:16]
        /// Port x lock bit y (y=
        LCKK: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port configuration lock
    pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

    /// AFRL
    const AFRL_val = packed struct {
        /// AFRL0 [0:3]
        /// Alternate function selection for port x
        AFRL0: u4 = 0,
        /// AFRL1 [4:7]
        /// Alternate function selection for port x
        AFRL1: u4 = 0,
        /// AFRL2 [8:11]
        /// Alternate function selection for port x
        AFRL2: u4 = 0,
        /// AFRL3 [12:15]
        /// Alternate function selection for port x
        AFRL3: u4 = 0,
        /// AFRL4 [16:19]
        /// Alternate function selection for port x
        AFRL4: u4 = 0,
        /// AFRL5 [20:23]
        /// Alternate function selection for port x
        AFRL5: u4 = 0,
        /// AFRL6 [24:27]
        /// Alternate function selection for port x
        AFRL6: u4 = 0,
        /// AFRL7 [28:31]
        /// Alternate function selection for port x
        AFRL7: u4 = 0,
    };
    /// GPIO alternate function low
    pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

    /// AFRH
    const AFRH_val = packed struct {
        /// AFRH8 [0:3]
        /// Alternate function selection for port x
        AFRH8: u4 = 0,
        /// AFRH9 [4:7]
        /// Alternate function selection for port x
        AFRH9: u4 = 0,
        /// AFRH10 [8:11]
        /// Alternate function selection for port x
        AFRH10: u4 = 0,
        /// AFRH11 [12:15]
        /// Alternate function selection for port x
        AFRH11: u4 = 0,
        /// AFRH12 [16:19]
        /// Alternate function selection for port x
        AFRH12: u4 = 0,
        /// AFRH13 [20:23]
        /// Alternate function selection for port x
        AFRH13: u4 = 0,
        /// AFRH14 [24:27]
        /// Alternate function selection for port x
        AFRH14: u4 = 0,
        /// AFRH15 [28:31]
        /// Alternate function selection for port x
        AFRH15: u4 = 0,
    };
    /// GPIO alternate function high
    pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOA = struct {
    const base_address = 0x40020000;
    /// MODER
    const MODER_val = packed struct {
        /// MODER0 [0:1]
        /// Port x configuration bits (y =
        MODER0: u2 = 0,
        /// MODER1 [2:3]
        /// Port x configuration bits (y =
        MODER1: u2 = 0,
        /// MODER2 [4:5]
        /// Port x configuration bits (y =
        MODER2: u2 = 0,
        /// MODER3 [6:7]
        /// Port x configuration bits (y =
        MODER3: u2 = 0,
        /// MODER4 [8:9]
        /// Port x configuration bits (y =
        MODER4: u2 = 0,
        /// MODER5 [10:11]
        /// Port x configuration bits (y =
        MODER5: u2 = 0,
        /// MODER6 [12:13]
        /// Port x configuration bits (y =
        MODER6: u2 = 0,
        /// MODER7 [14:15]
        /// Port x configuration bits (y =
        MODER7: u2 = 0,
        /// MODER8 [16:17]
        /// Port x configuration bits (y =
        MODER8: u2 = 0,
        /// MODER9 [18:19]
        /// Port x configuration bits (y =
        MODER9: u2 = 0,
        /// MODER10 [20:21]
        /// Port x configuration bits (y =
        MODER10: u2 = 0,
        /// MODER11 [22:23]
        /// Port x configuration bits (y =
        MODER11: u2 = 0,
        /// MODER12 [24:25]
        /// Port x configuration bits (y =
        MODER12: u2 = 0,
        /// MODER13 [26:27]
        /// Port x configuration bits (y =
        MODER13: u2 = 2,
        /// MODER14 [28:29]
        /// Port x configuration bits (y =
        MODER14: u2 = 2,
        /// MODER15 [30:31]
        /// Port x configuration bits (y =
        MODER15: u2 = 2,
    };
    /// GPIO port mode register
    pub const MODER = Register(MODER_val).init(base_address + 0x0);

    /// OTYPER
    const OTYPER_val = packed struct {
        /// OT0 [0:0]
        /// Port x configuration bits (y =
        OT0: u1 = 0,
        /// OT1 [1:1]
        /// Port x configuration bits (y =
        OT1: u1 = 0,
        /// OT2 [2:2]
        /// Port x configuration bits (y =
        OT2: u1 = 0,
        /// OT3 [3:3]
        /// Port x configuration bits (y =
        OT3: u1 = 0,
        /// OT4 [4:4]
        /// Port x configuration bits (y =
        OT4: u1 = 0,
        /// OT5 [5:5]
        /// Port x configuration bits (y =
        OT5: u1 = 0,
        /// OT6 [6:6]
        /// Port x configuration bits (y =
        OT6: u1 = 0,
        /// OT7 [7:7]
        /// Port x configuration bits (y =
        OT7: u1 = 0,
        /// OT8 [8:8]
        /// Port x configuration bits (y =
        OT8: u1 = 0,
        /// OT9 [9:9]
        /// Port x configuration bits (y =
        OT9: u1 = 0,
        /// OT10 [10:10]
        /// Port x configuration bits (y =
        OT10: u1 = 0,
        /// OT11 [11:11]
        /// Port x configuration bits (y =
        OT11: u1 = 0,
        /// OT12 [12:12]
        /// Port x configuration bits (y =
        OT12: u1 = 0,
        /// OT13 [13:13]
        /// Port x configuration bits (y =
        OT13: u1 = 0,
        /// OT14 [14:14]
        /// Port x configuration bits (y =
        OT14: u1 = 0,
        /// OT15 [15:15]
        /// Port x configuration bits (y =
        OT15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output type register
    pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

    /// OSPEEDR
    const OSPEEDR_val = packed struct {
        /// OSPEEDR0 [0:1]
        /// Port x configuration bits (y =
        OSPEEDR0: u2 = 0,
        /// OSPEEDR1 [2:3]
        /// Port x configuration bits (y =
        OSPEEDR1: u2 = 0,
        /// OSPEEDR2 [4:5]
        /// Port x configuration bits (y =
        OSPEEDR2: u2 = 0,
        /// OSPEEDR3 [6:7]
        /// Port x configuration bits (y =
        OSPEEDR3: u2 = 0,
        /// OSPEEDR4 [8:9]
        /// Port x configuration bits (y =
        OSPEEDR4: u2 = 0,
        /// OSPEEDR5 [10:11]
        /// Port x configuration bits (y =
        OSPEEDR5: u2 = 0,
        /// OSPEEDR6 [12:13]
        /// Port x configuration bits (y =
        OSPEEDR6: u2 = 0,
        /// OSPEEDR7 [14:15]
        /// Port x configuration bits (y =
        OSPEEDR7: u2 = 0,
        /// OSPEEDR8 [16:17]
        /// Port x configuration bits (y =
        OSPEEDR8: u2 = 0,
        /// OSPEEDR9 [18:19]
        /// Port x configuration bits (y =
        OSPEEDR9: u2 = 0,
        /// OSPEEDR10 [20:21]
        /// Port x configuration bits (y =
        OSPEEDR10: u2 = 0,
        /// OSPEEDR11 [22:23]
        /// Port x configuration bits (y =
        OSPEEDR11: u2 = 0,
        /// OSPEEDR12 [24:25]
        /// Port x configuration bits (y =
        OSPEEDR12: u2 = 0,
        /// OSPEEDR13 [26:27]
        /// Port x configuration bits (y =
        OSPEEDR13: u2 = 0,
        /// OSPEEDR14 [28:29]
        /// Port x configuration bits (y =
        OSPEEDR14: u2 = 0,
        /// OSPEEDR15 [30:31]
        /// Port x configuration bits (y =
        OSPEEDR15: u2 = 0,
    };
    /// GPIO port output speed
    pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

    /// PUPDR
    const PUPDR_val = packed struct {
        /// PUPDR0 [0:1]
        /// Port x configuration bits (y =
        PUPDR0: u2 = 0,
        /// PUPDR1 [2:3]
        /// Port x configuration bits (y =
        PUPDR1: u2 = 0,
        /// PUPDR2 [4:5]
        /// Port x configuration bits (y =
        PUPDR2: u2 = 0,
        /// PUPDR3 [6:7]
        /// Port x configuration bits (y =
        PUPDR3: u2 = 0,
        /// PUPDR4 [8:9]
        /// Port x configuration bits (y =
        PUPDR4: u2 = 0,
        /// PUPDR5 [10:11]
        /// Port x configuration bits (y =
        PUPDR5: u2 = 0,
        /// PUPDR6 [12:13]
        /// Port x configuration bits (y =
        PUPDR6: u2 = 0,
        /// PUPDR7 [14:15]
        /// Port x configuration bits (y =
        PUPDR7: u2 = 0,
        /// PUPDR8 [16:17]
        /// Port x configuration bits (y =
        PUPDR8: u2 = 0,
        /// PUPDR9 [18:19]
        /// Port x configuration bits (y =
        PUPDR9: u2 = 0,
        /// PUPDR10 [20:21]
        /// Port x configuration bits (y =
        PUPDR10: u2 = 0,
        /// PUPDR11 [22:23]
        /// Port x configuration bits (y =
        PUPDR11: u2 = 0,
        /// PUPDR12 [24:25]
        /// Port x configuration bits (y =
        PUPDR12: u2 = 0,
        /// PUPDR13 [26:27]
        /// Port x configuration bits (y =
        PUPDR13: u2 = 1,
        /// PUPDR14 [28:29]
        /// Port x configuration bits (y =
        PUPDR14: u2 = 2,
        /// PUPDR15 [30:31]
        /// Port x configuration bits (y =
        PUPDR15: u2 = 1,
    };
    /// GPIO port pull-up/pull-down
    pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

    /// IDR
    const IDR_val = packed struct {
        /// IDR0 [0:0]
        /// Port input data (y =
        IDR0: u1 = 0,
        /// IDR1 [1:1]
        /// Port input data (y =
        IDR1: u1 = 0,
        /// IDR2 [2:2]
        /// Port input data (y =
        IDR2: u1 = 0,
        /// IDR3 [3:3]
        /// Port input data (y =
        IDR3: u1 = 0,
        /// IDR4 [4:4]
        /// Port input data (y =
        IDR4: u1 = 0,
        /// IDR5 [5:5]
        /// Port input data (y =
        IDR5: u1 = 0,
        /// IDR6 [6:6]
        /// Port input data (y =
        IDR6: u1 = 0,
        /// IDR7 [7:7]
        /// Port input data (y =
        IDR7: u1 = 0,
        /// IDR8 [8:8]
        /// Port input data (y =
        IDR8: u1 = 0,
        /// IDR9 [9:9]
        /// Port input data (y =
        IDR9: u1 = 0,
        /// IDR10 [10:10]
        /// Port input data (y =
        IDR10: u1 = 0,
        /// IDR11 [11:11]
        /// Port input data (y =
        IDR11: u1 = 0,
        /// IDR12 [12:12]
        /// Port input data (y =
        IDR12: u1 = 0,
        /// IDR13 [13:13]
        /// Port input data (y =
        IDR13: u1 = 0,
        /// IDR14 [14:14]
        /// Port input data (y =
        IDR14: u1 = 0,
        /// IDR15 [15:15]
        /// Port input data (y =
        IDR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port input data register
    pub const IDR = Register(IDR_val).init(base_address + 0x10);

    /// ODR
    const ODR_val = packed struct {
        /// ODR0 [0:0]
        /// Port output data (y =
        ODR0: u1 = 0,
        /// ODR1 [1:1]
        /// Port output data (y =
        ODR1: u1 = 0,
        /// ODR2 [2:2]
        /// Port output data (y =
        ODR2: u1 = 0,
        /// ODR3 [3:3]
        /// Port output data (y =
        ODR3: u1 = 0,
        /// ODR4 [4:4]
        /// Port output data (y =
        ODR4: u1 = 0,
        /// ODR5 [5:5]
        /// Port output data (y =
        ODR5: u1 = 0,
        /// ODR6 [6:6]
        /// Port output data (y =
        ODR6: u1 = 0,
        /// ODR7 [7:7]
        /// Port output data (y =
        ODR7: u1 = 0,
        /// ODR8 [8:8]
        /// Port output data (y =
        ODR8: u1 = 0,
        /// ODR9 [9:9]
        /// Port output data (y =
        ODR9: u1 = 0,
        /// ODR10 [10:10]
        /// Port output data (y =
        ODR10: u1 = 0,
        /// ODR11 [11:11]
        /// Port output data (y =
        ODR11: u1 = 0,
        /// ODR12 [12:12]
        /// Port output data (y =
        ODR12: u1 = 0,
        /// ODR13 [13:13]
        /// Port output data (y =
        ODR13: u1 = 0,
        /// ODR14 [14:14]
        /// Port output data (y =
        ODR14: u1 = 0,
        /// ODR15 [15:15]
        /// Port output data (y =
        ODR15: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port output data register
    pub const ODR = Register(ODR_val).init(base_address + 0x14);

    /// BSRR
    const BSRR_val = packed struct {
        /// BS0 [0:0]
        /// Port x set bit y (y=
        BS0: u1 = 0,
        /// BS1 [1:1]
        /// Port x set bit y (y=
        BS1: u1 = 0,
        /// BS2 [2:2]
        /// Port x set bit y (y=
        BS2: u1 = 0,
        /// BS3 [3:3]
        /// Port x set bit y (y=
        BS3: u1 = 0,
        /// BS4 [4:4]
        /// Port x set bit y (y=
        BS4: u1 = 0,
        /// BS5 [5:5]
        /// Port x set bit y (y=
        BS5: u1 = 0,
        /// BS6 [6:6]
        /// Port x set bit y (y=
        BS6: u1 = 0,
        /// BS7 [7:7]
        /// Port x set bit y (y=
        BS7: u1 = 0,
        /// BS8 [8:8]
        /// Port x set bit y (y=
        BS8: u1 = 0,
        /// BS9 [9:9]
        /// Port x set bit y (y=
        BS9: u1 = 0,
        /// BS10 [10:10]
        /// Port x set bit y (y=
        BS10: u1 = 0,
        /// BS11 [11:11]
        /// Port x set bit y (y=
        BS11: u1 = 0,
        /// BS12 [12:12]
        /// Port x set bit y (y=
        BS12: u1 = 0,
        /// BS13 [13:13]
        /// Port x set bit y (y=
        BS13: u1 = 0,
        /// BS14 [14:14]
        /// Port x set bit y (y=
        BS14: u1 = 0,
        /// BS15 [15:15]
        /// Port x set bit y (y=
        BS15: u1 = 0,
        /// BR0 [16:16]
        /// Port x set bit y (y=
        BR0: u1 = 0,
        /// BR1 [17:17]
        /// Port x reset bit y (y =
        BR1: u1 = 0,
        /// BR2 [18:18]
        /// Port x reset bit y (y =
        BR2: u1 = 0,
        /// BR3 [19:19]
        /// Port x reset bit y (y =
        BR3: u1 = 0,
        /// BR4 [20:20]
        /// Port x reset bit y (y =
        BR4: u1 = 0,
        /// BR5 [21:21]
        /// Port x reset bit y (y =
        BR5: u1 = 0,
        /// BR6 [22:22]
        /// Port x reset bit y (y =
        BR6: u1 = 0,
        /// BR7 [23:23]
        /// Port x reset bit y (y =
        BR7: u1 = 0,
        /// BR8 [24:24]
        /// Port x reset bit y (y =
        BR8: u1 = 0,
        /// BR9 [25:25]
        /// Port x reset bit y (y =
        BR9: u1 = 0,
        /// BR10 [26:26]
        /// Port x reset bit y (y =
        BR10: u1 = 0,
        /// BR11 [27:27]
        /// Port x reset bit y (y =
        BR11: u1 = 0,
        /// BR12 [28:28]
        /// Port x reset bit y (y =
        BR12: u1 = 0,
        /// BR13 [29:29]
        /// Port x reset bit y (y =
        BR13: u1 = 0,
        /// BR14 [30:30]
        /// Port x reset bit y (y =
        BR14: u1 = 0,
        /// BR15 [31:31]
        /// Port x reset bit y (y =
        BR15: u1 = 0,
    };
    /// GPIO port bit set/reset
    pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

    /// LCKR
    const LCKR_val = packed struct {
        /// LCK0 [0:0]
        /// Port x lock bit y (y=
        LCK0: u1 = 0,
        /// LCK1 [1:1]
        /// Port x lock bit y (y=
        LCK1: u1 = 0,
        /// LCK2 [2:2]
        /// Port x lock bit y (y=
        LCK2: u1 = 0,
        /// LCK3 [3:3]
        /// Port x lock bit y (y=
        LCK3: u1 = 0,
        /// LCK4 [4:4]
        /// Port x lock bit y (y=
        LCK4: u1 = 0,
        /// LCK5 [5:5]
        /// Port x lock bit y (y=
        LCK5: u1 = 0,
        /// LCK6 [6:6]
        /// Port x lock bit y (y=
        LCK6: u1 = 0,
        /// LCK7 [7:7]
        /// Port x lock bit y (y=
        LCK7: u1 = 0,
        /// LCK8 [8:8]
        /// Port x lock bit y (y=
        LCK8: u1 = 0,
        /// LCK9 [9:9]
        /// Port x lock bit y (y=
        LCK9: u1 = 0,
        /// LCK10 [10:10]
        /// Port x lock bit y (y=
        LCK10: u1 = 0,
        /// LCK11 [11:11]
        /// Port x lock bit y (y=
        LCK11: u1 = 0,
        /// LCK12 [12:12]
        /// Port x lock bit y (y=
        LCK12: u1 = 0,
        /// LCK13 [13:13]
        /// Port x lock bit y (y=
        LCK13: u1 = 0,
        /// LCK14 [14:14]
        /// Port x lock bit y (y=
        LCK14: u1 = 0,
        /// LCK15 [15:15]
        /// Port x lock bit y (y=
        LCK15: u1 = 0,
        /// LCKK [16:16]
        /// Port x lock bit y (y=
        LCKK: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// GPIO port configuration lock
    pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

    /// AFRL
    const AFRL_val = packed struct {
        /// AFRL0 [0:3]
        /// Alternate function selection for port x
        AFRL0: u4 = 0,
        /// AFRL1 [4:7]
        /// Alternate function selection for port x
        AFRL1: u4 = 0,
        /// AFRL2 [8:11]
        /// Alternate function selection for port x
        AFRL2: u4 = 0,
        /// AFRL3 [12:15]
        /// Alternate function selection for port x
        AFRL3: u4 = 0,
        /// AFRL4 [16:19]
        /// Alternate function selection for port x
        AFRL4: u4 = 0,
        /// AFRL5 [20:23]
        /// Alternate function selection for port x
        AFRL5: u4 = 0,
        /// AFRL6 [24:27]
        /// Alternate function selection for port x
        AFRL6: u4 = 0,
        /// AFRL7 [28:31]
        /// Alternate function selection for port x
        AFRL7: u4 = 0,
    };
    /// GPIO alternate function low
    pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

    /// AFRH
    const AFRH_val = packed struct {
        /// AFRH8 [0:3]
        /// Alternate function selection for port x
        AFRH8: u4 = 0,
        /// AFRH9 [4:7]
        /// Alternate function selection for port x
        AFRH9: u4 = 0,
        /// AFRH10 [8:11]
        /// Alternate function selection for port x
        AFRH10: u4 = 0,
        /// AFRH11 [12:15]
        /// Alternate function selection for port x
        AFRH11: u4 = 0,
        /// AFRH12 [16:19]
        /// Alternate function selection for port x
        AFRH12: u4 = 0,
        /// AFRH13 [20:23]
        /// Alternate function selection for port x
        AFRH13: u4 = 0,
        /// AFRH14 [24:27]
        /// Alternate function selection for port x
        AFRH14: u4 = 0,
        /// AFRH15 [28:31]
        /// Alternate function selection for port x
        AFRH15: u4 = 0,
    };
    /// GPIO alternate function high
    pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// Inter-integrated circuit
pub const I2C3 = struct {
    const base_address = 0x40005c00;
    /// CR1
    const CR1_val = packed struct {
        /// PE [0:0]
        /// Peripheral enable
        PE: u1 = 0,
        /// SMBUS [1:1]
        /// SMBus mode
        SMBUS: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// SMBTYPE [3:3]
        /// SMBus type
        SMBTYPE: u1 = 0,
        /// ENARP [4:4]
        /// ARP enable
        ENARP: u1 = 0,
        /// ENPEC [5:5]
        /// PEC enable
        ENPEC: u1 = 0,
        /// ENGC [6:6]
        /// General call enable
        ENGC: u1 = 0,
        /// NOSTRETCH [7:7]
        /// Clock stretching disable (Slave
        NOSTRETCH: u1 = 0,
        /// START [8:8]
        /// Start generation
        START: u1 = 0,
        /// STOP [9:9]
        /// Stop generation
        STOP: u1 = 0,
        /// ACK [10:10]
        /// Acknowledge enable
        ACK: u1 = 0,
        /// POS [11:11]
        /// Acknowledge/PEC Position (for data
        POS: u1 = 0,
        /// PEC [12:12]
        /// Packet error checking
        PEC: u1 = 0,
        /// ALERT [13:13]
        /// SMBus alert
        ALERT: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// SWRST [15:15]
        /// Software reset
        SWRST: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// FREQ [0:5]
        /// Peripheral clock frequency
        FREQ: u6 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// ITERREN [8:8]
        /// Error interrupt enable
        ITERREN: u1 = 0,
        /// ITEVTEN [9:9]
        /// Event interrupt enable
        ITEVTEN: u1 = 0,
        /// ITBUFEN [10:10]
        /// Buffer interrupt enable
        ITBUFEN: u1 = 0,
        /// DMAEN [11:11]
        /// DMA requests enable
        DMAEN: u1 = 0,
        /// LAST [12:12]
        /// DMA last transfer
        LAST: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// OAR1
    const OAR1_val = packed struct {
        /// ADD0 [0:0]
        /// Interface address
        ADD0: u1 = 0,
        /// ADD7 [1:7]
        /// Interface address
        ADD7: u7 = 0,
        /// ADD10 [8:9]
        /// Interface address
        ADD10: u2 = 0,
        /// unused [10:14]
        _unused10: u5 = 0,
        /// ADDMODE [15:15]
        /// Addressing mode (slave
        ADDMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Own address register 1
    pub const OAR1 = Register(OAR1_val).init(base_address + 0x8);

    /// OAR2
    const OAR2_val = packed struct {
        /// ENDUAL [0:0]
        /// Dual addressing mode
        ENDUAL: u1 = 0,
        /// ADD2 [1:7]
        /// Interface address
        ADD2: u7 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Own address register 2
    pub const OAR2 = Register(OAR2_val).init(base_address + 0xc);

    /// DR
    const DR_val = packed struct {
        /// DR [0:7]
        /// 8-bit data register
        DR: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x10);

    /// SR1
    const SR1_val = packed struct {
        /// SB [0:0]
        /// Start bit (Master mode)
        SB: u1 = 0,
        /// ADDR [1:1]
        /// Address sent (master mode)/matched
        ADDR: u1 = 0,
        /// BTF [2:2]
        /// Byte transfer finished
        BTF: u1 = 0,
        /// ADD10 [3:3]
        /// 10-bit header sent (Master
        ADD10: u1 = 0,
        /// STOPF [4:4]
        /// Stop detection (slave
        STOPF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// RxNE [6:6]
        /// Data register not empty
        RxNE: u1 = 0,
        /// TxE [7:7]
        /// Data register empty
        TxE: u1 = 0,
        /// BERR [8:8]
        /// Bus error
        BERR: u1 = 0,
        /// ARLO [9:9]
        /// Arbitration lost (master
        ARLO: u1 = 0,
        /// AF [10:10]
        /// Acknowledge failure
        AF: u1 = 0,
        /// OVR [11:11]
        /// Overrun/Underrun
        OVR: u1 = 0,
        /// PECERR [12:12]
        /// PEC Error in reception
        PECERR: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TIMEOUT [14:14]
        /// Timeout or Tlow error
        TIMEOUT: u1 = 0,
        /// SMBALERT [15:15]
        /// SMBus alert
        SMBALERT: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register 1
    pub const SR1 = Register(SR1_val).init(base_address + 0x14);

    /// SR2
    const SR2_val = packed struct {
        /// MSL [0:0]
        /// Master/slave
        MSL: u1 = 0,
        /// BUSY [1:1]
        /// Bus busy
        BUSY: u1 = 0,
        /// TRA [2:2]
        /// Transmitter/receiver
        TRA: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// GENCALL [4:4]
        /// General call address (Slave
        GENCALL: u1 = 0,
        /// SMBDEFAULT [5:5]
        /// SMBus device default address (Slave
        SMBDEFAULT: u1 = 0,
        /// SMBHOST [6:6]
        /// SMBus host header (Slave
        SMBHOST: u1 = 0,
        /// DUALF [7:7]
        /// Dual flag (Slave mode)
        DUALF: u1 = 0,
        /// PEC [8:15]
        /// acket error checking
        PEC: u8 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register 2
    pub const SR2 = Register(SR2_val).init(base_address + 0x18);

    /// CCR
    const CCR_val = packed struct {
        /// CCR [0:11]
        /// Clock control register in Fast/Standard
        CCR: u12 = 0,
        /// unused [12:13]
        _unused12: u2 = 0,
        /// DUTY [14:14]
        /// Fast mode duty cycle
        DUTY: u1 = 0,
        /// F_S [15:15]
        /// I2C master mode selection
        F_S: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Clock control register
    pub const CCR = Register(CCR_val).init(base_address + 0x1c);

    /// TRISE
    const TRISE_val = packed struct {
        /// TRISE [0:5]
        /// Maximum rise time in Fast/Standard mode
        TRISE: u6 = 2,
        /// unused [6:31]
        _unused6: u2 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TRISE register
    pub const TRISE = Register(TRISE_val).init(base_address + 0x20);
};

/// Inter-integrated circuit
pub const I2C2 = struct {
    const base_address = 0x40005800;
    /// CR1
    const CR1_val = packed struct {
        /// PE [0:0]
        /// Peripheral enable
        PE: u1 = 0,
        /// SMBUS [1:1]
        /// SMBus mode
        SMBUS: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// SMBTYPE [3:3]
        /// SMBus type
        SMBTYPE: u1 = 0,
        /// ENARP [4:4]
        /// ARP enable
        ENARP: u1 = 0,
        /// ENPEC [5:5]
        /// PEC enable
        ENPEC: u1 = 0,
        /// ENGC [6:6]
        /// General call enable
        ENGC: u1 = 0,
        /// NOSTRETCH [7:7]
        /// Clock stretching disable (Slave
        NOSTRETCH: u1 = 0,
        /// START [8:8]
        /// Start generation
        START: u1 = 0,
        /// STOP [9:9]
        /// Stop generation
        STOP: u1 = 0,
        /// ACK [10:10]
        /// Acknowledge enable
        ACK: u1 = 0,
        /// POS [11:11]
        /// Acknowledge/PEC Position (for data
        POS: u1 = 0,
        /// PEC [12:12]
        /// Packet error checking
        PEC: u1 = 0,
        /// ALERT [13:13]
        /// SMBus alert
        ALERT: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// SWRST [15:15]
        /// Software reset
        SWRST: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// FREQ [0:5]
        /// Peripheral clock frequency
        FREQ: u6 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// ITERREN [8:8]
        /// Error interrupt enable
        ITERREN: u1 = 0,
        /// ITEVTEN [9:9]
        /// Event interrupt enable
        ITEVTEN: u1 = 0,
        /// ITBUFEN [10:10]
        /// Buffer interrupt enable
        ITBUFEN: u1 = 0,
        /// DMAEN [11:11]
        /// DMA requests enable
        DMAEN: u1 = 0,
        /// LAST [12:12]
        /// DMA last transfer
        LAST: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// OAR1
    const OAR1_val = packed struct {
        /// ADD0 [0:0]
        /// Interface address
        ADD0: u1 = 0,
        /// ADD7 [1:7]
        /// Interface address
        ADD7: u7 = 0,
        /// ADD10 [8:9]
        /// Interface address
        ADD10: u2 = 0,
        /// unused [10:14]
        _unused10: u5 = 0,
        /// ADDMODE [15:15]
        /// Addressing mode (slave
        ADDMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Own address register 1
    pub const OAR1 = Register(OAR1_val).init(base_address + 0x8);

    /// OAR2
    const OAR2_val = packed struct {
        /// ENDUAL [0:0]
        /// Dual addressing mode
        ENDUAL: u1 = 0,
        /// ADD2 [1:7]
        /// Interface address
        ADD2: u7 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Own address register 2
    pub const OAR2 = Register(OAR2_val).init(base_address + 0xc);

    /// DR
    const DR_val = packed struct {
        /// DR [0:7]
        /// 8-bit data register
        DR: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x10);

    /// SR1
    const SR1_val = packed struct {
        /// SB [0:0]
        /// Start bit (Master mode)
        SB: u1 = 0,
        /// ADDR [1:1]
        /// Address sent (master mode)/matched
        ADDR: u1 = 0,
        /// BTF [2:2]
        /// Byte transfer finished
        BTF: u1 = 0,
        /// ADD10 [3:3]
        /// 10-bit header sent (Master
        ADD10: u1 = 0,
        /// STOPF [4:4]
        /// Stop detection (slave
        STOPF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// RxNE [6:6]
        /// Data register not empty
        RxNE: u1 = 0,
        /// TxE [7:7]
        /// Data register empty
        TxE: u1 = 0,
        /// BERR [8:8]
        /// Bus error
        BERR: u1 = 0,
        /// ARLO [9:9]
        /// Arbitration lost (master
        ARLO: u1 = 0,
        /// AF [10:10]
        /// Acknowledge failure
        AF: u1 = 0,
        /// OVR [11:11]
        /// Overrun/Underrun
        OVR: u1 = 0,
        /// PECERR [12:12]
        /// PEC Error in reception
        PECERR: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TIMEOUT [14:14]
        /// Timeout or Tlow error
        TIMEOUT: u1 = 0,
        /// SMBALERT [15:15]
        /// SMBus alert
        SMBALERT: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register 1
    pub const SR1 = Register(SR1_val).init(base_address + 0x14);

    /// SR2
    const SR2_val = packed struct {
        /// MSL [0:0]
        /// Master/slave
        MSL: u1 = 0,
        /// BUSY [1:1]
        /// Bus busy
        BUSY: u1 = 0,
        /// TRA [2:2]
        /// Transmitter/receiver
        TRA: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// GENCALL [4:4]
        /// General call address (Slave
        GENCALL: u1 = 0,
        /// SMBDEFAULT [5:5]
        /// SMBus device default address (Slave
        SMBDEFAULT: u1 = 0,
        /// SMBHOST [6:6]
        /// SMBus host header (Slave
        SMBHOST: u1 = 0,
        /// DUALF [7:7]
        /// Dual flag (Slave mode)
        DUALF: u1 = 0,
        /// PEC [8:15]
        /// acket error checking
        PEC: u8 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register 2
    pub const SR2 = Register(SR2_val).init(base_address + 0x18);

    /// CCR
    const CCR_val = packed struct {
        /// CCR [0:11]
        /// Clock control register in Fast/Standard
        CCR: u12 = 0,
        /// unused [12:13]
        _unused12: u2 = 0,
        /// DUTY [14:14]
        /// Fast mode duty cycle
        DUTY: u1 = 0,
        /// F_S [15:15]
        /// I2C master mode selection
        F_S: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Clock control register
    pub const CCR = Register(CCR_val).init(base_address + 0x1c);

    /// TRISE
    const TRISE_val = packed struct {
        /// TRISE [0:5]
        /// Maximum rise time in Fast/Standard mode
        TRISE: u6 = 2,
        /// unused [6:31]
        _unused6: u2 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TRISE register
    pub const TRISE = Register(TRISE_val).init(base_address + 0x20);
};

/// Inter-integrated circuit
pub const I2C1 = struct {
    const base_address = 0x40005400;
    /// CR1
    const CR1_val = packed struct {
        /// PE [0:0]
        /// Peripheral enable
        PE: u1 = 0,
        /// SMBUS [1:1]
        /// SMBus mode
        SMBUS: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// SMBTYPE [3:3]
        /// SMBus type
        SMBTYPE: u1 = 0,
        /// ENARP [4:4]
        /// ARP enable
        ENARP: u1 = 0,
        /// ENPEC [5:5]
        /// PEC enable
        ENPEC: u1 = 0,
        /// ENGC [6:6]
        /// General call enable
        ENGC: u1 = 0,
        /// NOSTRETCH [7:7]
        /// Clock stretching disable (Slave
        NOSTRETCH: u1 = 0,
        /// START [8:8]
        /// Start generation
        START: u1 = 0,
        /// STOP [9:9]
        /// Stop generation
        STOP: u1 = 0,
        /// ACK [10:10]
        /// Acknowledge enable
        ACK: u1 = 0,
        /// POS [11:11]
        /// Acknowledge/PEC Position (for data
        POS: u1 = 0,
        /// PEC [12:12]
        /// Packet error checking
        PEC: u1 = 0,
        /// ALERT [13:13]
        /// SMBus alert
        ALERT: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// SWRST [15:15]
        /// Software reset
        SWRST: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// FREQ [0:5]
        /// Peripheral clock frequency
        FREQ: u6 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// ITERREN [8:8]
        /// Error interrupt enable
        ITERREN: u1 = 0,
        /// ITEVTEN [9:9]
        /// Event interrupt enable
        ITEVTEN: u1 = 0,
        /// ITBUFEN [10:10]
        /// Buffer interrupt enable
        ITBUFEN: u1 = 0,
        /// DMAEN [11:11]
        /// DMA requests enable
        DMAEN: u1 = 0,
        /// LAST [12:12]
        /// DMA last transfer
        LAST: u1 = 0,
        /// unused [13:31]
        _unused13: u3 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// OAR1
    const OAR1_val = packed struct {
        /// ADD0 [0:0]
        /// Interface address
        ADD0: u1 = 0,
        /// ADD7 [1:7]
        /// Interface address
        ADD7: u7 = 0,
        /// ADD10 [8:9]
        /// Interface address
        ADD10: u2 = 0,
        /// unused [10:14]
        _unused10: u5 = 0,
        /// ADDMODE [15:15]
        /// Addressing mode (slave
        ADDMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Own address register 1
    pub const OAR1 = Register(OAR1_val).init(base_address + 0x8);

    /// OAR2
    const OAR2_val = packed struct {
        /// ENDUAL [0:0]
        /// Dual addressing mode
        ENDUAL: u1 = 0,
        /// ADD2 [1:7]
        /// Interface address
        ADD2: u7 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Own address register 2
    pub const OAR2 = Register(OAR2_val).init(base_address + 0xc);

    /// DR
    const DR_val = packed struct {
        /// DR [0:7]
        /// 8-bit data register
        DR: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Data register
    pub const DR = Register(DR_val).init(base_address + 0x10);

    /// SR1
    const SR1_val = packed struct {
        /// SB [0:0]
        /// Start bit (Master mode)
        SB: u1 = 0,
        /// ADDR [1:1]
        /// Address sent (master mode)/matched
        ADDR: u1 = 0,
        /// BTF [2:2]
        /// Byte transfer finished
        BTF: u1 = 0,
        /// ADD10 [3:3]
        /// 10-bit header sent (Master
        ADD10: u1 = 0,
        /// STOPF [4:4]
        /// Stop detection (slave
        STOPF: u1 = 0,
        /// unused [5:5]
        _unused5: u1 = 0,
        /// RxNE [6:6]
        /// Data register not empty
        RxNE: u1 = 0,
        /// TxE [7:7]
        /// Data register empty
        TxE: u1 = 0,
        /// BERR [8:8]
        /// Bus error
        BERR: u1 = 0,
        /// ARLO [9:9]
        /// Arbitration lost (master
        ARLO: u1 = 0,
        /// AF [10:10]
        /// Acknowledge failure
        AF: u1 = 0,
        /// OVR [11:11]
        /// Overrun/Underrun
        OVR: u1 = 0,
        /// PECERR [12:12]
        /// PEC Error in reception
        PECERR: u1 = 0,
        /// unused [13:13]
        _unused13: u1 = 0,
        /// TIMEOUT [14:14]
        /// Timeout or Tlow error
        TIMEOUT: u1 = 0,
        /// SMBALERT [15:15]
        /// SMBus alert
        SMBALERT: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register 1
    pub const SR1 = Register(SR1_val).init(base_address + 0x14);

    /// SR2
    const SR2_val = packed struct {
        /// MSL [0:0]
        /// Master/slave
        MSL: u1 = 0,
        /// BUSY [1:1]
        /// Bus busy
        BUSY: u1 = 0,
        /// TRA [2:2]
        /// Transmitter/receiver
        TRA: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// GENCALL [4:4]
        /// General call address (Slave
        GENCALL: u1 = 0,
        /// SMBDEFAULT [5:5]
        /// SMBus device default address (Slave
        SMBDEFAULT: u1 = 0,
        /// SMBHOST [6:6]
        /// SMBus host header (Slave
        SMBHOST: u1 = 0,
        /// DUALF [7:7]
        /// Dual flag (Slave mode)
        DUALF: u1 = 0,
        /// PEC [8:15]
        /// acket error checking
        PEC: u8 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Status register 2
    pub const SR2 = Register(SR2_val).init(base_address + 0x18);

    /// CCR
    const CCR_val = packed struct {
        /// CCR [0:11]
        /// Clock control register in Fast/Standard
        CCR: u12 = 0,
        /// unused [12:13]
        _unused12: u2 = 0,
        /// DUTY [14:14]
        /// Fast mode duty cycle
        DUTY: u1 = 0,
        /// F_S [15:15]
        /// I2C master mode selection
        F_S: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Clock control register
    pub const CCR = Register(CCR_val).init(base_address + 0x1c);

    /// TRISE
    const TRISE_val = packed struct {
        /// TRISE [0:5]
        /// Maximum rise time in Fast/Standard mode
        TRISE: u6 = 2,
        /// unused [6:31]
        _unused6: u2 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TRISE register
    pub const TRISE = Register(TRISE_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const I2S2ext = struct {
    const base_address = 0x40003400;
    /// CR1
    const CR1_val = packed struct {
        /// CPHA [0:0]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [1:1]
        /// Clock polarity
        CPOL: u1 = 0,
        /// MSTR [2:2]
        /// Master selection
        MSTR: u1 = 0,
        /// BR [3:5]
        /// Baud rate control
        BR: u3 = 0,
        /// SPE [6:6]
        /// SPI enable
        SPE: u1 = 0,
        /// LSBFIRST [7:7]
        /// Frame format
        LSBFIRST: u1 = 0,
        /// SSI [8:8]
        /// Internal slave select
        SSI: u1 = 0,
        /// SSM [9:9]
        /// Software slave management
        SSM: u1 = 0,
        /// RXONLY [10:10]
        /// Receive only
        RXONLY: u1 = 0,
        /// DFF [11:11]
        /// Data frame format
        DFF: u1 = 0,
        /// CRCNEXT [12:12]
        /// CRC transfer next
        CRCNEXT: u1 = 0,
        /// CRCEN [13:13]
        /// Hardware CRC calculation
        CRCEN: u1 = 0,
        /// BIDIOE [14:14]
        /// Output enable in bidirectional
        BIDIOE: u1 = 0,
        /// BIDIMODE [15:15]
        /// Bidirectional data mode
        BIDIMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// RXDMAEN [0:0]
        /// Rx buffer DMA enable
        RXDMAEN: u1 = 0,
        /// TXDMAEN [1:1]
        /// Tx buffer DMA enable
        TXDMAEN: u1 = 0,
        /// SSOE [2:2]
        /// SS output enable
        SSOE: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// FRF [4:4]
        /// Frame format
        FRF: u1 = 0,
        /// ERRIE [5:5]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// RXNEIE [6:6]
        /// RX buffer not empty interrupt
        RXNEIE: u1 = 0,
        /// TXEIE [7:7]
        /// Tx buffer empty interrupt
        TXEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// RXNE [0:0]
        /// Receive buffer not empty
        RXNE: u1 = 0,
        /// TXE [1:1]
        /// Transmit buffer empty
        TXE: u1 = 1,
        /// CHSIDE [2:2]
        /// Channel side
        CHSIDE: u1 = 0,
        /// UDR [3:3]
        /// Underrun flag
        UDR: u1 = 0,
        /// CRCERR [4:4]
        /// CRC error flag
        CRCERR: u1 = 0,
        /// MODF [5:5]
        /// Mode fault
        MODF: u1 = 0,
        /// OVR [6:6]
        /// Overrun flag
        OVR: u1 = 0,
        /// BSY [7:7]
        /// Busy flag
        BSY: u1 = 0,
        /// TIFRFE [8:8]
        /// TI frame format error
        TIFRFE: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x8);

    /// DR
    const DR_val = packed struct {
        /// DR [0:15]
        /// Data register
        DR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data register
    pub const DR = Register(DR_val).init(base_address + 0xc);

    /// CRCPR
    const CRCPR_val = packed struct {
        /// CRCPOLY [0:15]
        /// CRC polynomial register
        CRCPOLY: u16 = 7,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// CRC polynomial register
    pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

    /// RXCRCR
    const RXCRCR_val = packed struct {
        /// RxCRC [0:15]
        /// Rx CRC register
        RxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// RX CRC register
    pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

    /// TXCRCR
    const TXCRCR_val = packed struct {
        /// TxCRC [0:15]
        /// Tx CRC register
        TxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TX CRC register
    pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

    /// I2SCFGR
    const I2SCFGR_val = packed struct {
        /// CHLEN [0:0]
        /// Channel length (number of bits per audio
        CHLEN: u1 = 0,
        /// DATLEN [1:2]
        /// Data length to be
        DATLEN: u2 = 0,
        /// CKPOL [3:3]
        /// Steady state clock
        CKPOL: u1 = 0,
        /// I2SSTD [4:5]
        /// I2S standard selection
        I2SSTD: u2 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// PCMSYNC [7:7]
        /// PCM frame synchronization
        PCMSYNC: u1 = 0,
        /// I2SCFG [8:9]
        /// I2S configuration mode
        I2SCFG: u2 = 0,
        /// I2SE [10:10]
        /// I2S Enable
        I2SE: u1 = 0,
        /// I2SMOD [11:11]
        /// I2S mode selection
        I2SMOD: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S configuration register
    pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

    /// I2SPR
    const I2SPR_val = packed struct {
        /// I2SDIV [0:7]
        /// I2S Linear prescaler
        I2SDIV: u8 = 16,
        /// ODD [8:8]
        /// Odd factor for the
        ODD: u1 = 0,
        /// MCKOE [9:9]
        /// Master clock output enable
        MCKOE: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S prescaler register
    pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const I2S3ext = struct {
    const base_address = 0x40004000;
    /// CR1
    const CR1_val = packed struct {
        /// CPHA [0:0]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [1:1]
        /// Clock polarity
        CPOL: u1 = 0,
        /// MSTR [2:2]
        /// Master selection
        MSTR: u1 = 0,
        /// BR [3:5]
        /// Baud rate control
        BR: u3 = 0,
        /// SPE [6:6]
        /// SPI enable
        SPE: u1 = 0,
        /// LSBFIRST [7:7]
        /// Frame format
        LSBFIRST: u1 = 0,
        /// SSI [8:8]
        /// Internal slave select
        SSI: u1 = 0,
        /// SSM [9:9]
        /// Software slave management
        SSM: u1 = 0,
        /// RXONLY [10:10]
        /// Receive only
        RXONLY: u1 = 0,
        /// DFF [11:11]
        /// Data frame format
        DFF: u1 = 0,
        /// CRCNEXT [12:12]
        /// CRC transfer next
        CRCNEXT: u1 = 0,
        /// CRCEN [13:13]
        /// Hardware CRC calculation
        CRCEN: u1 = 0,
        /// BIDIOE [14:14]
        /// Output enable in bidirectional
        BIDIOE: u1 = 0,
        /// BIDIMODE [15:15]
        /// Bidirectional data mode
        BIDIMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// RXDMAEN [0:0]
        /// Rx buffer DMA enable
        RXDMAEN: u1 = 0,
        /// TXDMAEN [1:1]
        /// Tx buffer DMA enable
        TXDMAEN: u1 = 0,
        /// SSOE [2:2]
        /// SS output enable
        SSOE: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// FRF [4:4]
        /// Frame format
        FRF: u1 = 0,
        /// ERRIE [5:5]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// RXNEIE [6:6]
        /// RX buffer not empty interrupt
        RXNEIE: u1 = 0,
        /// TXEIE [7:7]
        /// Tx buffer empty interrupt
        TXEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// RXNE [0:0]
        /// Receive buffer not empty
        RXNE: u1 = 0,
        /// TXE [1:1]
        /// Transmit buffer empty
        TXE: u1 = 1,
        /// CHSIDE [2:2]
        /// Channel side
        CHSIDE: u1 = 0,
        /// UDR [3:3]
        /// Underrun flag
        UDR: u1 = 0,
        /// CRCERR [4:4]
        /// CRC error flag
        CRCERR: u1 = 0,
        /// MODF [5:5]
        /// Mode fault
        MODF: u1 = 0,
        /// OVR [6:6]
        /// Overrun flag
        OVR: u1 = 0,
        /// BSY [7:7]
        /// Busy flag
        BSY: u1 = 0,
        /// TIFRFE [8:8]
        /// TI frame format error
        TIFRFE: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x8);

    /// DR
    const DR_val = packed struct {
        /// DR [0:15]
        /// Data register
        DR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data register
    pub const DR = Register(DR_val).init(base_address + 0xc);

    /// CRCPR
    const CRCPR_val = packed struct {
        /// CRCPOLY [0:15]
        /// CRC polynomial register
        CRCPOLY: u16 = 7,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// CRC polynomial register
    pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

    /// RXCRCR
    const RXCRCR_val = packed struct {
        /// RxCRC [0:15]
        /// Rx CRC register
        RxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// RX CRC register
    pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

    /// TXCRCR
    const TXCRCR_val = packed struct {
        /// TxCRC [0:15]
        /// Tx CRC register
        TxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TX CRC register
    pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

    /// I2SCFGR
    const I2SCFGR_val = packed struct {
        /// CHLEN [0:0]
        /// Channel length (number of bits per audio
        CHLEN: u1 = 0,
        /// DATLEN [1:2]
        /// Data length to be
        DATLEN: u2 = 0,
        /// CKPOL [3:3]
        /// Steady state clock
        CKPOL: u1 = 0,
        /// I2SSTD [4:5]
        /// I2S standard selection
        I2SSTD: u2 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// PCMSYNC [7:7]
        /// PCM frame synchronization
        PCMSYNC: u1 = 0,
        /// I2SCFG [8:9]
        /// I2S configuration mode
        I2SCFG: u2 = 0,
        /// I2SE [10:10]
        /// I2S Enable
        I2SE: u1 = 0,
        /// I2SMOD [11:11]
        /// I2S mode selection
        I2SMOD: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S configuration register
    pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

    /// I2SPR
    const I2SPR_val = packed struct {
        /// I2SDIV [0:7]
        /// I2S Linear prescaler
        I2SDIV: u8 = 16,
        /// ODD [8:8]
        /// Odd factor for the
        ODD: u1 = 0,
        /// MCKOE [9:9]
        /// Master clock output enable
        MCKOE: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S prescaler register
    pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI1 = struct {
    const base_address = 0x40013000;
    /// CR1
    const CR1_val = packed struct {
        /// CPHA [0:0]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [1:1]
        /// Clock polarity
        CPOL: u1 = 0,
        /// MSTR [2:2]
        /// Master selection
        MSTR: u1 = 0,
        /// BR [3:5]
        /// Baud rate control
        BR: u3 = 0,
        /// SPE [6:6]
        /// SPI enable
        SPE: u1 = 0,
        /// LSBFIRST [7:7]
        /// Frame format
        LSBFIRST: u1 = 0,
        /// SSI [8:8]
        /// Internal slave select
        SSI: u1 = 0,
        /// SSM [9:9]
        /// Software slave management
        SSM: u1 = 0,
        /// RXONLY [10:10]
        /// Receive only
        RXONLY: u1 = 0,
        /// DFF [11:11]
        /// Data frame format
        DFF: u1 = 0,
        /// CRCNEXT [12:12]
        /// CRC transfer next
        CRCNEXT: u1 = 0,
        /// CRCEN [13:13]
        /// Hardware CRC calculation
        CRCEN: u1 = 0,
        /// BIDIOE [14:14]
        /// Output enable in bidirectional
        BIDIOE: u1 = 0,
        /// BIDIMODE [15:15]
        /// Bidirectional data mode
        BIDIMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// RXDMAEN [0:0]
        /// Rx buffer DMA enable
        RXDMAEN: u1 = 0,
        /// TXDMAEN [1:1]
        /// Tx buffer DMA enable
        TXDMAEN: u1 = 0,
        /// SSOE [2:2]
        /// SS output enable
        SSOE: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// FRF [4:4]
        /// Frame format
        FRF: u1 = 0,
        /// ERRIE [5:5]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// RXNEIE [6:6]
        /// RX buffer not empty interrupt
        RXNEIE: u1 = 0,
        /// TXEIE [7:7]
        /// Tx buffer empty interrupt
        TXEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// RXNE [0:0]
        /// Receive buffer not empty
        RXNE: u1 = 0,
        /// TXE [1:1]
        /// Transmit buffer empty
        TXE: u1 = 1,
        /// CHSIDE [2:2]
        /// Channel side
        CHSIDE: u1 = 0,
        /// UDR [3:3]
        /// Underrun flag
        UDR: u1 = 0,
        /// CRCERR [4:4]
        /// CRC error flag
        CRCERR: u1 = 0,
        /// MODF [5:5]
        /// Mode fault
        MODF: u1 = 0,
        /// OVR [6:6]
        /// Overrun flag
        OVR: u1 = 0,
        /// BSY [7:7]
        /// Busy flag
        BSY: u1 = 0,
        /// TIFRFE [8:8]
        /// TI frame format error
        TIFRFE: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x8);

    /// DR
    const DR_val = packed struct {
        /// DR [0:15]
        /// Data register
        DR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data register
    pub const DR = Register(DR_val).init(base_address + 0xc);

    /// CRCPR
    const CRCPR_val = packed struct {
        /// CRCPOLY [0:15]
        /// CRC polynomial register
        CRCPOLY: u16 = 7,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// CRC polynomial register
    pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

    /// RXCRCR
    const RXCRCR_val = packed struct {
        /// RxCRC [0:15]
        /// Rx CRC register
        RxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// RX CRC register
    pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

    /// TXCRCR
    const TXCRCR_val = packed struct {
        /// TxCRC [0:15]
        /// Tx CRC register
        TxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TX CRC register
    pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

    /// I2SCFGR
    const I2SCFGR_val = packed struct {
        /// CHLEN [0:0]
        /// Channel length (number of bits per audio
        CHLEN: u1 = 0,
        /// DATLEN [1:2]
        /// Data length to be
        DATLEN: u2 = 0,
        /// CKPOL [3:3]
        /// Steady state clock
        CKPOL: u1 = 0,
        /// I2SSTD [4:5]
        /// I2S standard selection
        I2SSTD: u2 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// PCMSYNC [7:7]
        /// PCM frame synchronization
        PCMSYNC: u1 = 0,
        /// I2SCFG [8:9]
        /// I2S configuration mode
        I2SCFG: u2 = 0,
        /// I2SE [10:10]
        /// I2S Enable
        I2SE: u1 = 0,
        /// I2SMOD [11:11]
        /// I2S mode selection
        I2SMOD: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S configuration register
    pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

    /// I2SPR
    const I2SPR_val = packed struct {
        /// I2SDIV [0:7]
        /// I2S Linear prescaler
        I2SDIV: u8 = 16,
        /// ODD [8:8]
        /// Odd factor for the
        ODD: u1 = 0,
        /// MCKOE [9:9]
        /// Master clock output enable
        MCKOE: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S prescaler register
    pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI2 = struct {
    const base_address = 0x40003800;
    /// CR1
    const CR1_val = packed struct {
        /// CPHA [0:0]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [1:1]
        /// Clock polarity
        CPOL: u1 = 0,
        /// MSTR [2:2]
        /// Master selection
        MSTR: u1 = 0,
        /// BR [3:5]
        /// Baud rate control
        BR: u3 = 0,
        /// SPE [6:6]
        /// SPI enable
        SPE: u1 = 0,
        /// LSBFIRST [7:7]
        /// Frame format
        LSBFIRST: u1 = 0,
        /// SSI [8:8]
        /// Internal slave select
        SSI: u1 = 0,
        /// SSM [9:9]
        /// Software slave management
        SSM: u1 = 0,
        /// RXONLY [10:10]
        /// Receive only
        RXONLY: u1 = 0,
        /// DFF [11:11]
        /// Data frame format
        DFF: u1 = 0,
        /// CRCNEXT [12:12]
        /// CRC transfer next
        CRCNEXT: u1 = 0,
        /// CRCEN [13:13]
        /// Hardware CRC calculation
        CRCEN: u1 = 0,
        /// BIDIOE [14:14]
        /// Output enable in bidirectional
        BIDIOE: u1 = 0,
        /// BIDIMODE [15:15]
        /// Bidirectional data mode
        BIDIMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// RXDMAEN [0:0]
        /// Rx buffer DMA enable
        RXDMAEN: u1 = 0,
        /// TXDMAEN [1:1]
        /// Tx buffer DMA enable
        TXDMAEN: u1 = 0,
        /// SSOE [2:2]
        /// SS output enable
        SSOE: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// FRF [4:4]
        /// Frame format
        FRF: u1 = 0,
        /// ERRIE [5:5]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// RXNEIE [6:6]
        /// RX buffer not empty interrupt
        RXNEIE: u1 = 0,
        /// TXEIE [7:7]
        /// Tx buffer empty interrupt
        TXEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// RXNE [0:0]
        /// Receive buffer not empty
        RXNE: u1 = 0,
        /// TXE [1:1]
        /// Transmit buffer empty
        TXE: u1 = 1,
        /// CHSIDE [2:2]
        /// Channel side
        CHSIDE: u1 = 0,
        /// UDR [3:3]
        /// Underrun flag
        UDR: u1 = 0,
        /// CRCERR [4:4]
        /// CRC error flag
        CRCERR: u1 = 0,
        /// MODF [5:5]
        /// Mode fault
        MODF: u1 = 0,
        /// OVR [6:6]
        /// Overrun flag
        OVR: u1 = 0,
        /// BSY [7:7]
        /// Busy flag
        BSY: u1 = 0,
        /// TIFRFE [8:8]
        /// TI frame format error
        TIFRFE: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x8);

    /// DR
    const DR_val = packed struct {
        /// DR [0:15]
        /// Data register
        DR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data register
    pub const DR = Register(DR_val).init(base_address + 0xc);

    /// CRCPR
    const CRCPR_val = packed struct {
        /// CRCPOLY [0:15]
        /// CRC polynomial register
        CRCPOLY: u16 = 7,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// CRC polynomial register
    pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

    /// RXCRCR
    const RXCRCR_val = packed struct {
        /// RxCRC [0:15]
        /// Rx CRC register
        RxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// RX CRC register
    pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

    /// TXCRCR
    const TXCRCR_val = packed struct {
        /// TxCRC [0:15]
        /// Tx CRC register
        TxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TX CRC register
    pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

    /// I2SCFGR
    const I2SCFGR_val = packed struct {
        /// CHLEN [0:0]
        /// Channel length (number of bits per audio
        CHLEN: u1 = 0,
        /// DATLEN [1:2]
        /// Data length to be
        DATLEN: u2 = 0,
        /// CKPOL [3:3]
        /// Steady state clock
        CKPOL: u1 = 0,
        /// I2SSTD [4:5]
        /// I2S standard selection
        I2SSTD: u2 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// PCMSYNC [7:7]
        /// PCM frame synchronization
        PCMSYNC: u1 = 0,
        /// I2SCFG [8:9]
        /// I2S configuration mode
        I2SCFG: u2 = 0,
        /// I2SE [10:10]
        /// I2S Enable
        I2SE: u1 = 0,
        /// I2SMOD [11:11]
        /// I2S mode selection
        I2SMOD: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S configuration register
    pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

    /// I2SPR
    const I2SPR_val = packed struct {
        /// I2SDIV [0:7]
        /// I2S Linear prescaler
        I2SDIV: u8 = 16,
        /// ODD [8:8]
        /// Odd factor for the
        ODD: u1 = 0,
        /// MCKOE [9:9]
        /// Master clock output enable
        MCKOE: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S prescaler register
    pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI3 = struct {
    const base_address = 0x40003c00;
    /// CR1
    const CR1_val = packed struct {
        /// CPHA [0:0]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [1:1]
        /// Clock polarity
        CPOL: u1 = 0,
        /// MSTR [2:2]
        /// Master selection
        MSTR: u1 = 0,
        /// BR [3:5]
        /// Baud rate control
        BR: u3 = 0,
        /// SPE [6:6]
        /// SPI enable
        SPE: u1 = 0,
        /// LSBFIRST [7:7]
        /// Frame format
        LSBFIRST: u1 = 0,
        /// SSI [8:8]
        /// Internal slave select
        SSI: u1 = 0,
        /// SSM [9:9]
        /// Software slave management
        SSM: u1 = 0,
        /// RXONLY [10:10]
        /// Receive only
        RXONLY: u1 = 0,
        /// DFF [11:11]
        /// Data frame format
        DFF: u1 = 0,
        /// CRCNEXT [12:12]
        /// CRC transfer next
        CRCNEXT: u1 = 0,
        /// CRCEN [13:13]
        /// Hardware CRC calculation
        CRCEN: u1 = 0,
        /// BIDIOE [14:14]
        /// Output enable in bidirectional
        BIDIOE: u1 = 0,
        /// BIDIMODE [15:15]
        /// Bidirectional data mode
        BIDIMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// RXDMAEN [0:0]
        /// Rx buffer DMA enable
        RXDMAEN: u1 = 0,
        /// TXDMAEN [1:1]
        /// Tx buffer DMA enable
        TXDMAEN: u1 = 0,
        /// SSOE [2:2]
        /// SS output enable
        SSOE: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// FRF [4:4]
        /// Frame format
        FRF: u1 = 0,
        /// ERRIE [5:5]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// RXNEIE [6:6]
        /// RX buffer not empty interrupt
        RXNEIE: u1 = 0,
        /// TXEIE [7:7]
        /// Tx buffer empty interrupt
        TXEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// RXNE [0:0]
        /// Receive buffer not empty
        RXNE: u1 = 0,
        /// TXE [1:1]
        /// Transmit buffer empty
        TXE: u1 = 1,
        /// CHSIDE [2:2]
        /// Channel side
        CHSIDE: u1 = 0,
        /// UDR [3:3]
        /// Underrun flag
        UDR: u1 = 0,
        /// CRCERR [4:4]
        /// CRC error flag
        CRCERR: u1 = 0,
        /// MODF [5:5]
        /// Mode fault
        MODF: u1 = 0,
        /// OVR [6:6]
        /// Overrun flag
        OVR: u1 = 0,
        /// BSY [7:7]
        /// Busy flag
        BSY: u1 = 0,
        /// TIFRFE [8:8]
        /// TI frame format error
        TIFRFE: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x8);

    /// DR
    const DR_val = packed struct {
        /// DR [0:15]
        /// Data register
        DR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data register
    pub const DR = Register(DR_val).init(base_address + 0xc);

    /// CRCPR
    const CRCPR_val = packed struct {
        /// CRCPOLY [0:15]
        /// CRC polynomial register
        CRCPOLY: u16 = 7,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// CRC polynomial register
    pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

    /// RXCRCR
    const RXCRCR_val = packed struct {
        /// RxCRC [0:15]
        /// Rx CRC register
        RxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// RX CRC register
    pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

    /// TXCRCR
    const TXCRCR_val = packed struct {
        /// TxCRC [0:15]
        /// Tx CRC register
        TxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TX CRC register
    pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

    /// I2SCFGR
    const I2SCFGR_val = packed struct {
        /// CHLEN [0:0]
        /// Channel length (number of bits per audio
        CHLEN: u1 = 0,
        /// DATLEN [1:2]
        /// Data length to be
        DATLEN: u2 = 0,
        /// CKPOL [3:3]
        /// Steady state clock
        CKPOL: u1 = 0,
        /// I2SSTD [4:5]
        /// I2S standard selection
        I2SSTD: u2 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// PCMSYNC [7:7]
        /// PCM frame synchronization
        PCMSYNC: u1 = 0,
        /// I2SCFG [8:9]
        /// I2S configuration mode
        I2SCFG: u2 = 0,
        /// I2SE [10:10]
        /// I2S Enable
        I2SE: u1 = 0,
        /// I2SMOD [11:11]
        /// I2S mode selection
        I2SMOD: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S configuration register
    pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

    /// I2SPR
    const I2SPR_val = packed struct {
        /// I2SDIV [0:7]
        /// I2S Linear prescaler
        I2SDIV: u8 = 16,
        /// ODD [8:8]
        /// Odd factor for the
        ODD: u1 = 0,
        /// MCKOE [9:9]
        /// Master clock output enable
        MCKOE: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S prescaler register
    pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI4 = struct {
    const base_address = 0x40013400;
    /// CR1
    const CR1_val = packed struct {
        /// CPHA [0:0]
        /// Clock phase
        CPHA: u1 = 0,
        /// CPOL [1:1]
        /// Clock polarity
        CPOL: u1 = 0,
        /// MSTR [2:2]
        /// Master selection
        MSTR: u1 = 0,
        /// BR [3:5]
        /// Baud rate control
        BR: u3 = 0,
        /// SPE [6:6]
        /// SPI enable
        SPE: u1 = 0,
        /// LSBFIRST [7:7]
        /// Frame format
        LSBFIRST: u1 = 0,
        /// SSI [8:8]
        /// Internal slave select
        SSI: u1 = 0,
        /// SSM [9:9]
        /// Software slave management
        SSM: u1 = 0,
        /// RXONLY [10:10]
        /// Receive only
        RXONLY: u1 = 0,
        /// DFF [11:11]
        /// Data frame format
        DFF: u1 = 0,
        /// CRCNEXT [12:12]
        /// CRC transfer next
        CRCNEXT: u1 = 0,
        /// CRCEN [13:13]
        /// Hardware CRC calculation
        CRCEN: u1 = 0,
        /// BIDIOE [14:14]
        /// Output enable in bidirectional
        BIDIOE: u1 = 0,
        /// BIDIMODE [15:15]
        /// Bidirectional data mode
        BIDIMODE: u1 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 1
    pub const CR1 = Register(CR1_val).init(base_address + 0x0);

    /// CR2
    const CR2_val = packed struct {
        /// RXDMAEN [0:0]
        /// Rx buffer DMA enable
        RXDMAEN: u1 = 0,
        /// TXDMAEN [1:1]
        /// Tx buffer DMA enable
        TXDMAEN: u1 = 0,
        /// SSOE [2:2]
        /// SS output enable
        SSOE: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// FRF [4:4]
        /// Frame format
        FRF: u1 = 0,
        /// ERRIE [5:5]
        /// Error interrupt enable
        ERRIE: u1 = 0,
        /// RXNEIE [6:6]
        /// RX buffer not empty interrupt
        RXNEIE: u1 = 0,
        /// TXEIE [7:7]
        /// Tx buffer empty interrupt
        TXEIE: u1 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// control register 2
    pub const CR2 = Register(CR2_val).init(base_address + 0x4);

    /// SR
    const SR_val = packed struct {
        /// RXNE [0:0]
        /// Receive buffer not empty
        RXNE: u1 = 0,
        /// TXE [1:1]
        /// Transmit buffer empty
        TXE: u1 = 1,
        /// CHSIDE [2:2]
        /// Channel side
        CHSIDE: u1 = 0,
        /// UDR [3:3]
        /// Underrun flag
        UDR: u1 = 0,
        /// CRCERR [4:4]
        /// CRC error flag
        CRCERR: u1 = 0,
        /// MODF [5:5]
        /// Mode fault
        MODF: u1 = 0,
        /// OVR [6:6]
        /// Overrun flag
        OVR: u1 = 0,
        /// BSY [7:7]
        /// Busy flag
        BSY: u1 = 0,
        /// TIFRFE [8:8]
        /// TI frame format error
        TIFRFE: u1 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// status register
    pub const SR = Register(SR_val).init(base_address + 0x8);

    /// DR
    const DR_val = packed struct {
        /// DR [0:15]
        /// Data register
        DR: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// data register
    pub const DR = Register(DR_val).init(base_address + 0xc);

    /// CRCPR
    const CRCPR_val = packed struct {
        /// CRCPOLY [0:15]
        /// CRC polynomial register
        CRCPOLY: u16 = 7,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// CRC polynomial register
    pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

    /// RXCRCR
    const RXCRCR_val = packed struct {
        /// RxCRC [0:15]
        /// Rx CRC register
        RxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// RX CRC register
    pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

    /// TXCRCR
    const TXCRCR_val = packed struct {
        /// TxCRC [0:15]
        /// Tx CRC register
        TxCRC: u16 = 0,
        /// unused [16:31]
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// TX CRC register
    pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

    /// I2SCFGR
    const I2SCFGR_val = packed struct {
        /// CHLEN [0:0]
        /// Channel length (number of bits per audio
        CHLEN: u1 = 0,
        /// DATLEN [1:2]
        /// Data length to be
        DATLEN: u2 = 0,
        /// CKPOL [3:3]
        /// Steady state clock
        CKPOL: u1 = 0,
        /// I2SSTD [4:5]
        /// I2S standard selection
        I2SSTD: u2 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// PCMSYNC [7:7]
        /// PCM frame synchronization
        PCMSYNC: u1 = 0,
        /// I2SCFG [8:9]
        /// I2S configuration mode
        I2SCFG: u2 = 0,
        /// I2SE [10:10]
        /// I2S Enable
        I2SE: u1 = 0,
        /// I2SMOD [11:11]
        /// I2S mode selection
        I2SMOD: u1 = 0,
        /// unused [12:31]
        _unused12: u4 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S configuration register
    pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

    /// I2SPR
    const I2SPR_val = packed struct {
        /// I2SDIV [0:7]
        /// I2S Linear prescaler
        I2SDIV: u8 = 16,
        /// ODD [8:8]
        /// Odd factor for the
        ODD: u1 = 0,
        /// MCKOE [9:9]
        /// Master clock output enable
        MCKOE: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// I2S prescaler register
    pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Nested Vectored Interrupt
pub const NVIC = struct {
    const base_address = 0xe000e100;
    /// ISER0
    const ISER0_val = packed struct {
        /// SETENA [0:31]
        /// SETENA
        SETENA: u32 = 0,
    };
    /// Interrupt Set-Enable Register
    pub const ISER0 = Register(ISER0_val).init(base_address + 0x0);

    /// ISER1
    const ISER1_val = packed struct {
        /// SETENA [0:31]
        /// SETENA
        SETENA: u32 = 0,
    };
    /// Interrupt Set-Enable Register
    pub const ISER1 = Register(ISER1_val).init(base_address + 0x4);

    /// ISER2
    const ISER2_val = packed struct {
        /// SETENA [0:31]
        /// SETENA
        SETENA: u32 = 0,
    };
    /// Interrupt Set-Enable Register
    pub const ISER2 = Register(ISER2_val).init(base_address + 0x8);

    /// ICER0
    const ICER0_val = packed struct {
        /// CLRENA [0:31]
        /// CLRENA
        CLRENA: u32 = 0,
    };
    /// Interrupt Clear-Enable
    pub const ICER0 = Register(ICER0_val).init(base_address + 0x80);

    /// ICER1
    const ICER1_val = packed struct {
        /// CLRENA [0:31]
        /// CLRENA
        CLRENA: u32 = 0,
    };
    /// Interrupt Clear-Enable
    pub const ICER1 = Register(ICER1_val).init(base_address + 0x84);

    /// ICER2
    const ICER2_val = packed struct {
        /// CLRENA [0:31]
        /// CLRENA
        CLRENA: u32 = 0,
    };
    /// Interrupt Clear-Enable
    pub const ICER2 = Register(ICER2_val).init(base_address + 0x88);

    /// ISPR0
    const ISPR0_val = packed struct {
        /// SETPEND [0:31]
        /// SETPEND
        SETPEND: u32 = 0,
    };
    /// Interrupt Set-Pending Register
    pub const ISPR0 = Register(ISPR0_val).init(base_address + 0x100);

    /// ISPR1
    const ISPR1_val = packed struct {
        /// SETPEND [0:31]
        /// SETPEND
        SETPEND: u32 = 0,
    };
    /// Interrupt Set-Pending Register
    pub const ISPR1 = Register(ISPR1_val).init(base_address + 0x104);

    /// ISPR2
    const ISPR2_val = packed struct {
        /// SETPEND [0:31]
        /// SETPEND
        SETPEND: u32 = 0,
    };
    /// Interrupt Set-Pending Register
    pub const ISPR2 = Register(ISPR2_val).init(base_address + 0x108);

    /// ICPR0
    const ICPR0_val = packed struct {
        /// CLRPEND [0:31]
        /// CLRPEND
        CLRPEND: u32 = 0,
    };
    /// Interrupt Clear-Pending
    pub const ICPR0 = Register(ICPR0_val).init(base_address + 0x180);

    /// ICPR1
    const ICPR1_val = packed struct {
        /// CLRPEND [0:31]
        /// CLRPEND
        CLRPEND: u32 = 0,
    };
    /// Interrupt Clear-Pending
    pub const ICPR1 = Register(ICPR1_val).init(base_address + 0x184);

    /// ICPR2
    const ICPR2_val = packed struct {
        /// CLRPEND [0:31]
        /// CLRPEND
        CLRPEND: u32 = 0,
    };
    /// Interrupt Clear-Pending
    pub const ICPR2 = Register(ICPR2_val).init(base_address + 0x188);

    /// IABR0
    const IABR0_val = packed struct {
        /// ACTIVE [0:31]
        /// ACTIVE
        ACTIVE: u32 = 0,
    };
    /// Interrupt Active Bit Register
    pub const IABR0 = Register(IABR0_val).init(base_address + 0x200);

    /// IABR1
    const IABR1_val = packed struct {
        /// ACTIVE [0:31]
        /// ACTIVE
        ACTIVE: u32 = 0,
    };
    /// Interrupt Active Bit Register
    pub const IABR1 = Register(IABR1_val).init(base_address + 0x204);

    /// IABR2
    const IABR2_val = packed struct {
        /// ACTIVE [0:31]
        /// ACTIVE
        ACTIVE: u32 = 0,
    };
    /// Interrupt Active Bit Register
    pub const IABR2 = Register(IABR2_val).init(base_address + 0x208);

    /// IPR0
    const IPR0_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR0 = Register(IPR0_val).init(base_address + 0x300);

    /// IPR1
    const IPR1_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR1 = Register(IPR1_val).init(base_address + 0x304);

    /// IPR2
    const IPR2_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR2 = Register(IPR2_val).init(base_address + 0x308);

    /// IPR3
    const IPR3_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR3 = Register(IPR3_val).init(base_address + 0x30c);

    /// IPR4
    const IPR4_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR4 = Register(IPR4_val).init(base_address + 0x310);

    /// IPR5
    const IPR5_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR5 = Register(IPR5_val).init(base_address + 0x314);

    /// IPR6
    const IPR6_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR6 = Register(IPR6_val).init(base_address + 0x318);

    /// IPR7
    const IPR7_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR7 = Register(IPR7_val).init(base_address + 0x31c);

    /// IPR8
    const IPR8_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR8 = Register(IPR8_val).init(base_address + 0x320);

    /// IPR9
    const IPR9_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR9 = Register(IPR9_val).init(base_address + 0x324);

    /// IPR10
    const IPR10_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR10 = Register(IPR10_val).init(base_address + 0x328);

    /// IPR11
    const IPR11_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR11 = Register(IPR11_val).init(base_address + 0x32c);

    /// IPR12
    const IPR12_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR12 = Register(IPR12_val).init(base_address + 0x330);

    /// IPR13
    const IPR13_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR13 = Register(IPR13_val).init(base_address + 0x334);

    /// IPR14
    const IPR14_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR14 = Register(IPR14_val).init(base_address + 0x338);

    /// IPR15
    const IPR15_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR15 = Register(IPR15_val).init(base_address + 0x33c);

    /// IPR16
    const IPR16_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR16 = Register(IPR16_val).init(base_address + 0x340);

    /// IPR17
    const IPR17_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR17 = Register(IPR17_val).init(base_address + 0x344);

    /// IPR18
    const IPR18_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR18 = Register(IPR18_val).init(base_address + 0x348);

    /// IPR19
    const IPR19_val = packed struct {
        /// IPR_N0 [0:7]
        /// IPR_N0
        IPR_N0: u8 = 0,
        /// IPR_N1 [8:15]
        /// IPR_N1
        IPR_N1: u8 = 0,
        /// IPR_N2 [16:23]
        /// IPR_N2
        IPR_N2: u8 = 0,
        /// IPR_N3 [24:31]
        /// IPR_N3
        IPR_N3: u8 = 0,
    };
    /// Interrupt Priority Register
    pub const IPR19 = Register(IPR19_val).init(base_address + 0x34c);
};

/// Floting point unit
pub const FPU = struct {
    const base_address = 0xe000ef34;
    /// FPCCR
    const FPCCR_val = packed struct {
        /// LSPACT [0:0]
        /// LSPACT
        LSPACT: u1 = 0,
        /// USER [1:1]
        /// USER
        USER: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// THREAD [3:3]
        /// THREAD
        THREAD: u1 = 0,
        /// HFRDY [4:4]
        /// HFRDY
        HFRDY: u1 = 0,
        /// MMRDY [5:5]
        /// MMRDY
        MMRDY: u1 = 0,
        /// BFRDY [6:6]
        /// BFRDY
        BFRDY: u1 = 0,
        /// unused [7:7]
        _unused7: u1 = 0,
        /// MONRDY [8:8]
        /// MONRDY
        MONRDY: u1 = 0,
        /// unused [9:29]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u6 = 0,
        /// LSPEN [30:30]
        /// LSPEN
        LSPEN: u1 = 0,
        /// ASPEN [31:31]
        /// ASPEN
        ASPEN: u1 = 0,
    };
    /// Floating-point context control
    pub const FPCCR = Register(FPCCR_val).init(base_address + 0x0);

    /// FPCAR
    const FPCAR_val = packed struct {
        /// unused [0:2]
        _unused0: u3 = 0,
        /// ADDRESS [3:31]
        /// Location of unpopulated
        ADDRESS: u29 = 0,
    };
    /// Floating-point context address
    pub const FPCAR = Register(FPCAR_val).init(base_address + 0x4);

    /// FPSCR
    const FPSCR_val = packed struct {
        /// IOC [0:0]
        /// Invalid operation cumulative exception
        IOC: u1 = 0,
        /// DZC [1:1]
        /// Division by zero cumulative exception
        DZC: u1 = 0,
        /// OFC [2:2]
        /// Overflow cumulative exception
        OFC: u1 = 0,
        /// UFC [3:3]
        /// Underflow cumulative exception
        UFC: u1 = 0,
        /// IXC [4:4]
        /// Inexact cumulative exception
        IXC: u1 = 0,
        /// unused [5:6]
        _unused5: u2 = 0,
        /// IDC [7:7]
        /// Input denormal cumulative exception
        IDC: u1 = 0,
        /// unused [8:21]
        _unused8: u8 = 0,
        _unused16: u6 = 0,
        /// RMode [22:23]
        /// Rounding Mode control
        RMode: u2 = 0,
        /// FZ [24:24]
        /// Flush-to-zero mode control
        FZ: u1 = 0,
        /// DN [25:25]
        /// Default NaN mode control
        DN: u1 = 0,
        /// AHP [26:26]
        /// Alternative half-precision control
        AHP: u1 = 0,
        /// unused [27:27]
        _unused27: u1 = 0,
        /// V [28:28]
        /// Overflow condition code
        V: u1 = 0,
        /// C [29:29]
        /// Carry condition code flag
        C: u1 = 0,
        /// Z [30:30]
        /// Zero condition code flag
        Z: u1 = 0,
        /// N [31:31]
        /// Negative condition code
        N: u1 = 0,
    };
    /// Floating-point status control
    pub const FPSCR = Register(FPSCR_val).init(base_address + 0x8);
};

/// Memory protection unit
pub const MPU = struct {
    const base_address = 0xe000ed90;
    /// MPU_TYPER
    const MPU_TYPER_val = packed struct {
        /// SEPARATE [0:0]
        /// Separate flag
        SEPARATE: u1 = 0,
        /// unused [1:7]
        _unused1: u7 = 0,
        /// DREGION [8:15]
        /// Number of MPU data regions
        DREGION: u8 = 8,
        /// IREGION [16:23]
        /// Number of MPU instruction
        IREGION: u8 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// MPU type register
    pub const MPU_TYPER = Register(MPU_TYPER_val).init(base_address + 0x0);

    /// MPU_CTRL
    const MPU_CTRL_val = packed struct {
        /// ENABLE [0:0]
        /// Enables the MPU
        ENABLE: u1 = 0,
        /// HFNMIENA [1:1]
        /// Enables the operation of MPU during hard
        HFNMIENA: u1 = 0,
        /// PRIVDEFENA [2:2]
        /// Enable priviliged software access to
        PRIVDEFENA: u1 = 0,
        /// unused [3:31]
        _unused3: u5 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// MPU control register
    pub const MPU_CTRL = Register(MPU_CTRL_val).init(base_address + 0x4);

    /// MPU_RNR
    const MPU_RNR_val = packed struct {
        /// REGION [0:7]
        /// MPU region
        REGION: u8 = 0,
        /// unused [8:31]
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// MPU region number register
    pub const MPU_RNR = Register(MPU_RNR_val).init(base_address + 0x8);

    /// MPU_RBAR
    const MPU_RBAR_val = packed struct {
        /// REGION [0:3]
        /// MPU region field
        REGION: u4 = 0,
        /// VALID [4:4]
        /// MPU region number valid
        VALID: u1 = 0,
        /// ADDR [5:31]
        /// Region base address field
        ADDR: u27 = 0,
    };
    /// MPU region base address
    pub const MPU_RBAR = Register(MPU_RBAR_val).init(base_address + 0xc);

    /// MPU_RASR
    const MPU_RASR_val = packed struct {
        /// ENABLE [0:0]
        /// Region enable bit.
        ENABLE: u1 = 0,
        /// SIZE [1:5]
        /// Size of the MPU protection
        SIZE: u5 = 0,
        /// unused [6:7]
        _unused6: u2 = 0,
        /// SRD [8:15]
        /// Subregion disable bits
        SRD: u8 = 0,
        /// B [16:16]
        /// memory attribute
        B: u1 = 0,
        /// C [17:17]
        /// memory attribute
        C: u1 = 0,
        /// S [18:18]
        /// Shareable memory attribute
        S: u1 = 0,
        /// TEX [19:21]
        /// memory attribute
        TEX: u3 = 0,
        /// unused [22:23]
        _unused22: u2 = 0,
        /// AP [24:26]
        /// Access permission
        AP: u3 = 0,
        /// unused [27:27]
        _unused27: u1 = 0,
        /// XN [28:28]
        /// Instruction access disable
        XN: u1 = 0,
        /// unused [29:31]
        _unused29: u3 = 0,
    };
    /// MPU region attribute and size
    pub const MPU_RASR = Register(MPU_RASR_val).init(base_address + 0x10);
};

/// SysTick timer
pub const STK = struct {
    const base_address = 0xe000e010;
    /// CTRL
    const CTRL_val = packed struct {
        /// ENABLE [0:0]
        /// Counter enable
        ENABLE: u1 = 0,
        /// TICKINT [1:1]
        /// SysTick exception request
        TICKINT: u1 = 0,
        /// CLKSOURCE [2:2]
        /// Clock source selection
        CLKSOURCE: u1 = 0,
        /// unused [3:15]
        _unused3: u5 = 0,
        _unused8: u8 = 0,
        /// COUNTFLAG [16:16]
        /// COUNTFLAG
        COUNTFLAG: u1 = 0,
        /// unused [17:31]
        _unused17: u7 = 0,
        _unused24: u8 = 0,
    };
    /// SysTick control and status
    pub const CTRL = Register(CTRL_val).init(base_address + 0x0);

    /// LOAD
    const LOAD_val = packed struct {
        /// RELOAD [0:23]
        /// RELOAD value
        RELOAD: u24 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// SysTick reload value register
    pub const LOAD = Register(LOAD_val).init(base_address + 0x4);

    /// VAL
    const VAL_val = packed struct {
        /// CURRENT [0:23]
        /// Current counter value
        CURRENT: u24 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// SysTick current value register
    pub const VAL = Register(VAL_val).init(base_address + 0x8);

    /// CALIB
    const CALIB_val = packed struct {
        /// TENMS [0:23]
        /// Calibration value
        TENMS: u24 = 0,
        /// unused [24:29]
        _unused24: u6 = 0,
        /// SKEW [30:30]
        /// SKEW flag: Indicates whether the TENMS
        SKEW: u1 = 0,
        /// NOREF [31:31]
        /// NOREF flag. Reads as zero
        NOREF: u1 = 0,
    };
    /// SysTick calibration value
    pub const CALIB = Register(CALIB_val).init(base_address + 0xc);
};

/// System control block
pub const SCB = struct {
    const base_address = 0xe000ed00;
    /// CPUID
    const CPUID_val = packed struct {
        /// Revision [0:3]
        /// Revision number
        Revision: u4 = 1,
        /// PartNo [4:15]
        /// Part number of the
        PartNo: u12 = 3108,
        /// Constant [16:19]
        /// Reads as 0xF
        Constant: u4 = 15,
        /// Variant [20:23]
        /// Variant number
        Variant: u4 = 0,
        /// Implementer [24:31]
        /// Implementer code
        Implementer: u8 = 65,
    };
    /// CPUID base register
    pub const CPUID = Register(CPUID_val).init(base_address + 0x0);

    /// ICSR
    const ICSR_val = packed struct {
        /// VECTACTIVE [0:8]
        /// Active vector
        VECTACTIVE: u9 = 0,
        /// unused [9:10]
        _unused9: u2 = 0,
        /// RETTOBASE [11:11]
        /// Return to base level
        RETTOBASE: u1 = 0,
        /// VECTPENDING [12:18]
        /// Pending vector
        VECTPENDING: u7 = 0,
        /// unused [19:21]
        _unused19: u3 = 0,
        /// ISRPENDING [22:22]
        /// Interrupt pending flag
        ISRPENDING: u1 = 0,
        /// unused [23:24]
        _unused23: u1 = 0,
        _unused24: u1 = 0,
        /// PENDSTCLR [25:25]
        /// SysTick exception clear-pending
        PENDSTCLR: u1 = 0,
        /// PENDSTSET [26:26]
        /// SysTick exception set-pending
        PENDSTSET: u1 = 0,
        /// PENDSVCLR [27:27]
        /// PendSV clear-pending bit
        PENDSVCLR: u1 = 0,
        /// PENDSVSET [28:28]
        /// PendSV set-pending bit
        PENDSVSET: u1 = 0,
        /// unused [29:30]
        _unused29: u2 = 0,
        /// NMIPENDSET [31:31]
        /// NMI set-pending bit.
        NMIPENDSET: u1 = 0,
    };
    /// Interrupt control and state
    pub const ICSR = Register(ICSR_val).init(base_address + 0x4);

    /// VTOR
    const VTOR_val = packed struct {
        /// unused [0:8]
        _unused0: u8 = 0,
        _unused8: u1 = 0,
        /// TBLOFF [9:29]
        /// Vector table base offset
        TBLOFF: u21 = 0,
        /// unused [30:31]
        _unused30: u2 = 0,
    };
    /// Vector table offset register
    pub const VTOR = Register(VTOR_val).init(base_address + 0x8);

    /// AIRCR
    const AIRCR_val = packed struct {
        /// VECTRESET [0:0]
        /// VECTRESET
        VECTRESET: u1 = 0,
        /// VECTCLRACTIVE [1:1]
        /// VECTCLRACTIVE
        VECTCLRACTIVE: u1 = 0,
        /// SYSRESETREQ [2:2]
        /// SYSRESETREQ
        SYSRESETREQ: u1 = 0,
        /// unused [3:7]
        _unused3: u5 = 0,
        /// PRIGROUP [8:10]
        /// PRIGROUP
        PRIGROUP: u3 = 0,
        /// unused [11:14]
        _unused11: u4 = 0,
        /// ENDIANESS [15:15]
        /// ENDIANESS
        ENDIANESS: u1 = 0,
        /// VECTKEYSTAT [16:31]
        /// Register key
        VECTKEYSTAT: u16 = 0,
    };
    /// Application interrupt and reset control
    pub const AIRCR = Register(AIRCR_val).init(base_address + 0xc);

    /// SCR
    const SCR_val = packed struct {
        /// unused [0:0]
        _unused0: u1 = 0,
        /// SLEEPONEXIT [1:1]
        /// SLEEPONEXIT
        SLEEPONEXIT: u1 = 0,
        /// SLEEPDEEP [2:2]
        /// SLEEPDEEP
        SLEEPDEEP: u1 = 0,
        /// unused [3:3]
        _unused3: u1 = 0,
        /// SEVEONPEND [4:4]
        /// Send Event on Pending bit
        SEVEONPEND: u1 = 0,
        /// unused [5:31]
        _unused5: u3 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// System control register
    pub const SCR = Register(SCR_val).init(base_address + 0x10);

    /// CCR
    const CCR_val = packed struct {
        /// NONBASETHRDENA [0:0]
        /// Configures how the processor enters
        NONBASETHRDENA: u1 = 0,
        /// USERSETMPEND [1:1]
        /// USERSETMPEND
        USERSETMPEND: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// UNALIGN__TRP [3:3]
        /// UNALIGN_ TRP
        UNALIGN__TRP: u1 = 0,
        /// DIV_0_TRP [4:4]
        /// DIV_0_TRP
        DIV_0_TRP: u1 = 0,
        /// unused [5:7]
        _unused5: u3 = 0,
        /// BFHFNMIGN [8:8]
        /// BFHFNMIGN
        BFHFNMIGN: u1 = 0,
        /// STKALIGN [9:9]
        /// STKALIGN
        STKALIGN: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Configuration and control
    pub const CCR = Register(CCR_val).init(base_address + 0x14);

    /// SHPR1
    const SHPR1_val = packed struct {
        /// PRI_4 [0:7]
        /// Priority of system handler
        PRI_4: u8 = 0,
        /// PRI_5 [8:15]
        /// Priority of system handler
        PRI_5: u8 = 0,
        /// PRI_6 [16:23]
        /// Priority of system handler
        PRI_6: u8 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// System handler priority
    pub const SHPR1 = Register(SHPR1_val).init(base_address + 0x18);

    /// SHPR2
    const SHPR2_val = packed struct {
        /// unused [0:23]
        _unused0: u8 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        /// PRI_11 [24:31]
        /// Priority of system handler
        PRI_11: u8 = 0,
    };
    /// System handler priority
    pub const SHPR2 = Register(SHPR2_val).init(base_address + 0x1c);

    /// SHPR3
    const SHPR3_val = packed struct {
        /// unused [0:15]
        _unused0: u8 = 0,
        _unused8: u8 = 0,
        /// PRI_14 [16:23]
        /// Priority of system handler
        PRI_14: u8 = 0,
        /// PRI_15 [24:31]
        /// Priority of system handler
        PRI_15: u8 = 0,
    };
    /// System handler priority
    pub const SHPR3 = Register(SHPR3_val).init(base_address + 0x20);

    /// SHCRS
    const SHCRS_val = packed struct {
        /// MEMFAULTACT [0:0]
        /// Memory management fault exception active
        MEMFAULTACT: u1 = 0,
        /// BUSFAULTACT [1:1]
        /// Bus fault exception active
        BUSFAULTACT: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// USGFAULTACT [3:3]
        /// Usage fault exception active
        USGFAULTACT: u1 = 0,
        /// unused [4:6]
        _unused4: u3 = 0,
        /// SVCALLACT [7:7]
        /// SVC call active bit
        SVCALLACT: u1 = 0,
        /// MONITORACT [8:8]
        /// Debug monitor active bit
        MONITORACT: u1 = 0,
        /// unused [9:9]
        _unused9: u1 = 0,
        /// PENDSVACT [10:10]
        /// PendSV exception active
        PENDSVACT: u1 = 0,
        /// SYSTICKACT [11:11]
        /// SysTick exception active
        SYSTICKACT: u1 = 0,
        /// USGFAULTPENDED [12:12]
        /// Usage fault exception pending
        USGFAULTPENDED: u1 = 0,
        /// MEMFAULTPENDED [13:13]
        /// Memory management fault exception
        MEMFAULTPENDED: u1 = 0,
        /// BUSFAULTPENDED [14:14]
        /// Bus fault exception pending
        BUSFAULTPENDED: u1 = 0,
        /// SVCALLPENDED [15:15]
        /// SVC call pending bit
        SVCALLPENDED: u1 = 0,
        /// MEMFAULTENA [16:16]
        /// Memory management fault enable
        MEMFAULTENA: u1 = 0,
        /// BUSFAULTENA [17:17]
        /// Bus fault enable bit
        BUSFAULTENA: u1 = 0,
        /// USGFAULTENA [18:18]
        /// Usage fault enable bit
        USGFAULTENA: u1 = 0,
        /// unused [19:31]
        _unused19: u5 = 0,
        _unused24: u8 = 0,
    };
    /// System handler control and state
    pub const SHCRS = Register(SHCRS_val).init(base_address + 0x24);

    /// CFSR_UFSR_BFSR_MMFSR
    const CFSR_UFSR_BFSR_MMFSR_val = packed struct {
        /// unused [0:0]
        _unused0: u1 = 0,
        /// IACCVIOL [1:1]
        /// Instruction access violation
        IACCVIOL: u1 = 0,
        /// unused [2:2]
        _unused2: u1 = 0,
        /// MUNSTKERR [3:3]
        /// Memory manager fault on unstacking for a
        MUNSTKERR: u1 = 0,
        /// MSTKERR [4:4]
        /// Memory manager fault on stacking for
        MSTKERR: u1 = 0,
        /// MLSPERR [5:5]
        /// MLSPERR
        MLSPERR: u1 = 0,
        /// unused [6:6]
        _unused6: u1 = 0,
        /// MMARVALID [7:7]
        /// Memory Management Fault Address Register
        MMARVALID: u1 = 0,
        /// IBUSERR [8:8]
        /// Instruction bus error
        IBUSERR: u1 = 0,
        /// PRECISERR [9:9]
        /// Precise data bus error
        PRECISERR: u1 = 0,
        /// IMPRECISERR [10:10]
        /// Imprecise data bus error
        IMPRECISERR: u1 = 0,
        /// UNSTKERR [11:11]
        /// Bus fault on unstacking for a return
        UNSTKERR: u1 = 0,
        /// STKERR [12:12]
        /// Bus fault on stacking for exception
        STKERR: u1 = 0,
        /// LSPERR [13:13]
        /// Bus fault on floating-point lazy state
        LSPERR: u1 = 0,
        /// unused [14:14]
        _unused14: u1 = 0,
        /// BFARVALID [15:15]
        /// Bus Fault Address Register (BFAR) valid
        BFARVALID: u1 = 0,
        /// UNDEFINSTR [16:16]
        /// Undefined instruction usage
        UNDEFINSTR: u1 = 0,
        /// INVSTATE [17:17]
        /// Invalid state usage fault
        INVSTATE: u1 = 0,
        /// INVPC [18:18]
        /// Invalid PC load usage
        INVPC: u1 = 0,
        /// NOCP [19:19]
        /// No coprocessor usage
        NOCP: u1 = 0,
        /// unused [20:23]
        _unused20: u4 = 0,
        /// UNALIGNED [24:24]
        /// Unaligned access usage
        UNALIGNED: u1 = 0,
        /// DIVBYZERO [25:25]
        /// Divide by zero usage fault
        DIVBYZERO: u1 = 0,
        /// unused [26:31]
        _unused26: u6 = 0,
    };
    /// Configurable fault status
    pub const CFSR_UFSR_BFSR_MMFSR = Register(CFSR_UFSR_BFSR_MMFSR_val).init(base_address + 0x28);

    /// HFSR
    const HFSR_val = packed struct {
        /// unused [0:0]
        _unused0: u1 = 0,
        /// VECTTBL [1:1]
        /// Vector table hard fault
        VECTTBL: u1 = 0,
        /// unused [2:29]
        _unused2: u6 = 0,
        _unused8: u8 = 0,
        _unused16: u8 = 0,
        _unused24: u6 = 0,
        /// FORCED [30:30]
        /// Forced hard fault
        FORCED: u1 = 0,
        /// DEBUG_VT [31:31]
        /// Reserved for Debug use
        DEBUG_VT: u1 = 0,
    };
    /// Hard fault status register
    pub const HFSR = Register(HFSR_val).init(base_address + 0x2c);

    /// MMFAR
    const MMFAR_val = packed struct {
        /// MMFAR [0:31]
        /// Memory management fault
        MMFAR: u32 = 0,
    };
    /// Memory management fault address
    pub const MMFAR = Register(MMFAR_val).init(base_address + 0x34);

    /// BFAR
    const BFAR_val = packed struct {
        /// BFAR [0:31]
        /// Bus fault address
        BFAR: u32 = 0,
    };
    /// Bus fault address register
    pub const BFAR = Register(BFAR_val).init(base_address + 0x38);

    /// AFSR
    const AFSR_val = packed struct {
        /// IMPDEF [0:31]
        /// Implementation defined
        IMPDEF: u32 = 0,
    };
    /// Auxiliary fault status
    pub const AFSR = Register(AFSR_val).init(base_address + 0x3c);
};

/// Nested vectored interrupt
pub const NVIC_STIR = struct {
    const base_address = 0xe000ef00;
    /// STIR
    const STIR_val = packed struct {
        /// INTID [0:8]
        /// Software generated interrupt
        INTID: u9 = 0,
        /// unused [9:31]
        _unused9: u7 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Software trigger interrupt
    pub const STIR = Register(STIR_val).init(base_address + 0x0);
};

/// Floating point unit CPACR
pub const FPU_CPACR = struct {
    const base_address = 0xe000ed88;
    /// CPACR
    const CPACR_val = packed struct {
        /// unused [0:19]
        _unused0: u8 = 0,
        _unused8: u8 = 0,
        _unused16: u4 = 0,
        /// CP [20:23]
        /// CP
        CP: u4 = 0,
        /// unused [24:31]
        _unused24: u8 = 0,
    };
    /// Coprocessor access control
    pub const CPACR = Register(CPACR_val).init(base_address + 0x0);
};

/// System control block ACTLR
pub const SCB_ACTRL = struct {
    const base_address = 0xe000e008;
    /// ACTRL
    const ACTRL_val = packed struct {
        /// DISMCYCINT [0:0]
        /// DISMCYCINT
        DISMCYCINT: u1 = 0,
        /// DISDEFWBUF [1:1]
        /// DISDEFWBUF
        DISDEFWBUF: u1 = 0,
        /// DISFOLD [2:2]
        /// DISFOLD
        DISFOLD: u1 = 0,
        /// unused [3:7]
        _unused3: u5 = 0,
        /// DISFPCA [8:8]
        /// DISFPCA
        DISFPCA: u1 = 0,
        /// DISOOFP [9:9]
        /// DISOOFP
        DISOOFP: u1 = 0,
        /// unused [10:31]
        _unused10: u6 = 0,
        _unused16: u8 = 0,
        _unused24: u8 = 0,
    };
    /// Auxiliary control register
    pub const ACTRL = Register(ACTRL_val).init(base_address + 0x0);
};
pub const interrupts = struct {
    pub const TIM1_TRG_COM_TIM11 = 26;
    pub const RTC_WKUP = 3;
    pub const I2C3_ER = 73;
    pub const SPI3 = 51;
    pub const I2C2_ER = 34;
    pub const EXTI3 = 9;
    pub const SPI2 = 36;
    pub const RTC_Alarm = 41;
    pub const EXTI9_5 = 23;
    pub const TIM1_CC = 27;
    pub const EXTI0 = 6;
    pub const I2C2_EV = 33;
    pub const TAMP_STAMP = 2;
    pub const I2C1_EV = 31;
    pub const EXTI1 = 7;
    pub const SPI4 = 84;
    pub const TIM2 = 28;
    pub const EXTI15_10 = 40;
    pub const ADC = 18;
    pub const OTG_FS_WKUP = 42;
    pub const EXTI2 = 8;
    pub const RCC = 5;
    pub const TIM1_UP_TIM10 = 25;
    pub const I2C1_ER = 32;
    pub const I2C3_EV = 72;
    pub const OTG_FS = 67;
    pub const FLASH = 4;
    pub const PVD = 1;
    pub const TIM1_BRK_TIM9 = 24;
    pub const TIM3 = 29;
    pub const SDIO = 49;
    pub const SPI1 = 35;
    pub const FPU = 81;
    pub const EXTI4 = 10;
};
