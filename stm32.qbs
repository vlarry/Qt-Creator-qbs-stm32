import qbs

Project {
    minimumQbsVersion: "1.6.0"

    Product
    {
        property string optimization: "fast"

        type: ["application", "flash"]

        Depends
        {
            name: "cpp"
        }

        cpp.defines: ["STM32F10X_LD_VL"]
        cpp.positionIndependentCode: false
        cpp.enableExceptions: false
        cpp.executableSuffix: ".elf"
        cpp.cxxFlags: ["-std=c++11"]
        cpp.cFlags: ["-std=gnu99"]

        Properties
        {
            condition: qbs.buildVariant === "debug"
            cpp.defines: outer.concat(["DEBUG=1"])
            cpp.debugInformation: true
            cpp.optimization: "none"
        }

        Properties
        {
            condition: qbs.buildVariant === "release"
            cpp.debugInformation: false
            cpp.optimization: optimization
        }

        files:
        [
                 "src/system/cmsis/*.h",
                 "src/system/cmsis/*.h",
                 "src/system/cmsis_boot/*.h",
                 "src/system/cmsis_boot/*.c",
                 "src/system/cmsis_boot/startup/*.c",
                 "src/main.cpp"
        ]

        cpp.driverFlags:
        [
                  "-mthumb",
                  "-mcpu=cortex-m3",
                  "-mfloat-abi=soft",
                  "-fno-strict-aliasing",
                  "-g3",
                  "-Wall",
                  "-mfpu=vfp",
                  "-flto"
        ]

        cpp.commonCompilerFlags:
        [
                  "-fdata-sections",
                  "-ffunction-sections",
                  "-fno-inline",
                  "-flto"
        ]

        cpp.linkerFlags:
        [
                  //"--specs=nano.specs",
                  "--start-group",
                  "--gc-sections",
                  "-T" + path + "/src/system/linker/stm32f10x_flash.ld",
                  "-lnosys",
                  "-lgcc",
                  "-lc",
                  "-lstdc++",
                  "-lm"
        ]

        cpp.includePaths:
        [
                  "src/system/cmsis",
                  "src/system/cmsis_boot",
                  "src/system/cmsis_boot/statup"
        ]

        Rule
        {
            inputs: ["application"]

            Artifact
            {
                filePath: project.buildDirectory + product.name + ".hex"
                fileTags: "flash"
            }

            prepare:
            {
                var GCCPath = "c:/development/gcc-arm/bin"
                var OpenOCDPath = "c:/development/openocd_0_10_0"
                var OpenOCDInterface = "stlink-v2.cfg"
                var OpenOCDTarget = "stm32f1x.cfg"
//                var OpenOCDTarget = "stm32f0x.cfg"

                var argsSize = [input.filePath]
                var argsObjcopy = ["-O", "ihex", input.filePath, output.filePath]

                var argsFlashing =
                [
                            "-f", OpenOCDPath + "/scripts/interface/" + OpenOCDInterface,
                            "-f", OpenOCDPath + "/scripts/target/" + OpenOCDTarget,
                            "-c", "init",
                            "-c", "halt",
                            "-c", "flash write_image erase " + input.filePath,
                            "-c", "reset",
                            "-c", "shutdown"
                ]

                var cmdSize = new Command(GCCPath + "/arm-none-eabi-size.exe", argsSize)
                var cmdObjcopy = new Command(GCCPath + "/arm-none-eabi-objcopy.exe", argsObjcopy)
                var cmdFlash = new Command(OpenOCDPath + "/bin/openocd.exe", argsFlashing);

                cmdSize.description = "Size of sections:"
                cmdSize.highlight = "linker"

                cmdObjcopy.description = "convert to bin..."
                cmdObjcopy.highlight = "linker"

                cmdFlash.description = "download firmware to uC..."
                cmdFlash.highlight = "linker"

                return [cmdSize, cmdObjcopy, cmdFlash]
            }
        }
    }
}
